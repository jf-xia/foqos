#!/usr/bin/env bash
set -euo pipefail

echo "Starting appium-mcp..."
# Prefer using npx to ensure latest local/global install is used
npx appium-mcp@latest
