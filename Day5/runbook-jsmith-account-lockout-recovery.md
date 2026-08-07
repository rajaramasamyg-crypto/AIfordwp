---
Title: Runbook – User Account Lockout Recovery (jsmith Pattern)
Version: 1.0
Date: 07/08/2026
Author: Sathishbabu
Reviewed: Self
Status: Draft
Change: Initial version from RCA
---

# Runbook: User Account Lockout Recovery - jsmith Pattern

## Purpose
Use this runbook when a user is locked out after repeated bad-password attempts from a single Windows endpoint, matching the jsmith incident pattern documented in day3/RCA-jsmith-account-lockout-2026-08-06.md.

## Prerequisites
- [ ] You are connected to the FINBRIDGE corporate network (LAN/VPN) from a domain-joined admin workstation.
- [ ] You can open **Active Directory Users and Computers** (ADUC): `Start` -> `Windows Tools` -> `Active Directory Users and Computers`.
- [ ] You can open **Event Viewer** on a domain controller: `Server Manager` -> `Tools` -> `Event Viewer`.
- [ ] You have one approved remote tool for endpoint remediation: RDP (`mstsc`), Intune Remote Help, or approved enterprise remote-control tool.
- [ ] [Elevated] Your account has delegated rights to unlock/enable/reset users in AD.
- [ ] [Elevated] Your account has rights to read Security logs on domain controllers or read the approved SIEM workspace.
- [ ] [Elevated] Your account can run local admin actions on the source workstation (Credential Manager, Task Scheduler, Services).
- [ ] You have a temporary strong password prepared in case reset is required.

### Required Tools
- [ ] `eventvwr.msc` (domain controller and source workstation).
- [ ] `dsa.msc` (AD Users and Computers).
- [ ] Endpoint admin access method (RDP/Remote Help/approved tool).
- [ ] Optional SIEM access (Microsoft Sentinel / Log Analytics) for cross-validation.

### Mandatory Information From End User (Do Not Start Without This)
- [ ] User UPN/sAMAccountName (example: `FINBRIDGE\\jsmith`).
- [ ] User phone number or alternate contact (in case they are signed out).
- [ ] Current device hostname shown on lock screen (`This sign-in option`) or from sticker/asset tag.
- [ ] Exact time of latest failed sign-in (local time with timezone).
- [ ] Whether the user changed password recently (last 24 to 72 hours).
- [ ] Whether user is signed in on additional devices (laptop, mobile, Outlook phone app, Teams room, kiosk).
- [ ] Whether VPN was connected during failed sign-in.
- [ ] Screenshot/photo of lockout message if possible.
- [ ] Business impact and urgency (cannot sign in at all vs app-only issue).

### Log Locations You Will Use
- Domain Controller Security Log: `Event Viewer -> Windows Logs -> Security`.
- Account lockout audit events to filter: `4625`, `4624`, `4722`, `4740`, `4771`, `4776`.
- SIEM (if used): `Azure portal -> Microsoft Sentinel -> <Workspace> -> Logs` and query table `SecurityEvent` (or your mapped Windows Security table).
- Endpoint local logs (if needed): `Event Viewer -> Windows Logs -> Security` and `Event Viewer -> Applications and Services Logs -> Microsoft -> Windows -> TaskScheduler -> Operational`.

