#!/usr/bin/env python3
"""Build and sign Pickup's importable recipes using Apple's public shortcuts CLI.

Run on macOS: python3 Scripts/generate_shortcuts.py --team YOUR_TEAM_ID
Apple receives the recipes for validation. No user/session data is included.
"""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[1]


def app_action(bundle, team, intent):
    return {
        "WFWorkflowActionIdentifier": f"{bundle}.{intent}",
        "WFWorkflowActionParameters": {
            "AppIntentDescriptor": {
                "AppIntentIdentifier": intent,
                "BundleIdentifier": bundle,
                "Name": "Pickup",
                "TeamIdentifier": team,
            },
            "UUID": str(uuid.uuid5(uuid.NAMESPACE_URL, f"{bundle}/{intent}")).upper(),
        },
    }


def recipe(name, actions):
    return {
        "WFWorkflowName": name,
        "WFWorkflowActions": actions,
        "WFWorkflowClientVersion": "3036.0.4",
        "WFWorkflowMinimumClientVersion": 900,
        "WFWorkflowMinimumClientVersionString": "900",
        "WFWorkflowIcon": {
            "WFWorkflowIconGlyphNumber": 61456,
            "WFWorkflowIconStartColor": 1238682367,
        },
        "WFWorkflowImportQuestions": [],
        "WFWorkflowInputContentItemClasses": [],
        "WFWorkflowOutputContentItemClasses": [],
        "WFWorkflowTypes": [],
        "WFQuickActionSurfaces": [],
        "WFWorkflowHasOutputFallback": False,
        "WFWorkflowHasShortcutInputVariables": False,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--team", required=True, help="Apple Development team ID for Pickup")
    parser.add_argument("--bundle", help="Override bundle ID (otherwise read Base.xcconfig)")
    parser.add_argument("--wait", type=int, default=50, help="Start recipe's Wait in seconds")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Z0-9]{10}", args.team):
        parser.error("Team ID must be 10 uppercase letters/digits")
    if not 1 <= args.wait <= 300:
        parser.error("Wait must be between 1 and 300 seconds")
    prefix = re.search(r"^BUNDLE_PREFIX\s*=\s*(\S+)",
                       (ROOT / "Config/Base.xcconfig").read_text(), re.MULTILINE).group(1)
    bundle = args.bundle or f"{prefix}.pickup"
    if not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle):
        parser.error("Invalid bundle ID")
    recipes = {
        "Pickup Session": recipe("Pickup Session", [
            app_action(bundle, args.team, "StartSessionIntent"),
            {"WFWorkflowActionIdentifier": "is.workflow.actions.delay",
             "WFWorkflowActionParameters": {"WFDelayTime": args.wait}},
            app_action(bundle, args.team, "ShowTimerIntent"),
        ]),
        "Pickup End Session": recipe("Pickup End Session", [
            app_action(bundle, args.team, "EndSessionIntent"),
        ]),
    }
    # Stage both signatures before updating the shipped resources.
    with tempfile.TemporaryDirectory(prefix="pickup-shortcuts-") as directory:
        staging = Path(directory)
        signed = {}
        for name, content in recipes.items():
            source = staging / f"{name}.unsigned.shortcut"
            destination = staging / f"{name}.shortcut"
            source.write_bytes(plistlib.dumps(content, fmt=plistlib.FMT_BINARY))
            subprocess.run(["/usr/bin/shortcuts", "sign", "--mode", "anyone",
                            "--input", str(source), "--output", str(destination)], check=True)
            data = destination.read_bytes()
            if data == source.read_bytes() or not data:
                raise RuntimeError(f"Signing did not produce a signed file: {name}")
            signed[name] = data
        resources = ROOT / "Pickup/ShortcutResources"
        sources = ROOT / "Shortcuts/Source"
        resources.mkdir(parents=True, exist_ok=True)
        sources.mkdir(parents=True, exist_ok=True)
        manifest = {"bundleIdentifier": bundle, "teamIdentifier": args.team,
                    "waitSeconds": args.wait, "files": {}}
        for name, data in signed.items():
            filename = f"{name}.shortcut"
            (resources / filename).write_bytes(data)
            (sources / f"{name}.plist").write_bytes(plistlib.dumps(recipes[name]))
            manifest["files"][filename] = hashlib.sha256(data).hexdigest()
        (resources / "ShortcutManifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Signed both recipes for {bundle}, team {args.team}, Wait {args.wait}s.")


if __name__ == "__main__":
    main()
