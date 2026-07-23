//
//  GitRunner.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation
import Logging
import MCP

private let gitLogger = Logger(label: "com.prowllabs.prowl-mcp.gitrunner")

func runGitInfo(repoPath rawPath: String, action rawAction: String, targetFile: String?)
    async throws -> CallTool.Result
{
    let repoPath: String
    do {
        repoPath = try validateDirectoryPath(rawPath)
    } catch {
        return CallTool.Result(
            content: [.text(text: "\(error)", annotations: nil, _meta: nil)], isError: true)
    }

    guard rawAction == "diff" || rawAction == "blame" else {
        return CallTool.Result(
            content: [.text(text: "Invalid action: \(rawAction)", annotations: nil, _meta: nil)],
            isError: true)
    }

    if rawAction == "blame" && targetFile == nil {
        return CallTool.Result(
            content: [
                .text(
                    text: "target_file is required for blame action", annotations: nil, _meta: nil)
            ], isError: true)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.currentDirectoryURL = URL(fileURLWithPath: repoPath)

    var arguments = [rawAction]
    if let targetFile {
        arguments.append(targetFile)
    }

    process.arguments = arguments
    gitLogger.info("Running git \(arguments.joined(separator: " ")) in \(repoPath)")

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
        let errString = String(data: errData, encoding: .utf8) ?? "Unknown git error"
        gitLogger.error("git \(rawAction) failed: \(errString)")
        return CallTool.Result(
            content: [
                .text(text: "Git command failed:\n\(errString)", annotations: nil, _meta: nil)
            ],
            isError: true
        )
    }

    let outString = String(data: outData, encoding: .utf8) ?? ""
    return CallTool.Result(content: [.text(text: outString, annotations: nil, _meta: nil)])
}
