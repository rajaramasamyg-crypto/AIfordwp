# Runbook - Floor 6 Login Recovery (Section 4 Fix)

Version: 1.0  
Date: 2026-08-14  
Owner: EUC/VDI Engineering  
Source Incident: Day10/Issue 1 -Triage/incident-triage-20260814-login-security.md

## 1. Purpose
Restore normal sign-in performance for Floor 6 Legal users after Win11 + Intune migration, where at least 12 users cannot log in or experience severe delay.

## 2. Prerequisites
1. Incident ticket opened and marked High.
2. Change approval for emergency VDI recovery on dc-vdi-02.
3. Admin access to Citrix Director and dc-vdi-02.
4. Access to FinBridge-VDI-Pool-02 registration metrics.
5. Affected user list (UPN, device name, last failed login time).

## 3. Safety Notes
1. Do not restart multiple controllers at once.
2. Preserve screenshots/logs before each corrective action.
3. Keep Legal operations lead informed every 30 minutes until recovery stabilizes.

## 4. Fix Procedure (Numbered, with expected result per step)
1. Confirm incident scope in Citrix Director.
Expected result: FinBridge-VDI-Pool-02 shows materially degraded registration compared with healthy baseline/pool (for example, Pool-01 remains mostly registered).

2. On dc-vdi-02, verify Citrix Broker Service status.
Expected result: Service is identified as Stopped, Hung, or Unhealthy (if Running but unstable, continue to Step 3).

3. Check for recent patching and pending reboot state.
Expected result: Evidence shows updates were installed recently and reboot is pending or reboot timing is inconsistent with patch completion.

4. Execute controlled reboot of dc-vdi-02.
Expected result: Controller returns online cleanly, core Citrix services start, and host is reachable.

5. Validate Citrix Broker Service after reboot; start/restart if needed.
Expected result: Citrix Broker Service is Running and stable for 10 minutes with no immediate crash/restart loop.

6. Monitor VDA re-registration for FinBridge-VDI-Pool-02 for 15 to 30 minutes.
Expected result: Registered machine count climbs toward normal operating range and Error 1030 volume drops.

7. Test logins with three previously affected users.
Expected result: Users launch sessions successfully and login duration returns to normal support baseline.

8. Communicate recovery status to Service Desk and Floor 6 Legal lead.
Expected result: New tickets stop increasing; support messaging changes from outage notice to recovery/monitoring notice.

## 5. Verification
1. Registration health: Pool-02 reaches and sustains acceptable registration ratio for 30 minutes.
2. User outcome: At least 3 of 3 pilot retests succeed; no new broad login-failure spike.
3. Symptom outcome: Citrix Error 1030 count is near zero after stabilization window.
4. Business outcome: Floor 6 Legal confirms normal access to priority applications.

## 6. Rollback
Use rollback only if service becomes less stable after Step 4/5 or registration does not recover.

1. Stop further controller changes and declare rollback start in the incident record.
Expected result: Change freeze in place and all responders aligned on rollback mode.

2. Route urgent users to healthy capacity (Pool-01 or approved DR path) per EUC lead approval.
Expected result: Critical users regain access while Pool-02 remains under repair.

3. Revert any non-standard Broker Service configuration changes made during incident response.
Expected result: Service configuration matches last known good baseline.

4. Escalate to Citrix platform team for deep repair (controller service dependencies, database/licensing/network validation).
Expected result: Dedicated engineering owner assigned with ETA and remediation plan.

5. Continue business-hour updates every 30 minutes until permanent fix is validated.
Expected result: Leadership has clear status, impact, and next action visibility.

## 7. References
1. Day10/Issue 1 -Triage/incident-triage-20260814-login-security.md
2. Day9/RCA-citrix-session-launch-failure-finbridge-pool-02-2026-08-14.md
