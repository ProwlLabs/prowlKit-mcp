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
                server: server,
                progressToken: params._meta?.progressToken,
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
                server: server,
                progressToken: params._meta?.progressToken,
                projectPath: projectPath, scheme: scheme, destination: destination)

        case gitInfoTool.name:
            guard let repoPath = params.arguments?["repo_path"]?.stringValue else {
                throw MCPError.invalidParams("Missing required argument: repo_path")
            }
            guard let action = params.arguments?["action"]?.stringValue else {
                throw MCPError.invalidParams("Missing required argument: action")
            }
            let targetFile = params.arguments?["target_file"]?.stringValue
            return try await runGitInfo(repoPath: repoPath, action: action, targetFile: targetFile)

        case swiftLintTool.name:
            guard let projectPath = params.arguments?["project_path"]?.stringValue else {
                throw MCPError.invalidParams("Missing required argument: project_path")
            }
            let targetPath = params.arguments?["target_path"]?.stringValue
            return try await runSwiftLint(projectPath: projectPath, targetPath: targetPath)

        case sourceKitLSPTool.name:
            guard let projectPath = params.arguments?["project_path"]?.stringValue else {
                throw MCPError.invalidParams("Missing required argument: project_path")
            }
            guard let action = params.arguments?["action"]?.stringValue else {
                throw MCPError.invalidParams("Missing required argument: action")
            }
            guard let file = params.arguments?["file"]?.stringValue else {
                throw MCPError.invalidParams("Missing required argument: file")
            }
            guard let line = params.arguments?["line"]?.intValue ?? params.arguments?["line"]?.intValue ?? Int(params.arguments?["line"]?.stringValue ?? "") else {
                throw MCPError.invalidParams("Missing required argument: line")
            }
            guard let character = params.arguments?["character"]?.intValue ?? params.arguments?["character"]?.intValue ?? Int(params.arguments?["character"]?.stringValue ?? "") else {
                throw MCPError.invalidParams("Missing required argument: character")
            }
            return try await runSourceKitLSPQuery(projectPath: projectPath, action: action, file: file, line: line, character: character)

        default:
            throw MCPError.invalidParams("Unknown tool: \(params.name)")
        }
    }
}
