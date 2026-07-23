//
//  Diagnostics.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation
import MCP

struct Diagnostic {
    let file: String
    let line: Int
    let column: Int
    let severity: String
    let message: String

    func toValue() -> Value {
        .object([
            "file": .string(file),
            "line": .int(line),
            "column": .int(column),
            "severity": .string(severity),
            "message": .string(message),
        ])
    }
}

func parseXcodebuildDiagnostics(from output: String) -> [Diagnostic] {
    var diagnostics: [Diagnostic] = []
    let pattern = #"^(.+\.(?:swift|m|mm|h)):(\d+):(\d+):\s+(error|warning):\s+(.+)$"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
    else {
        return diagnostics
    }
    let nsrange = NSRange(output.startIndex..<output.endIndex, in: output)
    regex.enumerateMatches(in: output, options: [], range: nsrange) { match, _, _ in
        guard let match, match.numberOfRanges == 6 else { return }
        func group(_ idx: Int) -> String {
            guard let r = Range(match.range(at: idx), in: output) else { return "" }
            return String(output[r])
        }
        diagnostics.append(
            Diagnostic(
                file: group(1),
                line: Int(group(2)) ?? 0,
                column: Int(group(3)) ?? 0,
                severity: group(4),
                message: group(5)
            )
        )
    }
    return diagnostics
}

func encodeValueToJSONString(_ value: Value) throws -> String {
    let data = try JSONEncoder().encode(value)
    return String(data: data, encoding: .utf8) ?? "{}"
}
