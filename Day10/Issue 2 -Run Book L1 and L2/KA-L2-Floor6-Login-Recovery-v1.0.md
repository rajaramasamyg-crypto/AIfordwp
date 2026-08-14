# L2 Technical Article - Floor 6 Login Recovery

Version: 1.0  
Date: 2026-08-14  
Derived From: Runbook-Floor6-Login-Recovery-Section4-v1.0

## Incident Pattern
- Floor 6 Legal users report failed or very slow VDI sign-in after Win11 + Intune migration.
- Common user-facing symptom: Citrix session launch failure and/or prolonged sign-in time.
- Operational signal: FinBridge-VDI-Pool-02 registration collapse relative to control pool.

## Working Cause Model
Most likely cause is controller-side service degradation on dc-vdi-02 after patching, often with incomplete reboot state, leading to Broker instability and reduced registered VDA capacity.

## Prerequisites
1. High-priority incident and emergency change window.
2. Citrix Director access.
3. Administrative access to dc-vdi-02.
4. Affected user sample list for post-fix validation.

## Procedure (from source runbook)
1. Confirm registration degradation in FinBridge-VDI-Pool-02.
Expected result: Pool-02 health is materially below baseline.

2. Check Citrix Broker Service state on dc-vdi-02.
Expected result: Faulty state identified (stopped/hung/unstable).

3. Validate recent patch and reboot posture.
Expected result: Recent update timing aligns with fault onset and indicates required reboot action.

4. Reboot dc-vdi-02 in a controlled window.
Expected result: Controller returns with core services online.

5. Ensure Broker Service is Running and stable.
Expected result: No immediate service failure loop.

6. Observe VDA re-registration for 15 to 30 minutes.
Expected result: Registered count rises; launch failures decline.

7. Perform three-user login retest.
Expected result: Test users successfully launch sessions within baseline timing.

## Verification Criteria
1. Pool-02 registration ratio stable for 30 minutes.
2. Error 1030 volume near zero.
3. No new mass-login tickets from Floor 6.
4. Legal operations confirms restored access.

## Rollback
Trigger rollback if registration does not recover or controller stability worsens.

1. Freeze further controller changes and document rollback start.
2. Route urgent users to approved alternate capacity.
3. Revert any incident-time non-standard Broker configuration changes.
4. Escalate to Citrix platform engineering for deep service/dependency repair.

## Escalation
- Escalate to EUC/VDI lead if no registration recovery after stabilization window.
- Escalate to IT Operations Director if business-critical access remains blocked beyond one hour from fix start.
