# Floor 6 Incident Package - Legal (2026-08-14)

Version: 1.0  
Date: 2026-08-14  
Owner: Incident Command (EUC + Identity + Security)

## 1) Most-likely cause (top-ranked)

Most-likely cause: A change-control scoping failure in Entra groups.

The same broad group path appears to have been used for both:
- Win11/Intune deployment ring assignment for Floor 6 devices
- Copilot pilot/license assignment before SharePoint permission remediation was complete

Why this is top-ranked:
- It explains login delays/failures after Win11 + Intune enrollment (policy/compliance churn and token evaluation on sign-in).
- It explains why Copilot surfaced a client matter: Copilot is honoring existing data permissions, and inherited SharePoint access remained over-permissive.
- It matches the known blocker documented in pre-deployment context: unresolved inherited permissions from legacy SharePoint migration.

## 2) Evidence check to prove/disprove the cause

Use the script pair in Section 3a:
- AI draft: collect-floor6-evidence-ai-draft.ps1
- Corrected script: collect-floor6-evidence-final.ps1
- Side-by-side comparison: Section-3a-AI-vs-Corrected-Script.md

Execution examples:

```powershell
# Dry run (safe planning artifact only)
.\collect-floor6-evidence-final.ps1 -DryRun

# Full evidence collection
.\collect-floor6-evidence-final.ps1 -LookbackHours 72
```

Expected output location:
- C:\ProgramData\FinBridge\Floor6Evidence\<timestamp>\summary.json
- C:\ProgramData\FinBridge\Floor6Evidence\<timestamp>\steps.json
- Additional raw evidence files in the same folder

## 3) Immediate technical action

Contain blast radius now by removing Floor 6 from the ring and Copilot pilot group, then force policy refresh.

```powershell
# Requires Microsoft Graph PowerShell modules and appropriate admin roles
Connect-MgGraph -Scopes "Group.ReadWrite.All,DeviceManagementManagedDevices.ReadWrite.All,User.Read.All"

$ringGroupName = "SG-INTUNE-W11-FLOOR6-LEGAL-RING"
$copilotPilotGroupName = "SG-M365-COPILOT-PILOT"
$floor6Prefix = "L6-"   # Example device naming convention

$ringGroupId = (Get-MgGroup -Filter "displayName eq '$ringGroupName'").Id
$copilotGroupId = (Get-MgGroup -Filter "displayName eq '$copilotPilotGroupName'").Id

# Pull devices out of deployment ring
Get-MgGroupMember -GroupId $ringGroupId -All |
    Where-Object { $_.AdditionalProperties.displayName -like "$floor6Prefix*" } |
    ForEach-Object { Remove-MgGroupMemberByRef -GroupId $ringGroupId -DirectoryObjectId $_.Id }

# Pull impacted users out of Copilot pilot license group (source list maintained by Service Desk)
Get-Content .\floor6-legal-upns.txt |
    ForEach-Object {
        $u = Get-MgUser -Filter "userPrincipalName eq '$_'"
        if ($u) {
            Remove-MgGroupMemberByRef -GroupId $copilotGroupId -DirectoryObjectId $u.Id
        }
    }

# Force Intune sync for impacted managed devices
Get-MgDeviceManagementManagedDevice -All |
    Where-Object { $_.DeviceName -like "$floor6Prefix*" } |
    ForEach-Object { Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $_.Id }
```

## 4) Message to Floor 6 (plain language)

Team, we are actively fixing a configuration issue that is affecting sign-in speed and, in one case, document visibility in Copilot. We have already started containment to stop the issue from spreading, and we are checking each affected account/device before restoring normal access. Your files are not being deleted, and this is being handled with Legal and Security oversight. We will send the next update as soon as verification completes. If you are blocked right now, log a ticket with your device name and the time of your last failed sign-in so we can prioritize you.

## 5) Prevention note (specific process change)

Process change to implement: Dual-Gate Group Scope Check (DG-GSC) for AI and endpoint rollouts.

Control definition:
- Any Entra group used for Copilot licensing must be a dedicated group that cannot also be used as an Intune deployment target.
- Change cannot move to production unless an automated pre-flight job confirms zero overlap between licensing groups and deployment-ring groups.
- Evidence artifact (overlap report CSV + approver sign-off) must be attached to the change record before approval.

This would have blocked this rollout before Monday morning.
