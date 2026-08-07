# Root Cause Analysis (RCA): AVD Session Host Instability in POOL-FIN-01

## Incident Summary
- Incident type: AVD session host instability with repeated user session disconnects
- Affected environment: POOL-FIN-01
- Primary affected host: SHFIN-01-A
- Comparison host: SHFIN-02-A
- Observation window: 2024-03-15 07:00 to 07:30
- Resolution status: Suggested resolution applied; issue confirmed resolved at 10:00 AM
- Verification status: Users were able to log in to hosts in POOL-FIN-01 and no further issues were reported

## Executive Summary
During the morning incident window, users on SHFIN-01-A experienced repeated session disconnects immediately after logon. The host had restarted after the overnight image update and then entered a crash loop involving dwm.exe and igdumd64.dll. The same time window on SHFIN-02-A showed successful logon and normal Desktop Window Manager startup with no Application Error events. The evidence supports an update-associated host stability issue limited to the affected session host rather than a user credential or network issue.

A suggested remediation was applied, and by 10:00 AM the issue was resolved. Verification showed users successfully logging into hosts in POOL-FIN-01 with no issues reported.

## Supporting Evidence

### SHFIN-01-A Event Window: 2024-03-15 07:00-07:30
- 07:02:10 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 21: Remote Desktop Services session logon succeeded for FINBRIDGE\mlopez, Session ID 3, source 10.10.1.55.
- 07:02:14 - Microsoft-Windows-Kernel-General Event 1: system boot time recorded as 2024-03-15 02:03:11, confirming the host restarted after the overnight image update.
- 07:02:16 - Application Error Event 1000: dwm.exe faulted in igdumd64.dll with exception code 0xc0000005.
- 07:02:17 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 40: session disconnected for FINBRIDGE\mlopez, Session ID 3, reason code 0.
- 07:02:18 - Desktop Window Manager Event 9009: DWM exited with code 0x40010004.
- 07:02:44 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 21: session logon succeeded again for FINBRIDGE\mlopez, Session ID 3, reconnect.
- 07:02:46 - Application Error Event 1000: dwm.exe faulted again in igdumd64.dll with exception code 0xc0000005.
- 07:02:47 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 40: session disconnected again for FINBRIDGE\mlopez, Session ID 3.
- 07:03:01 - Desktop Window Manager Event 9009: DWM exited again with code 0x40010004.
- 07:03:10 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 21: session logon succeeded a second time for FINBRIDGE\mlopez, Session ID 4.
- 07:08:22 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 21: session logon succeeded for FINBRIDGE\akapoor, Session ID 5, source 10.10.1.61.
- 07:08:24 - Application Error Event 1000: dwm.exe faulted again in igdumd64.dll with exception code 0xc0000005.

### SHFIN-02-A Comparison Host
- 07:01:44 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 21: session logon succeeded for FINBRIDGE\bwalker, Session ID 2.
- 07:01:46 - Desktop Window Manager Event 9011: DWM started successfully.
- No Application Error events were recorded in the same window.

## Timeline
1. 07:01:44 to 07:01:46 - SHFIN-02-A shows normal session logon and healthy DWM startup, establishing a clean comparison host.
2. 07:02:10 - A user session successfully logs on to SHFIN-01-A.
3. 07:02:14 - The host boot time confirms SHFIN-01-A restarted after the overnight image update.
4. 07:02:16 - dwm.exe crashes in igdumd64.dll with access violation 0xc0000005.
5. 07:02:17 to 07:02:18 - The active user session disconnects and DWM exits.
6. 07:02:44 to 07:03:01 - The user reconnects, but the same crash/disconnect pattern repeats.
7. 07:03:10 - Another successful session logon occurs, showing the host is still accepting connections but not remaining stable.
8. 07:08:22 to 07:08:24 - A second user logs on and the same dwm.exe crash recurs, confirming the issue is host-wide rather than user-specific.
9. 10:00:00 - Suggested resolution is applied and the issue is confirmed resolved.
10. After 10:00 AM - Users are verified logging in to hosts in POOL-FIN-01 with no issues reported.

## Root Cause Statement
The most likely root cause was an update-associated instability on SHFIN-01-A that caused dwm.exe to crash repeatedly in igdumd64.dll after the host restarted. This instability disrupted user sessions on the affected session host, while the comparison host remained healthy during the same window.

## Five Whys Analysis

### Problem
Why were users disconnected from AVD sessions on SHFIN-01-A?
- Because the session host was not stable after logon and repeatedly terminated the active session.
- Evidence: Event 40 at 07:02:17 and 07:02:47.

### Why 1
Why was the session host not stable?
- Because Desktop Window Manager exited with error after dwm.exe crashed.
- Evidence: Application Error Event 1000 at 07:02:16 and 07:02:46; DWM Event 9009 at 07:02:18 and 07:03:01.

### Why 2
Why did dwm.exe crash?
- Because dwm.exe faulted in igdumd64.dll with access violation 0xc0000005.
- Evidence: Application Error Event 1000 at 07:02:16, 07:02:46, and 07:08:24.

### Why 3
Why was the crash limited to SHFIN-01-A?
- Because SHFIN-01-A had restarted after the overnight image update, while SHFIN-02-A remained on the pre-update image and stayed healthy.
- Evidence: Kernel-General Event 1 at 07:02:14 on SHFIN-01-A; DWM Event 9011 at 07:01:46 and no Application Error events on SHFIN-02-A.

### Why 4
Why did the update matter?
- Because the updated host introduced or exposed an incompatibility in the graphics/session stack that was not present on the unaffected host.
- Evidence: repeated post-update crash loop on SHFIN-01-A at 07:02:16, 07:02:46, and 07:08:24 versus clean startup on SHFIN-02-A.

### Why 5
Why did the issue require a remediation step rather than self-recovery?
- Because the fault repeated across multiple user logons and continued until the suggested resolution was applied.
- Evidence: repeated successful logons followed by repeated crashes on SHFIN-01-A, then resolution confirmed at 10:00 AM.

## Conclusion
The incident was caused by a host-side stability issue on SHFIN-01-A following the overnight image update. The issue manifested as repeated dwm.exe crashes in igdumd64.dll and session disconnects. SHFIN-02-A remained unaffected during the same period, which strengthens the conclusion that the problem was specific to the updated host state rather than a general AVD service outage.

## Preventive Actions
1. Validate post-update host health before returning updated session hosts to service, with special attention to DWM and graphics-related crashes.
2. Compare updated and non-updated hosts during rollout windows to identify host-specific regressions early.
3. Add alerting for repeated Application Error Event 1000 entries involving dwm.exe or igdumd64.dll on AVD session hosts.
4. Introduce a short post-patch smoke test for user logon, reconnect, and session stability before marking a pool ready.
5. Review image update and driver compatibility checks to reduce the risk of graphics stack regressions.
6. Document the remediation runbook so the same resolution can be applied quickly if the crash pattern recurs.

## Verification of Resolution
- The suggested resolution was applied successfully.
- The issue was resolved at 10:00 AM.
- Users were verified logging in to hosts in POOL-FIN-01 without issues.
- No further incidents were reported after validation.

## Lessons Learned
- A single healthy comparison host can materially narrow the investigation when another updated host shows repeated crash behavior.
- DWM and graphics module failures on AVD session hosts should be treated as a service-impacting signal, especially when they occur immediately after a reboot or image update.
- Resolution verification should include actual user login confirmation across the affected pool, not only service availability checks.
