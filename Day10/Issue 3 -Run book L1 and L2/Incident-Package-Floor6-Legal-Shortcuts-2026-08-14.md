# Floor 6 Incident Package - Legal Shortcuts

Version: 1.0  
Date: 2026-08-14  
Owner: Incident Command (EUC + Intune + Security)

## 1) Situation in plain terms
Floor 6 Legal (45 users) reported missing desktop shortcuts after Friday deployment of the new document management app. Devices were recently moved to Win11 and Intune, increasing change overlap and reducing confidence in any single symptom.

## 2) Most-likely cause (ranked)
Top-ranked cause: Intune app deployment side effect removed or replaced .lnk shortcuts on Public Desktop/user Desktop during install or uninstall command execution.

Why this is highest probability:
1. Timing matches exactly: issue appears right after Friday app rollout.
2. Symptom pattern is narrow: shortcut visibility loss, not broad disk or profile loss.
3. Recently migrated and newly enrolled endpoints are more sensitive to deployment script mistakes.

Alternative causes considered:
1. Win11 profile corruption
2. OneDrive Known Folder Move redirection issue

These remain lower-ranked until log evidence disproves deployment side effects.

## 3) Evidence required and what to check
On one affected Floor 6 device, collect:
1. Current shortcut inventory from Public Desktop and user Desktop.
2. Intune Management Extension logs for deletion/uninstall patterns.
3. App install/uninstall events in Application log.
4. Registry uninstall entries for target app.
5. Structured summary output for handoff.

Use:
- collect-floor6-shortcut-evidence-ai-draft.ps1
- collect-floor6-shortcut-evidence-final.ps1
- Section-3a-AI-vs-Corrected-Script.md

Command examples:

```powershell
.\collect-floor6-shortcut-evidence-final.ps1 -DryRun
.\collect-floor6-shortcut-evidence-final.ps1 -LookbackHours 72
```

Expected output location:
- C:\ProgramData\FinBridge\Floor6ShortcutEvidence\<timestamp>\summary.json
- C:\ProgramData\FinBridge\Floor6ShortcutEvidence\<timestamp>\steps.json
- Supporting CSV/log files in same folder

## 4) Immediate fix (technical action now)
Pause the rollout scope by removing Floor 6 assignment from the app, then restore shortcut and sync devices.

```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All,DeviceManagementApps.ReadWrite.All,DeviceManagementManagedDevices.ReadWrite.All"

$appDisplayName = "FinBridge Document Management"
$targetGroupName = "SG-INTUNE-APP-FLOOR6-LEGAL"

$app = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$appDisplayName'" | Select-Object -First 1
$targetGroup = Get-MgGroup -Filter "displayName eq '$targetGroupName'" | Select-Object -First 1

$assignmentsUri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.Id)/assignments"
$assignments = (Invoke-MgGraphRequest -Method GET -Uri $assignmentsUri).value

$toRemove = $assignments | Where-Object {
    $_.target.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget' -and
    $_.target.groupId -eq $targetGroup.Id
}

foreach ($assignment in $toRemove) {
    Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.Id)/assignments/$($assignment.id)"
}

Get-Content .\floor6-legal-device-ids.txt | ForEach-Object {
    Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $_
}
```

## 5) Message to Floor 6 users
Team, we have identified a software rollout issue that removed some desktop shortcuts. Your documents are safe, and this does not indicate data loss. We have already paused the rollout and started restoring affected shortcuts in priority order. If you are blocked, please raise a ticket with your device name and the time you noticed the issue so we can prioritize recovery.

## 6) Required reflection (first instinct was wrong)
My first instinct was Win11 migration profile corruption because recent migration often causes desktop anomalies. The evidence approach changed that view: the script was expanded to prioritize Intune deployment logs and app assignment traces, because the symptom timing lined up tightly with Friday rollout. If logs show deletion or uninstall-side cleanup actions, deployment scoping/packaging is the true driver, not profile corruption.

## 7) Linked operational artifacts
1. Runbook-Floor6-Shortcut-Containment-and-Restore-v1.0.md
2. KA-L1-Floor6-Shortcut-Recovery-v1.0.md
3. KA-L2-Floor6-Shortcut-Recovery-v1.0.md
4. Partner-Update-By-Lunch-Floor6-Shortcuts-v1.0.md
5. Prevention-Note-Floor6-Deployment-Control-v1.0.md
