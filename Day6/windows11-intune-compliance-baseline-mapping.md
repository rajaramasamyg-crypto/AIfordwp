# Windows 11 Intune Compliance Policy Mapping (DWP Baseline)

Date: 2026-08-11  
Scope: Translate baseline requirements into Microsoft Intune compliance policy settings for Windows 11.

## Best-known Intune UI Path (flagged for possible UI drift)

UI labels and navigation in Intune change periodically. The path below is the latest commonly used layout, but should be verified in your tenant:

- Intune admin center > Devices > Compliance > Policies > Create Policy
- Platform: Windows 10 and later
- Profile type: Compliance policy
- Compliance settings categories used below:
  - Device Health
  - Device Properties
  - Microsoft Defender Antimalware
  - System Security

Change-risk flag: Medium (UI grouping and category names can shift between Intune releases).

## Requirement-to-setting mapping

| Requirement | Setting name (exact Intune label) | Value | Effect | False-positive risk | Recommendation |
|---|---|---|---|---|---|
| 1. BitLocker must be enabled on the OS drive | BitLocker | Require | Device is noncompliant unless OS drive encryption is detected as enabled. | Encryption was just enabled but status has not reported yet; suspended protection during servicing; unsupported/legacy hardware reporting gaps. | Pair with an Endpoint security Disk encryption policy and allow first sync before enforcement. Keep compliance grace period at 7 days to absorb reporting delay. |
| 2. Secure Boot must be enabled | Secure Boot | Require | Device is noncompliant unless Secure Boot is on in firmware/UEFI. | BIOS mode devices (non-UEFI), virtual devices without Secure Boot capability, or delayed health attestation signal can appear noncompliant. | Scope this policy to supported Windows 11 hardware groups only; exclude known non-UEFI legacy devices pending remediation. |
| 3. Minimum OS build N-1 (22621.2861) | Minimum OS version | 10.0.22621.2861 | Device must run this version or newer; older builds are noncompliant. | Build metadata can lag immediately after update/restart; rings on staged rollout may briefly be below threshold. | Keep staged update rings aligned to N-1 target and retain 7-day grace period. Validate update completion plus reboot before compliance deadline. |
| 4. Windows Defender real-time protection must be on | Real-time protection | Require | Device is noncompliant if Defender real-time monitoring is disabled. | Third-party AV deployments can disable Defender RTP by design; passive mode or service transition periods can flag temporarily. | If using non-Microsoft AV, decide whether this requirement should be tenant-wide. Otherwise scope to Defender-managed populations only. |
| 5. Firewall must be enabled for all profiles | Firewall | Require | Device is noncompliant unless firewall protection is active (domain/private/public profiles expected active by policy). | Temporary profile detection issues on network transitions; third-party firewall products can interfere with reporting state. | Enforce Microsoft Defender Firewall through Endpoint security Firewall policy and avoid overlapping third-party controls where possible. |
| 6. A PIN or password must be configured | Password required | Require | Device is noncompliant unless a user unlock credential (password/PIN policy backed) is configured. | Shared kiosk/autologon scenarios; local account edge cases; newly provisioned devices before user sign-in can read as not configured. | For user-driven devices, keep Require. For kiosk/shared devices, use a dedicated compliance policy with compensating controls. |
| 7. Device must not be jailbroken or rooted | Jailbroken devices | Block | Device is noncompliant when Intune detects jailbreak/root compromise state. | Rare on Windows, but integrity telemetry gaps or stale agent state can produce unexpected noncompliance. | Keep Block. Add helpdesk triage steps to confirm device integrity and force a fresh check-in before escalation. |

## Grace period configuration (all settings)

Use Actions for noncompliance at policy level:

- Action: Mark device noncompliant
- Schedule (days after noncompliance): 7

Effect: a device can be out of compliance for up to 7 days before being marked noncompliant for conditional access decisions.

False-positive reduction value: this buffers telemetry lag, reboot-pending update states, and first-enrollment timing issues without lowering the actual security requirement values.

## Validation: check one device against one specific compliance policy

Use the policy-centric path first when you want the status for one known test device against one known policy:

