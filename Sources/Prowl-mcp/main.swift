//
//  main.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation
import Logging
import MCP

let prowlMCPVersion = "0.0.3"

if CommandLine.arguments.contains("--version") {
    print("prowl-mcp \(prowlMCPVersion)")
    exit(0)
}

if CommandLine.arguments.contains("--setup") {
    let fileManager = FileManager.default
    let homeURL = fileManager.homeDirectoryForCurrentUser
    let claudeConfigURL = homeURL.appendingPathComponent(
        "Library/Application Support/Claude/claude_desktop_config.json")
    let claudeDir = claudeConfigURL.deletingLastPathComponent()

    if !fileManager.fileExists(atPath: claudeDir.path) {
        try? fileManager.createDirectory(
            at: claudeDir, withIntermediateDirectories: true, attributes: nil)
    }

    var config: [String: Any] = [:]
    if let data = try? Data(contentsOf: claudeConfigURL),
        let existingConfig = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    {
        config = existingConfig
    }

    var mcpServers = config["mcpServers"] as? [String: Any] ?? [:]
    let executablePath = Bundle.main.executablePath ?? "prowl-mcp"

    mcpServers["prowl-mcp"] = [
        "command": executablePath,
        "args": [],
    ]
    config["mcpServers"] = mcpServers

    do {
        let newData = try JSONSerialization.data(
            withJSONObject: config, options: [.prettyPrinted, .withoutEscapingSlashes])
        try newData.write(to: claudeConfigURL)
        print("Successfully configured Claude Desktop at: \(claudeConfigURL.path)")
        print("Restart Claude Desktop to start using ProwlMCP.")
        exit(0)
    } catch {
        print("Failed to write config: \(error.localizedDescription)")
        exit(1)
    }
}

LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardError(label: label)
    handler.logLevel = .info
    return handler
}
let logger = Logger(label: "com.prowllabs.prowl-mcp")

let server = Server(
    name: "prowl-mcp",
    version: prowlMCPVersion,
    capabilities: .init(tools: .init(listChanged: false))
)

await registerToolHandlers(on: server)

let transport = StdioTransport(logger: logger)
try await server.start(transport: transport)
await server.waitUntilCompleted()
