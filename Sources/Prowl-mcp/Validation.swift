//
//  Validation.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation
import Logging
import MCP

enum ValidationError: Error, CustomStringConvertible {
    case notAbsolutePath(String)
    case pathNotFound(String)
    case invalidExtension(String)
    case directoryNotFound(String)

    var description: String {
        switch self {
        case .notAbsolutePath(let path):
            return "project_path must be an absolute path, got: \(path)"
        case .pathNotFound(let path):
            return "No file exists at project_path: \(path)"
        case .invalidExtension(let path):
            return "project_path must end in .xcodeproj or .xcworkspace, got: \(path)"
        case .directoryNotFound(let path):
            return "Directory does not exist at path: \(path)"
        }
    }
}

actor WorkspaceSandbox {
    static let shared = WorkspaceSandbox()
    private var allowedRoot: String?

    func registerAndValidate(path: String) throws -> String {
        let standardized = URL(fileURLWithPath: path).standardized.path

        if let root = allowedRoot {
            guard standardized.hasPrefix(root) else {
                throw MCPError.invalidParams(
                    "Security Violation: Path \(standardized) is outside the allowed workspace root (\(root))."
                )
            }
        } else {
            let rootDir = URL(fileURLWithPath: standardized).deletingLastPathComponent().path
            allowedRoot = rootDir
            logger.info("🔒 Workspace Sandboxed to: \(rootDir)")
        }
        return standardized
    }
}

func validateProjectPath(_ path: String) async throws -> String {
    guard path.hasPrefix("/") else {
        throw ValidationError.notAbsolutePath(path)
    }

    guard path.hasSuffix(".xcodeproj") || path.hasSuffix(".xcworkspace") else {
        throw ValidationError.invalidExtension(path)
    }

    guard FileManager.default.fileExists(atPath: path) else {
        throw ValidationError.pathNotFound(path)
    }

    return try await WorkspaceSandbox.shared.registerAndValidate(path: path)
}

func validateScheme(_ scheme: String) throws -> String {
    guard !scheme.isEmpty, !scheme.hasPrefix("-") else {
        throw MCPError.invalidParams("Invalid scheme name: \(scheme)")
    }
    return scheme
}

func validateDirectoryPath(_ path: String) async throws -> String {
    guard path.hasPrefix("/") else {
        throw ValidationError.notAbsolutePath(path)
    }

    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
        isDirectory.boolValue
    else {
        throw ValidationError.directoryNotFound(path)
    }

    return try await WorkspaceSandbox.shared.registerAndValidate(path: path)
}
