# Root Cause Analysis (RCA): User Account Lockout - jsmith

## Incident Summary
- Incident type: User account lockout
- Affected account: jsmith
- Observation window: 08:02:14 to 08:23:44 (approximately 22 minutes)
- Primary host involved: DESKTOP-FB001
- Security context: Windows Security Event Log

## Event ID Explanations

### Event ID 4625 (Audit Failure)
Records a failed logon attempt. It includes the account name used, failure reason, source computer, and logon type.

- In this incident:
  - 08:02:14 and 08:04:22: failed interactive logons (logon type 2) with reason "Unknown username or bad password"
  - 08:07:45: failed unlock attempt (logon type 7) with reason "Account locked out"

### Event ID 4740 (Audit Failure in supplied data; commonly logged as account management event)
Records that an account was locked out after reaching the domain/account lockout threshold for bad password attempts.

- In this incident:
  - 08:06:01: account jsmith was locked out
  - Caller/source: DESKTOP-FB001

### Event ID 4722 (Audit Success)
Records that a user account was enabled (or re-enabled) by an administrator.

- In this incident:
  - 08:22:10: account jsmith enabled by FINBRIDGE\helpdesk-admin

### Event ID 4624 (Audit Success)
Records a successful logon.

- In this incident:
  - 08:23:44: successful interactive logon for jsmith (logon type 2)

## Reconstructed Sequence of Events (Plain English)
1. At 08:02:14, jsmith tried to sign in at DESKTOP-FB001 and entered an incorrect password (or otherwise invalid credentials), causing a failed interactive logon.
2. At 08:04:22, a second failed interactive sign-in for jsmith occurred from the same machine with the same bad-password reason.
3. By 08:06:01, the account lockout threshold had been reached and jsmith was locked out. The lockout event identifies DESKTOP-FB001 as the caller.
4. At 08:07:45, another attempt was made to unlock/sign in (logon type 7), but it failed because the account was already locked.
5. At 08:22:10, helpdesk admin FINBRIDGE\helpdesk-admin enabled/re-enabled the account.
6. At 08:23:44, jsmith successfully logged on interactively, confirming restoration of access and valid credentials.

## Most Likely Cause of Lockout
The most likely cause is repeated bad-password attempts from DESKTOP-FB001 during interactive sign-in/unlock, which triggered the account lockout policy threshold.

## Evidence Supporting the Cause
- Two explicit bad-password failures for jsmith occurred before lockout:
  - 08:02:14 (4625, type 2, bad password)
  - 08:04:22 (4625, type 2, bad password)
- The lockout event follows shortly after:
  - 08:06:01 (4740, account locked out)
- The caller/source in the lockout event is the same endpoint:
  - DESKTOP-FB001
- A later unlock attempt fails specifically due to lockout state:
  - 08:07:45 (4625, type 7, failure reason: account locked out)
- Administrative intervention is then required, after which logon succeeds:
  - 08:22:10 (4722 by helpdesk-admin)
  - 08:23:44 (4624 successful logon)

## Root Cause Statement
User jsmith entered incorrect credentials multiple times at DESKTOP-FB001 (interactive and unlock contexts), exceeding the configured account lockout threshold and causing a temporary lockout until helpdesk re-enabled the account.

## Five Whys Analysis

### Problem
jsmith was locked out and unable to access their machine.

### Why 1
Why was jsmith locked out?
- Because the account hit the lockout threshold after failed logon attempts.
- Evidence: 4740 at 08:06:01.

### Why 2
Why were there failed logon attempts?
- Because incorrect credentials were submitted for jsmith.
- Evidence: 4625 at 08:02:14 and 08:04:22 with "Unknown username or bad password".

### Why 3
Why were incorrect credentials repeatedly submitted?
- Most likely the user typed an incorrect password more than once during local sign-in/unlock activity on DESKTOP-FB001.
- Evidence: failures are interactive (type 2), then unlock context (type 7), all from DESKTOP-FB001.

