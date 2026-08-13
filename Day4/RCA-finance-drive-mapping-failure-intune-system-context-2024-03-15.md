# Root Cause Analysis (RCA): Finance Drive Mapping Failure After Intune Script Migration

## Incident Summary
- Incident type: Enterprise drive mapping failure at logon
- Affected population: All Finance users on DESKTOP-FB* devices in OU=Finance
- Primary affected device example: DESKTOP-FB041
- Observation time: 2024-03-15 08:00 startup and logon window
- Change reference: 2024-03-14 23:30 migration from GPO user logon script to Intune PowerShell script running as SYSTEM
- Current status: Root cause identified; mapping method requires remediation

## Executive Summary
Finance users lost their mapped drive assignment after the drive-mapping workflow was migrated from a GPO logon script running in user context to an Intune PowerShell script running in SYSTEM context. At execution time, the Intune Management Extension launched `Map-FinBridgeDrives.ps1` as SYSTEM, and the script failed immediately because the UNC path `\\finbridge-fs01\Finance` was not accessible from that context.

System log evidence shows the Workstation service came online and Group Policy processed successfully, which rules out a general network startup failure or GPO processing issue. The failure is specific to how the script was executed after the migration: the original mapping logic depended on user context, user-available credentials, and an interactive session, but the migrated Intune script still used the same assumptions while running as SYSTEM.

## Scope and Impact
- Scope: All Finance endpoints using the migrated mapping workflow
- User impact: Finance users did not receive the expected mapped `S:` drive at login
- Technical impact: `Map-FinBridgeDrives.ps1` exited with code 1 under Intune Management Extension
- Business impact: Finance staff lost access to expected drive-letter-based workflows and any applications or shortcuts depending on `S:`

## Supporting Evidence

### Intune Management Extension Log
1. 08:00:01 - ScriptRunner Info
   - Executing: `Map-FinBridgeDrives.ps1`

2. 08:00:02 - ScriptRunner Info
   - Script context: SYSTEM account

3. 08:00:03 - ScriptRunner Warning
   - Network path `\\finbridge-fs01\Finance` not accessible from SYSTEM context at execution time

4. 08:00:03 - ScriptRunner Error
   - Script `Map-FinBridgeDrives.ps1` failed
   - Exit code: 1
   - Error: Network name cannot be found

5. 08:00:04 - ScriptRunner Info
   - No retry configured

### System Log - DESKTOP-FB041
1. 08:00:05 - Service Control Manager Event 7036
   - Workstation service entered running state

2. 08:00:06 - GroupPolicy Event 1500
   - Group Policy settings processed successfully
   - This confirms Group Policy itself was healthy in the same startup window

3. 08:00:07 - Ntfs Event 98 Warning
   - File system could not map drive letter `S:`
   - Drive letter has not been assigned

### Prior Change Evidence
- 2024-03-14 23:30 - Migration change log
  - Drive mapping script was moved from GPO logon script running as USER to Intune PowerShell script running as SYSTEM
  - The script was not updated to handle SYSTEM execution
  - UNC path access depended on conditions not present for SYSTEM at login time
  - Source reference: DESKTOP-FB022

## Timeline
1. 2024-03-14 23:30 - The drive mapping workflow is migrated from GPO user logon script to Intune PowerShell script running as SYSTEM.
2. 08:00:01 - Intune Management Extension starts `Map-FinBridgeDrives.ps1`.
3. 08:00:02 - The log confirms the script is running as SYSTEM, not as the signed-in user.
4. 08:00:03 - The script cannot access `\\finbridge-fs01\Finance` and exits with `Network name cannot be found`.
5. 08:00:04 - Intune records that no retry is configured, so the failure is final for that run.
6. 08:00:05 - The Workstation service enters running state after the script failure sequence has already started.
7. 08:00:06 - Group Policy completes successfully, ruling out GPO failure as the cause.
8. 08:00:07 - Windows records that drive letter `S:` could not be assigned.

