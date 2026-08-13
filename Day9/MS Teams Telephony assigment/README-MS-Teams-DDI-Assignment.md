# MS Teams DDI Assignment - Step by Step (Day 9)

## Purpose
This guide explains how to assign DDI (Direct Dial-In) phone numbers to Microsoft Teams users using both:
- Teams Admin Center (GUI)
- PowerShell (single or bulk assignment)

## Prerequisites
1. You are a Teams Administrator or Global Administrator.
2. Users have a Teams Phone license assigned.
3. Phone numbers are available in your tenant.
4. The correct PSTN connectivity model is ready:
   - Calling Plan
   - Operator Connect
   - Direct Routing
5. PowerShell 7+ (recommended) is installed.
6. MicrosoftTeams PowerShell module is installed.

## Quick Validation Checklist
Before assigning numbers, confirm:
1. User sign-in account exists and is enabled.
2. Teams Phone license is assigned to the user.
3. User usage location is set.
4. Number format is E.164 (example: +14155550123).
5. Number type matches your environment (CallingPlan, OperatorConnect, or DirectRouting).

---

## Method A - Teams Admin Center (Portal)
1. Go to Microsoft Teams Admin Center.
2. Open Voice > Phone numbers.
3. Verify the DDI number is available.
4. Go to Users > Manage users.
5. Select the target user.
6. Open the Account tab and locate Assigned phone number.
7. Click Edit.
8. Select Number type:
   - Calling Plan
   - Operator Connect
   - Direct Routing
9. Enter or select the DDI number.
10. Save changes.
11. (If required) Assign voice routing policy and dial plan.
12. Test inbound and outbound calling.

---

## Method B - PowerShell (Recommended for repeatable operations)

### Step 1: Install and import module
```powershell
Install-Module MicrosoftTeams -Scope CurrentUser
Import-Module MicrosoftTeams
```

### Step 2: Connect to Teams
```powershell
Connect-MicrosoftTeams
```

### Step 3: Assign a DDI to one user
```powershell
Set-CsPhoneNumberAssignment -Identity "user1@contoso.com" -PhoneNumber "+14155550123" -PhoneNumberType DirectRouting
```

### Step 4: (Optional) Enable Enterprise Voice explicitly
```powershell
Set-CsPhoneNumberAssignment -Identity "user1@contoso.com" -EnterpriseVoiceEnabled $true
```

### Step 5: (Optional) Assign policies
```powershell
Grant-CsOnlineVoiceRoutingPolicy -Identity "user1@contoso.com" -PolicyName "VRP-US"
Grant-CsTenantDialPlan -Identity "user1@contoso.com" -PolicyName "DP-US"
```

### Step 6: Verify assignment
```powershell
Get-CsPhoneNumberAssignment -Identity "user1@contoso.com"
```

---

## Bulk Assignment (CSV + Script)
Use the script in this folder:
- assign-teams-ddi.ps1

Expected CSV columns:
- UserPrincipalName
- PhoneNumber
- PhoneNumberType
- VoiceRoutingPolicy (optional)
- TenantDialPlan (optional)

Example CSV:
```csv
UserPrincipalName,PhoneNumber,PhoneNumberType,VoiceRoutingPolicy,TenantDialPlan
user1@contoso.com,+14155550123,DirectRouting,VRP-US,DP-US
user2@contoso.com,+14155550124,DirectRouting,VRP-US,DP-US
```

Run script:
```powershell
.\assign-teams-ddi.ps1 -CsvPath .\ddi-assignments.csv -WhatIf
.\assign-teams-ddi.ps1 -CsvPath .\ddi-assignments.csv
```

---

## Rollback Example
To remove a number from a user:
```powershell
Remove-CsPhoneNumberAssignment -Identity "user1@contoso.com" -PhoneNumber "+14155550123" -PhoneNumberType DirectRouting
```

## Troubleshooting
1. Error: Insufficient permissions
   - Confirm admin role and reconnect session.
2. Error: Number unavailable
   - Verify number status under Voice > Phone numbers.
3. Error: User not enabled for Enterprise Voice
   - Re-run assignment with enterprise voice enabled.
4. Calls fail after assignment
   - Validate voice routing policy and SBC/Operator configuration.

## Operational Notes
- Always test with 1 pilot user before bulk assignment.
- Keep a backup CSV for rollback.
- Use WhatIf before production execution.

Created: 2026-08-13
