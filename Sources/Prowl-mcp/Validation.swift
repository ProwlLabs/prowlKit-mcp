//
//  Validation.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation
import MCP

enum ValidationError: Error, CustomStringConvertible {
    case notAbsolutePath(String)
    case pathNotFound(String)
    case invalidExtension(String)

    var description: String {
        switch self {
        case .notAbsolutePath(let path):
            return "project_path must be an absolute path, got: \(path)"
        case .pathNotFound(let path):
            return "No file exists at project_path: \(path)"
        case .invalidExtension(let path):
            return "project_path must end in .xcodeproj or .xcworkspace, got: \(path)"
        }
    }
}

func validateProjectPath(_ path: String) throws -> String {
    guard path.hasPrefix("/") else {
        throw ValidationError.notAbsolutePath(path)
    }

    guard path.hasSuffix(".xcodeproj") || path.hasSuffix(".xcworkspace") else {
        throw ValidationError.invalidExtension(path)
    }

    guard FileManager.default.fileExists(atPath: path) else {
        throw ValidationError.pathNotFound(path)
    }

    return path
}

func validateScheme(_ scheme: String) throws -> String {
    guard !scheme.isEmpty, !scheme.hasPrefix("-") else {
        throw MCPError.invalidParams("Invalid scheme name: \(scheme)")
    }
    return scheme
}
