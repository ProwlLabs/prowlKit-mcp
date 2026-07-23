//
//  DiagnosticsTests.swift
//  Prowl-MCPTests
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import XCTest

@testable import prowl_mcp

final class DiagnosticsTests: XCTestCase {

    func testParsesSingleError() {
        let output = """
            /Users/elmee/Saldoo/Sources/PaymentViewModel.swift:42:15: error: cannot find 'amount' in scope
            ** BUILD FAILED **
            """

        let diagnostics = parseXcodebuildDiagnostics(from: output)

        XCTAssertEqual(diagnostics.count, 1)
        XCTAssertEqual(diagnostics[0].file, "/Users/elmee/Saldoo/Sources/PaymentViewModel.swift")
        XCTAssertEqual(diagnostics[0].line, 42)
        XCTAssertEqual(diagnostics[0].column, 15)
        XCTAssertEqual(diagnostics[0].severity, "error")
        XCTAssertEqual(diagnostics[0].message, "cannot find 'amount' in scope")
    }

    func testParsesMixedErrorsAndWarnings() {
        let output = """
            /Project/A.swift:10:2: warning: variable 'x' was never used
            /Project/B.swift:88:33: error: missing return in function
            Some unrelated build log line
            /Project/C.m:5:1: warning: unused import
            """

        let diagnostics = parseXcodebuildDiagnostics(from: output)

        XCTAssertEqual(diagnostics.count, 3)
        XCTAssertEqual(diagnostics.filter { $0.severity == "error" }.count, 1)
        XCTAssertEqual(diagnostics.filter { $0.severity == "warning" }.count, 2)
    }

    func testReturnsEmptyForCleanBuildOutput() {
        let output = """
            Build settings from command line:
            ** BUILD SUCCEEDED **
            """

        let diagnostics = parseXcodebuildDiagnostics(from: output)

        XCTAssertTrue(diagnostics.isEmpty)
    }

    func testIgnoresLinesThatLookSimilarButArentDiagnostics() {
        // e.g. a stack trace or a path mentioned in prose shouldn't false-positive
        let output = "See /Project/Notes.txt:10:2 for more context (not a real diagnostic)"

        let diagnostics = parseXcodebuildDiagnostics(from: output)

        XCTAssertTrue(
            diagnostics.isEmpty, "Non .swift/.m/.mm/.h files should not be parsed as diagnostics")
    }

    func testDiagnosticEncodesToExpectedJSONShape() throws {
        let diagnostic = Diagnostic(
            file: "/A.swift", line: 1, column: 2, severity: "error", message: "boom")
        let json = try encodeValueToJSONString(diagnostic.toValue())

        XCTAssertTrue(json.contains("\"file\""))
        XCTAssertTrue(json.contains("\"line\""))
        XCTAssertTrue(json.contains("\"severity\""))
        XCTAssertTrue(json.contains("boom"))
    }
}
