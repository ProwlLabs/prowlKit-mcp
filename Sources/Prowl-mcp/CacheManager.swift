//
//  CacheManager.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation

actor XcodebuildCache {
    static let shared = XcodebuildCache()

    struct CacheEntry {
        let output: String
        let modificationDate: Date
    }

    private var listCache: [String: CacheEntry] = [:]

    private func getModificationDate(for path: String) -> Date? {
        let isWorkspace = path.hasSuffix(".xcworkspace")
        let targetFile =
            isWorkspace
            ? URL(fileURLWithPath: path).appendingPathComponent("contents.xcworkspacedata").path
            : URL(fileURLWithPath: path).appendingPathComponent("project.pbxproj").path

        guard let attr = try? FileManager.default.attributesOfItem(atPath: targetFile),
            let date = attr[.modificationDate] as? Date
        else {
            return nil
        }
        return date
    }

    func getCachedList(for projectPath: String) -> String? {
        guard let entry = listCache[projectPath],
            let currentModDate = getModificationDate(for: projectPath),
            entry.modificationDate >= currentModDate
        else {
            return nil
        }
        return entry.output
    }

    func setCachedList(for projectPath: String, output: String) {
        guard let currentModDate = getModificationDate(for: projectPath) else { return }
        listCache[projectPath] = CacheEntry(output: output, modificationDate: currentModDate)
    }
}
