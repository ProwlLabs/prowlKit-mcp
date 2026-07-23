# ProwlKit-MCP

An MCP (Model Context Protocol) server for Xcode project introspection, enabling AI assistants like Claude to read schemes, targets, build projects, and run tests directly from your `.xcodeproj` or `.xcworkspace`.

Part of the [ProwlLabs](https://github.com/ProwlLabs) tooling ecosystem (alongside ProwlKit).

---

## Features

- **Project Introspection**: Instantly list all targets, schemes, and configurations.
- **Build Projects**: Build Xcode projects/workspaces and retrieve structured, readable errors and warnings (file, line, column, message).
- **Run Tests**: Execute tests for a given scheme on an iOS Simulator destination and get a structured pass/fail summary.

## Setup & Installation

1. Clone the repository and navigate to the project directory:
   ```bash
   git clone https://github.com/ProwlLabs/prowlKit-mcp.git
   cd prowlKit-mcp
   ```

2. Build the project:
   ```bash
   swift build
   ```

> [!NOTE]
> If you encounter an SDK version error in `Package.swift`, check the latest release at [modelcontextprotocol/swift-sdk](https://github.com/modelcontextprotocol/swift-sdk/releases) and adjust the `from:` version accordingly.

## Running Manually (Debugging)

To run the server manually for debugging purposes:

```bash
swift run prowl-mcp
```

*Note: This server uses `stdio` transport. It listens for JSON-RPC input from `stdin`, so it is normal for the terminal to appear to "hang" when running it directly.*

## Connecting to Claude Desktop

1. Build the release version:
   ```bash
   swift build -c release
   ```
2. Get the binary path:
   ```bash
   swift build -c release --show-bin-path
   ```
3. Open Claude Desktop → **Developer** (in the sidebar) → **Edit Config**.
4. Add the following entry to your `claude_desktop_config.json`:

   ```json
   {
     "mcpServers": {
       "prowl-mcp": {
         "command": "/absolute/path/to/.build/release/prowl-mcp"
       }
     }
   }
   ```
   *(Replace `/absolute/path/to` with the actual path obtained from step 2)*

5. **Completely restart** Claude Desktop (Quit the application, don't just close the window).
6. Click the **"+"** button in the chat box → **Connectors** → ensure `prowl-mcp` appears and is running.

## Available Tools

- `list_schemes_targets(project_path)`: Runs `xcodebuild -list -json` to return project/workspace schemes, targets, and configurations.
- `build_project(project_path, scheme, configuration)`: Wraps `xcodebuild build` and parses errors/warnings into structured JSON.
- `run_tests(project_path, scheme, destination)`: Wraps `xcodebuild test` and parses `.xcresult` files via `xcresulttool`.
- `git_info(repo_path, action, target_file)`: Runs `git diff` or `git blame` on a repository or specific file.
- `swiftlint(project_path, target_path)`: Runs `swiftlint lint --reporter json` to check for Swift coding style and convention violations.

## Roadmap

- [x] `build_project` implementation
- [x] `run_tests` implementation
- [x] Git diff/blame tool integration
- [x] SwiftLint violations tool

---

<p align="center">
  Made with ❤️ by <b>Elmee</b> & the <b>ProwlLabs</b> Team.
</p>
