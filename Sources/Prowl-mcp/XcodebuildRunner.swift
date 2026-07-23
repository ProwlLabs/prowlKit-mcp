//
//  XcodebuildRunner.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation
import Logging
import MCP

private let runnerLogger = Logger(label: "com.prowllabs.prowl-mcp.runner")

private func findXcbeautify() -> URL? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    process.arguments = ["xcbeautify"]
    let pipe = Pipe()
    process.standardOutput = pipe
    try? process.run()
    process.waitUntilExit()
    if process.terminationStatus == 0 {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let path = path, !path.isEmpty {
            return URL(fileURLWithPath: path)
        }
    }
    return nil
}

func runXcodebuildList(projectPath rawPath: String) async throws -> CallTool.Result {
    let projectPath: String
    do {
        projectPath = try await validateProjectPath(rawPath)
    } catch {
        return CallTool.Result(
            content: [.text(text: "\(error)", annotations: nil, _meta: nil)], isError: true)
    }

    if let cachedOutput = await XcodebuildCache.shared.getCachedList(for: projectPath) {
        runnerLogger.info("Returning cached xcodebuild -list for \(projectPath)")
        return CallTool.Result(content: [.text(text: cachedOutput, annotations: nil, _meta: nil)])
    }

    let isWorkspace = projectPath.hasSuffix(".xcworkspace")
    let flag = isWorkspace ? "-workspace" : "-project"
    let arguments = [flag, projectPath, "-list", "-json"]

    runnerLogger.info("Running xcodebuild \(arguments.joined(separator: " "))")

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
    process.arguments = arguments

    let outPipe = Pipe()
    let errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errPipe

    do {
        try await runProcessWithTimeout(process, timeoutSeconds: 60)
    } catch {
        return CallTool.Result(
            content: [.text(text: "\(error)", annotations: nil, _meta: nil)], isError: true)
    }

    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

    if process.terminationStatus != 0 {
        let errString = String(data: errData, encoding: .utf8) ?? "Unknown error"
        runnerLogger.error("xcodebuild -list failed: \(errString)")
        return CallTool.Result(
            content: [
                .text(text: "xcodebuild failed:\n\(errString)", annotations: nil, _meta: nil)
            ],
            isError: true
        )
    }

    let outString = String(data: outData, encoding: .utf8) ?? "{}"
    await XcodebuildCache.shared.setCachedList(for: projectPath, output: outString)
    return CallTool.Result(content: [.text(text: outString, annotations: nil, _meta: nil)])
}

func runXcodebuildBuild(
    server: Server?,
    progressToken: ProgressToken?,
    projectPath rawPath: String, scheme rawScheme: String, configuration: String?
) async throws -> CallTool.Result {
    let projectPath: String
    let scheme: String
    do {
        projectPath = try await validateProjectPath(rawPath)
        scheme = try validateScheme(rawScheme)
    } catch {
        return CallTool.Result(
            content: [.text(text: "\(error)", annotations: nil, _meta: nil)], isError: true)
    }

    let isWorkspace = projectPath.hasSuffix(".xcworkspace")
    let flag = isWorkspace ? "-workspace" : "-project"

    var arguments = [flag, projectPath, "-scheme", scheme, "build"]
    if let configuration {
        arguments += ["-configuration", configuration]
    }

    let process = Process()
    if let xcbeautify = findXcbeautify() {
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        let argsString = arguments.map { "\"\($0)\"" }.joined(separator: " ")
        process.arguments = ["-c", "set -o pipefail && /usr/bin/xcodebuild \(argsString) | \"\(xcbeautify.path)\""]
        runnerLogger.info("Running xcodebuild \(arguments.joined(separator: " ")) | xcbeautify")
    } else {
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = arguments
        runnerLogger.info("Running xcodebuild \(arguments.joined(separator: " "))")
    }

    let outPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = outPipe

    do {
        try process.run()
    } catch {
        return CallTool.Result(
            content: [.text(text: "\(error)", annotations: nil, _meta: nil)], isError: true)
    }

    let outputTask = Task {
        var fullOutput = ""
        var lineCount = 0
        if #available(macOS 12.0, *) {
            do {
                for try await line in outPipe.fileHandleForReading.bytes.lines {
                    fullOutput += line + "\n"
                    lineCount += 1
                    
                    if let server = server, let token = progressToken, lineCount % 5 == 0 {
                        let note = Message<ProgressNotification>(
                            method: ProgressNotification.name,
                            params: ProgressNotification.Parameters(
                                progressToken: token,
                                progress: Double(lineCount),
                                total: nil,
                                message: line
                            )
                        )
                        try? await server.notify(note)
                    }
                }
            } catch {
                runnerLogger.error("Error reading output stream: \(error)")
            }
        } else {
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            fullOutput = String(data: data, encoding: .utf8) ?? ""
        }
        return fullOutput
    }

    let timeoutTask = Task {
        try await Task.sleep(nanoseconds: 300 * 1_000_000_000)
        process.terminate()
        throw MCPError.internalError("Timeout")
    }

    let fullOutput = await outputTask.value
    timeoutTask.cancel()
    process.waitUntilExit()

    let succeeded = process.terminationStatus == 0
    runnerLogger.info("Build finished: success=\(succeeded)")

    return CallTool.Result(
        content: [.text(text: fullOutput, annotations: nil, _meta: nil)], isError: !succeeded)
}

