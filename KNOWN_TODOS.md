# Pickup remaining work

## Dynamic Island stop fix — September 25, 2026

- Phone diagnostics confirmed a Start timestamp and no End timestamp. Automatic stopping cannot work until the App Closed automation sends End Session. Do not describe the code fix as proof that the phone automation is connected.
- [x] Close now dismisses the activity even for a one-second visit and clears orphan activities.
- [x] Manual Stop finalizes immediately and is visible at the top of Island; removed the five-second disabled period and debounce control. Manual Stop does not manufacture an automation End diagnostic.
- [x] 35 package tests pass, including quick Close, grace resume, manual Stop/recovery, orphan cleanup, and dismissal before a failed save.
- [x] Debug simulator, Release iPhone, and development-signed iPhone builds passed with no warnings/errors; installed and launched the update on the connected phone.
- [ ] Inspect/repair and verify the Close automation on the physical iPhone. Mirroring remained stuck connecting after unlock and retry; confirmed no End diagnostic on the installed app before this update.

## Drop It redesign — September 25, 2026

- [x] Rebuilt the main native UI from Yusuf's Drop It reference, including fonts, cream/purple styling, all four brain states, onboarding, Today/Goal/Island, previews, app icon, and actual widget presentations.
- [x] Connected persistent goals/interests and native tracked-app tokens; kept usage calculations inside the report extension and retained session history, exports, and existing shortcut installers.
- [x] Simulator verified real Island rendering outside the app and the actual Lock Screen Live Activity, including ticking timer. Onboarding, saved goal after relaunch, stage selection, goal/interest controls, history/detail navigation, and End were exercised.
- [x] Xcode 27.0 / iOS 27 SDK now builds the app and extensions. The installed simulator used for runtime checks remains iOS 26.5. Earlier toolchain statements below are dated history.
- [ ] Verify the redesign on Yusuf's physical iOS 27 iPhone, especially filtered reports/native picker and widget layouts. No physical installation or acceptance is claimed in this pass.
- [ ] Implement and validate a supported background update mechanism before claiming automatic minute-by-minute brain/roast changes while another app stays foregrounded. Current timer ticks independently; visuals refresh on session actions and foreground entry. See `Docs/DROP_IT_REDESIGN.md`.
- [ ] Finish the existing iOS 27 Opened/Closed template import/public-link validation. Redesign does not solve this earlier blocker or expose the unverified installers.

## User decision

- Yusuf initially deferred full phone acceptance testing. He subsequently authorized iOS 27 template creation and inspection through iPhone Mirroring. This does not establish acceptance of the new Pickup build; no updated app was installed on the phone during this refinement.

## Required before distribution

- [ ] Select a signing team in `Config/Base.xcconfig`; register the three identifiers and common App Group; verify development provisioning on a device.
- [ ] Execute and fill `Docs/DEVICE_TEST_PLAN.md`. A connected iPhone and development certificate were detected, but that is not an installation or test result.
- [ ] Verify the two prepared shortcuts resolve Pickup actions and execute on an iPhone; signed files and real import links are included.
- [ ] Add the six real on-device tutorial screenshots named in `SetupConstants`.
- [ ] Request and receive Family Controls **distribution** entitlement for app and report identifiers; verify distribution profiles before TestFlight.

## Setup friction reported by Yusuf

- Yusuf finds the manual shortcut recipe and especially the app-selection automation step too burdensome. Treat reducing setup work as the next product priority.
- [x] Implemented prepared Start (Start → Wait 50 seconds → Show Timer) and End recipes, signed for Anyone using Apple's public CLI. Both imported into macOS Shortcuts and have real iCloud links. The iOS simulator resolved all actions, imported End from its link and Start from the bundled-file fallback.
- [x] Setup now offers Add Start / Add End buttons, bundled signed-file fallbacks, and collapsible manual instructions. Opening an installer never marks it complete.
- [x] Added regeneration instructions and checks against compiled App Intents metadata. Keep bundle/team/recipe files and shared links aligned when changing signing or actions.
- [x] Explained app selection explicitly: select several desired apps in one picker, using two automations total (Opened and Closed), not one automation per app. Each selected app still needs a checkmark; users need not select every installed app.
- For the implemented iOS 17–26 setup, no supported public API was found for Pickup to create an App-trigger personal automation or prefill its selected apps. Keep the remaining manual trigger setup honest, including Apple's final import confirmation.

## Known platform tradeoffs

