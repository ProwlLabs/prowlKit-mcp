//
//  SourceKitRunner.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation
import MCP

func runSourceKitLSPQuery(
    projectPath rawPath: String,
    action: String,
    file: String,
    line: Int,
    character: Int
) async throws -> CallTool.Result {
    let projectPath = try await validateDirectoryPath(rawPath)

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["sourcekit-lsp"]
    process.currentDirectoryURL = URL(fileURLWithPath: projectPath)

    let inPipe = Pipe()
    let outPipe = Pipe()
    process.standardInput = inPipe
    process.standardOutput = outPipe

    try process.run()

    func sendRequest(id: Int, method: String, params: [String: Any]?) {
        var payload: [String: Any] = ["jsonrpc": "2.0", "method": method]
        if let id = id as Int? { payload["id"] = id }
        if let params = params { payload["params"] = params }
        let json = try! JSONSerialization.data(withJSONObject: payload)
        let header = "Content-Length: \(json.count)\r\n\r\n"
        inPipe.fileHandleForWriting.write(header.data(using: .utf8)!)
        inPipe.fileHandleForWriting.write(json)
    }

    sendRequest(
        id: 1, method: "initialize",
        params: [
            "processId": ProcessInfo.processInfo.processIdentifier,
            "rootUri": "file://\(projectPath)",
            "capabilities": [:],
        ])

    let method: String = {
        switch action {
        case "definition": return "textDocument/definition"
        case "references": return "textDocument/references"
        case "hover": return "textDocument/hover"
        default: return "textDocument/definition"
        }
    }()

    var actionParams: [String: Any] = [
        "textDocument": ["uri": "file://\(file)"],
        "position": ["line": line, "character": character],
    ]
    if action == "references" {
        actionParams["context"] = ["includeDeclaration": true]
    }

    sendRequest(id: 2, method: method, params: actionParams)

    sendRequest(id: 3, method: "shutdown", params: nil)
    sendRequest(id: 4, method: "exit", params: nil)

    try? inPipe.fileHandleForWriting.close()

    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let outString = String(data: outData, encoding: .utf8) ?? ""

    let components = outString.components(separatedBy: "Content-Length:")
    var resultJson = "{}"
    for component in components {
        guard let range = component.range(of: "\r\n\r\n") else { continue }
        let jsonPart = String(component[range.upperBound...])
        if let data = jsonPart.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            if let id = obj["id"] as? Int, id == 2 {
                if let result = obj["result"] {
                    let resultData = try! JSONSerialization.data(
                        withJSONObject: result, options: .prettyPrinted)
                    resultJson = String(data: resultData, encoding: .utf8) ?? "{}"
                } else if let error = obj["error"] {
                    let errorData = try! JSONSerialization.data(
                        withJSONObject: error, options: .prettyPrinted)
                    resultJson = String(data: errorData, encoding: .utf8) ?? "{}"
                }
            }
        }
    }

    return CallTool.Result(content: [.text(text: resultJson, annotations: nil, _meta: nil)])
}
