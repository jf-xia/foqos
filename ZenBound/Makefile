# Makefile for Appium helper tasks

.PHONY: appium-mcp appium demo install-scripts

appium-mcp:
	chmod +x ./scripts/appium/*.sh && ./scripts/appium/start_appium_mcp.sh

appium:
	chmod +x ./scripts/appium/*.sh && ./scripts/appium/start_appium.sh

demo:
	@if [ -z "$(UDID)" ] || [ -z "$(TEAM)" ]; then \
		echo "Usage: make demo UDID=00008140-000038C83462401C TEAM=YOUR_TEAM_ID [BUNDLE=com.foqos.ZenBound]"; exit 1; \
	fi
	chmod +x ./scripts/appium/*.sh && ./scripts/appium/run_demo_session.sh "$(UDID)" "$(TEAM)" "$(BUNDLE)"

install-scripts:
	chmod +x ./scripts/appium/*.sh