### Why 4
Why did repeated incorrect attempts cause immediate loss of access?
- Because account lockout policy is configured to lock the account after a defined number of bad attempts (security control behavior).
- Evidence: transition from 4625 bad password events to 4740 lockout within minutes.

### Why 5
Why did resolution require helpdesk intervention?
- Because once lockout occurred, user self-recovery was insufficient and administrative re-enable/reset action was needed.
- Evidence: 4722 by FINBRIDGE\helpdesk-admin followed by 4624 successful logon.

## Contributing Factors
- Interactive local sign-in attempts under time pressure.
- No successful sign-in before threshold was reached.
- Dependence on helpdesk workflow to restore access.

## Impact
- User access interruption for approximately 17 minutes from lockout (08:06:01) to administrative recovery action (08:22:10), with successful access confirmed at 08:23:44.
- Productivity loss and support desk involvement.

## Corrective Actions Taken
- Helpdesk re-enabled account jsmith (4722).
- User subsequently authenticated successfully (4624).

## Preventive Actions (Recommended)
1. User guidance: verify keyboard layout/Caps Lock before repeated retries.
2. Encourage use of password manager or approved credential workflows to reduce entry errors.
3. Tune support process for faster lockout recovery during business hours.
4. Review lockout threshold/duration settings to balance security and usability.
5. Add alerting correlation: multiple 4625 events followed by 4740 from same host to trigger early support outreach.

## Confidence and Gaps
- Confidence level: High for sequence and immediate trigger (bad password attempts leading to lockout).
- Remaining gap: Raw logs do not prove the precise human behavior (typo vs stale cached credential vs keyboard/layout issue), only that bad credentials were presented from DESKTOP-FB001.

## Timeline (Condensed)
- 08:02:14 - 4625 bad password (interactive) from DESKTOP-FB001
- 08:04:22 - 4625 bad password (interactive) from DESKTOP-FB001
- 08:06:01 - 4740 account locked out, caller DESKTOP-FB001
- 08:07:45 - 4625 account locked out (unlock attempt)
- 08:22:10 - 4722 account enabled by FINBRIDGE\helpdesk-admin
- 08:23:44 - 4624 successful interactive logon for jsmith

## Addendum: AVD Session Host Event Details

### SHFIN-01-A Event Window: 2024-03-15 07:00-07:30
- 07:02:10 - TerminalServices-LocalSessionManager Event 21: session logon succeeded for FINBRIDGE\mlopez, Session ID 3.
- 07:02:14 - Kernel-General Event 1: system boot time recorded as 2024-03-15 02:03:11, confirming a restart after the overnight image update.
- 07:02:16 - Application Error Event 1000: dwm.exe faulted in igdumd64.dll with exception code 0xc0000005.
- 07:02:17 - TerminalServices-LocalSessionManager Event 40: session disconnected for FINBRIDGE\mlopez, Session ID 3.
- 07:02:18 - Desktop Window Manager Event 9009: DWM exited with code 0x40010004.
- 07:02:44 - TerminalServices-LocalSessionManager Event 21: session logon succeeded again for FINBRIDGE\mlopez, Session ID 3 (reconnect).
- 07:02:46 - Application Error Event 1000: dwm.exe faulted again in igdumd64.dll with exception code 0xc0000005.
- 07:02:47 - TerminalServices-LocalSessionManager Event 40: session disconnected again for FINBRIDGE\mlopez, Session ID 3.
- 07:03:01 - Desktop Window Manager Event 9009: DWM exited again with code 0x40010004.
- 07:03:10 - TerminalServices-LocalSessionManager Event 21: session logon succeeded a second time for FINBRIDGE\mlopez, Session ID 4.
- 07:08:22 - TerminalServices-LocalSessionManager Event 21: session logon succeeded for FINBRIDGE\akapoor, Session ID 5.
- 07:08:24 - Application Error Event 1000: dwm.exe faulted again in igdumd64.dll with exception code 0xc0000005.

