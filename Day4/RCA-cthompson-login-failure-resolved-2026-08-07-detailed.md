# Root Cause Analysis (RCA): cthompson Login Failure (Resolved)

## Document Control
- Incident ID: INC-CTHOMPSON-LOGIN-2026-08-07
- Prepared on: 2026-08-07
- Prepared by: IT Support Operations
- Affected user: FINBRIDGE\cthompson
- Affected host: DESKTOP-FB022
- Incident status: Resolved
- Resolution time: 09:09 AM

## 1) Incident Summary
At approximately 08:40 AM, user FINBRIDGE\cthompson reported inability to sign in. A targeted account recovery action was performed by FINBRIDGE\helpdesk-admin at 09:08:14 AM (Security Event 4722: account enabled). At 09:09:01 AM, the user successfully completed an interactive sign-in from DESKTOP-FB022 (Security Event 4624, Logon Type 2). User validation confirmed normal access with no remaining issues. Incident was closed as resolved at 09:09 AM.

## 2) Scope and Impact
- Scope: Single-user authentication incident.
- Service impact: User unable to access workstation session until remediation.
- Business impact: Short-duration productivity interruption for one employee.
- Platform impact: No evidence of wider authentication outage in available records.

## 3) Supporting Evidence

### 3.1 Raw Event Log Evidence
```text
09:08:14 Security Event 4722 Audit Success
A user account was enabled.
Account: FINBRIDGE\cthompson
Done by: FINBRIDGE\helpdesk-admin

09:09:01 Security Event 4624 Audit Success
An account was successfully logged on.
Account: FINBRIDGE\cthompson
Logon type: 2 (Interactive) Source: DESKTOP-FB022
```

### 3.2 Evidence-to-Conclusion Mapping
- Event 4722 confirms administrative restoration of account state for FINBRIDGE\cthompson.
- Event 4624 (Logon Type 2) confirms successful interactive login immediately after restoration.
- Time delta between corrective action and successful login is 47 seconds, strongly indicating direct remediation effectiveness.

## 4) Detailed Timeline (All Times Local)
1. ~08:40 AM: User FINBRIDGE\cthompson reports login failure.
2. 09:08:14 AM: Security Event 4722 recorded. Account FINBRIDGE\cthompson enabled by FINBRIDGE\helpdesk-admin.
3. 09:09:01 AM: Security Event 4624 recorded. Successful interactive login (Logon Type 2) for FINBRIDGE\cthompson from DESKTOP-FB022.
4. 09:09 AM: User confirms successful login and no further issue. Incident marked resolved.

## 5) Root Cause Statement
The immediate technical cause of the outage was an account state that blocked user authentication until administrative re-enable was performed. The most likely upstream trigger was account lockout or disablement after repeated invalid authentication attempts, based on the remediation pattern and immediate post-enable successful sign-in.

## 6) 5 Whys Analysis

### Problem
Why was FINBRIDGE\cthompson unable to log in?
- Because the account was not in a state that permitted successful authentication at that time.

### Why 1
Why was authentication not permitted?
- Because administrative intervention was required to enable the account.
- Evidence: Security Event 4722 at 09:08:14 AM.

### Why 2
Why do we know account state was the blocking factor?
- Because successful interactive login occurred right after the account was enabled.
- Evidence: Security Event 4624 at 09:09:01 AM (47 seconds later).

### Why 3
Why did the account likely enter a blocked state?
- Most likely due to repeated invalid credentials from user entry and/or cached credentials.

### Why 4
Why could repeated invalid attempts occur without earlier interception?
- Existing process appears to rely on reactive helpdesk escalation rather than proactive failure-threshold alerting tied to a user identity.

### Why 5
Why did recovery require admin action rather than self-service?
- Current operational controls for this incident type require privileged account recovery workflow.

## 7) Corrective Actions Taken (During Incident)
1. Helpdesk identified account-state issue affecting FINBRIDGE\cthompson.
2. FINBRIDGE\helpdesk-admin enabled the account (Event 4722).
3. User retried sign-in from DESKTOP-FB022.
4. Security logs confirmed successful interactive login (Event 4624).
5. User verified no remaining access issue; case resolved at 09:09 AM.

## 8) Preventive Actions

### 8.1 Immediate (0-7 days)
1. Add lockout triage checklist to L1 workflow (source host, cached credentials, account-state check, verification step).
2. Require one post-recovery validation event (4624 Logon Type 2) before closure.
3. Trigger same-day credential hygiene on affected endpoint (Credential Manager, Office/Teams/VPN saved credentials).

### 8.2 Short-Term (1-4 weeks)
1. Implement alerting for repeated failed authentication events per user to reduce mean time to detection.
2. Add runbook decision tree for account lockout versus password expiry versus conditional access failures.
3. Record recovery metrics: detection time, recovery time, and recurrence within 24 hours.

### 8.3 Long-Term (1-3 months)
1. Evaluate secure self-service account recovery controls to reduce dependency on manual admin actions.
2. Introduce periodic review of recurring lockout users and root trigger sources (device, service, or app).
3. Standardize identity incident postmortem template across service desk teams.

## 9) Verification and Closure Criteria
- Administrative account restore logged: Yes (Event 4722 at 09:08:14 AM).
- Successful interactive login logged: Yes (Event 4624, Logon Type 2 at 09:09:01 AM).
- User confirmation received: Yes (no further issue reported).
- Incident state: Closed as Resolved at 09:09 AM.

## 10) Residual Risk and Monitoring
- Residual risk: If stale credentials exist on other devices or background clients, recurrence is possible.
- Monitoring recommendation: Monitor account failure events for FINBRIDGE\cthompson through next business day and trigger targeted cleanup if failures recur.

## 11) Lessons Learned
- Event-pair validation (4722 followed by 4624 Type 2) is a high-confidence closure pattern for account-state login incidents.
- Faster detection can be achieved with proactive failed-authentication alerting before user-facing lockout escalation.
