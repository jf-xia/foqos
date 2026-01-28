# Appium scripts (appium-mcp)

Prerequisites:
- Node >= 20.19.x or >= 22.12.x (use `nvm` / `fnm` / `volta`) ✅
- Xcode and Developer Mode enabled on device
- `ios-deploy`, `libimobiledevice`, `usbmuxd` (recommended via Homebrew)

Scripts:
- `start_appium_mcp.sh` — run `npx appium-mcp@latest` (for MCP-managed Appium)
- `start_appium.sh` — run `npx appium@latest` (direct Appium server)
- `run_demo_session.sh <UDID> <TEAM_ID> [BUNDLE_ID]` — sends a simple session-create request to Appium using `curl`.

Usage example:

1. Start appium-mcp in one terminal:

   ./scripts/appium/start_appium_mcp.sh

2. In another terminal, run a demo session (fill your TEAM_ID):

   ./scripts/appium/run_demo_session.sh 00008140-000038C83462401C YOUR_TEAM_ID com.foqos.ZenBound

Notes:
- `run_demo_session.sh` prints the JSON response; if session creation fails, check WDA signing and device visibility.
- Make scripts executable: `chmod +x scripts/appium/*.sh` ✅
Npm / Makefile convenience:
- `npm run appium:start-mcp` — start `appium-mcp` (from `package.json`)
- `npm run appium:start` — start `appium` directly
- `npm run appium:demo` — run demo session script (accepts same args)

- `make appium-mcp` — start `appium-mcp` via `Makefile`
- `make appium` — start `appium` via `Makefile`
- `make demo UDID=00008140-000038C83462401C TEAM=YOUR_TEAM_ID [BUNDLE=com.foqos.ZenBound]` — run demo session