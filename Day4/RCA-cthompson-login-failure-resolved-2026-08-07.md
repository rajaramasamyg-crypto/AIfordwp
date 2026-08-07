# Root Cause Analysis (RCA): cthompson Login Failure - Resolved 2026-08-07

## Incident Summary
- Incident type: User login failure leading to access interruption
- Affected user: FINBRIDGE\cthompson
- Affected endpoint: DESKTOP-FB022
- Detection time: Approximately 08:40 AM (per incident scope)
- Resolution applied: Account re-enabled by Helpdesk
- Resolution confirmation time: 09:09 AM
- Current status: Resolved and user validated as working

## Executive Summary
User FINBRIDGE\cthompson was unable to log in during the morning support window. The suggested remediation was executed by Helpdesk: re-enabling the account. Security logs then recorded a successful interactive user logon from DESKTOP-FB022 one minute later. This sequence confirms service restoration and validates the resolution effectiveness.

Based on the incident pattern and prior triage context, the most likely root cause was account lockout caused by repeated invalid credential submissions before escalation. The supplied event evidence directly confirms administrative recovery and successful post-recovery authentication.

## Scope and Impact
- Scope: Single-user incident (FINBRIDGE\cthompson)
- Service impact: User could not access workstation session until remediation
- Business impact: Short-duration productivity interruption for one user and helpdesk intervention requirement
- Broader system impact: No evidence of multi-user or platform-wide outage in this incident record

## Supporting Evidence (Security Event Log)

### Evidence Extract
1. 09:08:14 - Security Event 4722 (Audit Success)
   - Message: A user account was enabled
   - Account: FINBRIDGE\cthompson
   - Performed by: FINBRIDGE\helpdesk-admin

2. 09:09:01 - Security Event 4624 (Audit Success)
   - Message: An account was successfully logged on
   - Account: FINBRIDGE\cthompson
   - Logon Type: 2 (Interactive)
   - Source: DESKTOP-FB022

### Evidence Interpretation
- Event 4722 confirms targeted administrative restoration of the affected account.
- Event 4624 (Type 2) confirms that normal interactive access was restored from the user endpoint immediately after remediation.
- The short delta between events (47 seconds) supports direct causality between the corrective action and successful user recovery.

## Detailed Timeline
1. ~08:40 AM
   - User reports inability to log in (initial symptom observed).
2. 09:08:14 AM
   - Helpdesk admin executes account enable action.
   - Logged as Security Event 4722 for FINBRIDGE\cthompson.
3. 09:09:01 AM
   - User authentication succeeds with interactive sign-in from DESKTOP-FB022.
   - Logged as Security Event 4624 (Logon Type 2).
4. 09:09 AM
   - Incident marked resolved.
5. Post-resolution verification
   - User tested sign-in to host and reported no further issue.

## Root Cause Statement
The most probable root cause was an account lockout condition on FINBRIDGE\cthompson, likely triggered by repeated invalid credential attempts before helpdesk engagement. Administrative account re-enable restored account usability, and successful interactive logon immediately followed.

## Five Whys Analysis

### Problem
Why could FINBRIDGE\cthompson not log in?
- Because the account was in a state that prevented successful interactive authentication before support action.

### Why 1
Why was authentication blocked?
- Because the account required administrative re-enable to restore access.
- Evidence: Security Event 4722 at 09:08:14.

### Why 2
Why did account re-enable resolve the issue?
- Because account state (disabled/locked) was the gating factor for authentication success.
- Evidence: Successful 4624 interactive logon at 09:09:01 immediately after re-enable.

### Why 3
Why did the account likely enter this blocked state?
- Most likely due to repeated invalid credential submissions causing lockout conditions.
- Basis: Incident pattern matches known lockout behavior from similar prior cases in this environment.

### Why 4
Why were repeated invalid credential attempts possible?
- Stored or mistyped credentials may have been retried during interactive login and/or background authentication flows.

### Why 5
Why did this become a helpdesk ticket instead of self-recovery?
- Current workflow depends on admin action for locked/disabled account recovery in this scenario.

## Corrective Actions Taken
1. Helpdesk re-enabled FINBRIDGE\cthompson account.
2. User retried login from DESKTOP-FB022.
3. Successful interactive logon was validated in Security logs.
4. User confirmed normal access after remediation.

## Preventive Actions
1. Implement early lockout alerting.
   - Correlate repeated authentication failures and notify support before full lockout.
2. Add lockout triage checklist to first-line workflow.
   - Include endpoint source confirmation, credential cache review, and fast recovery path.
3. Reduce stale credential sources.
   - Review and clear saved credentials in Windows Credential Manager, Office/Teams, VPN, and mapped resources when lockouts recur.
4. Strengthen user guidance.
   - Provide quick reminders for keyboard layout/Caps Lock checks and safe password entry practices during failed logins.
5. Evaluate self-service recovery controls.
   - Assess SSPR or equivalent policy to reduce MTTR while preserving security controls.
6. Add post-resolution validation standard.
   - Require one confirmed interactive login (Event 4624 Type 2) after account recovery before closure.

## Verification of Resolution
- Administrative action completed: Yes (Event 4722 at 09:08:14).
- Successful interactive login completed: Yes (Event 4624 Type 2 at 09:09:01 from DESKTOP-FB022).
- User-reported outcome: Login tested, no further issue reported.
- Final incident state: Resolved at 09:09 AM.

## Residual Risk and Follow-Up
- Residual risk: If stale credentials remain on another endpoint or app, future lockout recurrence is possible.
- Follow-up recommendation: Monitor for new account-failure events for FINBRIDGE\cthompson for the next business day and perform targeted credential hygiene if failures reappear.