1. Intune admin center > Devices > Compliance.
2. Select Policies.
3. Open the specific Windows compliance policy.
4. On the policy page, open Monitor, then select Device status.
5. Select View report.
6. Search for the test device by device name or logged-in user.
7. Open the device row to review Policy compliance status, Last contacted, and any noncompliant settings.
8. If the device is failing, open Per-setting status and confirm whether BitLocker is the failing control.

If the policy is assigned to All devices and your test device has just synced, use this quick freshness check before you trust the state:

1. Confirm the test device is in scope for assignment (for dynamic groups, verify current group membership first).
2. In the same policy Device status report, confirm Last contacted is newer than the sync you just triggered.
3. Refresh once after 1-2 minutes if the timestamp has not moved yet.
4. Only treat the shown status as final after the timestamp is fresh.

Use the device-centric path when you start from the device record instead of the policy:

1. Intune admin center > Devices > All devices.
2. Open the test device.
3. Select Device compliance.
4. Open Policies.
5. Select the specific compliance policy to see that device's result for that policy.

Interpret the timestamps carefully:

- Last check-in / Last contacted is the fastest way to tell whether you are looking at fresh evaluation data or an older compliance result.
- A device can sync before the detailed policy report view refreshes, so confirm the timestamp changed before concluding the status is current.

## Compliance state meaning for Conditional Access

- Compliant: The device passed required settings for the policy evaluation. Conditional Access policies that require a compliant device see this requirement as satisfied.
- Not compliant: The device failed one or more required settings and is past any configured remediation window. Conditional Access policies that require a compliant device deny access from this device until compliance is restored.
- In grace period: The device has a known compliance failure, but the mark-device-noncompliant timer has not expired. During this window, Conditional Access usually still allows access because the device is not yet marked Not compliant; once the timer expires, access is denied by policies requiring compliant devices.

Operational note: if the default Mark device noncompliant action is left at 0 days, there is effectively no grace period, and a failed setting moves straight to Not compliant.

## Validation: BitLocker shows Not compliant even though BitLocker is enabled

These are the three most common causes of an apparent false positive, along with the fastest check for each.

### 1. Stale compliance result or reporting lag after enablement

What happens:

- BitLocker was enabled recently, the policy was assigned recently, or the device synced before Intune finished recalculating and publishing the latest result.

Fastest check:

1. On the device, confirm local encryption is really active:

```powershell
Get-BitLockerVolume -MountPoint 'C:' | Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionPercentage
```

2. In Intune, compare the device's Last check-in / Last contacted time in the policy report.
3. Trigger a fresh Sync from Company Portal or from Intune device actions, then refresh the policy report and confirm the timestamp changed.

Validation outcome:

- If the timestamp advances and the device flips to Compliant, the issue was stale reporting.
- If local BitLocker is healthy but the timestamp is still old, the problem is still reporting freshness, not BitLocker itself.

### 2. BitLocker encryption is present, but protection is suspended or not fully active

What happens:

- The drive can still appear encrypted while BitLocker protection is suspended, often after firmware work, BIOS updates, or temporary admin suspension.

Fastest check:

```powershell
manage-bde -status C:
```

Validate all three values:

- Conversion Status: Fully Encrypted
- Percentage Encrypted: 100%
- Protection Status: Protection On

Validation outcome:

- If Protection Status is Off or the drive is still encrypting, Intune is correctly failing the device and this is not a false positive.
- If all three values are healthy, move to the next check.

### 3. Local BitLocker state is healthy, but Windows has not produced a fresh compliance signal after reboot, TPM, or firmware change

What happens:

- After TPM recovery, BIOS or UEFI changes, Secure Boot changes, or recovery/suspension events, the compliance provider can keep reporting an older BitLocker state until the device completes a normal restart and check-in cycle.

Fastest check:

1. Confirm the device has completed at least one normal reboot since BitLocker was enabled or resumed.
2. Run this on the device to verify the OS volume is the protected one Intune cares about:

```powershell
Get-BitLockerVolume | Select-Object MountPoint, VolumeType, ProtectionStatus, EncryptionPercentage
```

