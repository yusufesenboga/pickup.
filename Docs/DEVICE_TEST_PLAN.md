# Physical iPhone acceptance record

**Full app acceptance: not executed. Yusuf deferred those checks, then authorized separate iOS 27 shortcut-template editor inspection. See VALIDATION.md for that narrower evidence.** Do not replace “not run” with “pass” based on simulation or unit tests.

- Tester: ____________________
- Date / timezone: ____________________
- iPhone / iOS version: ____________________
- Commit / build: ____________________
- Screen Time permission: ____________________
- Live Activities permission: ____________________
- Tracked apps (include Safari to check an Apple app): ____________________
- Wait / grace / minimum display length: 50 / 30 / 60 seconds, unless recorded otherwise.

Before tests, add both prepared shortcuts in Setup, then configure the two personal automations from README. “Run Immediately” must be enabled. Use History or Show short sessions when a short session is hidden from Today. Setup diagnostics display Start/End arrivals. Manual Stop does not count as a Close automation event.

| # | Action | Expected / record | Result |
| --- | --- | --- | --- |
| 1 | Open a tracked app | Island glyph within about 2 seconds; record actual delay: ____ | Not run |
| 2 | Remain in the app through Wait | Timer appears at about 50 seconds, counting from original Start; actual delay: ____ | Not run |
| 3 | After at least 10 seconds in a tracked app, lock the phone | Record whether Closed fires and the Island clears. Last End timestamp: ____. If no Close, record the limitation and manually End in Pickup; raising grace cannot end an active session with no Close. | Not run |
| 4 | Switch A → B → A rapidly, both tracked; exercise both Open-before-Close and Close-before-Open ordering | Exactly one session, original start, no premature end beyond acceptable brief activity flicker | Not run |
| 5 | Stay over 5 seconds, leave a tracked app, reopen after 20 seconds | Same session ID and original start; icon resets unless immediate timer is enabled | Not run |
| 6 | Leave, reopen after 60 seconds | Two sessions; old end equals Close timestamp, not reopen time | Not run |
| 7 | Force-quit Pickup; open a tracked app | Intent opens shared store without UI; session logs, activity request works. Record any OS restriction. | Not run |
| 8 | Use Safari more than one minute in an overlapping hour; open Session Detail | Safari is included; header honestly says hour buckets, no per-session precision claim | Not run |
| 9 | Open Today with Screen Time approved | Apple total, pickups, logged, untracked render; untracked ≥ 0. Compare Settings → Screen Time at the same time; record update delay/discrepancies. | Not run |
| 10 | Disable Live Activities in iOS Settings; open tracked app | Fix-it card appears in Pickup, session still logs | Not run |

Additional acceptance checks:

- [ ] With other setup incomplete, tap Test Dynamic Island. Verify a real session and immediate timer; go Home and check the physical Island, then End Session. Test permission-denied and already-active cases.
- [ ] On iOS 27, import each automation template into a fresh library. Verify App import question, correct Opened/Closed state, disabled-until-reviewed behavior, and matching app selections.
- [ ] Verify both automation installer buttons and bundled-file fallbacks. Confirm three ordered actions in Opened, End only in Closed, and no duplicate enabled triggers.
- [ ] Test the revised Describe fallback using Run Shortcut. Inspect the actual editor rather than trusting the generated summary.


- [ ] Deny Screen Time. All timer/log actions still work; allow access later using retry.
- [ ] Turn Show timer immediately on, open a tracked app, verify digits without waiting.
- [ ] End followed by a late Show Timer does not revive a pending/ended session.
- [ ] Tap turn off Dynamic Island immediately after starting; confirm dismissal, no recovery on return, and a new session on the next Start.
- [ ] Visit a tracked app for one second, then leave; confirm the Close event arrives and the Island disappears immediately.
- [ ] Leave a pending session, briefly foreground Pickup within grace, then reopen tracked app within grace: resume works.
- [ ] Wait for an activity's eight-hour expiry, then foreground Pickup: activity recovery uses original start. Record stale presentation.
- [ ] Tap expanded or Lock Screen activity: correct session detail opens.
- [ ] Midnight session contributes correctly to both days and appears only under its starting day in History.
- [ ] Today mounts only one report; detail mounts only one. Refresh handles blank/stale reports.
- [ ] Test a report containing more apps than fit vertically, including the Other group.
- [ ] Change accent/detail preference and foreground Pickup: running activity and reports refresh.
- [ ] Export JSON and CSV, inspect pending end, status and duration, dismiss share sheet.
- [ ] Delete one history row; clear one day with confirmation; delete all with confirmation. Verify activity cleanup and fresh empty snapshot.
- [ ] Test smaller iPhone layout, largest Dynamic Type, VoiceOver, and Lock Screen-only presentation.
- [ ] On a fresh library, tap Add Start Shortcut → Add Shortcut, then Add End Shortcut → Add Shortcut. Confirm names and all three Pickup actions resolve, with no Unknown Action blocks.
- [ ] Verify Start has Start Session → Wait 50 seconds → Show Timer, and End has just End Session. Imported actions must not foreground Pickup.
- [ ] Cancel either import: Step 3 must stay incomplete. Reopen Setup, import again, and confirm manually.
- [ ] Verify the signed-file fallback opens in Shortcuts (or Save to Files → open); test both files.
- [ ] If iCloud sync already supplied both recipes, skip reimport and select them for the automations.
- [ ] Choose several apps together for Opened, then the same apps together for Closed. Only two automations should exist.
- [ ] Change preferred delay; Setup must explain that the imported Wait needs manual editing.
- [ ] Add real tutorial screenshots.

Failure notes / evidence:

________________________________________

Release sign-off: ____________________
