//
//  Tools+Handlers.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import MCP

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
            guard let projectPath = params.arguments?["project_path"]?.stringValue,
                let scheme = params.arguments?["scheme"]?.stringValue
            else {
                throw MCPError.invalidParams("Missing required arguments: project_path, scheme")
            }
            let configuration = params.arguments?["configuration"]?.stringValue
            return try await runXcodebuildBuild(
                projectPath: projectPath, scheme: scheme, configuration: configuration)

        case runTestsTool.name:
            guard let projectPath = params.arguments?["project_path"]?.stringValue,
                let scheme = params.arguments?["scheme"]?.stringValue
            else {
                throw MCPError.invalidParams("Missing required arguments: project_path, scheme")
            }
            let destination = params.arguments?["destination"]?.stringValue
            return try await runXcodebuildTests(
                projectPath: projectPath, scheme: scheme, destination: destination)

        default:
            throw MCPError.invalidParams("Unknown tool: \(params.name)")
        }
    }
}
