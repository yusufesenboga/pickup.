# drop it. (Pickup)

The native Drop It redesign of Pickup: a brain that lives on your Dynamic Island, a daily Screen Time check-in, and a goal for getting your time back. The local session engine, history, exports, and prepared shortcut installers are retained.

See [the redesign and platform boundaries](Docs/DROP_IT_REDESIGN.md) for the new screens, real-data behavior, and remaining automatic background brain-update work. The project and bundle identifiers stay named Pickup for compatibility.

## Open and run

1. Open `Pickup.xcodeproj` in **Xcode 27 or newer** (current verified toolchain). Choose the **Pickup** scheme and a physical iPhone running **iOS 17+**.
2. In `Config/Base.xcconfig`, set `DEVELOPMENT_TEAM` to your Apple Developer team and, if needed, change `BUNDLE_PREFIX`. The default app identifier is `com.yusufesenboga.pickup`; its App Group is `group.com.yusufesenboga.pickup`.
3. For **all three targets**, select the same team, automatic signing, and the same **App Groups** capability. The Info.plist App Group value and entitlements derive from the shared configuration, so keep that one source of truth.
4. Enable **Family Controls (Development)** for **Pickup** and **PickupReport**. PickupWidgets needs only App Groups. **Push Notifications is not needed**; no background audio, location, remote notification, or Screen Time monitor capability is used.
5. Build and Run. Complete onboarding, then open **Island → connect my shortcuts** and complete the device steps below. A denied Screen Time or Live Activity permission does not prevent saving sessions. If the App Group cannot open, the app and intents report the storage error instead of silently creating an unshared store.

The Dynamic Island appears on compatible iPhones, beginning with iPhone 14 Pro. Other supported iPhones get the Lock Screen Live Activity. The project is iPhone-only and does not enable Mac, Catalyst, visionOS compatibility, or iPad.

**Build verification and remaining device work:** see [Docs/VALIDATION.md](Docs/VALIDATION.md) and [Docs/DEVICE_TEST_PLAN.md](Docs/DEVICE_TEST_PLAN.md). Device automation, permission, timing, and real Screen Time checks must run on an iPhone. A simulator screenshot or passing unit test cannot establish those results.

## Targets and source layout

| Component | Responsibility |
| --- | --- |
| `Pickup` | SwiftUI app, exactly three `LiveActivityIntent` actions, ActivityKit adapter, authorization and setup |
| `PickupWidgets` | Dynamic Island compact/minimal/expanded presentations and Lock Screen banner |
| `PickupReport` | `dropItToday`, `dropItGoal`, `sessionApps`, and `dailySummary` report scenes; all Screen Time arithmetic and rendering |
| `PickupCore` | Local Swift package: SwiftData model/repository, actor coordinator, settings, snapshots, export, daily clipping, tests |
| `Shared` | Target-shared Activity attributes, report contexts, localization catalog, glyph, privacy manifest |

Swift 6 language mode and complete concurrency checking are enabled. The package also supports macOS 14+ solely so its real coordinator and SwiftData persistence tests can run without a device. It does not ship a Mac app.

The checked-in project has no external package dependencies or generator prerequisites. After adding/removing source files, run `python3 Scripts/generate_project.py` to update file membership. Existing asset catalogs and plist configuration are included. The generator preserves `Config/Base.xcconfig`; it regenerates target plists, entitlements, the shared scheme, and the project.

## Shortcuts setup

The shortcut setup sheet has **Add Start Shortcut** and **Add End Shortcut** buttons. Each opens a real iCloud shortcut preview; confirm **Add Shortcut**. If the names already exist in your library, keep the existing copies instead of importing duplicates. Importing does not run the actions or automatically mark setup complete.

