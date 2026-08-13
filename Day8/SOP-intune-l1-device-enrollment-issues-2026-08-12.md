# SOP: Intune L1 Device Enrollment Issues

**Document ID:** SOP-INTUNE-L1-ENROLLMENT-001  
**Version:** 1.0  
**Date:** 2026-08-12  
**Owner:** Service Desk L1  
**Scope:** Windows endpoints and Company Portal enrollment issues handled by L1 support.

## 1. Purpose
Provide a repeatable L1 process to diagnose and resolve common Intune device enrollment problems.

## 2. Symptoms Covered
1. Device not enrolling in Intune.
2. Error during Company Portal registration.
3. Device not appearing in Intune console.

## 3. Prerequisites
- User has a valid corporate account and MFA method.
- Device has stable internet access.
- L1 has access to:
  - Microsoft Intune admin center (read access minimum).
  - Entra ID (Azure AD) device/user lookup.
  - Ticketing system.

## 4. Intake Checklist (L1)
Collect and record the following before troubleshooting:
- User UPN (email) and department.
- Device name, serial number, OS version/build.
- Ownership type (corporate/personal).
- Exact error text and screenshot.
- Time of issue and timezone.
- Network type used during enrollment (corp LAN/home/VPN/mobile hotspot).
- Whether this is new enrollment, re-enrollment, or post-reset enrollment.

## 5. Standard Triage Workflow

### Step 1: Verify Service Health
- Check Microsoft 365/Intune service health dashboard.
- If incident/advisory exists, link incident ID in ticket and inform user.

### Step 2: Verify Licensing and Enrollment Eligibility
- Confirm user has valid Intune license assigned.
- Confirm MDM user scope includes the user group.
- Confirm device enrollment restrictions do not block platform/version/ownership.
- Confirm user is below device enrollment limit.

### Step 3: Validate Device State
On the affected Windows device:
1. Open **Settings > Accounts > Access work or school**.
2. Confirm account is connected.
3. Click connection > **Info** > **Sync**.
4. Note any sync errors.

Run in elevated PowerShell/CMD:
```powershell
dsregcmd /status
```
Record:
- `AzureAdJoined`
- `DomainJoined`
- `DeviceId`
- `TenantId`
- `WorkplaceJoined`

### Step 4: Basic Connectivity Checks
- Confirm access to:
  - `https://portal.manage.microsoft.com`
  - `https://login.microsoftonline.com`
  - `https://enterpriseregistration.windows.net`
- Validate system date/time and timezone are correct.
- Temporarily disable SSL inspection/proxy exceptions if enterprise proxy is suspected (per policy).

### Step 5: Company Portal Validation
- Confirm Company Portal is installed and updated.
- Sign out and sign back in with corporate account.
- Retry device registration.
- Capture new error message/code if it fails.

## 6. Symptom-Based Procedure

### Symptom 1: Device Not Enrolling in Intune
**Likely Causes**
- Missing/incorrect Intune license.
- Enrollment restriction/policy block.
- Device already registered with stale object.
- Join state mismatch.

**L1 Actions**
1. Verify license and MDM scope.
2. Check for existing stale device objects in Entra ID/Intune (same serial/device name).
3. If stale duplicate exists, escalate to L2 for safe cleanup if L1 lacks permissions.
4. Re-attempt from **Access work or school** (disconnect/reconnect only if approved by runbook).
5. Trigger manual sync and wait 5-10 minutes.

**Success Criteria**
- Device shows as enrolled in Company Portal and appears in Intune within expected sync window.

### Symptom 2: Error During Company Portal Registration
**Likely Causes**
- Authentication/MFA challenge failure.
- Device compliance prerequisite not met.
- App corruption or outdated Company Portal app.

**L1 Actions**
1. Record exact error code/message.
2. Confirm user can sign into `https://portal.office.com` successfully.
3. Update/reinstall Company Portal.
4. Clear cached credentials (Windows Credential Manager for work account context) and retry sign-in.
5. Confirm MFA prompt is completed successfully.
6. Retry enrollment on alternate network (hotspot) to rule out local network filtering.

**Success Criteria**
- Company Portal completes registration without error and displays managed status.

### Symptom 3: Device Not Appearing in Intune Console
**Likely Causes**
- Enrollment succeeded locally but sync has not completed.
- Device object mismatch between Entra ID and Intune.
- Intune admin filter/view issue.

**L1 Actions**
1. Confirm local device shows connected work account.
2. Trigger **Sync** from device and Company Portal.
3. In Intune admin center, search by:
   - Device name
   - User UPN
   - Serial number
4. Check Entra ID for joined/registered device object.
5. Wait up to 15 minutes and refresh console.

**Success Criteria**
- Device object visible in Intune with correct user association.

## 7. Escalation to L2/L3
Escalate when any of the following are true:
- License/scope/restriction configuration changes are required.
- Duplicate/stale device object removal is required and outside L1 permission.
- Error persists after all L1 steps.
- Multiple users/devices impacted (possible service degradation).

## 8. Required Escalation Artifacts
Attach the following to the escalation ticket:
- User UPN and impacted device details (name/serial).
- Screenshots of errors.
- Output summary from `dsregcmd /status`.
- Time of last failed attempt.
- Steps already performed from this SOP.
- Service health status at time of triage.

## 9. User Communication Template (L1)
Subject: Update on your Intune device enrollment issue

Hello <User Name>,

We investigated your enrollment issue and completed initial troubleshooting (account/license checks, device join/sync checks, and Company Portal validation). Current status: <Resolved / Escalated to L2>.

If resolved:
- Please restart your device and open Company Portal to confirm device status is managed.

If escalated:
- We have escalated your case with diagnostic details and will provide the next update by <time/date>.

Regards,  
Service Desk

## 10. KPI/Closure Notes
For ticket closure, record:
- First response time.
- Time to resolve/escalate.
- Root cause category (license, policy, connectivity, app, stale object, unknown).
- Whether user productivity was restored.

---

**End of SOP**
