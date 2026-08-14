# Runbook - Floor 6 Shortcut Containment and Restore

Version: 1.0  
Date: 2026-08-14  
Owner: EUC Engineering + Intune Admin

## Purpose
Contain the Floor 6 shortcut-loss incident linked to Friday app deployment, restore required desktop shortcuts, and prevent new impact while root cause is verified.

## Prerequisites
1. Emergency change ticket approved.
2. Roles available: Intune Administrator, Groups Administrator, Security Reader.
3. Microsoft Graph PowerShell module installed and authenticated.
4. Input files prepared:
   - floor6-legal-device-ids.txt
   - floor6-legal-upns.txt
5. Evidence script available:
   - collect-floor6-shortcut-evidence-final.ps1

## Procedure

1. Capture evidence from one affected device before changes.
Expected result: collection-plan.json, summary.json, and steps.json are created under C:\ProgramData\FinBridge\Floor6ShortcutEvidence\<timestamp>.

```powershell
.\collect-floor6-shortcut-evidence-final.ps1 -LookbackHours 72
```

2. Identify app and target ring group in Graph.
Expected result: Non-empty IDs for app and Floor 6 target group.

```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All,DeviceManagementApps.ReadWrite.All,DeviceManagementManagedDevices.ReadWrite.All"

$appDisplayName = "FinBridge Document Management"
$targetGroupName = "SG-INTUNE-APP-FLOOR6-LEGAL"

$app = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$appDisplayName'" | Select-Object -First 1
$targetGroup = Get-MgGroup -Filter "displayName eq '$targetGroupName'" | Select-Object -First 1

$app.Id
$targetGroup.Id
```

3. Remove Floor 6 group assignment from the app (containment).
Expected result: Assignment scoped to SG-INTUNE-APP-FLOOR6-LEGAL is removed.

```powershell
$assignmentsUri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.Id)/assignments"
$assignments = (Invoke-MgGraphRequest -Method GET -Uri $assignmentsUri).value

$toRemove = $assignments | Where-Object {
    $_.target.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget' -and
    $_.target.groupId -eq $targetGroup.Id
}

foreach ($assignment in $toRemove) {
    $deleteUri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.Id)/assignments/$($assignment.id)"
    Invoke-MgGraphRequest -Method DELETE -Uri $deleteUri
}
```

4. Push temporary shortcut restore remediation script to affected ring.
Expected result: Required shortcut(s) appear again on Public Desktop and impacted user desktops.

```powershell
$restoreScript = @'
$public = Join-Path $env:PUBLIC "Desktop"
if (-not (Test-Path $public)) { New-Item -ItemType Directory -Path $public -Force | Out-Null }

$target = Join-Path $public "FinBridge DMS.lnk"
$wsh = New-Object -ComObject WScript.Shell
$link = $wsh.CreateShortcut($target)
$link.TargetPath = "C:\Program Files\FinBridge\DMS\DMS.exe"
$link.WorkingDirectory = "C:\Program Files\FinBridge\DMS"
$link.Save()
'@

$restorePath = "C:\ProgramData\FinBridge\restore-dms-shortcut.ps1"
New-Item -ItemType Directory -Path (Split-Path $restorePath) -Force | Out-Null
Set-Content -Path $restorePath -Value $restoreScript -Encoding UTF8
powershell.exe -ExecutionPolicy Bypass -File $restorePath
```

5. Force Intune sync on impacted devices.
Expected result: Devices report policy sync initiation and receive updated app assignments.

```powershell
Get-Content .\floor6-legal-device-ids.txt | ForEach-Object {
    Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $_
}
```

6. Verify recovery.
Expected result: Restored shortcuts confirmed for pilot sample, no new shortcut-loss reports after containment.

```powershell
.\collect-floor6-shortcut-evidence-final.ps1 -LookbackHours 4
```

## Verification
1. At least 5 affected Floor 6 users confirm shortcut is present and opens the correct app.
2. No new tickets for shortcut disappearance after assignment removal.
3. App assignment list no longer includes SG-INTUNE-APP-FLOOR6-LEGAL.
4. Post-change evidence shows stable shortcut counts and no fresh deletion log lines.

## Rollback
Use if assignment removal was incorrect or removed intended access.

1. Re-assign app to approved pilot group only.
Expected result: App deploys only to validated pilot group.

```powershell
$pilotGroup = Get-MgGroup -Filter "displayName eq 'SG-INTUNE-APP-LEGAL-PILOT'" | Select-Object -First 1

$body = @{
    mobileAppAssignments = @(
        @{
            "@odata.type" = "#microsoft.graph.mobileAppAssignment"
            intent = "required"
            target = @{
                "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                groupId = $pilotGroup.Id
            }
            settings = @{
                "@odata.type" = "#microsoft.graph.win32LobAppAssignmentSettings"
                notifications = "showAll"
                restartSettings = $null
                installTimeSettings = $null
            }
        }
    )
}

Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.Id)/assign" -Body ($body | ConvertTo-Json -Depth 10) -ContentType "application/json"
```

2. Force sync and re-verify on pilot devices.
Expected result: Only pilot users/devices receive app and shortcuts remain intact.