- [Pickup Session](https://www.icloud.com/shortcuts/04cd0a0baa78465abd1b230b81349604): **drop it.: Start Session → Wait 50 seconds → drop it.: Show Timer**.
- [Pickup End Session](https://www.icloud.com/shortcuts/ee261535fae8450d81551e973cb045cf): **drop it.: End Session** with no Wait.

The same signed `.shortcut` files are bundled in `Pickup/ShortcutResources`. **Files and manual setup** in Step 3 offers a file share route if links are unavailable: choose Shortcuts, or save to Files and open the file there. Action-by-action instructions remain as a fallback. Completion is always confirmed by the user, never inferred from opening a link or share sheet.

Create **two personal automations total** in Apple's Shortcuts app:

- **Opened:** Automation → + → App → Choose → select several time-sink apps in the same picker → Done → **Is Opened** → **Run Immediately** → disable **Notify When Run** if shown → select **Pickup Session** (or add **Run Shortcut → Pickup Session**).
- **Closed:** repeat with **the same apps**, choose **Is Closed**, **Run Immediately**, disable **Notify When Run** if shown → select **Pickup End Session** (or **Run Shortcut → Pickup End Session**).

Start with 3–5 apps; you do not need every installed app or one automation per app. Each selected app needs a checkmark, and Apple requires choosing the same list again for Closed. For the implemented iOS 17–26 setup, no supported public API was found for creating these personal App automations or prefilling their selected apps. The imported recipes do not install those triggers.

Messages, Camera, and other apps are not session triggers unless you add them to both automations. Today and Goal use your native tracked-app selection. The session detail report still shows all apps active during the enclosing hour(s). These report selections do not configure automation triggers.

Goal or Island → gear → timer settings & export → Advanced exposes a preferred delay. The bundled Start recipe uses **50 seconds**; changing the setting does **not** edit an imported shortcut. Setup shows a reminder when these differ. Edit its Wait action to match. **Show timer immediately** skips the icon-only phase on the next Start and is the fallback for delayed or unreliable Wait execution.

The install buttons and shared templates are for **every Pickup user**. They contain app action references, not Yusuf's app selections or account credentials. Apple's confirmation still requires a separate tap.

The current Screen Time permission does not supply an exportable used-app list for automation creation. Keep usage data inside the report extension. Newer EU-restricted data-access APIs and the WWDC26 automation-editor redesign need separate capability and compatibility checks; see `KNOWN_TODOS.md`. Do not interpret the current setup limitation as a permanent claim about all future iOS versions.

### iOS 27 setup and quick Island check

Setup uses the newer shortcut-editor instructions on iOS 27. Steps 4 and 5 include a prepared Describe a Shortcut prompt as a fallback. It copies locally for ten minutes and opens Apple's creation screen; paste it, then inspect the actual editor. Apple's generated summary can describe actions that were not added. The fallback asks for Run Shortcut using the existing Step 3 helpers; that revised prompt remains unverified on a phone.

The actual App Opened and App Closed installer templates are being verified on iOS 27. Their buttons are conditional on validated manifest entries and resources, and are not exposed in this build. See KNOWN_TODOS.md for exact editor/export progress. Do not use a Mac 26 export for these templates: it removes iOS 27 trigger metadata.

Step 2 now has **Test Dynamic Island** (or **Show Timer Now** during an active session). It starts or resumes a real session and shows the timer immediately, independently of Screen Time or automation setup. Go Home to inspect the Island, then tap End Session. The app reports whether ActivityKit has a running activity; that status does not guarantee iOS is visibly presenting it. The simulator verified creation and cleanup; physical Island display remains a device check.

### Maintaining the prepared shortcuts

The signed resources target bundle **com.yusufesenboga.pickup**, development team **E3FG37H8X3**, and the three compiled App Intent identifiers. Setup suppresses the prepared resources when its bundle or a nonempty build team differs from the manifest. A blank team is allowed for simulator and unsigned build validation only; use the correct development team on device.

After changing the app identity, intent names, or default Wait:

1. Run `python3 Scripts/generate_shortcuts.py --team YOUR_TEAM_ID` on macOS (optionally `--wait 50`). This creates reviewable source plists and uses Apple's public `shortcuts sign --mode anyone` service. Apple receives only the recipes for validation; they contain no session data or contact information.
2. Regeneration deliberately removes old iCloud links to avoid importing stale recipes. Import the signed files into Shortcuts, then Share → Copy iCloud Link for each. Record the new links in `Pickup/ShortcutResources/ShortcutManifest.json` under `installURLs`, keyed by each `.shortcut` filename. Until then, the buttons use the bundled files.
3. Run `python3 Scripts/generate_project.py`, build, and run `python3 Scripts/validate_shortcuts.py --metadata /path/to/Pickup.app/Metadata.appintents/extract.actionsdata --app /path/to/Pickup.app`.
4. Complete the real iPhone import checks in `Docs/DEVICE_TEST_PLAN.md`. macOS accepts both signed files but shows the iPhone-only Pickup actions as unavailable; that is not proof of iPhone action resolution or execution.

The source plist structure is a serialized shortcut recipe, not a public schema contract. Keep the signed files and reviewable sources together, and recheck import compatibility when updating iOS/Xcode. No private frameworks, Shortcuts database edits, or automation injection are used.

### Tutorial images

Capture real tutorial screens on a device and add imagesets to `Pickup/Assets.xcassets` named `SetupScreenTime`, `SetupLiveActivities`, `SetupShortcut`, `SetupAutomationOpened`, `SetupAutomationClosed`, and `SetupTest`. The UI includes screenshots only when present; numbered instructions remain available.

Apple references: [share shortcuts](https://support.apple.com/guide/shortcuts/share-shortcuts-apdf01f8c054/ios), [command-line signing](https://support.apple.com/guide/shortcuts-mac/apd455c82f02/mac).

## State and persistence

All intent events enter one `SessionCoordinator` actor. A FIFO permit spans repository and ActivityKit awaits; actor reentrancy alone would not serialize whole events. The SwiftData repository owns its context on a separate actor and exchanges only Sendable value records. Its container can open from the intent path without constructing a SwiftUI scene.

| Event / condition | Result |
| --- | --- |
| Start with no open session | Save active session, dismiss stray activities, request one new activity |
| Start while active | Keep the session; record the Start timestamp; recover a missing activity if necessary |
| Start within 30 seconds of pending Close | Resume same ID and original start time; restart the activity in the preferred initial phase |
| Start beyond grace | Finalize old session at its Close timestamp and create a new session |
| End while active, even immediately after Start | Dismiss all activities immediately; save pending end and Close timestamp |
| End while pending/ended/absent | Dismiss any orphan activities; preserve the first Close timestamp in the session |
| Manual Stop | Dismiss all activities and finalize the session, bypassing resume grace |
| Show Timer while active | Reveal count-up time; recover a missing activity using the original start |
| Show Timer without active session | No-op |
| Foreground after pending grace expired | Finalize at the original Close timestamp |

Pending sessions remain resumable during grace, even during a brief visit to Pickup. Foreground finalization only happens **after** that window, so reopening Pickup does not inadvertently defeat resume. While Pickup stays foreground, its lightweight refresh also finalizes an expired pending session. There is no background keep-alive or scheduled finalizer.

ActivityKit failure never rolls back a saved session. The app displays a retry/settings card. An active session with an expired or dismissed activity is recovered on Start, Show Timer, or foreground, as requested by the spec's edge-case section. `staleDate` remains original start + 8 hours; it marks content stale and is **not** a timer that ends a session. A re-request for an older session can therefore be stale immediately. The system's activity lifetime is separate from the session's stored lifetime.

The SwiftData store is in the App Group's `Library/Application Support/Pickup.store`, with CloudKit disabled and protection until first device unlock after reboot. Session history is not automatically pruned. A compact JSON snapshot of intervals overlapping the last 90 days is shared under `sessionsSnapshot`; pending intervals use `pendingEndAt` as their snapshot end, so they don't continue accumulating time. Snapshots are capped at 99,000 bytes. If unusually high volume requires omitting older entries, coverage metadata prevents the report from presenting an incomplete day's logged/untracked estimate as complete. This truncation never deletes SwiftData history.

Exports include short sessions and status (`0 = active`, `1 = pendingEnd`, `2 = ended`). JSON uses ISO 8601 dates; CSV includes pending end and elapsed seconds. The share sheet is user initiated and temporary export files are removed when dismissed. Delete all resets stored sessions, preferences, diagnostics, and tutorial progress, then ends the Live Activity. It cannot delete Apple's Screen Time or the personal automations; an automation can create new data afterward.

## Screen Time accuracy and privacy

- Authorization uses `requestAuthorization(for: .individual)`.
- Session lists never embed reports. Today mounts its report only when selected and outside detail navigation. Session Detail has the single hourly report.
- Per-session app lists mean **apps with usage during the overlapping hour buckets**, not exact app attribution to that session. Apps under one minute are grouped as Other. Names are grouped by Apple's localized display name as specified.
- Daily totals use `segment.totalActivityDuration`. The installed SDK has **no `segment.numberOfPickups`**. The extension sums `application.numberOfPickups` and `segment.totalPickupsWithoutApplicationActivity`, and reads `segment.firstPickup`.
- The extension clips every shared session to the calendar day and current time. Calendar intervals handle 23/25-hour daylight-saving days. Crossing-midnight sessions appear in the History day they started, but contribute clipped time to both daily totals.
- `untracked = max(0, Apple total - logged total)`. This is an estimate: a resumed session includes its brief gap, and Apple may not yet have updated its totals. No Screen Time number is written back to the app.
- A bounded snapshot or unavailable App Group shows an unavailable comparison instead of invented totals. Apple report data can be delayed, zero, or blank; a skeleton sits behind the report and Refresh recreates it.
- The report reads shared settings/snapshots; it does not try to export Screen Time out of the report sandbox. No network client, backend, analytics, cloud synchronization, push server, accounts, private API, or keep-alive service is included.
- The privacy manifest declares UserDefaults access for own-app and App Group settings. User-facing strings are supplied in `Shared/Localizable.xcstrings`; date and duration presentation uses locale-aware Foundation formatting.

## Platform limitations that need honest testing

1. **No Close event means no known end.** The spec's test suggestion that increasing grace makes a still-active session end on the next Start is incompatible with its idempotent Start rule. Grace only applies after a Close event. Pickup preserves the specified state machine: if locking does not fire the Closed automation, an active session remains active until an End arrives. Use End in Pickup and record the device behavior. Do not claim lock/unlock detection or fabricate an end timestamp.
2. **Debounce is a heuristic.** A genuine visit shorter than five seconds can have its Close ignored and remain active; an unusually delayed app-switch Close can end the session while another tracked app is still open. Advanced settings expose the tradeoff; there is no API that supplies missing foreground-app identity.
3. **Wait has no session token.** A delayed Show Timer action can reveal a newer active session early. It never changes its start time. Exactly three parameterless intents are kept as specified.
4. **Force quit, automation latency, permissions, and report rendering need physical-device evidence.** They are not marked passed by the unit suite.
5. Apple's totals can differ from intervals logged by automations. This app makes sessions visible; it is not an exact reconstruction of unlock time or per-second app usage.

## Build and tests

From this directory:

```sh
swift test --package-path PickupCore
xcodebuild -project Pickup.xcodeproj -scheme Pickup -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath /tmp/PickupDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

The unsigned command verifies compilation and extension packaging, not signing or installation. For a device run select your team and iPhone in Xcode, then Run. Do not treat a successful simulator build as Screen Time or Shortcuts validation.

Keep signed build products in Xcode's default DerivedData location or a local temporary directory. A synced Documents folder can attach Finder metadata to app bundles, which causes codesign's “resource fork, Finder information, or similar detritus not allowed” error. This is a build-location issue; do not weaken code-signing checks to work around it.

The tests exercise the actual coordinator through injected repository/ActivityKit boundaries, including all specified transitions and exact grace boundaries and immediate Close/Stop behavior, 50 simultaneous Starts, missing-activity recovery, permission failure, failed saves, deletion snapshots, disk-store reopen, export format, midnight/DST clipping, negative untracked prevention, snapshot size, and 90-day retention.

## TestFlight and App Store

Request Apple's **Family Controls distribution entitlement** for the main app and the DeviceActivityReport extension identifiers via the Apple Developer entitlement request process before distributing. Local device development uses the development capability and does not depend on that distribution approval. A paid team, correctly registered capabilities, and valid local provisioning are still required for development signing.

Verify the prepared shortcut imports on an iPhone, supply device screenshots, complete every [on-device test](Docs/DEVICE_TEST_PLAN.md), choose the appropriate App Store privacy answers, and verify the distribution provisioning profiles. The code is designed around public APIs; compilation is not a guarantee of entitlement approval or App Review acceptance.

## Apple references

- [Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities) — foreground and LiveActivityIntent starts, updates, end policies, system lifetime.
- [DeviceActivityReport](https://developer.apple.com/documentation/deviceactivity/deviceactivityreport) — privacy-preserving report rendering and sandbox.
- [First pickup](https://developer.apple.com/documentation/deviceactivity/deviceactivitydata/activitysegment/firstpickup) and [pickups without application activity](https://developer.apple.com/documentation/deviceactivity/deviceactivitydata/activitysegment/totalpickupswithoutapplicationactivity).
- [Configuring App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups).
- [Required-reason API declarations](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).
- [Family Controls](https://developer.apple.com/documentation/familycontrols) and [Family Controls entitlement request](https://developer.apple.com/contact/request/family-controls-distribution).
