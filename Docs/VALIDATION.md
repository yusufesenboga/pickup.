# Dynamic Island stop fix — September 25, 2026

- Read the installed app's own preferences from the connected iPhone: a Start event was present; no End event or completed setup steps were recorded. This establishes that the app had not received Close, not which Shortcuts trigger/configuration was responsible.
- Removed discarded Close events within five seconds of Start. Every End dismisses all activities before persistence; explicit manual Stop finalizes instead of preserving resume grace. Added a prominent Stop control and an honest no-Close diagnostic on Island.
- 35 core tests passed: immediate Close, quick app-switch resume, delayed Show Timer after Close, immediate/repeated manual Stop, foreground recovery after Stop, orphan activities, and ActivityKit dismissal when persistence fails.
- Debug simulator, unsigned Release iPhone, and development-signed Debug iPhone builds all succeeded with warnings treated as errors and no warnings/errors. Bundled shortcuts remain aligned with compiled App Intent identifiers.
- Installed the development-signed update on the connected physical iPhone and launched it successfully. This is an installation/launch result, not confirmation that its App Closed automation fires.
- iPhone Mirroring was unlocked but stalled connecting after a retry, so physical shortcut inspection and end-to-end automatic Close acceptance are still pending.
- Simulator update installed and launched; app screenshot confirmed normal rendering. No new UI interaction/physical Island dismissal claim is made by this pass.

---

# Current validation — Drop It redesign, September 25, 2026

- Xcode 27.0 (27A266a), Swift 6, iOS 27 SDK.
- Debug simulator build with ad-hoc signing and Release generic-iPhone build with signing disabled: succeeded with zero compiler warnings/errors, using warnings-as-errors. Physical-device signing/distribution was not tested by these builds.
- 29 package tests passed, including the original session/persistence/day-total checks plus brain/roast boundaries, goals, missing-data behavior, completed-day streaks across daylight-saving time, seven-day baseline estimates, preference clamping and reset.
- Runtime checks on iPhone 17 Pro simulator, iOS 26.5: onboarding and deferral, saved goal after cold launch, goal adjustments/interest chips, four-stage previews, session history/detail navigation, real Live Activity start, compact Island visible on Home, actual Lock Screen rendering, and End removing the activity.
- The Simulator displayed Apple's Live Activity permission prompt. Physical Screen Time authorization, private token selection, real usage reports, and personal automation execution remain unverified on the redesigned build.
- Bundled shortcut recipes still match the compiled App Intent IDs and their manifest. Both bundled fonts and licenses are present in all three products. The verified source ZIP contains 110 files, excluding build caches and personal Xcode settings.
- Debug fixture screenshots are visual QA only; they do not establish Screen Time data correctness. Release excludes these fixtures.
- Further implementation/runtime boundaries are in `DROP_IT_REDESIGN.md`. Earlier September 10 validation below describes the previous UI and is retained as history.

---

# Build and verification record

Verification performed on September 9, 2026 (America/Chicago).

## Toolchain

- Xcode **26.6**, build **17F113**.
- Apple Swift **6.3.3**, compiling the app, extensions, and package in **Swift 6** language mode.
- Installed iOS / simulator SDK **26.5**; product minimum deployment **iOS 17.0**.
- No external Swift package dependencies.

## Automated verification

| Check | Result |
| --- | --- |
| PickupCore tests on macOS, real SwiftData included | **23 tests passed**, 0 failures, 0 warnings |
| Device-target Debug build, including both extensions | **Passed**, 0 warnings; Swift warnings treated as errors |
| Device-target Release build, including both extensions | **Passed**, 0 warnings; Swift warnings treated as errors |
| Locally signed iPhone 17 Pro simulator Debug build | **Passed**, 0 warnings |
| Compiled App Intents metadata | Exactly **3 actions and 3 App Shortcuts** |
| Embedded extensions in Release app | **PickupWidgets.appex** and **PickupReport.appex** present |
| Built Info.plist values | All three products: iOS 17.0; common `group.com.yusufesenboga.pickup` |
| App Group / Family Controls source entitlements | Shared group on all targets; Family Controls on app and report only |
| App icon | 1024 × 1024, opaque RGB PNG; bundled original glyph |
| Localization lookup audit | All explicit localized text/format lookups present in catalog |

The strict build checks use both `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` and `SWIFT_SUPPRESS_WARNINGS=NO`; the latter removes SwiftPM's dependency-warning suppression. No compiler diagnostics are hidden to obtain a zero-warning result.

## Simulator UI smoke check

- First launch enters the six-step Setup tutorial.
- App Group container was confirmed after local simulator signing; SwiftData opens without a storage alert.
- Today renders the introductory content, Screen Time access-needed card, short-session toggle, and empty log.
- History renders its empty state.
- Settings renders all six accent presets, detail toggle, session threshold, immediate timer setting, delay, grace, debounce, data, and privacy sections.
- The initial unsigned copy correctly displayed an App Group error. That error path was adjusted to avoid repeating the alert on a two-second loop.
- The first export attempt exposed a blank-sheet state race. Export presentation now uses an identifiable file item so the file URL is available when the sheet opens.
- Retested JSON export on the updated build: the native share sheet displayed **Pickup-sessions**, type **JSON**, with Copy and Save to Files actions. It was dismissed without sending data.

These are UI and storage smoke checks, **not** tests of real Screen Time, phone locking, physical Dynamic Island timing, or personal automation execution.

## Not executed / release prerequisites

