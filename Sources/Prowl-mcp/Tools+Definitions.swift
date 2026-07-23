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
        "Build an Xcode project or workspace for a given scheme and return a concise, formatted summary of errors and warnings (using xcbeautify if available). If scheme is omitted, falls back to the default_scheme configured in the extension settings.",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "project_path": .object([
                "type": .string("string"),
                "description": .string("Absolute path to the .xcodeproj or .xcworkspace"),
            ]),
            "scheme": .object([
                "type": .string("string"),
                "description": .string(
                    "Scheme to build. Optional if a default_scheme is configured in extension settings."
                ),
            ]),
            "configuration": .object([
                "type": .string("string"),
                "description": .string("Build configuration, e.g. Debug-Development. Optional."),
            ]),
        ]),
        "required": .array([.string("project_path")]),
    ])
)

let runTestsTool = Tool(
    name: "run_tests",
    description:
        "Run tests for a given scheme on an iOS Simulator destination and return a structured pass/fail summary with failure reasons. If scheme or destination are omitted, falls back to the defaults configured in the extension settings.",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "project_path": .object([
                "type": .string("string"),
                "description": .string("Absolute path to the .xcodeproj or .xcworkspace"),
            ]),
            "scheme": .object([
                "type": .string("string"),
                "description": .string(
                    "Scheme to test. Optional if a default_scheme is configured in extension settings."
                ),
            ]),
            "destination": .object([
                "type": .string("string"),
                "description": .string(
                    "xcodebuild -destination string, e.g. 'platform=iOS Simulator,name=iPhone 16'. Optional — falls back to default_destination config, then iPhone 16 simulator."
                ),
            ]),
        ]),
        "required": .array([.string("project_path")]),
    ])
)

let gitInfoTool = Tool(
    name: "git_info",
    description: "Run git diff or git blame on a repository or specific file",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "repo_path": .object([
                "type": .string("string"),
                "description": .string("Absolute path to the git repository"),
            ]),
            "action": .object([
                "type": .string("string"),
                "enum": .array([.string("diff"), .string("blame")]),
                "description": .string("Git action to perform: 'diff' or 'blame'"),
            ]),
            "target_file": .object([
                "type": .string("string"),
                "description": .string("Specific file to run action on (optional for diff, required for blame)"),
            ]),
        ]),
        "required": .array([.string("repo_path"), .string("action")]),
    ])
)

let swiftLintTool = Tool(
    name: "swiftlint",
    description: "Run SwiftLint on a specific path to check for Swift coding style and convention violations",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "project_path": .object([
                "type": .string("string"),
                "description": .string("Absolute path to the project root directory"),
            ]),
            "target_path": .object([
                "type": .string("string"),
                "description": .string("Specific file or directory to lint within the project. If omitted, lints the whole project."),
            ]),
        ]),
        "required": .array([.string("project_path")]),
    ])
)

let sourceKitLSPTool = Tool(
    name: "sourcekit_lsp_query",
    description: "Run SourceKit-LSP to query symbols, find definitions, or get hover documentation. Action can be 'definition', 'hover', or 'references'.",
    inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "project_path": .object([
                "type": .string("string"),
                "description": .string("Absolute path to the project root directory"),
            ]),
            "action": .object([
                "type": .string("string"),
                "enum": .array([.string("definition"), .string("hover"), .string("references")]),
                "description": .string("LSP action to perform"),
            ]),
            "file": .object([
                "type": .string("string"),
                "description": .string("Absolute path to the Swift file"),
            ]),
            "line": .object([
                "type": .string("integer"),
                "description": .string("0-based line number"),
            ]),
            "character": .object([
                "type": .string("integer"),
                "description": .string("0-based character/column number"),
            ]),
        ]),
        "required": .array([.string("project_path"), .string("action"), .string("file"), .string("line"), .string("character")]),
    ])
)

let allTools: [Tool] = [listSchemesTool, buildProjectTool, runTestsTool, gitInfoTool, swiftLintTool, sourceKitLSPTool]