## Procedure
1. In the ticket, instruct the user to stop all sign-in attempts on all devices (PC, phone, Outlook mobile, VPN) until you confirm containment. Expected result: No new retry activity is introduced.
2. Sign in to a domain controller (preferably PDC emulator) and open `Server Manager -> Tools -> Event Viewer -> Windows Logs -> Security`. Expected result: You are at the authoritative lockout event source.
3. In `Security`, click `Filter Current Log...` and enter Event IDs `4740`; click `OK`. Then use `Find...` with the impacted username. Expected result: You find the lockout event for the user.
4. Open the newest 4740 event and capture `TargetUserName`, `Caller Computer Name`, and timestamp into the incident notes. Expected result: Lockout source host and exact lockout time are documented.
5. In the same Security log, re-open `Filter Current Log...` and enter Event IDs `4625,4771,4776`; review 5 to 10 minutes before the 4740 time. Expected result: You identify retries that triggered lockout.
6. For each relevant 4625 event, record `Logon Type`, `Status`, `SubStatus`, and `Workstation Name`. Expected result: You confirm whether pattern is single-endpoint bad-password retry.
7. Optional SIEM validation: go to `Azure portal -> Microsoft Sentinel -> <Workspace> -> Logs` and run query on `SecurityEvent` for `EventID in (4740,4625,4771,4776)` and the user/time window. Expected result: SIEM timeline matches DC timeline.
8. [Elevated] Open ADUC via `Start -> Windows Tools -> Active Directory Users and Computers` (or run `dsa.msc`). Use `Find...` to open the affected user object. Expected result: Correct AD user object is open.
9. [Elevated] In user `Properties -> Account`, check whether `Unlock account` is shown and whether `Account is disabled` applies. Expected result: Required account recovery actions are identified.
10. [Elevated] If locked, clear `Unlock account`; if disabled, enable the account. Click `Apply`. Expected result: Account is available for authentication.
11. [Elevated] If user is unsure of current password or retries continue, run `Right-click user -> Reset Password...`, set temporary strong password, and select `User must change password at next logon`. Expected result: Known-good credential state is established.
12. Connect to caller workstation from Step 4 (example `DESKTOP-FB001`) using approved admin remote method. Expected result: You have admin access to the retry source endpoint.
13. On source workstation, open `Control Panel -> Credential Manager -> Windows Credentials` and `Generic Credentials`; remove entries for affected identity (Outlook, Teams, OneDrive, VPN, file shares). Expected result: Stale cached credentials are removed.
14. Open `Task Scheduler -> Task Scheduler Library` and subfolders. Review `Run As User` for tasks using affected account; disable those tasks temporarily. Expected result: Task-driven retries are stopped.
15. Open `services.msc`, sort by `Log On As`, identify non-Microsoft services running under affected account, then stop and set Startup Type to `Manual` temporarily. Expected result: Service-driven retries are stopped.
16. Re-open endpoint logs at `Event Viewer -> Windows Logs -> Security` and `...TaskScheduler -> Operational`; check for new bad-password attempts after containment. Expected result: No fresh local retry events.
17. Ask user to sign in once on source workstation using known-good password, then perform one lock/unlock cycle. Expected result: Successful interactive logon and unlock.
18. Ask user to re-enter credentials in Outlook, Teams, OneDrive, VPN, and mapped resources. Expected result: Client credential caches are updated.
19. Re-enable disabled tasks/services one at a time, waiting 2 to 3 minutes between each and checking logs after each change. Expected result: You identify any specific background retry source before full restoration.
20. Return to domain controller `Event Viewer -> Windows Logs -> Security` and monitor user events for 10 minutes. Expected result: At least one `4624` success and no new `4740/4625/4771/4776` events.

## Verification
1. **Confirm successful logon on domain controller** — On the domain controller, open `Start` → `Windows Tools` → `Event Viewer` → expand `Windows Logs` → click `Security`. In the right-hand `Actions` pane click `Filter Current Log...`, enter `4624` in the **Event IDs** field, click `OK`. Then click `Find...` (Actions pane), type the affected username (e.g. `jsmith`), click `Find Next`. **Expected result:** At least one `4624` event for the user appears with a timestamp after the unlock/password-reset time recorded in the ticket.
2. **Confirm no new bad-password or lockout events on domain controller** — In the same `Event Viewer` → `Windows Logs` → `Security` window, click `Filter Current Log...` again, clear the previous value and enter `4625,4740,4771,4776`, click `OK`. Click `Find...`, type the username, click `Find Next`. **Expected result:** No matching events for the user appear in the 10 minutes following the confirmed `4624` logon.
3. **Confirm no new bad-password events on the source workstation** — Connect to the source workstation (e.g. `DESKTOP-FB001`) via the approved remote method. Open `Start` → search `Event Viewer` → expand `Windows Logs` → click `Security`. Click `Filter Current Log...`, enter `4625`, click `OK`. Click `Find...`, type the username, click `Find Next`. **Expected result:** No `4625` events for the user appear after the credential cleanup time.
4. **Confirm Task Scheduler is not generating retries** — On the source workstation in the same `Event Viewer`, expand `Applications and Services Logs` → `Microsoft` → `Windows` → `TaskScheduler` → click `Operational`. Click `Filter Current Log...`, enter `101,103` (task failed/stopped event IDs) in the Event IDs field, click `OK`. Scan for entries referencing the affected username or task names noted during remediation. **Expected result:** No scheduler failures involving the affected account appear after remediation.
5. **Confirm user interactive sign-in** — Ask the user to lock the workstation with `Win + L` and unlock using their current password. **Expected result:** Unlock succeeds immediately with no credential error or second prompt.
6. **Confirm business application re-authentication** — Ask the user to open Outlook, Teams, OneDrive, and attempt to access one mapped network drive or SharePoint site. **Expected result:** All applications connect silently without displaying a new credential prompt.

## Rollback
> **Target: full containment in under 3 minutes. Execute steps in order. Do not skip ahead.**