- Missing Close events cannot be recovered by increasing grace or by an idempotent Start. Preserve this limitation in tutorial/release copy.
- Close events are no longer discarded after Start. Delayed Close events during app switches can still end a session prematurely because the parameterless events do not identify which app closed.
- Delayed parameterless Show Timer can reveal a later active session early.
- A resumed session includes the grace gap, so logged time can exceed Apple's total; Untracked is clamped and labeled as an estimate.
- Long-running activity recovery retains original staleDate, so a recovered activity older than eight hours is immediately stale.
- Very high session volume caps shared snapshots while preserving all SwiftData history; comparisons are hidden for incomplete days.

## Setup clarification and platform follow-up — September 10, 2026

- Product requirement: install buttons must work for every Pickup customer, not just Yusuf. The current buttons and Anyone-signed templates meet that scope for a matching Pickup app build; they contain no personal app selections or account credentials. Each user confirms Apple's Add Shortcut screen. Imports are not silently installed by Pickup.
- The current app requests ordinary individual Family Controls authorization. Used-app names and durations are read inside the sandboxed report extension; they are not exported to the containing app or Shortcuts. Source: https://developer.apple.com/documentation/deviceactivity/deviceactivityreport
- iOS 26.4 adds FamilyActivityData and approvedWithDataAccess, requiring a separate app-and-website-usage entitlement and explicit permission. Apple restricts customer data-access authorization to devices in the EU with an EU Apple Account. This is not the access Pickup currently has and is not a general solution for all customers. Sources: https://developer.apple.com/documentation/familycontrols/authorizationstatus/approvedwithdataaccess and https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.family-controls.app-and-website-usage
- [ ] Validate automation-containing templates using the new Shortcuts editor announced at WWDC26 for the iOS 27 generation. The earlier universal statement that automation setup can never be shared was too broad. Apple confirms automations now live in the shortcut editor; this does not by itself prove app-list preselection, trigger activation on import, or compatibility with older iOS. Source: https://developer.apple.com/videos/play/wwdc2026/310/
- Only Xcode.app and simulator runtimes through iOS 26.5 are installed. iOS 27 editor inspection is being performed on Yusuf's existing phone; no SDK or OS upgrade was installed. Full import/activation verification remains outstanding.

## iOS 27 refinement — September 10, 2026

- [x] Added a direct Test Dynamic Island / Show Timer Now button, real ActivityKit status, and an End Session control. Simulator verified a real session and registered Live Activity without completing other setup steps, then End removed it. Physical Island presentation remains unverified.
- [x] Added version-aware setup instructions and a copyable Describe a Shortcut fallback. The prompt opens Apple's creation screen; it does not auto-submit or claim completion. Native AI omitted Pickup actions during testing despite describing them in its summary, so fallback now requests Run Shortcut using the existing Step 3 helpers. That revised AI prompt still needs a phone check.
- [x] Built Pickup Apps Opened on the iOS 27 phone: App Opened trigger, Start Session, Wait 50, Show Timer, disabled for review. Added an App import question with no default selection. Exported an Anyone-signed file to work/Pickup Apps Opened.shortcut for inspection.
- [x] Duplicated and edited Pickup Apps Closed on the phone: App Closed trigger and End Session only, disabled for review. Closed export and matching question wording are still pending.
- [ ] Finish and verify both iOS 27 signed templates and real public installer links; only then populate the manifest to expose the primary Add buttons in Steps 4 and 5. Current build contains conditional UI but does not ship these unverified automation assets.
- [ ] Verify a fresh import preserves the correct Opened/Closed state and offers app selection. iPhone export contains WFWorkflowTriggers plus a Trigger/WFSelectedApps import question, but WFTriggerSerializedParameters is empty. Do not assume runtime state from the editor or invent the missing format.
- [ ] Confirm Apple-side activation and repeated app selection requirements during import; retain one automation per event and use matching app lists.
- Mac Shortcuts 26 export strips iOS 27 trigger metadata. Create/export/share automation templates from the phone, not the Mac editor. Existing ordinary Start/End templates remain valid.
- Computer-control clicks intermittently fail with noWindowsAvailable even though Mirroring screenshots work. Yusuf explicitly authorized macOS UI scripting. The first attempt was blocked by macOS with “osascript is not allowed assistive access”; requested Accessibility permission. Bringing the app forward through Apple Events succeeded but did not restore control-tool clicks. Exports/import checks remain blocked on usable phone control.