### SHFIN-02-A Comparison Host
- 07:01:44 - TerminalServices-LocalSessionManager Event 21: session logon succeeded for FINBRIDGE\bwalker, Session ID 2.
- 07:01:46 - Desktop Window Manager Event 9011: DWM started successfully.
- No Application Error events were recorded in the same window.

## Addendum: Reviewed Hypotheses

### 1. Update-triggered credential cache invalidation or authentication behavior change
Status: Supported.
The updated host rebooted at 07:02:14 and immediately entered a DWM crash/disconnect loop at 07:02:16, 07:02:17, 07:02:46, and 07:02:47, while SHFIN-02-A remained clean with Event 9011 at 07:01:46 and no Application Error events. The split between updated and unaffected hosts supports an update-linked change.

### 2. Group Policy Object change applied during the update window
Status: Neutral.
The evidence set does not contain a policy-processing event or a GPO-specific failure. The most relevant events are the DWM Application Error 1000 entries at 07:02:16, 07:02:46, and 07:08:24, which point to session instability rather than policy behavior.

### 3. Service or scheduled task using stale credentials, re-triggered by machine restart post-update
Status: Supported.
Kernel-General Event 1 at 07:02:14 confirms the restart, and the first post-reboot session activity is followed immediately by DWM crashes at 07:02:16 and 07:02:46, with disconnects at 07:02:17 and 07:02:47. The logs do not name a specific service or task, but the restart-triggered timing is consistent with this hypothesis.

### 4. Mobile device or secondary device with saved old password
Status: Contradicted.
The visible failures are local to SHFIN-01-A and tied to DWM/Application Error events at 07:02:16, 07:02:46, and 07:08:24, plus session disconnects at 07:02:17 and 07:02:47. There is no evidence in this window of external credential retries from a phone or secondary device.

### 5. Pure user error, manual mistyping at DESKTOP-FB001
Status: Contradicted.
The event set for the affected AVD host shows successful session logons followed by DWM crashes and disconnects, not bad-password failures. The determining events are TerminalServices-LocalSessionManager Event 21 at 07:02:10, 07:02:44, 07:03:10, and DWM/Application Error events at 07:02:16, 07:02:46, and 07:08:24.

## Addendum: Resolution

The added AVD evidence points to a host/session-stability issue on SHFIN-01-A after the overnight image update, centered on repeated dwm.exe crashes in igdumd64.dll and repeated session disconnects. SHFIN-02-A remained unaffected during the same window, which strengthens the update-linked interpretation.

This addendum does not replace the original jsmith lockout RCA. Instead, it clarifies that the new event evidence supports an AVD session-host problem as the updated analysis thread, while the previously documented jsmith account lockout sequence remains unchanged in the main body of the report.

## Addendum: cthompson Security Log Evidence Review (2024-03-15 08:44-09:12)

### Event Details In Scope
- 08:44:01 - Security Event 4776 (Audit Failure): Domain credential validation failed for FINBRIDGE\cthompson with error code 0xC000006A (wrong password). Source workstation: DESKTOP-FB022.
- 08:44:03 - Security Event 4625 (Audit Failure): Failed interactive logon (type 2) for FINBRIDGE\cthompson. Reason: unknown username or bad password. Source: DESKTOP-FB022.
- 08:44:28 - Security Event 4625 (Audit Failure): Failed interactive logon (type 2) for FINBRIDGE\cthompson. Reason: unknown username or bad password. Source: DESKTOP-FB022.
- 08:44:55 - Security Event 4625 (Audit Failure): Failed interactive logon (type 2) for FINBRIDGE\cthompson. Reason: unknown username or bad password. Source: DESKTOP-FB022.
- 08:44:56 - Security Event 4740 (Audit Failure): Account FINBRIDGE\cthompson locked out. Caller computer: DESKTOP-FB022.
- 08:45:10 - Security Event 4625 (Audit Failure): Failed unlock attempt (type 7) for FINBRIDGE\cthompson. Reason: account locked out. Source: DESKTOP-FB022.
- 08:45:44 - Security Event 4771 (Audit Failure): Kerberos pre-authentication failed for FINBRIDGE\cthompson. Failure code 0x18 (wrong password). Source IP: 10.10.8.112.
- 08:46:01 - Security Event 4771 (Audit Failure): Kerberos pre-authentication failed for FINBRIDGE\cthompson. Failure code 0x18 (wrong password). Source IP: 10.10.8.112.
- 08:46:33 - Security Event 4771 (Audit Failure): Kerberos pre-authentication failed for FINBRIDGE\cthompson. Failure code 0x18 (wrong password). Source IP: 10.10.8.112.

