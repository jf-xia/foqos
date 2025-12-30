#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Needle:
    section: str
    path: Path
    substrings: list[str]
    max_hits_per_substring: int = 8


def find_lines(path: Path, needle: str, limit: int) -> list[tuple[int, str]]:
    hits: list[tuple[int, str]] = []
    for line_number, line in enumerate(path.read_text(errors="ignore").splitlines(), start=1):
        if needle in line:
            hits.append((line_number, line.strip()))
            if len(hits) >= limit:
                break
    return hits


def main() -> None:
    sdk_base = Path(
        "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks"
    )

    managedsettings_if = sdk_base / (
        "ManagedSettings.framework/Modules/ManagedSettings.swiftmodule/arm64-apple-ios-simulator.swiftinterface"
    )
    managedsettingsui_if = sdk_base / (
        "ManagedSettingsUI.framework/Modules/ManagedSettingsUI.swiftmodule/arm64-apple-ios-simulator.swiftinterface"
    )

    output = Path(
        "docs/study/05-file-notes/apple-sdk__managedsettings__swiftinterface-evidence.md"
    )
    output.parent.mkdir(parents=True, exist_ok=True)

    items = [
        Needle(
            section="ManagedSettings.ManagedSettingsStore",
            path=managedsettings_if,
            substrings=[
                "public class ManagedSettingsStore",
                "public var shield",
                "public var webContent",
                "public var application",
                "public func clearAllSettings()",
            ],
        ),
        Needle(
            section="ManagedSettings.ShieldSettings",
            path=managedsettings_if,
            substrings=[
                "public struct ShieldSettings",
                "public var applications:",
                "public var applicationCategories:",
                "public var webDomains:",
                "public var webDomainCategories:",
                "public enum ActivityCategoryPolicy",
            ],
        ),
        Needle(
            section="ManagedSettings.WebContentSettings",
            path=managedsettings_if,
            substrings=[
                "public struct WebContentSettings",
                "public enum FilterPolicy",
                "public var blockedByFilter:",
            ],
        ),
        Needle(
            section="ManagedSettings.ShieldActionDelegate",
            path=managedsettings_if,
            substrings=[
                "open class ShieldActionDelegate",
                "open func handle(action:",
                "ShieldActionResponse",
            ],
        ),
        Needle(
            section="ManagedSettingsUI.ShieldConfigurationDataSource",
            path=managedsettingsui_if,
            substrings=[
                "ShieldConfigurationDataSource",
                "configuration(shielding application:",
                "configuration(shielding webDomain:",
            ],
        ),
    ]

    lines: list[str] = []
    lines.append("# Apple SDK evidence — ManagedSettings / ManagedSettingsUI")
    lines.append("")
    lines.append("## Context")
    lines.append(
        "This file is auto-generated from the local iOS Simulator SDK `.swiftinterface` files.")
    lines.append(
        "It exists to make API-shape claims in `docs/study/07-api-cards/` verifiable within this repo.")
    lines.append("")
    lines.append("## How to regenerate")
    lines.append(
        "Run: `python3 scripts/extract_managedsettings_sdk_evidence.py`")

    for item in items:
        lines.append("")
        lines.append(f"## {item.section}")
        lines.append(f"Source: `{item.path}`")

        if not item.path.exists():
            lines.append("")
            lines.append("- ERROR: source file not found on this machine.")
            continue

        for substring in item.substrings:
            hits = find_lines(item.path, substring,
                              item.max_hits_per_substring)
            lines.append("")
            lines.append(f"### Needle: `{substring}`")
            if not hits:
                lines.append("- No matches")
                continue
            for line_number, line in hits:
                lines.append(f"- L{line_number}: `{line}`")

    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {output}")


if __name__ == "__main__":
    main()