3. If `C:` shows `OperatingSystem` with `ProtectionStatus` On, do one reboot, then trigger another Intune sync and recheck Per-setting status.

Validation outcome:

- If compliance clears after reboot plus sync, the issue was stale local-to-service compliance signaling.
- If it does not clear, escalate to deeper MDM/compliance log review instead of changing the policy.

## Fast validation sequence for the test device

Use this sequence before changing assignments or relaxing the policy:

1. Open the policy report and verify the test device appears under View report.
2. Confirm the assignment scope includes the test device (direct or group-based assignment).
3. Confirm Last contacted is newer than the last manual sync you initiated.
4. Open Per-setting status and confirm BitLocker is the exact failing setting.
5. On the device, run `Get-BitLockerVolume -MountPoint 'C:'` and verify `ProtectionStatus` is `On` and `EncryptionPercentage` is `100`.
6. If needed, run `manage-bde -status C:` to confirm protection is not suspended.
7. Reboot once if BitLocker was recently enabled, resumed, or the device had a TPM or firmware event.
8. Trigger another Intune sync and re-check the same policy report.
9. Only after those checks, treat the result as a true compliance failure or escalate to log analysis.

## UI drift watchlist (important)

These setting names and categories are historically stable but may appear with slightly different wording in your tenant UI:

- Secure Boot (sometimes shown as Secure Boot enabled on device)
- Real-time protection (can be grouped under Defender requirement labels)
- Password required (wording can differ based on compliance template generation)
- Jailbroken devices (may appear as block rooted/jailbroken devices)

Operational recommendation: validate labels in your current tenant wizard at creation time, then export policy JSON and store it as your source of truth for future reproducibility.

## Troubleshooting: "Fetch scope tags" error in Compliance policy flow

Symptom observed:

- Toast error: "Fetch scope tags" -> "Unable to fetch scope tags for some unexpected reason."

Most likely causes (in order):

- Intune RBAC role assignment does not include read access needed to list scope tags.
- The admin account has an Intune role but is assigned to a limited scope/group that does not include available scope tags.
- Browser token/session issue (stale token after role change).
- Temporary Intune service-side UI/API issue.

### Resolution checklist

1. Confirm the signed-in account has an Intune role that can read scope tags.
2. In Intune admin center, verify role assignment includes:
  - Correct member/user
  - Correct Scope groups
  - Correct Scope tags (for admins who should see all tags, include default or all approved tags per your RBAC model)
3. If using custom roles, validate permissions include scope tag visibility/read operations.
4. Sign out from Intune admin center, close browser, sign in again, and retry in an InPrivate window.
5. Retry from a second browser profile to rule out extension/cookie interference.
6. If still failing, check Intune tenant health/service status and retry after 15-30 minutes.

### Fast workaround for policy creation

- Create or edit the compliance policy using an account with known-good Intune Administrator permissions.
- Set required Scope tags explicitly during creation.
- Re-test with the original account after RBAC adjustment.

### Verification criteria

- Scope tag picker loads without error.
- At least one expected scope tag is visible and selectable.
- Compliance policy saves successfully and appears in Devices > Compliance > Policies.
- Audit trail shows role/scope adjustment completed (if RBAC change was required).

### Escalation trigger

Escalate to Intune platform administration when both conditions are true:

- A known-good admin account can open scope tags, but the target account cannot after RBAC correction and token refresh.
- Issue persists across browsers and after waiting for propagation.

## Execute fix workflow (PowerShell)

Use the local script to validate and resolve the error path quickly:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Day6\fix-intune-fetch-scope-tags.ps1 -AttemptTokenRefresh -ShowAssignments
```

If your tenant requires explicit tenant targeting:

```powershell
.\Day6\fix-intune-fetch-scope-tags.ps1 -TenantId "<your-tenant-guid>" -AttemptTokenRefresh
```

How to interpret output:

- Success on roleScopeTags API: portal cache/session issue likely. Reopen Intune in InPrivate and retry policy edit.
- 401/403 on roleScopeTags API: RBAC permission or scope assignment issue. Fix role assignment first.
- Other failures: possible service-side issue or conditional access interruption; retry after health check.