## Technical Interpretation
- The decisive signal is the Intune log entry stating the script ran as SYSTEM and that the network path was not accessible from that context.
- The prior implementation succeeded because GPO logon scripts run in user context, where drive mappings naturally align with the interactive user session and that user's access token.
- After migration, the execution context changed but the script logic did not. A script that maps user drives by drive letter and depends on user-session network access is not equivalent when run as SYSTEM.
- Group Policy Event 1500 proves policy processing was successful, which disqualifies a GPO outage or startup policy delay as the root cause.
- The Workstation service entering running state at 08:00:05 does not rescue the failure because the relevant script execution had already failed and no retry was configured.

## Root Cause Statement
The incident was caused by migrating the Finance drive-mapping script from a user-context GPO logon script to an Intune PowerShell script running in SYSTEM context without redesigning the script for that execution model. Because the script still relied on user-context UNC access and drive-letter mapping behavior, it failed to access `\\finbridge-fs01\Finance` and could not assign the `S:` drive for Finance users.

## Five Whys Analysis

### Problem
Why did Finance users lose their `S:` drive mapping?
- Because the drive-mapping script failed during logon processing.

### Why 1
Why did the script fail?
- Because it could not access `\\finbridge-fs01\Finance` when executed.
- Evidence: Intune ScriptRunner warning and error at 08:00:03.

### Why 2
Why could it not access the UNC path?
- Because the script was running as SYSTEM rather than in the signed-in user's context.
- Evidence: Intune ScriptRunner Info at 08:00:02 explicitly states SYSTEM account.

### Why 3
Why was it running as SYSTEM?
- Because the mapping workflow had been migrated from a GPO user logon script to an Intune PowerShell script.
- Evidence: Change log entry from 2024-03-14 23:30.

### Why 4
Why did the migration break the workflow?
- Because the script was not updated to handle the different security and session model of SYSTEM execution.
- Evidence: Change note states the script was not updated to handle SYSTEM context.

### Why 5
Why was that design gap not caught before rollout?
- Because the migration validated script delivery but did not validate user-context outcomes such as interactive drive visibility, user-token access to UNC paths, and post-logon retry behavior.

## Recommended Remediation
1. Move Finance drive mapping back to a user-context execution method, such as a user-targeted logon script or an Intune remediation that runs in user context.
2. If Intune must remain the delivery mechanism, redesign the script so it runs after user sign-in in the user session rather than as SYSTEM.
3. Add retry or deferred execution logic so mapping occurs only after the required network components and user context are available.
4. Validate access using the target user's token and confirm the `S:` drive appears in the interactive session.
5. Review dependent applications, shortcuts, and scripts that assume `S:` exists and verify restoration after remediation.

## Preventive Actions
1. Add an execution-context review to all script migrations, explicitly documenting whether the script depends on user profile, user token, mapped credentials, or interactive session state.
2. Require pilot validation on representative endpoints whenever logon scripts are moved between GPO, Intune, scheduled tasks, or other delivery mechanisms.
3. Add post-change testing that confirms both backend success and end-user outcomes, including visible mapped drives.
4. Standardize a decision rule: user resource mappings should run in user context unless the script is specifically engineered for SYSTEM.
5. Add retry and telemetry for failed drive mapping tasks so startup timing problems do not become silent persistent failures.

## Verification Criteria
- `Map-FinBridgeDrives.ps1` or its replacement runs in user context for Finance users.
- `S:` appears in the interactive user session after sign-in on DESKTOP-FB* devices.
- The script no longer logs `Network name cannot be found` for `\\finbridge-fs01\Finance` under the deployed execution model.
- Finance users can access expected file shares and dependent workflows without manual remapping.

## Lessons Learned
- Script delivery success is not the same as behavior equivalence when the execution context changes.
- User drive mappings are especially sensitive to context because they rely on the interactive user's security token and desktop session.
- A successful Group Policy event in the same window is useful negative evidence when isolating issues introduced by Intune-side changes.