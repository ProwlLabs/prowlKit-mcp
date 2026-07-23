<p align="center">
  <img src="logo.png" width="250" alt="ProwlKit Logo">
</p>

# ProwlKit-MCP

An MCP (Model Context Protocol) server for Xcode project introspection, enabling AI assistants like Claude to read schemes, targets, build projects, and run tests directly from your `.xcodeproj` or `.xcworkspace`.

Part of the [ProwlLabs](https://github.com/ProwlLabs) tooling ecosystem (alongside ProwlKit).

---

## Features

- **Zero-Config Workspace Path Jailing**: Safely exposes Xcode projects to the MCP agent without manual path configurations.
- **Live Streaming Build Logs**: Stream build output and test progress directly into your Claude chat utilizing MCP's Progress API.
- **Smart Scheme Discovery**: Instantly list all targets, schemes, and configurations.
- **Build Projects & Tests**: Build Xcode projects/workspaces and get structured, readable errors and warnings (file, line, column, message) using `xcbeautify`.
- **SourceKit-LSP Integration**: Retrieve rich Xcode build settings, hover definitions, and compiler flags directly from the Swift Language Server.

## Installation (Recommended)

ProwlMCP is installed and automatically configured for Claude Desktop via Homebrew:

```bash
brew install ProwlLabs/prowlKit-mcp/prowl-mcp
```

*That's it! Homebrew will compile the server and automatically inject the connection settings into your `claude_desktop_config.json`.* 

**Completely Restart Claude Desktop** (Quit the application) to load the new MCP server. You will see `prowl-mcp` tools available in the chat (via the "+" or Tools icon).

## Manual Installation (From Source)

1. Clone the repository and navigate to the project directory:
   ```bash
   git clone https://github.com/ProwlLabs/prowlKit-mcp.git
   cd prowlKit-mcp
   ```

2. Build the project:
   ```bash
   swift build -c release
   ```

3. Connect to Claude Desktop by adding this to your `claude_desktop_config.json`:

   ```json
   {
     "mcpServers": {
       "prowl-mcp": {
         "command": "/absolute/path/to/prowlKit-mcp/.build/release/prowl-mcp"
       }
     }
   }
   ```

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