func runXcodebuildTests(
    server: Server?,
    progressToken: ProgressToken?,
    projectPath rawPath: String, scheme rawScheme: String, destination: String?
) async throws -> CallTool.Result {
    let projectPath: String
    let scheme: String
    do {
        projectPath = try await validateProjectPath(rawPath)
        scheme = try validateScheme(rawScheme)
    } catch {
        return CallTool.Result(
            content: [.text(text: "\(error)", annotations: nil, _meta: nil)], isError: true)
    }

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

    runnerLogger.info("Running xcodebuild \(arguments.joined(separator: " "))")

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
            content: [.text(text: "\(error)", annotations: nil, _meta: nil)], isError: true)
    }

    let outputTask = Task {
        var lineCount = 0
        if #available(macOS 12.0, *) {
            do {
                for try await line in testOutPipe.fileHandleForReading.bytes.lines {
                    lineCount += 1
                    if let server = server, let token = progressToken, lineCount % 5 == 0 {
                        let note = Message<ProgressNotification>(
                            method: ProgressNotification.name,
                            params: ProgressNotification.Parameters(
                                progressToken: token,
                                progress: Double(lineCount),
                                total: nil,
                                message: line
                            )
                        )
                        try? await server.notify(note)
                    }
                }
            } catch {
                runnerLogger.error("Error reading test output stream: \(error)")
            }
        } else {
            _ = testOutPipe.fileHandleForReading.readDataToEndOfFile()
        }
    }

    let timeoutTask = Task {
        try await Task.sleep(nanoseconds: 600 * 1_000_000_000)
        testProcess.terminate()
        throw MCPError.internalError("Timeout")
    }

    _ = await outputTask.value
    timeoutTask.cancel()
    testProcess.waitUntilExit()

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
        try await runProcessWithTimeout(summaryProcess, timeoutSeconds: 30)
    } catch {
        return CallTool.Result(
            content: [
                .text(
                    text:
                        "Tests finished (xcodebuild exit code \(testProcess.terminationStatus)) but failed to read result bundle: \(error)",
                    annotations: nil, _meta: nil
                )
            ],
            isError: true
        )
    }

    let summaryData = summaryOutPipe.fileHandleForReading.readDataToEndOfFile()
    let summaryErrData = summaryErrPipe.fileHandleForReading.readDataToEndOfFile()

    if summaryProcess.terminationStatus != 0 {
        let errString = String(data: summaryErrData, encoding: .utf8) ?? "Unknown error"
        runnerLogger.error("xcresulttool failed: \(errString)")
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
