# Drop It redesign — September 25, 2026

Pickup is now presented as **drop it.**, following the supplied [Drop It reference](https://claude.ai/artifact/SRvPoNX7d7a3tK8Hiu9oU8). The existing bundle identifiers, App Group, App Intent types, shortcut recipes, and session store remain compatible.

## Native implementation

- Cream `#FBF7F0`, purple `#7B4DFF`, raised buttons, Caprasimo display type, Figtree body type, rounded cards, and the reference copy.
- A shared vector brain with locked-in, eepy, brainrot, and rotten expressions, used in onboarding, dashboards, Island previews, the real Live Activity, and the new app icon.
- Welcome → Screen Time → tracked apps and daily limit → meet your brain onboarding. Permission can be deferred. “Turn it on” requests a real foreground Live Activity and selects the Island tab; it does not mark shortcut setup complete.
- Today / Goal / Island navigation. Goal controls persist 15-minute increments, bounded to 15 minutes–12 hours, and the eight interests. The gear opens tracked apps, existing shortcut installers, session history, timer controls, and exports.
- Real Screen Time data stays inside the report extension. Both new reports use the saved FamilyActivitySelection filter. The Today screen shows the top three apps, with totals covering the entire selection. Old session reports remain available through History.
- Missing usage is shown as unavailable, never the prototype's sample totals. Streaks count consecutive completed days under the current goal (up to the 30-day report window); today is provisional. Historical comparisons use the current app selection and current goal, not a separately recorded history of prior goals. Savings require all seven preceding days and are explicitly an estimate of 30 days at the chosen goal.
- Stage and roast controls are previews. The Lock Screen preview is labeled as such. Runtime timers use the real session start date; no dummy Instagram identity is claimed by parameterless session actions.
- DEBUG-only `-dropItPreview welcome|permission|apps|brain|today|goal|island|lock` routes provide deterministic screenshot fixtures. They are absent from Release and never write fixture data to shared storage or the report extension.

## Intentional differences from the web prototype

Apple's FamilyActivityPicker and authorization sheets are native system UI. The prototype's nine named app checkboxes cannot supply real private application tokens. Users can choose whole categories or multiple apps in the native picker; those tokens filter the usage reports. This selection does not create or prefill Shortcuts automations. Existing setup explains the separate Opened/Closed selections.

The real Dynamic Island shape, camera clearance, placement, Lock Screen wallpaper/clock, and always-on timer rendering are controlled by iOS. In-app previews sit inside the content area and cannot replace the hardware island. The settings entry and setup/test controls preserve essential functionality outside the prototype's three-tab content.

A seven-day streak and all example usage figures are not asserted for a fresh install. The QA fixtures intentionally use internally consistent histories instead of copying the prototype's contradictory seven-day badge and missed days.

## Live Activity update boundary

The continuously ticking timer is implemented with SwiftUI's system timer text. Brain and roast state refresh on Start, Show Timer, recovery, and foreground entry. A repeated Start updates the presentation without changing the original session time or reveal phase. End removes the Live Activity.

Autonomous minute-by-minute **background** mood/roast transitions have not been implemented or claimed. ActivityKit uses app/intent updates or ActivityKit push notifications, not a WidgetKit timeline. No background server, fake audio session, or unreliable long-running task was added. A supported update mechanism and physical-device verification are required before advertising that behavior. See [Apple's Live Activity documentation](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities).

## Fonts

Bundled unmodified Google Fonts releases of [Caprasimo](https://github.com/google/fonts/tree/main/ofl/caprasimo) and [Figtree](https://github.com/google/fonts/tree/main/ofl/figtree), with their SIL Open Font License files in `Shared/Fonts`. Both are registered and copied into the app, widget, and report bundles. No font download is needed at runtime.

## Remaining device acceptance

Physical iOS 27 permission handling, private app-token labels, filtered Screen Time totals and report sizing, automation imports/runs, long session rendering, and system Live Activity layout still require an iPhone pass. Simulator appearance and successful builds do not prove these. The earlier unverified App-Opened/App-Closed installer templates remain hidden; their validation is separate from this redesign.
