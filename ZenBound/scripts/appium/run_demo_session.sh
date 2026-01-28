#!/usr/bin/env bash
set -euo pipefail

# Usage: ./run_demo_session.sh <UDID> <TEAM_ID> [BUNDLE_ID]
UDID=${1:-00008140-000038C83462401C}
TEAM_ID=${2:-<TEAM_ID>}
BUNDLE_ID=${3:-com.foqos.ZenBound}

read -r -d '' CAP_JSON <<EOF || true
{
  "capabilities": {
    "firstMatch": [
      {
        "platformName": "iOS",
        "platformVersion": "26.2",
        "deviceName": "JackXia16Pro",
        "udid": "${UDID}",
        "automationName": "XCUITest",
        "bundleId": "${BUNDLE_ID}",
        "xcodeOrgId": "${TEAM_ID}",
        "xcodeSigningId": "iPhone Developer",
        "updatedWDABundleId": "com.foqos.WebDriverAgentRunner",
        "usePrebuiltWDA": false
      }
    ]
  }
}
EOF

echo "Creating session with Appium at http://127.0.0.1:4723/session"
# Send session create request
curl -s -X POST http://127.0.0.1:4723/session -H "Content-Type: application/json" -d "$CAP_JSON" | python -m json.tool || true
