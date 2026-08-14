# Runbook - Floor 6 Ring Containment and Rollback

Version: 1.0  
Date: 2026-08-14  
Owner: EUC Engineering + Identity + Security

## Purpose
Contain and remediate Floor 6 login failures and Copilot overexposure by removing impacted users/devices from mis-scoped deployment/licensing groups, then validating normal access.

## Prerequisites
1. Change ticket approved for emergency containment.
2. Admin roles: Intune Administrator, Groups Administrator, Security Reader.
3. Microsoft Graph PowerShell installed and authenticated.
4. Input files:
   - floor6-legal-upns.txt
   - impacted-device-names.txt
5. Evidence collection script available:
   - collect-floor6-evidence-final.ps1

## Procedure

1. Capture pre-change evidence on one affected Floor 6 device.
Expected result: summary.json and steps.json are created under C:\ProgramData\FinBridge\Floor6Evidence\<timestamp>.

```powershell
.\collect-floor6-evidence-final.ps1 -LookbackHours 72
```

2. Connect to Microsoft Graph with required scopes.
Expected result: Get-MgContext returns active tenant and granted scopes.

```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All,DeviceManagementManagedDevices.ReadWrite.All,User.Read.All"
Get-MgContext
```

3. Resolve target groups used in rollout.
Expected result: Non-empty group IDs for ring and Copilot pilot groups.

```powershell
$ringGroupName = "SG-INTUNE-W11-FLOOR6-LEGAL-RING"
$copilotPilotGroupName = "SG-M365-COPILOT-PILOT"
$ringGroupId = (Get-MgGroup -Filter "displayName eq '$ringGroupName'").Id
$copilotGroupId = (Get-MgGroup -Filter "displayName eq '$copilotPilotGroupName'").Id
$ringGroupId
$copilotGroupId
```

4. Remove impacted devices from the ring group.
Expected result: Affected devices are no longer group members.

```powershell
Get-Content .\impacted-device-names.txt | ForEach-Object {
    $deviceName = $_
    $member = Get-MgGroupMember -GroupId $ringGroupId -All |
        Where-Object { $_.AdditionalProperties.displayName -eq $deviceName } |
        Select-Object -First 1
    if ($member) {
        Remove-MgGroupMemberByRef -GroupId $ringGroupId -DirectoryObjectId $member.Id
    }
}
```

5. Remove impacted users from Copilot pilot licensing group.
Expected result: Listed users no longer receive pilot license assignment.

```powershell
Get-Content .\floor6-legal-upns.txt | ForEach-Object {
    $u = Get-MgUser -Filter "userPrincipalName eq '$_'"
    if ($u) {
        Remove-MgGroupMemberByRef -GroupId $copilotGroupId -DirectoryObjectId $u.Id
    }
}
```

6. Force Intune sync for impacted managed devices.
Expected result: Sync action accepted for each impacted device.

```powershell
Get-Content .\impacted-device-names.txt | ForEach-Object {
    $deviceName = $_
    $md = Get-MgDeviceManagementManagedDevice -All |
        Where-Object { $_.DeviceName -eq $deviceName } |
        Select-Object -First 1
    if ($md) {
        Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $md.Id
    }
}
```

7. Validate access recovery and containment.
Expected result: Login time normalizes and Copilot no longer returns out-of-scope matter content.

```powershell
# On one recovered device
.\collect-floor6-evidence-final.ps1 -LookbackHours 4
```

## Verification
1. At least 3 previously affected users can log in within normal baseline time.
2. No new reports of unauthorized matter visibility in Copilot.
3. Group membership checks confirm users/devices removed from target groups.
4. Post-change evidence summary.json shows reduced AAD/MDM error signals.

## Rollback
Use only if containment was applied to the wrong cohort.

1. Re-add required devices to ring group.
Expected result: Devices appear again under SG-INTUNE-W11-FLOOR6-LEGAL-RING.

```powershell
Get-Content .\rollback-device-names.txt | ForEach-Object {
    $d = Get-MgDevice -Filter "displayName eq '$_'"
    if ($d) {
        New-MgGroupMemberByRef -GroupId $ringGroupId -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$($d.Id)"
    }
}
```

2. Re-add approved users to Copilot pilot group.
Expected result: Approved users regain pilot assignment on next license sync.

```powershell
Get-Content .\rollback-upns.txt | ForEach-Object {
    $u = Get-MgUser -Filter "userPrincipalName eq '$_'"
    if ($u) {
        New-MgGroupMemberByRef -GroupId $copilotGroupId -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$($u.Id)"
    }
}
```

3. Force Intune sync and re-verify.
Expected result: Membership and policy state match approved rollout design.
