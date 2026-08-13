# DWP Step-by-Step Guide: Add a Windows App to the Intune App Catalog Before Phased Rollout

## Purpose
This guide shows a DWP engineer exactly how to add a Windows app to Intune, configure deployment settings, assign to a pilot group, and verify results before any broad rollout.

Worked example used throughout:
- Application: FinBridge Connect v3.1
- Package type: Windows app (Win32) packaged as .intunewin
- Install command: FinBridgeConnect_Setup.exe /silent
- Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
- Detection method: Registry key
- Detection target: HKLM\SOFTWARE\FinBridge\Connect\Version equals 3.1

## Important UI Label Warning (Read First)
Intune and Entra portal labels can vary by tenant version, feature rollout ring, and admin center updates.
At every navigation step in this document, verify live labels in your tenant instead of trusting label text here blindly.

## Prerequisites
1. Confirm you have an Intune admin role that can create and assign apps.
2. Confirm you have the FinBridge Connect v3.1 .intunewin package file ready.
3. Confirm you have or can create a small pilot Azure AD/Entra ID group for test devices/users.
4. Confirm you know whether the app should install in system or user context. For this example, use system context.

## Step-by-Step Procedure

1. Sign in and open the Intune app area.
- Go to Microsoft Intune admin center.
- Navigation path (labels may vary, verify live): Home -> Apps -> All apps -> Add.
- UI variation flag: In some tenants, Apps may appear as Applications or be nested under Endpoint Manager views.

2. Select the app type based on source.
- In Select app type, choose one of the following:
- Windows app (Win32): Use for .intunewin-packaged Win32 installers. Use this for FinBridge Connect v3.1.
- Microsoft Store app: Use for apps sourced from Microsoft Store integration.
- Web link: Use when publishing a URL shortcut rather than installing local binaries.
- UI variation flag: You may see Win32 app wording or separate platform pickers before type selection. Verify equivalent option in your tenant.

3. Upload the package for the Win32 app.
- Select Windows app (Win32).
- Upload the FinBridge Connect v3.1 .intunewin file.
- Wait for package metadata processing to complete.

4. Complete required App information fields.
- Name: FinBridge Connect v3.1
- Description: Finance secure bridge client for internal systems connectivity.
- Publisher: FinBridge
- Version: 3.1
- Save and continue.
- UI variation flag: Version may appear as App version or Display version depending on blade layout.

5. Complete Program fields.
- Install command: FinBridgeConnect_Setup.exe /silent
- Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
- Install behavior: System
- Why system for this example: App writes under HKLM and should install for device-wide usage.
- UI variation flag: Install behavior may appear under a Context selector (System/User).

6. Configure Requirements.
- Operating system architecture: Select as appropriate for package support (x64 recommended if app supports only x64).
- Minimum operating system: Set your enterprise baseline (for example Windows 10 22H2 or Windows 11 baseline used by your tenant).
- UI variation flag: Minimum OS options are tenant-dependent and may be grouped by platform families.

7. Configure Detection rules so Intune can confirm install success.
- Choose detection rule type: Registry.
- Hive/Path: HKLM\SOFTWARE\FinBridge\Connect
- Value name: Version
- Detection method: String comparison equals
- Expected value: 3.1
- Why this matters: Intune reports Installed only when detection evaluates true after command execution.
- Alternative valid methods (not used in this example): MSI product code or file/folder path existence/version.
- UI variation flag: Detection operators and value-type fields can be arranged differently by tenant UX version.

8. Configure Return codes.
- Keep or define return codes so Intune interprets installer exit codes correctly.
- Recommended baseline mapping:
- 0 = Success
- 1707 = Success
- 3010 = Soft reboot required
- 1641 = Hard reboot initiated
- Any unmapped non-zero code = Failure (unless explicitly mapped)
- UI variation flag: Some tenant screens preload defaults; verify they are present and not overridden.

9. Review and create the app.
- Validate summary page values.
- Select Create.
- Confirm app object appears in All apps list.

10. Assign to a pilot group first.
- Open the created app -> Assignments.
- Add a Required assignment to a small pilot group (for example 10-50 managed test devices or a controlled pilot user set).
- Do not assign to the full 10,000-device fleet initially.
- Reason: Pilot deployment limits blast radius, exposes detection/command issues early, and gives rollback room.
- UI variation flag: Assignment targeting may be split into Included groups and Excluded groups with separate tabs.

11. Understand assignment types before broader rollout.
- Required: Intune enforces automatic install on targeted devices/users.
- Available for enrolled devices: App appears in Company Portal for user-initiated install.
- Uninstall: Intune enforces app removal from targeted devices/users.
- Use pattern for new apps: Start with Required on pilot, validate, then phase outward in rings.

12. Verify catalog presence and config correctness.
- In Intune All apps, locate FinBridge Connect v3.1.
- Open properties and verify:
- App info fields match expected values.
- Program commands are exact.
- Detection rule path/value is correct.
- Return codes are correct.
- Assignments target only pilot scope.

13. Verify install status on assigned test devices.
- In app monitoring views, check Device install status and User install status (label names may vary; verify live).
- On a pilot device, force policy sync and wait for app evaluation cycle.
- Confirm local result using one or more of:
- Company Portal app state.
- Presence of registry value HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1.
- Intune Management Extension logs if troubleshooting is needed.

14. Interpret common status results.
- Installed: Intune ran command and detection rule passed.
- Failed: Install command failed, timed out, or detection did not pass after install attempt.
- Not applicable: Device/user does not meet assignment or requirement criteria (for example wrong OS version/architecture, filtered out target, or incompatible context).

15. Gate for phase 1 rollout.
- Proceed to wider deployment only after pilot shows stable Installed rates and low/understood failures.
- If failures exist, correct package, commands, detection rules, or requirements, then retest pilot before expanding.

## Quick Validation Checklist
1. Correct app type selected for package source.
2. Required metadata completed (name, description, publisher, version).
3. Program commands verified exactly.
4. Install behavior intentionally chosen (System for this example).
5. Requirements aligned to supported device population.
6. Detection rule proven to identify installed state.
7. Return code mapping validated.
8. Assignment limited to pilot scope first.
9. Monitoring confirms expected Installed outcomes.
10. Only then begin phased rollout.
