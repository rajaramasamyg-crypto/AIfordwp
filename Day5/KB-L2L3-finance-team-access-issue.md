# L2/L3 Knowledge Base: Finance Team Access Issue

v 1.0, 10/08/2026, status: Draft

## Background
Finance department users access network shared drives via UNC paths or mapped drive letters backed by one or more Windows file servers. Access is controlled through Active Directory security groups, share permissions, and NTFS permissions. DFS namespaces may be used to abstract the underlying file server path.

Why this matters:
- If AD group membership, share permissions, NTFS permissions, or DFS targets are broken, Finance users cannot reach business-critical files.
- The impact can range from a single user to the entire Finance department depending on the root cause.
- Fast scope identification prevents unnecessary file server restarts and misdirected remediation.

## Symptom

What the engineer observes:
- One or more Finance users raise tickets reporting inability to open a shared drive (drive letter or UNC path).
- Users may see errors such as `Access is denied`, `Network path not found`, `You do not have permission to access this folder`, or a drive letter with a red X in File Explorer.
- Other departments are not affected in the same time window.
- Server monitoring may or may not show an alert depending on root cause.

What users report:
- "My S: drive has disappeared."
- "I get Access is denied when I try to open the Finance shared folder."
- "I can see the drive letter but nothing opens when I click it."
- Impact may be single user, a subset of Finance, or the entire team.

## Root Cause Categories

This incident typically resolves to one of the following root causes. Detection steps below confirm which applies.

| Category | Description |
|---|---|
| A | User(s) missing from AD security group governing Finance share access |
| B | Share permission removed or incorrect on the file server |
| C | NTFS permission removed or incorrect on the share folder |
| D | File server unreachable (service stopped, network, or hardware) |
| E | DFS namespace target offline or misconfigured |
| F | Kerberos / authentication failure (DC connectivity, account lockout, expired password) |

## Detection

Use this workflow to confirm the root cause category before making any changes.

### Detection Step 1: Establish scope and collect error evidence

- Confirm total number of affected users and whether they share the same OU, site, or AD security group.
- Collect the exact error message text from at least two affected users.
- Confirm whether any Finance users are unaffected (this rules out a complete server outage).
- Check monitoring dashboard for file server and DC availability alerts in the incident window.

Decision: if the file server itself is unreachable (all users affected, monitoring alert active), go directly to **Root Cause D**. Otherwise continue.

### Detection Step 2: Validate AD group membership

Run on any domain controller. Replace `jbrown` with an affected user's samAccountName:

```powershell
Get-ADUser -Identity jbrown -Properties MemberOf | Select-Object -ExpandProperty MemberOf | Sort-Object
```

- Confirm whether the expected Finance access group (example: `GRP-Finance-ShareAccess`) is present in the output.
- Compare against a user who is **not** affected and is known to have access.

```powershell
# Compare two users side-by-side
$affected   = (Get-ADUser -Identity jbrown  -Properties MemberOf).MemberOf | Sort-Object
$unaffected = (Get-ADUser -Identity swright -Properties MemberOf).MemberOf | Sort-Object
Compare-Object $affected $unaffected
```

Required outcome to confirm Root Cause A:
- Affected user is missing from the Finance AD security group.
- Unaffected user is a member of the same group.

### Detection Step 3: Validate share and NTFS permissions

Run on the file server (locally or via remote PowerShell):

```powershell
# Share permissions
Get-SmbShareAccess -Name 'Finance'

# NTFS permissions
(Get-Acl -Path 'D:\Shares\Finance').Access |
  Select-Object IdentityReference, FileSystemRights, AccessControlType |
  Sort-Object IdentityReference
```

Required outcome to confirm Root Cause B or C:
- The AD security group governing Finance access is absent from `Get-SmbShareAccess` output (Root Cause B).
- The AD security group is absent from the NTFS ACL output, or `AccessControlType` is `Deny` (Root Cause C).

### Detection Step 4: Check file server reachability and SMB service

From your workstation or jump host:

```powershell
Test-NetConnection -ComputerName FILESVR01 -Port 445
```

Then on the file server:

```powershell
Get-Service -Name LanmanServer | Select-Object Name, Status, StartType

Get-SmbShare | Where-Object { $_.Name -like 'Finance*' } | Select-Object Name, Path
```

Required outcome to confirm Root Cause D:
- `TcpTestSucceeded : False` from `Test-NetConnection`, or
- `LanmanServer` service is `Stopped`, or
- Finance share is absent from `Get-SmbShare` output.

### Detection Step 5: Check DFS namespace health (if applicable)

```powershell
# Namespace root status
Get-DfsnRoot | Where-Object { $_.Path -like '*Finance*' } | Select-Object Path, State

# Folder targets
Get-DfsnFolderTarget -Path '\\domain\Finance\Shared' |
  Select-Object Path, TargetPath, State
```

Required outcome to confirm Root Cause E:
- DFS namespace root `State` is not `Online`, or
- One or more folder targets show `State : Offline`.

### Detection Step 6: Check authentication and Kerberos health

On a domain controller, filter `Windows Logs -> Security` for affected users:

```powershell
$since = (Get-Date).AddHours(-2)

# Failed logon / authentication events for Finance users
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=@(4625,4771,4768); StartTime=$since} |
  Where-Object { $_.Message -match 'jbrown' -or $_.Message -match 'swright' } |
  Select-Object TimeCreated, Id, Message | Format-List
```

Also test DC connectivity from the file server:

```powershell
nltest /sc_query:<YourDomainName>
repadmin /replsummary
```

