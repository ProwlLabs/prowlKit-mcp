//
//  SwiftLintRunner.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation
import Logging
import MCP

private let swiftLintLogger = Logger(label: "com.prowllabs.prowl-mcp.swiftlintrunner")

func runSwiftLint(projectPath rawPath: String, targetPath: String?) async throws -> CallTool.Result
{
    let projectPath: String
    do {
        projectPath = try validateDirectoryPath(rawPath)
    } catch {
        return CallTool.Result(
            content: [.text(text: "\(error)", annotations: nil, _meta: nil)], isError: true)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.currentDirectoryURL = URL(fileURLWithPath: projectPath)

    var arguments = ["swiftlint", "lint", "--reporter", "json"]
    if let targetPath {
        arguments.append(targetPath)
    }

    process.arguments = arguments
    swiftLintLogger.info("Running \(arguments.joined(separator: " ")) in \(projectPath)")

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

    let outString = String(data: outData, encoding: .utf8) ?? ""

    let isJSON = outString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[")

    if !isJSON && process.terminationStatus != 0 {
        let errString = String(data: errData, encoding: .utf8) ?? "Unknown swiftlint error"
        swiftLintLogger.error("swiftlint failed: \(errString)")

        var errorMsg = errString
        if errString.isEmpty || errString.contains("No such file or directory") {
            errorMsg =
                "swiftlint command not found. Please ensure SwiftLint is installed (e.g., `brew install swiftlint`) and available in your PATH."
        }

        return CallTool.Result(
            content: [
                .text(text: "SwiftLint command failed:\n\(errorMsg)", annotations: nil, _meta: nil)
            ],
            isError: true
        )
    }

    return CallTool.Result(content: [
        .text(text: outString.isEmpty ? "[]" : outString, annotations: nil, _meta: nil)
    ])
}