Yusuf explicitly chose **“Finish the build; I'll test the phone later.”** The connected physical iPhone was not used for installation or acceptance testing. All ten physical-device scenarios remain marked **Not run** in [DEVICE_TEST_PLAN.md](DEVICE_TEST_PLAN.md).

Device/distribution signing is not claimed by the unsigned device-target builds. Select the team and verify development provisioning before running on a physical phone. Family Controls distribution approval, physical iPhone shortcut import/execution checks, and the six developer-captured tutorial screenshots remain outstanding; see [KNOWN_TODOS.md](../KNOWN_TODOS.md).

## Environment issues resolved during verification

- The simulator's first boot stalled in an Apple data migration. Restarting it without erasing data completed the boot.
- Finder metadata from the synced Documents folder prevented signing build products there. The successful simulator build used a local temporary DerivedData directory. Xcode's default DerivedData location is also appropriate.
- Extension copy stripping was disabled to preserve already-signed embedded extension binaries and eliminate packaging warnings.

## Reproduce

From the project directory:

```sh
swift test --package-path PickupCore
xcodebuild -project Pickup.xcodeproj -scheme Pickup -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath /tmp/PickupDebug \
  CODE_SIGNING_ALLOWED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES SWIFT_SUPPRESS_WARNINGS=NO build
xcodebuild -project Pickup.xcodeproj -scheme Pickup -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath /tmp/PickupRelease \
  CODE_SIGNING_ALLOWED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES SWIFT_SUPPRESS_WARNINGS=NO build
```

For a simulator UI check, select an installed iPhone simulator in Xcode and Run. For the actual product acceptance test, use the physical-device checklist.

## Prepared shortcut setup update — September 9, 2026

- Generated **Pickup Session** (Start → Wait 50 → Show Timer) and **Pickup End Session** (End only), targeting the compiled app intent IDs, bundle `com.yusufesenboga.pickup` and team `E3FG37H8X3`.
- Apple's public `shortcuts sign --mode anyone` command succeeded for both files. Both were accepted by the normal macOS **Add Shortcut** UI and added to the library without editing their actions.
- macOS Shortcuts displayed the 50-second Wait between the two unavailable iPhone-only actions. Pickup is not installed on macOS, so this validates the recipe container and Wait, not iPhone action resolution or execution.
- Created real iCloud install links through native Shortcuts sharing. Both web previews resolved with their expected recipe names and **Get Shortcut** controls. The links are stored alongside signed-resource hashes in `ShortcutManifest.json`.
- Checked source action order, bundle/team, Wait value and all three identifiers against Xcode's compiled App Intents metadata; verified the built app includes byte-identical signed resources and manifest.
- No personal App automation was created, no app list was prefilled, and no physical iPhone was installed or tested. Device acceptance remains deferred by the user.
- Updated Debug and Release device-target builds passed with warnings treated as errors (0 warnings); the locally signed simulator build also passed (0 warnings).
- The updated Setup screen rendered in the simulator with both import buttons, 50-second recipe summary, file/manual disclosure, and multi-app instructions. No changes were made to the session engine; its previously recorded 23-test result remains applicable, and the core suite was not rerun for this setup-only update.
- On the iOS 26.5 simulator, tapping **Add Start Shortcut** in Pickup opened Apple's named **Add Shortcut** screen. Its preview resolved **Pickup: Start Session → Wait 50 seconds → Pickup: Show Timer** correctly, with no Unknown Action blocks.
- Tapping **Add End Shortcut** opened the corresponding Apple import screen; its preview resolved **Pickup: End Session** as the only action.
- Canceling the Start import and returning to Pickup left the completion switch off and event diagnostics at “Not yet.” Actual physical-phone execution remains untested.
- Added the End recipe to the simulator library, reopened its editor, and confirmed the saved **Pickup: End Session** action remains present.
- The bundled Start file opened a populated share sheet showing the 22 KB Shortcut and a **Shortcuts** destination. Selecting Shortcuts opened Apple's **Add Shortcut** screen; confirming imported the file and its editor retained **Start Session → Wait 50 seconds → Show Timer**. Both recipes are now saved in the simulator library. Physical iPhone acceptance remains deferred.

## iOS 27 setup refinement — September 10, 2026

- Debug and Release device-target builds and a locally signed iOS 26.5 simulator build passed with zero warnings after adding the setup guide and Dynamic Island test. The final fallback wording/layout edits were then rebuilt in Debug and Release: both passed again with zero warnings; bundled resources and compiled App Intent metadata validation also passed.
- Simulator: Test Dynamic Island created a real active session and ActivityKit activity while setup remained 1/6. End Session changed it to pending end and removed the active-activity indication. The Home control did not navigate out of Pickup, so visual Island presentation is not marked passed.
- Authorized physical iOS 27 editor inspection: native Describe produced an App Opened trigger and Wait only, while its summary described missing Pickup actions. Manually corrected to Start / Wait 50 / Show Timer and disabled automation. Added an import question targeting the trigger's App parameter.
- Saved an Anyone-signed export directly from iPhone. Public aea/aa tools verified and extracted the archive: the three actions and App import question are present; trigger parameters are empty. Mac 26 exports omit the trigger entirely. Fresh iOS 27 import behavior still requires validation.
- Created the Closed draft in the iOS 27 editor with App Closed and End Session only. Export, fresh import checks and installer-link integration remain pending. Neither draft has been enabled for execution testing.
- Full physical-app acceptance and installation of the updated build remain deferred. These editor checks do not mark the ten device scenarios passed.