Required outcome to confirm Root Cause F:
- Multiple Event ID `4625` or `4771` entries for Finance user accounts, or
- `nltest` returns errors, or
- `repadmin /replsummary` shows replication failures that could cause stale group data on some DCs.

### Detection Decision (go/no-go)

Apply the resolution below only after confirming the root cause category. If the evidence points to more than one category, resolve them in order: D first, then F, then A, then B/C, then E.

## Resolution

### Root Cause A: Missing AD Group Membership

1. In ADUC or PowerShell, add the affected user(s) to the correct Finance AD security group:

   ```powershell
   Add-ADGroupMember -Identity 'GRP-Finance-ShareAccess' -Members jbrown
   ```

2. Ask the user to log off completely and log back on (or run `klist purge` on their device to flush the Kerberos ticket cache), then test access.
3. Confirm in ADUC that the group membership is visible under the user account `Member Of` tab.
4. If multiple users are affected, check whether the group itself was emptied or the GPO/drive mapping was altered as a secondary check.

### Root Cause B: Share Permission Removed or Incorrect

1. On the file server, restore the correct share permission:

   ```powershell
   Grant-SmbShareAccess -Name 'Finance' -AccountName 'DOMAIN\GRP-Finance-ShareAccess' -AccessRight Change -Force
   ```

2. Verify the change:

   ```powershell
   Get-SmbShareAccess -Name 'Finance'
   ```

3. Ask an affected user to test access immediately (no logoff required for share permission changes).

### Root Cause C: NTFS Permission Removed or Incorrect

1. Open File Server Management Console or use PowerShell to restore the NTFS ACE:

   ```powershell
   $acl  = Get-Acl -Path 'D:\Shares\Finance'
   $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
               'DOMAIN\GRP-Finance-ShareAccess',
               'Modify',
               'ContainerInherit,ObjectInherit',
               'None',
               'Allow'
           )
   $acl.AddAccessRule($rule)
   Set-Acl -Path 'D:\Shares\Finance' -AclObject $acl
   ```

2. Verify the ACL reflects the new entry:

   ```powershell
   (Get-Acl -Path 'D:\Shares\Finance').Access |
     Where-Object { $_.IdentityReference -match 'GRP-Finance' } |
     Select-Object IdentityReference, FileSystemRights, AccessControlType
   ```

3. Ask an affected user to test access.

### Root Cause D: File Server Unreachable

1. Check server power, hypervisor status, or Azure VM status depending on hosting model.
2. If the `LanmanServer` service is stopped, restart it:

   ```powershell
   Start-Service -Name LanmanServer
   Get-Service -Name LanmanServer | Select-Object Name, Status
   ```

3. Confirm the Finance share is accessible after service restart:

   ```powershell
   Test-NetConnection -ComputerName FILESVR01 -Port 445
   Get-SmbShare -Name 'Finance'
   ```

4. If the server is fully unavailable, escalate to the infrastructure team as a P1 incident and activate the Business Continuity plan for Finance data access if one exists.

### Root Cause E: DFS Target Offline

1. Bring the offline target back online in the DFS Management console or via PowerShell:

   ```powershell
   Set-DfsnFolderTarget -Path '\\domain\Finance\Shared' -TargetPath '\\FILESVR01\Finance' -State Online
   ```

2. Verify the target state:

   ```powershell
   Get-DfsnFolderTarget -Path '\\domain\Finance\Shared' | Select-Object Path, TargetPath, State
   ```

3. Ask a user to test the DFS path. No logoff is required.

### Root Cause F: Authentication / Kerberos Failure

1. If the user account is locked out, unlock it:

   ```powershell
   Unlock-ADAccount -Identity jbrown
   ```

2. If the user's password has expired, reset it following your password policy and inform the user.
3. If DC connectivity is the issue, escalate to the AD/infrastructure team immediately as this will affect all domain services.
4. If replication failures are found, raise a separate AD health incident and monitor whether the Finance share issue resolves once replication is healthy.

## Verification

1. Ask two affected users from different parts of Finance to access the shared drive simultaneously and confirm files open. Expected result: No error messages; files are accessible.
2. Confirm no new `Event ID 4625` entries appear on the file server or DC for Finance user accounts after remediation. Expected result: Authentication failures have stopped.
3. Confirm AD group membership is correct in ADUC for all previously affected users. Expected result: Affected users are members of the correct Finance access group.
4. Confirm share permissions and NTFS permissions match the documented baseline. Expected result: No unexpected entries are present in either permission set.
5. Confirm DFS targets are `Online` if DFS is in scope. Expected result: All Finance DFS folder targets resolve to the correct file server.
6. Update the incident ticket with the confirmed root cause category (A through F) and close only after the reporting user confirms access is restored. Expected result: Ticket accurately reflects root cause and verified resolution.

## Escalation Criteria

Escalate beyond L2/L3 (to infrastructure, AD, or network teams) if any of the following apply:

- The file server is fully unreachable and cannot be restored by restarting the `LanmanServer` service.
- DC replication failures are detected in `repadmin /replsummary`.
- The `nltest /sc_query` shows domain trust or secure channel failures.
- Multiple root cause categories are active simultaneously (for example, both the DFS target is offline and the file server is unreachable).
- The Finance share or its parent folder has been deleted from the file system.
- The incident affects more than the Finance department, suggesting a broader infrastructure failure.

## Related Articles

- Runbook: [runbook-finance-team-access-issue.md](runbook-finance-team-access-issue.md)
- L1 Self-Service: [L1-self-service-finance-team-access-issue.md](L1-self-service-finance-team-access-issue.md)
