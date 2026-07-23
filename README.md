# Prowl-MCP

MCP server buat Xcode project introspection — biar Claude bisa baca scheme/target project lo langsung.

Bagian dari [ProwlLabs](https://github.com/) tooling ecosystem (bareng ProwlKit).

## Setup

```bash
cd prowl-mcp
swift build
```

Kalau ada error di `Package.swift` soal versi SDK, cek release terbaru di
https://github.com/modelcontextprotocol/swift-sdk/releases dan sesuaikan `from:`.

## Jalanin manual (buat debug)

```bash
swift run prowl-mcp
```

Server ini pakai stdio transport — dia nunggu input JSON-RPC dari stdin, jadi
kalau dijalanin langsung di terminal keliatannya "hang", itu normal.

## Connect ke Claude Desktop

1. Build dulu: `swift build -c release`
2. Cek path binary: `swift build -c release --show-bin-path`
3. Buka Claude Desktop → Developer (sidebar) → Edit Config
4. Tambahin entry ini ke `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "prowl-mcp": {
      "command": "/absolute/path/to/.build/release/prowl-mcp"
    }
  }
}
```

5. Restart Claude Desktop sepenuhnya (quit, bukan cuma close window)
6. Klik "+" di chat box → Connectors → pastiin "prowl-mcp" muncul dan running

## Tools yang tersedia

- `list_schemes_targets(project_path)` — jalanin `xcodebuild -list -json` dan
  return scheme/target/configuration project atau workspace.

## Next steps (roadmap)

- `build_project` — wrap `xcodebuild build`, parse error jadi structured JSON
- `run_tests` — wrap `xcodebuild test`, parse `.xcresult` via `xcresulttool`
- Git diff/blame tool
- SwiftLint violations tool# prowlkit-MCP
# prowl-MCP
