# Runbook: AVD Session Host Instability Recovery - POOL-FIN-01

## Purpose
Use this runbook when one AVD session host shows repeated user disconnects immediately after logon and the evidence matches the SHFIN-01-A pattern: Application Error Event 1000 for dwm.exe faulting in igdumd64.dll, Desktop Window Manager Event 9009, and TerminalServices-LocalSessionManager disconnect events after an overnight image update.

## Prerequisites
- [ ] You can sign in to Azure portal: `https://portal.azure.com`.
- [ ] You are in the correct tenant and subscription that hosts `POOL-FIN-01`.
- [ ] [Elevated] Your Azure RBAC role includes one of: `Desktop Virtualization Contributor`, `Contributor`, or equivalent custom role that can manage host pools/session hosts.
- [ ] [Elevated] You can restart the backing VM from `Virtual machines` in Azure portal.
- [ ] [Elevated] You can remote to the session host with local admin rights (Azure Bastion, RDP, or approved enterprise remote tool).
- [ ] You can open Event Viewer on the affected host.
- [ ] You can access the approved central logging platform (Microsoft Sentinel / Log Analytics), if used by your team.
- [ ] You have one approved AVD test account that can sign in to `POOL-FIN-01`.
- [ ] You have an active service-desk or Teams/bridge channel to notify and coordinate with impacted users.

### Mandatory Information From End User (Do Not Start Without This)
- [ ] Affected username(s) in UPN format (example: `mlopez@finbridge.com`).
- [ ] Time of the latest disconnect (local time + timezone).
- [ ] AVD client type used (`Remote Desktop` app, Windows App, browser client).
- [ ] Device name and OS of user endpoint (example: `DESKTOP-FB022`, `Windows 11 23H2`).
- [ ] Whether disconnect happens at sign-in, within 1 to 2 minutes, or randomly later.
- [ ] Screenshot/text of error message shown in AVD client (if available).
- [ ] Business impact (single user, team-wide, VIP, production blocker).
- [ ] Confirmation whether the user can connect to a different host pool or app group.

### Required Tools
- [ ] Azure portal (`https://portal.azure.com`).
- [ ] Event Viewer (`eventvwr.msc`) on the affected session host.
- [ ] Optional: Log Analytics query editor in Azure portal.

### Log Locations (Use These Exact Paths)
- Azure portal host status:
	- `Azure portal -> Azure Virtual Desktop -> Host pools -> POOL-FIN-01 -> Session hosts`.
- Azure portal session view:
	- `Azure portal -> Azure Virtual Desktop -> Host pools -> POOL-FIN-01 -> Sessions`.
- Session host crash log:
	- `Event Viewer -> Windows Logs -> Application` (filter Event ID `1000`, source `Application Error`, process `dwm.exe`, module `igdumd64.dll`).
- Session host DWM termination log:
	- `Event Viewer -> Windows Logs -> System` (filter Event ID `9009`, source `Desktop Window Manager`).
- Session connect/disconnect log:
	- `Event Viewer -> Applications and Services Logs -> Microsoft -> Windows -> TerminalServices-LocalSessionManager -> Operational` (Event IDs `21`, `40`).
- Optional centralized log path:
	- `Azure portal -> Monitor -> Logs` (Log Analytics workspace linked to AVD diagnostics).

