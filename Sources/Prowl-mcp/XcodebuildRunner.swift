//
//  XcodebuildRunner.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation
import MCP

func runXcodebuildList(projectPath: String) async throws -> CallTool.Result {
    let isWorkspace = projectPath.hasSuffix(".xcworkspace")
    let flag = isWorkspace ? "-workspace" : "-project"

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
    process.arguments = [flag, projectPath, "-list", "-json"]

    let outPipe = Pipe()
    let errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errPipe

    do {
        try process.run()
    } catch {
        return CallTool.Result(
            content: [
                .text(
                    text: "Failed to launch xcodebuild: \(error.localizedDescription)",
                    annotations: nil, _meta: nil)
            ],
            isError: true
        )
    }

    process.waitUntilExit()

    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

    if process.terminationStatus != 0 {
        let errString = String(data: errData, encoding: .utf8) ?? "Unknown error"
        return CallTool.Result(
            content: [
                .text(text: "xcodebuild failed:\n\(errString)", annotations: nil, _meta: nil)
            ],
            isError: true
        )
    }

    let outString = String(data: outData, encoding: .utf8) ?? "{}"
    return CallTool.Result(content: [.text(text: outString, annotations: nil, _meta: nil)])
}

func runXcodebuildBuild(projectPath: String, scheme: String, configuration: String?) async throws
    -> CallTool.Result
{
    let isWorkspace = projectPath.hasSuffix(".xcworkspace")
    let flag = isWorkspace ? "-workspace" : "-project"

    var arguments = [flag, projectPath, "-scheme", scheme, "build"]
    if let configuration {
        arguments += ["-configuration", configuration]
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
    process.arguments = arguments

    let outPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = outPipe

    do {
        try process.run()
    } catch {
        return CallTool.Result(
            content: [
                .text(
                    text: "Failed to launch xcodebuild: \(error.localizedDescription)",
                    annotations: nil, _meta: nil)
            ],
            isError: true
        )
    }

    process.waitUntilExit()

    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let outString = String(data: outData, encoding: .utf8) ?? ""

    let diagnostics = parseXcodebuildDiagnostics(from: outString)
    let succeeded = process.terminationStatus == 0
    let errorCount = diagnostics.filter { $0.severity == "error" }.count
    let warningCount = diagnostics.filter { $0.severity == "warning" }.count

    let resultValue: Value = .object([
        "success": .bool(succeeded),
        "errorCount": .int(errorCount),
        "warningCount": .int(warningCount),
        "diagnostics": .array(diagnostics.map { $0.toValue() }),
    ])

    let jsonString = (try? encodeValueToJSONString(resultValue)) ?? "{}"
    return CallTool.Result(
        content: [.text(text: jsonString, annotations: nil, _meta: nil)], isError: !succeeded)
}

func runXcodebuildTests(projectPath: String, scheme: String, destination: String?) async throws
    -> CallTool.Result
{
    let isWorkspace = projectPath.hasSuffix(".xcworkspace")
    let flag = isWorkspace ? "-workspace" : "-project"

    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("prowl-mcp-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    let resultBundlePath = tempDir.appendingPathComponent("TestResults.xcresult").path
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let dest = destination ?? "platform=iOS Simulator,name=iPhone 16"
    let arguments = [
        flag, projectPath,
        "-scheme", scheme,
        "-destination", dest,
        "-resultBundlePath", resultBundlePath,
        "test",
    ]

    let testProcess = Process()
    testProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
    testProcess.arguments = arguments

    let testOutPipe = Pipe()
    testProcess.standardOutput = testOutPipe
    testProcess.standardError = testOutPipe

    do {
        try testProcess.run()
    } catch {
        return CallTool.Result(
            content: [
                .text(
                    text: "Failed to launch xcodebuild: \(error.localizedDescription)",
                    annotations: nil, _meta: nil)
            ],
            isError: true
        )
    }
    testProcess.waitUntilExit()

    _ = testOutPipe.fileHandleForReading.readDataToEndOfFile()

    let summaryProcess = Process()
    summaryProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    summaryProcess.arguments = [
        "xcresulttool", "get", "test-results", "summary",
        "--path", resultBundlePath,
        "--format", "json",
    ]

    let summaryOutPipe = Pipe()
    let summaryErrPipe = Pipe()
    summaryProcess.standardOutput = summaryOutPipe
    summaryProcess.standardError = summaryErrPipe

    do {
        try summaryProcess.run()
    } catch {
        return CallTool.Result(
            content: [
                .text(
                    text:
                        "Tests finished (xcodebuild exit code \(testProcess.terminationStatus)) but failed to read result bundle: \(error.localizedDescription)",
                    annotations: nil, _meta: nil
                )
            ],
            isError: true
        )
    }
    summaryProcess.waitUntilExit()

    let summaryData = summaryOutPipe.fileHandleForReading.readDataToEndOfFile()
    let summaryErrData = summaryErrPipe.fileHandleForReading.readDataToEndOfFile()

    if summaryProcess.terminationStatus != 0 {
        let errString = String(data: summaryErrData, encoding: .utf8) ?? "Unknown error"
        return CallTool.Result(
            content: [
                .text(
                    text:
                        "xcresulttool failed (your Xcode version may not support 'test-results summary' — try 'xcrun xcresulttool get --format json --path \(resultBundlePath)' manually):\n\(errString)",
                    annotations: nil, _meta: nil
                )
            ],
            isError: true
        )
    }

    let summaryString = String(data: summaryData, encoding: .utf8) ?? "{}"
    return CallTool.Result(content: [.text(text: summaryString, annotations: nil, _meta: nil)])
}
