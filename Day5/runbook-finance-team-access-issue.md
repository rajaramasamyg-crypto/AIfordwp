# Runbook: Finance Team Access Issue

## Purpose
Use this runbook when one or more Finance department users report that they cannot access network shared drives or DFS shares, and the issue is not explained by a known scheduled maintenance window. Follow this runbook to contain the impact, identify the affected scope, and restore access.

## Prerequisites
- [ ] You have access to Active Directory Users and Computers (ADUC) or the AD Admin Center.
- [ ] You have read access to the File Server Management Console on the affected file server(s).
- [ ] You can open the DFS Management console (if DFS shares are in scope).
- [ ] You can run PowerShell on the affected file server(s) (locally or via remote session).
- [ ] You have read access to the monitoring platform (e.g. SCOM, Nagios, or equivalent).
- [ ] You have access to the Incident Management Tool and can create or update tickets.
- [ ] You have the list of Finance shared drive UNC paths and the AD security groups that govern access.

### Mandatory Information From End User (Do Not Start Without This)
- [ ] Affected username(s) in UPN format (example: `jbrown@organisation.gov.uk`).
- [ ] Time the issue was first noticed (local time + timezone).
- [ ] Drive letter(s) or UNC path(s) affected (example: `S:\`, `\\FILESVR01\Finance`).
- [ ] Error message shown when trying to access the drive (exact text or screenshot).
- [ ] Whether the user can access other network drives outside Finance.
- [ ] Whether the issue affects only this user, a group of users, or the entire Finance team.
- [ ] Whether any recent changes occurred: password reset, device rebuild, or Group Policy refresh.
- [ ] Device name and OS of the user endpoint.

### Required Tools
- [ ] Active Directory Users and Computers (`dsa.msc`) or Active Directory Admin Center.
- [ ] File Server Management Console or Server Manager on the file server.
- [ ] DFS Management (`dfsmgmt.msc`) if DFS shares are in scope.
- [ ] PowerShell on the file server (remote or local).
- [ ] Event Viewer (`eventvwr.msc`) on the file server and domain controller.
- [ ] Monitoring dashboard for server availability alerts.

### Log Locations (Use These Exact Paths)
- File server share access errors:
  - `Event Viewer -> Windows Logs -> Security` on the file server (filter Event ID `5140` share access, `5145` detailed share access, `4625` failed logon).
- File server service events:
  - `Event Viewer -> Windows Logs -> System` on the file server (filter source `Server`, `LanmanServer`).
- Domain controller authentication:
  - `Event Viewer -> Windows Logs -> Security` on the DC (filter Event ID `4768` Kerberos TGT, `4769` Kerberos service ticket, `4771` pre-auth failure, `4625` logon failure).
- DFS namespace status:
  - `Event Viewer -> Applications and Services Logs -> Microsoft -> Windows -> DFSN-Server -> Operational` on the DFS namespace server.
- AD group membership:
  - ADUC: user account `-> Member Of` tab, or PowerShell on any DC.

## Procedure

### Phase 1: Scope Assessment

1. Log the number of reports in the incident ticket and note whether affected users share the same department, OU, or AD security group. Expected result: You have a documented count (single user, subset, or all Finance).
2. Contact two or three affected users and ask them to attempt access right now while on the call. Note the exact error message text (example: `Network path not found`, `Access is denied`, `You do not have permission`). Expected result: You have consistent error text to guide diagnosis.
3. Confirm whether users who are NOT in Finance, or Finance users on a different site, can access the same share. Expected result: You can narrow scope to group/server/site.
4. Check the monitoring dashboard for file server and DC availability alerts raised in the same time window. Expected result: You know whether the server or domain is showing active alerts.

### Phase 2: Validate Active Directory Group Membership

5. Open ADUC or run the command below on a domain controller for an affected user. Replace `jbrown` with the actual samAccountName:

   ```powershell
   Get-ADUser -Identity jbrown -Properties MemberOf | Select-Object -ExpandProperty MemberOf | Sort-Object
   ```

   Expected result: Output lists all AD groups the user belongs to.

6. Confirm the user is a member of the AD security group that grants access to the Finance share (example: `GRP-Finance-ShareAccess`). Expected result: Either the user is in the group (rule out missing membership) or they are not (root cause identified).

7. If testing multiple affected users, run the following to compare memberships:

   ```powershell
   $users = @('jbrown','swright','mmills')
   foreach ($u in $users) {
       Write-Host "`n--- $u ---"
       Get-ADUser -Identity $u -Properties MemberOf | Select-Object -ExpandProperty MemberOf | Sort-Object
   }
   ```

   Expected result: You identify whether the missing group applies to all, some, or one affected user.

8. If group membership is missing for affected users but present for unaffected users, document this as the likely root cause and proceed to Resolution - Phase A. If membership looks correct, continue to Phase 3.

### Phase 3: Check File Server Availability and Share Configuration

9. From your workstation or a jump host, test connectivity to the file server:

   ```powershell
   Test-NetConnection -ComputerName FILESVR01 -Port 445
   ```

   Expected result: `TcpTestSucceeded : True`. If False, escalate as server/network outage immediately.

10. On the file server, open Server Manager or run:

    ```powershell
    Get-SmbShare | Where-Object { $_.Name -like 'Finance*' -or $_.Path -like '*Finance*' } | Select-Object Name, Path, Description
    ```

    Expected result: Finance share(s) are listed. If not listed, the share has been removed or renamed.

11. Check share permissions on the file server:

    ```powershell
    Get-SmbShareAccess -Name 'Finance'
    ```

    Expected result: The AD security group appears with at least `Read` access. If the group is missing from share permissions, document as root cause.

12. Check NTFS permissions on the share folder:

    ```powershell
    (Get-Acl -Path '\\FILESVR01\Finance').Access | Select-Object IdentityReference, FileSystemRights, AccessControlType | Sort-Object IdentityReference
    ```

    Expected result: The AD security group appears in the ACL with at least `Read and Execute`. If absent, document as root cause.

13. Open Event Viewer on the file server. Filter `Windows Logs -> Security` for Event ID `5140` (share accessed) and `4625` (logon failure) in the incident time window. Expected result: You can see whether access attempts are being rejected and at what point.

### Phase 4: Check Domain Controller and Kerberos Health

14. On a domain controller, filter `Windows Logs -> Security` for Event ID `4768` (Kerberos TGT request) and `4771` (Kerberos pre-authentication failure) for affected users. Expected result: Presence of Event 4771 or 4625 for Finance users points to an authentication issue, not a permissions issue.

15. Run the following to test whether a DC is reachable and responding:

    ```powershell
    nltest /sc_query:<YourDomainName>
    ```

    Expected result: `Flags: 30 HAS_IP  HAS_TIMESERV` and `The command completed successfully`. Failures here indicate a DC connectivity problem.

16. Run a quick replication health check:

    ```powershell
    repadmin /replsummary
    ```

    Expected result: No replication failures or errors. Failures here could explain stale group membership on some DCs.

### Phase 5: Check DFS Namespace (If Applicable)

17. Open `dfsmgmt.msc` or run:

    ```powershell
    Get-DfsnRoot | Where-Object { $_.Path -like '*Finance*' }
    ```

    Expected result: The Finance DFS namespace root is listed as `Online`.

18. Check DFS folder targets:

    ```powershell
    Get-DfsnFolderTarget -Path '\\domain\Finance\Shared' | Select-Object Path, TargetPath, State
    ```

    Expected result: All targets show `State : Online`. An `Offline` or missing target explains user failures.

19. Test DFS referral from a user device or jump host:

    ```powershell
    dfsutil /pktinfo
    ```

    Expected result: Finance DFS path resolves to a valid file server target.

## Verification

1. Ask two affected users at different parts of Finance (different site or OU if applicable) to access the shared drive simultaneously. Expected result: Drive opens without error and files are accessible.
2. Confirm no new Event ID `4625` entries appear on the file server or DC for Finance user accounts after the fix is applied. Expected result: Authentication failures have stopped.
3. Confirm the AD security group membership is visible in ADUC for all previously affected users. Expected result: Affected users are now members of the correct group(s).
4. Confirm share and NTFS permissions still match the expected baseline configuration. Expected result: No unexpected permission entries have been added or removed.
5. Confirm DFS namespace targets are `Online` if DFS shares are in scope. Expected result: All Finance DFS folder targets resolve correctly.
6. Update the incident ticket with the root cause category (Group membership / Share permissions / NTFS permissions / File server unavailability / DFS misconfiguration / Authentication failure) and mark resolved only after user confirmation. Expected result: Ticket reflects accurate root cause and verified resolution.

## Rollback

1. If a group membership addition was made and causes unintended access to other resources, remove the user from the group immediately in ADUC and document the change. Expected result: Access is reverted and security posture is restored.
2. If a share permission change was made and causes access issues for other teams, restore the previous permission from the backup ACL or documented baseline. Expected result: Other teams regain access with no unintended change to Finance permissions.
3. If a DFS target was brought online and it exposes stale or incorrect data, set it back to `Offline` in the DFS Management console and redirect users to the known-good target. Expected result: Users are on the correct data path.

## Notes

- Always confirm scope first. A single-user issue requires a different resolution path than a team-wide outage.
- AD group membership changes propagate at the Kerberos ticket lifetime interval (default 10 hours for TGT, 60 minutes for service tickets). Users may need to log off and back on, or run `klist purge` to pick up new memberships immediately.
- Do not modify share or NTFS permissions during business hours without change approval unless the outage is active and blocking Finance operations.
- If the file server is inaccessible (Step 9 fails), escalate as a P1 infrastructure incident rather than following this runbook further.
- Replication failures discovered in Step 16 should be raised as a separate AD health ticket even if the immediate Finance share issue is resolved another way.
