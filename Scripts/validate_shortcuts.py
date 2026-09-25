#!/usr/bin/env python3
"""Check shipped recipes against their manifest and real compiled App Intents metadata."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import re
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--metadata', type=Path, required=True,
                    help='Built Pickup.app/Metadata.appintents/extract.actionsdata')
parser.add_argument('--app', type=Path, help='Also check resources inside a built Pickup.app')
args = parser.parse_args()
resources = ROOT / 'Pickup/ShortcutResources'
manifest = json.loads((resources / 'ShortcutManifest.json').read_text())
metadata = json.loads(args.metadata.read_text())
prefix = re.search(r'^BUNDLE_PREFIX\s*=\s*(\S+)',
                   (ROOT / 'Config/Base.xcconfig').read_text(), re.MULTILINE).group(1)
assert manifest['bundleIdentifier'] == prefix + '.pickup', 'Regenerate recipes for the current bundle ID'
assert re.fullmatch(r'[A-Z0-9]{10}', manifest['teamIdentifier'])
expected = {'Pickup Session': ['StartSessionIntent', 'wait', 'ShowTimerIntent'],
            'Pickup End Session': ['EndSessionIntent']}
assert set(manifest['files']) == {name + '.shortcut' for name in expected}
for name, intents in expected.items():
    filename = name + '.shortcut'
    source = plistlib.loads((ROOT / 'Shortcuts/Source' / (name + '.plist')).read_bytes())
    assert source['WFWorkflowName'] == name
    assert source['WFWorkflowTypes'] == []  # ordinary shortcut, not personal automation
    assert len(source['WFWorkflowActions']) == len(intents)
    for action, intent in zip(source['WFWorkflowActions'], intents):
        params = action['WFWorkflowActionParameters']
        if intent == 'wait':
            assert action['WFWorkflowActionIdentifier'] == 'is.workflow.actions.delay'
            assert params['WFDelayTime'] == manifest['waitSeconds']
        else:
            actual = metadata['actions'][intent]
            assert actual['identifier'] == intent and actual['parameters'] == []
            assert actual['openAppWhenRun'] is False
            assert action['WFWorkflowActionIdentifier'] == manifest['bundleIdentifier'] + '.' + intent
            assert params['AppIntentDescriptor'] == {
                'AppIntentIdentifier': intent, 'BundleIdentifier': manifest['bundleIdentifier'],
                'TeamIdentifier': manifest['teamIdentifier'], 'Name': 'Pickup'}
    data = (resources / filename).read_bytes()
    assert hashlib.sha256(data).hexdigest() == manifest['files'][filename]
    assert data != plistlib.dumps(source, fmt=plistlib.FMT_BINARY), 'File has not been signed'
    link = manifest.get('installURLs', {}).get(filename)
    if link:
        url = urlparse(link)
        assert url.scheme == 'https' and url.netloc == 'www.icloud.com'
        assert re.fullmatch(r'/shortcuts/[a-f0-9]{32}', url.path)
    if args.app:
        assert (args.app / filename).read_bytes() == data, 'Bundled recipe differs from signed resource'
if args.app:
    assert (args.app / 'ShortcutManifest.json').read_bytes() == (resources / 'ShortcutManifest.json').read_bytes()
    info = plistlib.loads((args.app / 'Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] == manifest['bundleIdentifier']
    assert info.get('PickupSigningTeam', '') in ('', manifest['teamIdentifier'])
print('Both signed resources, action order, Wait, bundle/team, compiled intent IDs and import URL shapes passed.')
print('Apple import UI and iPhone execution require separate validation; this script does not verify signatures or fetch links.')
