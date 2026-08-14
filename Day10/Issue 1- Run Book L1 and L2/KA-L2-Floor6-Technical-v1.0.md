# L2 Knowledge Article - Floor 6 Ring Mis-Scoping Incident

Version: 1.0  
Date: 2026-08-14  
Source: Runbook-Floor6-Ring-Containment-and-Rollback-v1.0

## Incident pattern
- Floor 6 Legal users (Win11 + Intune) report long or failed sign-in.
- One or more users report Copilot surfacing client matter content they should not normally work with.

## Root cause model
Mis-scoped Entra group targeting caused overlap between endpoint deployment ring and Copilot pilot licensing assignment. Existing SharePoint inherited permissions amplified impact by allowing Copilot to surface content within underlying read scope.

## Required artifacts
1. collect-floor6-evidence-final.ps1 output (summary.json, steps.json, raw CSV/TXT).
2. floor6-legal-upns.txt and impacted-device-names.txt.
3. Change record for emergency containment.

## Procedure (from source runbook)
1. Collect baseline evidence on an affected endpoint.
2. Connect to Graph with Group.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, User.Read.All.
3. Resolve IDs for SG-INTUNE-W11-FLOOR6-LEGAL-RING and SG-M365-COPILOT-PILOT.
4. Remove impacted devices from ring group.
5. Remove impacted users from Copilot pilot group.
6. Force Intune sync on impacted managed devices.
7. Collect post-change evidence and compare indicators.

## Verification criteria
- Login success/time improved for sampled affected users.
- No recurring Copilot out-of-scope content reports.
- Membership diff confirms removals are effective.
- summary.json indicator trends improve (fewer AAD/MDM error signals).

## Rollback criteria
Rollback only if scope error in containment list is verified by change manager.
- Re-add approved users/devices using rollback files.
- Force sync.
- Re-test and document.

## Escalation
- Security/Compliance: any confirmed unauthorized matter exposure.
- Identity/EUC lead: if login failures persist after group containment and sync.