## Procedure
1. In browser, go to `https://portal.azure.com`, then verify top-right `Directory + subscription` matches the incident scope. Expected result: You are operating in the correct Azure tenant/subscription.
2. In Azure portal search bar, type `Azure Virtual Desktop` and open it. Then go to `Host pools` and select `POOL-FIN-01`. Expected result: Host pool overview page is open.
3. Open `Session hosts` tab under `POOL-FIN-01`. Locate the affected host (example: `SHFIN-01-A`) and record `Status`, `Allow new sessions`, and `Sessions`. Expected result: You have the current affected-host state documented.
4. In the same `Session hosts` list, select one healthy comparison host (example: `SHFIN-02-A`) and record the same fields. Expected result: You have a baseline host for comparison.
5. Open `POOL-FIN-01 -> Sessions` and filter by `Session host = SHFIN-01-A`. Notify listed users through service desk/Teams to save work and sign out. Expected result: Users are informed before host actions.
6. [Elevated] Return to `POOL-FIN-01 -> Session hosts -> SHFIN-01-A` and set `Allow new sessions = No` (drain mode). Expected result: No new sessions can land on SHFIN-01-A.
7. [Elevated] Go back to `POOL-FIN-01 -> Sessions`, filter `Session host = SHFIN-01-A`, select each active session, click `Sign out`. Expected result: SHFIN-01-A has zero active sessions.
8. [Elevated] Open `Virtual machines` in Azure portal, select VM `SHFIN-01-A`, and connect with approved admin method (Bastion/RDP). Expected result: You have administrative access to the affected host.
9. On SHFIN-01-A, run `eventvwr.msc`. Navigate to `Event Viewer -> Windows Logs -> Application`, click `Filter Current Log...`, set `Event IDs` to `1000`, set `Event sources` to `Application Error`. Expected result: Crash events are isolated.
10. Open newest relevant Event ID 1000 entries and confirm fields: `Faulting application name = dwm.exe` and `Faulting module name = igdumd64.dll`. Expected result: Incident matches known crash signature.
11. Navigate to `Event Viewer -> Windows Logs -> System`, click `Filter Current Log...`, set `Event IDs` to `9009`, source `Desktop Window Manager`. Expected result: DWM termination events are isolated.
12. Confirm Event 9009 timestamps line up with user disconnect times from ticket/user report. Expected result: DWM exits align with impact window.
13. Navigate to `Event Viewer -> Applications and Services Logs -> Microsoft -> Windows -> TerminalServices-LocalSessionManager -> Operational`, filter for `21,40`. Expected result: Session connect/disconnect sequence is visible.
14. Verify pattern `Event 21 (logon)` followed shortly by `Event 40 (disconnect)` on SHFIN-01-A. Expected result: Host instability is confirmed.
15. Optional central validation: in Azure portal, open `Monitor -> Logs` for the mapped Log Analytics workspace and run a query for host `SHFIN-01-A` with Event IDs `1000,9009,21,40` during incident window. Expected result: Central logs match local Event Viewer timeline.
16. [Elevated] Restart `SHFIN-01-A` from `Virtual machines -> SHFIN-01-A -> Overview -> Restart`. Expected result: Controlled reboot begins.
17. Wait until VM status is `Running`, then return to `Azure Virtual Desktop -> Host pools -> POOL-FIN-01 -> Session hosts` and verify `SHFIN-01-A` reports `Available`. Expected result: Host is back online and manageable.
18. [Elevated] Reconnect to SHFIN-01-A and repeat checks in log paths from Steps 9 to 14 for events generated after reboot time. Expected result: You determine whether the crash/disconnect pattern recurs.
19. Keep SHFIN-01-A in drain mode if any post-restart Event 1000 for `dwm.exe/igdumd64.dll` appears. Expected result: Unstable host remains isolated.
20. Confirm at least one other host in `POOL-FIN-01 -> Session hosts` is `Available` with `Allow new sessions = Yes`. Expected result: User service remains available through healthy hosts.
21. Ask one approved test user to sign in to the AVD workspace and confirm in `POOL-FIN-01 -> Sessions` that they land on a healthy host and remain connected for 10 minutes. Expected result: Service is stable for production users.
22. [Elevated] Only if SHFIN-01-A shows no post-restart recurrence, set `Allow new sessions = Yes` for SHFIN-01-A and run a controlled test sign-in. Expected result: Host is returned safely to rotation.
23. Ask a second test user to sign in and observe `POOL-FIN-01 -> Sessions` plus local logs for 10 minutes. Expected result: No immediate disconnect and no new matching error signature.

## Verification
1. Confirm that users can sign in to POOL-FIN-01 successfully after the remediation window. Expected result: User sessions start normally.
2. Confirm that no new Application Error Event 1000 entries for dwm.exe in igdumd64.dll appear on SHFIN-01-A after the restart and test sign-ins. Expected result: The known crash signature is absent.
3. Confirm that no new Desktop Window Manager Event 9009 entries appear on SHFIN-01-A after the restart and test sign-ins. Expected result: DWM is no longer exiting unexpectedly.
4. Confirm that no new TerminalServices-LocalSessionManager Event 40 disconnect entries appear immediately after user logon on SHFIN-01-A. Expected result: Session disconnects no longer recur on the affected host.
5. Confirm that SHFIN-02-A or another healthy host in POOL-FIN-01 continues to accept user sessions normally. Expected result: The pool remains stable even if SHFIN-01-A stays drained.
6. Confirm with the service desk that no new user reports for repeated disconnects in POOL-FIN-01 were raised during the validation period. Expected result: No fresh incident reports appear before closure.

## Rollback
1. [Elevated] Set SHFIN-01-A back to drain mode immediately if users disconnect again after Step 33. Expected result: New sessions stop landing on the unstable host.
2. [Elevated] Sign out any user session that lands on SHFIN-01-A after the recurrence is observed. Expected result: Active users are removed from the unstable host quickly.
3. [Elevated] Leave SHFIN-01-A out of rotation for the rest of the incident if a new Event ID 1000 for dwm.exe appears after the restart. Expected result: The known-bad host is contained.
4. [Elevated] Start an additional healthy session host in POOL-FIN-01 immediately if pool capacity becomes too low after draining SHFIN-01-A. Expected result: User capacity is restored without reintroducing the unstable host.
5. [Elevated] Reapply drain mode to any other host that begins showing the same Event 1000 and Event 9009 pattern during validation. Expected result: The failure does not spread through normal load balancing.
6. Escalate to the AVD platform or image engineering team with the host name, restart time, Event 1000 timestamps, Event 9009 timestamps, and comparison-host evidence if SHFIN-01-A fails again after restart. Expected result: The owning team has exact evidence for image rollback, host rebuild, or driver remediation.

## Notes
- This runbook is designed for the documented SHFIN-01-A pattern: successful AVD logon followed immediately by dwm.exe crashes in igdumd64.dll and session disconnects.
- The first operational goal is service restoration for users, not immediate repair of the affected host.
- Keep the affected host drained if the pool has enough healthy capacity to support users.
- Do not return SHFIN-01-A to service on a single successful reboot alone; require a clean post-restart log check and a controlled sign-in test.
- If multiple hosts in the same pool begin showing the same Event 1000 and Event 9009 pattern after an update wave, treat the incident as image-wide rather than host-specific.
- If only one host is affected and comparison hosts remain clean, prioritize containment of that host over broader AVD troubleshooting.
- Related evidence in the source RCA shows SHFIN-02-A remained healthy during the same window, which is the key comparison that rules out a general AVD outage.