### Step R1 — Disable the re-enabled scheduled task (≈ 45 seconds)
**Trigger:** New `4625`, `4740`, `4771`, or `4776` events appear for the user after a task was re-enabled.
1. On the source workstation, press `Start`, search `Task Scheduler`, open it.
2. In the left tree expand `Task Scheduler Library` → navigate to the subfolder where the task was re-enabled.
3. Right-click the task → `Disable`.
4. Verify: in `Event Viewer` → `Windows Logs` → `Security` on the same workstation, press `F5` to refresh; confirm no new `4625` events for the username appear within 60 seconds.
**Expected result:** Retry events stop within 60 seconds of disabling the task.

### Step R2 — Stop the re-enabled service (≈ 45 seconds)
**Trigger:** New `4625`, `4740`, `4771`, or `4776` events appear for the user after a service was restarted.
1. On the source workstation, press `Start`, search `Services`, open `services.msc`.
2. Click the `Log On As` column header to sort; locate the service running under the affected account.
3. Right-click the service → `Stop`.
4. Right-click the service → `Properties` → set `Startup type` to `Manual` → click `OK`.
5. Verify: in `Event Viewer` → `Windows Logs` → `Security`, press `F5`; confirm no new `4625` events within 60 seconds.
**Expected result:** Service stops; retry events cease within 60 seconds.

### Step R3 — Unlock the account if re-locked (≈ 30 seconds)
**Trigger:** User reports they cannot sign in again during or after verification.
1. On your admin workstation, press `Start`, search `Active Directory Users and Computers`, open `dsa.msc`.
2. Click `Action` → `Find...`; in the **Name** field type the username (e.g. `jsmith`), click `Find Now`.
3. Double-click the user in the results → click the `Account` tab → tick `Unlock account` → click `Apply` → click `OK`.
4. Confirm with the user that they can now sign in.
**Expected result:** Account unlocked; user can attempt sign-in immediately.

### Step R4 — Reset to a new temporary password if sign-in still fails (≈ 45 seconds)
**Trigger:** Account is unlocked (R3 done) but user still cannot sign in.
1. In `dsa.msc` (open as in R3), right-click the user → `Reset Password...`.
2. Enter a new strong temporary password (format: `Temp@<TicketNumber>1!`), confirm it.
3. Tick `User must change password at next logon`, click `OK`.
4. Communicate the temporary password to the user over a verified phone call — do **not** send via email or Teams until they can sign in.
**Expected result:** Known-good credential state re-established; user signs in once and sets their own permanent password.

### Step R5 — Move user to a clean workstation (≈ 30 seconds to instruct)
**Trigger:** Source workstation continues generating lockouts after R1–R4 are complete.
1. Direct the user to sign in on a different domain-joined corporate workstation.
2. Do **not** attempt further cleanup on the original machine — leave tasks and services disabled.
3. Record the original hostname (from the `4740` event `Caller Computer Name` field) and the ticket number in your notes.
**Expected result:** User productivity restored; original machine isolated.

### Step R6 — Escalate (complete within remaining time)
**Trigger:** Lockout source cannot be contained after R1–R5, or the source is non-interactive (no scheduled task or service found).
1. Open a sub-task or new incident linked to the current ticket.
2. Include the following in the escalation notes (copy-paste from your ticket):
   - Affected username and UPN
   - Source workstation hostname (from `4740` `Caller Computer Name`)
   - Timestamps of first and most recent `4740` events (from `Event Viewer` → `Windows Logs` → `Security` on the DC)
   - All event IDs observed (`4625`, `4740`, `4771`, `4776`) with counts
   - Names of any tasks or services that were found running under the account
3. Assign to the **Identity and Access** or **Endpoint Engineering** team per your organisation's escalation matrix.
**Expected result:** Engineering team receives all required data and can continue investigation without repeating triage.

## Notes
- This runbook is for the main jsmith pattern: repeated bad-password attempts from one Windows endpoint followed by Event ID 4740 lockout.
- The source RCA file also contains later AVD and cthompson addenda that do not change this recovery procedure for a single-endpoint lockout.
- If Event IDs 4771 or 4776 continue from a second host or source IP after workstation cleanup, this incident no longer matches the single-endpoint jsmith pattern; treat it as a multi-source stale-credential investigation.
- If the lockout source is an AVD host, check for disconnected sessions and profile the host for saved credentials, scheduled tasks, and services before returning the user to that host.
- If the affected account is used by automation, do not leave the service disabled without handing off to the application or automation owner.
- If the user reports repeated password prompts on mobile devices, remove and re-add the work account on those devices after the desktop sign-in succeeds.
- Related incident: cthompson showed a similar lockout symptom with an additional second source, which is a useful warning sign that one workstation may not be the only retry origin.