### Reviewed Hypotheses vs Evidence

#### 1. Incorrect password or credential mismatch (human entry error or stale remembered password)
Status: Supported.
Determining evidence:
- 08:44:01 Event 4776 with 0xC000006A (wrong password)
- 08:44:03, 08:44:28, 08:44:55 Event 4625 bad password (interactive)
- 08:45:44, 08:46:01, 08:46:33 Event 4771 with 0x18 (wrong password)

#### 2. Account lockout triggered by repeated bad attempts from one saved client/session
Status: Neutral.
Determining evidence:
- Supports lockout by retries: 08:44:03, 08:44:28, 08:44:55 Event 4625 followed by 08:44:56 Event 4740.
- Weakens one-source qualifier: additional failures originate from 10.10.8.112 at 08:45:44, 08:46:01, and 08:46:33 (Event 4771), not only DESKTOP-FB022.

#### 3. Expired password or newly enforced sign-in condition for that account
Status: Contradicted.
Determining evidence:
- 08:44:01 Event 4776 indicates wrong password (0xC000006A).
- 08:45:44, 08:46:01, 08:46:33 Event 4771 indicates wrong password (0x18).

#### 4. Conditional Access/MFA challenge failure specific to cthompson context
Status: Contradicted.
Determining evidence:
- Observed failures are credential-validation failures (4776/4771 wrong password) rather than MFA or policy challenge-deny outcomes.

#### 5. Local workstation profile/cache issue preventing successful interactive logon
Status: Contradicted.
Determining evidence:
- 08:44:03, 08:44:28, 08:44:55 Event 4625 explicitly show bad-password failures.
- Continued failures from a second source (10.10.8.112) at 08:45:44, 08:46:01, and 08:46:33 indicate the issue is not solely a local profile/cache failure on DESKTOP-FB022.

### Surviving Hypothesis
Incorrect password or credential mismatch, with repeated retries causing account lockout.

### Resolution Steps (Detailed)
1. Contain active lockout triggers.
  - Temporarily isolate DESKTOP-FB022 and host 10.10.8.112 from authentication retries.
  - Confirm no new Event 4625, 4771, or 4776 failures for cthompson for at least 5 to 10 minutes.
2. Restore user access.
  - Unlock account FINBRIDGE\cthompson.
  - Reset password to a temporary strong value and require change at next sign-in.
  - Validate sign-in first through a known-good web flow, then local interactive logon.
3. Remove stale credentials from all endpoints and clients.
  - On DESKTOP-FB022, clear Windows Credential Manager entries and re-authenticate Office/Teams/OneDrive/VPN/mapped resources.
  - On host 10.10.8.112, identify owner/workload and update any saved credentials in scheduled tasks, services, scripts, and client apps.
  - On mobile/secondary devices, update stored account password and re-add profile if retry behavior persists.
4. Validate stabilization.
  - Verify successful interactive logon and unlock behavior for cthompson.
  - Monitor for 30 to 60 minutes to ensure no new 4625/4771/4776 failures and no new 4740 lockout.
5. Prevent recurrence.
  - Add correlation alerting for repeated bad password events leading to lockout.
  - Include secondary source IP/device tracing in lockout triage runbook.
  - Use managed service identities for automation tasks instead of user credentials where applicable.

### Confidence and Residual Gap
- Confidence: High that bad credential submissions triggered the lockout.
- Residual gap: Event data does not by itself identify which exact client/process on 10.10.8.112 submitted the stale credentials.
