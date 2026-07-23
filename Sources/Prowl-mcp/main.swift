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

let prowlMCPVersion = "0.0.2"

if CommandLine.arguments.contains("--version") {
    print("prowl-mcp \(prowlMCPVersion)")
    exit(0)
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
