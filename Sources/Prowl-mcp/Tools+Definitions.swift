//
//  Tools+Definitions.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import MCP

let listSchemesTool = Tool(
    name: "list_schemes_targets",
    description: "List the schemes and targets available in an Xcode project or workspace",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "project_path": .object([
                "type": .string("string"),
                "description": .string("Absolute path to the .xcodeproj or .xcworkspace"),
            ])
        ]),
        "required": .array([.string("project_path")]),
    ])
)

let buildProjectTool = Tool(
    name: "build_project",
    description:
        "Build an Xcode project or workspace for a given scheme and return structured errors and warnings (file, line, column, message) instead of raw log output",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "project_path": .object([
                "type": .string("string"),
                "description": .string("Absolute path to the .xcodeproj or .xcworkspace"),
            ]),
            "scheme": .object([
                "type": .string("string"),
                "description": .string("Scheme to build"),
            ]),
            "configuration": .object([
                "type": .string("string"),
                "description": .string("Build configuration, e.g. Debug-Development. Optional."),
            ]),
        ]),
        "required": .array([.string("project_path"), .string("scheme")]),
    ])
)

let runTestsTool = Tool(
    name: "run_tests",
    description:
        "Run tests for a given scheme on an iOS Simulator destination and return a structured pass/fail summary with failure reasons",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "project_path": .object([
                "type": .string("string"),
                "description": .string("Absolute path to the .xcodeproj or .xcworkspace"),
            ]),
            "scheme": .object([
                "type": .string("string"),
                "description": .string("Scheme to test"),
            ]),
            "destination": .object([
                "type": .string("string"),
                "description": .string(
                    "xcodebuild -destination string, e.g. 'platform=iOS Simulator,name=iPhone 16'. Optional — defaults to iPhone 16 simulator."
                ),
            ]),
        ]),
        "required": .array([.string("project_path"), .string("scheme")]),
    ])
)

let allTools: [Tool] = [listSchemesTool, buildProjectTool, runTestsTool]
