# JAMF Translation: macOS Security Baseline (Design Team, 25 Devices)

Date: 2026-08-14  
Scope: macOS fleet (25 Design team devices)

Important verification discipline:
Some JAMF payload names, tab labels, and control wording vary by JAMF Pro version and UI updates. Where noted below, verify exact naming and location in your own JAMF instance before implementation.

## Baseline to JAMF Configuration Mapping

| Requirement | Payload type | Value | Effect | False-positive risk |
|---|---|---|---|---|
| FileVault disk encryption must be enabled | Security & Privacy payload (FileVault section) | Enable FileVault for managed macOS devices; escrow personal recovery key to JAMF; require institutional/personal key rotation policy per org standard | Enforces full-disk encryption so data at rest is unreadable without unlock credentials/recovery key | Device can appear non-compliant while encryption is still in progress; escrow check may fail temporarily if device has not checked in after key creation/rotation |
| Gatekeeper must be enabled (identified developers only) | Restrictions payload or Security & Privacy controls for app execution policy (label varies by JAMF version) | Allow apps from App Store and identified developers only; block Anywhere/unsigned app execution | Prevents users from launching unsigned or unnotarized apps by default | Security tool may flag custom enterprise-signed tools/scripts as failures if it only checks for unsigned-app prompts or misreads local override state |
| Minimum macOS version: current stable minus one point release | Not reliably enforced by a single classic config profile setting in all JAMF versions; typically enforced via Smart Group compliance + update policy. If used, see Software Update payload controls (naming/version support varies) | Define compliance rule: macOS version must be >= N-1 (where N is current stable major/minor standard); remediate with managed update policy/workflow | Keeps devices on supported security patch level while allowing controlled adoption lag | Version inventory lag (device offline, delayed inventory, or failed recon) can incorrectly mark a healthy recently-updated device as below minimum |
| Firewall must be enabled | Security & Privacy payload (Firewall section) | Enable Application Firewall; optionally enable stealth mode and block all incoming except essential management-approved services | Reduces exposure to unsolicited inbound connections | Local firewall state can look disabled immediately after reboot/login until profile reapplies/reporting updates; third-party security tools may read network extension state differently |
| Login password required after sleep/screen saver | Security & Privacy payload (General/password-after-sleep control) or Login Window/Restrictions equivalent depending on JAMF version | Require password immediately after sleep or screen saver begins (grace period = 0 or org-defined short value) | Prevents unattended unlocked access after lid-close, sleep, or idle lock | False flags occur when check scripts read current user session settings before profile enforcement completes, or when fast user switching/session handoff causes stale state |
| Automatic security updates enabled | Software Update payload (or managed software update settings, version dependent) | Enable automatic security response/system data files and install security updates automatically (including XProtect/MRT/system data updates where exposed) | Ensures devices receive security fixes with minimal user dependency | Device may flag non-compliant if power/network conditions delayed update install despite correct policy assignment |

## Settings That Need Label Verification in Your JAMF Instance

Verify exact payload/control names before change approval and screenshots, because these are known to vary by JAMF Pro version and Apple framework changes:

1. Gatekeeper setting location and wording (Restrictions vs Security & Privacy presentation)
2. Minimum macOS version enforcement UI (often compliance/policy-driven rather than single profile toggle)
3. Password-after-sleep control label placement (Security & Privacy vs Login Window mapping)
4. Automatic security update control names in Software Update payload

## Implementation Notes for This Fleet

1. Scope these profiles/policies to a dedicated Design smart/static group containing the 25 devices.
2. Stage in pilot ring first (3 to 5 devices) to validate app compatibility (especially Design toolchains and plug-ins).
3. For the minimum OS requirement, pair version compliance with an automated remediation policy and a user communication workflow.
4. Record proof points per control: profile UUID, last check-in timestamp, and one device-level evidence screenshot/log extract.
