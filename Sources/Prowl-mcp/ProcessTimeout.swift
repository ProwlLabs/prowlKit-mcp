//
//  ProcessTimeout.swift
//  Prowl-MCP
//
//  Created by Elmee on 07/23/26.
//  Copyright © 2026 KaMy Studio | Prowl-MCP. All rights reserved.
//

import Foundation

enum ProcessTimeoutError: Error, CustomStringConvertible {
    case timedOut(seconds: Int)

    var description: String {
        switch self {
        case .timedOut(let seconds):
            return
                "Process did not finish within \(seconds)s and was terminated. This usually means xcodebuild is waiting on something (e.g. code signing, a simulator prompt, or a stuck lock file)."
        }
    }
}

func runProcessWithTimeout(_ process: Process, timeoutSeconds: Int = 180) async throws {
    try process.run()

    let deadline = Date().addingTimeInterval(TimeInterval(timeoutSeconds))
    while process.isRunning {
        if Date() > deadline {
            process.terminate()
            try? await Task.sleep(nanoseconds: 500_000_000)
            throw ProcessTimeoutError.timedOut(seconds: timeoutSeconds)
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
    }
}
