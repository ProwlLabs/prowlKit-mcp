//
//  Tools+Handlers.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation
import MCP

private func envDefault(_ key: String) -> String? {
    guard let value = ProcessInfo.processInfo.environment[key], !value.isEmpty else {
        return nil
    }
    return value
}

func registerToolHandlers(on server: Server) async {
    await server.withMethodHandler(ListTools.self) { _ in
        ListTools.Result(tools: allTools)
    }

    await server.withMethodHandler(CallTool.self) { params in
        switch params.name {
        case listSchemesTool.name:
            guard let projectPath = params.arguments?["project_path"]?.stringValue else {
                throw MCPError.invalidParams("Missing required argument: project_path")
            }
            return try await runXcodebuildList(projectPath: projectPath)

        case buildProjectTool.name:
            guard let projectPath = params.arguments?["project_path"]?.stringValue else {
                throw MCPError.invalidParams("Missing required argument: project_path")
            }
            guard
                let scheme = params.arguments?["scheme"]?.stringValue
                    ?? envDefault("PROWL_MCP_DEFAULT_SCHEME")
            else {
                throw MCPError.invalidParams(
                    "Missing required argument: scheme (and no default_scheme configured in extension settings)"
                )
            }
            let configuration = params.arguments?["configuration"]?.stringValue
            return try await runXcodebuildBuild(
                projectPath: projectPath, scheme: scheme, configuration: configuration)

        case runTestsTool.name:
            guard let projectPath = params.arguments?["project_path"]?.stringValue else {
                throw MCPError.invalidParams("Missing required argument: project_path")
            }
            guard
                let scheme = params.arguments?["scheme"]?.stringValue
                    ?? envDefault("PROWL_MCP_DEFAULT_SCHEME")
            else {
                throw MCPError.invalidParams(
                    "Missing required argument: scheme (and no default_scheme configured in extension settings)"
                )
            }
            let destination =
                params.arguments?["destination"]?.stringValue
                ?? envDefault("PROWL_MCP_DEFAULT_DESTINATION")
            return try await runXcodebuildTests(
                projectPath: projectPath, scheme: scheme, destination: destination)

        default:
            throw MCPError.invalidParams("Unknown tool: \(params.name)")
        }
    }
}
