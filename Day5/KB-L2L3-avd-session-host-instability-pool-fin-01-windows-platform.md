# L2/L3 Knowledge Base: AVD Session Host Instability - POOL-FIN-01 (Windows Platform)

v 1.0, 07/08/2026, status : Draft

## Background
Azure Virtual Desktop (AVD) host pool POOL-FIN-01 provides multi-user remote desktop access for Finance users. Each user session depends on a stable Windows session stack on the assigned host, including Desktop Window Manager (DWM).

Why this matters:
- If DWM on a session host crashes during or just after sign-in, users can authenticate but still get disconnected.
- This creates high ticket volume, blocks finance operations, and can look like a broad AVD outage unless host-level evidence is checked.
- Fast containment of the bad host preserves service by moving users to healthy hosts.

## Symptom
What the engineer observes:
- In Azure portal, one host in POOL-FIN-01 (SHFIN-01-A) shows repeated session churn.
- Users connect then disconnect within seconds to 1-2 minutes.
- Other host(s), especially SHFIN-02-A, remain stable in the same time window.

What users report:
- "Remote desktop logs in then immediately closes/disconnects."
- Reconnect attempts may briefly succeed, then disconnect again.
- Impact can be multiple users on one host, not just one user account.

## Root Cause
Specific technical cause:
- SHFIN-01-A entered a post-update crash loop where dwm.exe faulted in igdumd64.dll (access violation), causing DWM termination and immediate session disconnects.

Evidence that confirms root cause:
- Event ID 1000 (Application Error): Faulting application dwm.exe, faulting module igdumd64.dll, exception code 0xc0000005.
- Event ID 9009 (Desktop Window Manager): DWM exited unexpectedly.
- Event ID 21 then Event ID 40 (TerminalServices-LocalSessionManager): successful logon followed shortly by disconnect.
- Event ID 1 (Kernel-General): confirms SHFIN-01-A rebooted after overnight image update.
- Comparison check: SHFIN-02-A in same host pool shows Event ID 21 and healthy DWM startup Event ID 9011, with no matching Event ID 1000 during same window.

## Detection
Use this 3-minute, command-first workflow to confirm the incident signature before making changes.

### Detection Step 1: Set targets and time window
- Affected host: SHFIN-01-A in POOL-FIN-01.
- Same-pool comparison host: SHFIN-02-A in POOL-FIN-01.
- Unaffected control host: any known healthy session host in POOL-FIN-02.
- Time window: last 60 minutes (or ticket-reported impact window).

### Detection Step 2: Run fast PowerShell checks on SHFIN-01-A (affected host)
- Exact log locations queried:
  - Application log: Event Viewer > Windows Logs > Application
  - System log: Event Viewer > Windows Logs > System
  - TerminalServices log: Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational
- Run on SHFIN-01-A (locally or via remote PowerShell):

```powershell
$since = (Get-Date).AddHours(-1)

# Application log: Event ID 1000 must show dwm.exe faulting in igdumd64.dll
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$since} |
  Where-Object { $_.ProviderName -eq 'Application Error' -and $_.Message -match 'dwm.exe' -and $_.Message -match 'igdumd64.dll' } |
  Select-Object TimeCreated, Id, ProviderName, MachineName, Message

# System log: Event ID 9009 from Desktop Window Manager
Get-WinEvent -FilterHashtable @{LogName='System'; Id=9009; StartTime=$since} |
  Where-Object { $_.ProviderName -eq 'Desktop Window Manager' } |
  Select-Object TimeCreated, Id, ProviderName, MachineName, Message

# Session sequence: Event 21 and Event 40
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=@(21,40); StartTime=$since} |
  Select-Object TimeCreated, Id, ProviderName, MachineName, Message
```

- Required fields to confirm:
  - Event ID 1000 row contains: faulting application dwm.exe and faulting module igdumd64.dll
  - Event ID 9009 exists in same impact window
  - Event 21 is followed shortly by Event 40 for affected users

### Detection Step 3: Confirm healthy baseline on POOL-FIN-02 control host
- Required control signal:
  - Event ID 9011 on the POOL-FIN-02 control host (healthy DWM startup)
- Exact log location queried:
  - System log: Event Viewer > Windows Logs > System
- Run on a known healthy POOL-FIN-02 session host:

```powershell
$since = (Get-Date).AddHours(-1)

# Healthy control: DWM started successfully
Get-WinEvent -FilterHashtable @{LogName='System'; Id=9011; StartTime=$since} |
  Where-Object { $_.ProviderName -eq 'Desktop Window Manager' } |
  Select-Object TimeCreated, Id, ProviderName, MachineName, Message

# Control should not show affected signature
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$since} |
  Where-Object { $_.ProviderName -eq 'Application Error' -and $_.Message -match 'dwm.exe' -and $_.Message -match 'igdumd64.dll' } |
  Select-Object TimeCreated, Id, ProviderName, MachineName, Message
```

- Required comparison outcome:
  - Affected host (POOL-FIN-01) shows Event 1000 + Event 9009 + rapid 21 to 40 pattern.
  - Unaffected control (POOL-FIN-02) shows Event 9011 and no matching Event 1000 for dwm.exe/igdumd64.dll.

### Detection Step 4: Quick Azure-side extraction (optional but fast for central evidence)
- Use Azure CLI to locate AVD hosts quickly:

```bash
az desktopvirtualization hostpool list --resource-group <rg-name> --query "[].{Pool:name}" -o table
az desktopvirtualization session-host list --resource-group <rg-name> --host-pool-name POOL-FIN-01 --query "[].{Host:name,Status:status,AllowNew:allowNewSession,Sessions:sessions}" -o table
az desktopvirtualization session-host list --resource-group <rg-name> --host-pool-name POOL-FIN-02 --query "[].{Host:name,Status:status,AllowNew:allowNewSession,Sessions:sessions}" -o table
```

- Use Azure Monitor Logs query for event correlation (if diagnostics are enabled):

```bash
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "Event | where TimeGenerated > ago(1h) | where Computer in ('SHFIN-01-A','<POOL-FIN-02-CONTROL-HOST>') | where EventID in (1000,9009,9011,21,40) | project TimeGenerated, Computer, EventID, Source, RenderedDescription | order by TimeGenerated asc" \
  -o table
```

### Detection Decision (go/no-go)
Treat as this incident only if all are true:
- Application log has Event ID 1000 with dwm.exe faulting in igdumd64.dll on SHFIN-01-A.
- System log has Event ID 9009 in the same timeframe on SHFIN-01-A.
- TerminalServices log shows Event 21 followed quickly by Event 40 on SHFIN-01-A.
- POOL-FIN-02 control host shows Event ID 9011 and no matching Event ID 1000 signature.

If any one of the above is missing, stop and re-triage before applying this KB resolution.

## Resolution
Follow in order. Each step includes expected result.

0. Fast prerequisites (one time per shell).
- Azure CLI option path: install/use the AVD command group before running commands.

```bash
az extension add --name desktopvirtualization --upgrade
az account set --subscription <subscription-name-or-id>
```

1. Drain SHFIN-01-A immediately.
- Azure portal path/options: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Allow new sessions = No > Save.
- Azure CLI:

```bash
az desktopvirtualization session-host update \
  --resource-group <rg-avd> \
  --host-pool-name POOL-FIN-01 \
  --name SHFIN-01-A \
  --allow-new-session false
```

- Expected result: SHFIN-01-A no longer accepts new sessions.

2. Sign out active users on the affected host.
- Azure portal path/options: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Sessions > Filter: Session host = SHFIN-01-A > Select session(s) > Sign out.
- Azure CLI:

```bash
# List sessions on POOL-FIN-01 and identify IDs on SHFIN-01-A
az desktopvirtualization user-session list \
  --resource-group <rg-avd> \
  --host-pool-name POOL-FIN-01 \
  --query "[?contains(name, 'SHFIN-01-A')].{Session:name,User:userPrincipalName,State:sessionState}" \
  -o table

# Sign out one or more sessions (repeat per session ID)
az desktopvirtualization user-session delete \
  --resource-group <rg-avd> \
  --host-pool-name POOL-FIN-01 \
  --session-host-name SHFIN-01-A \
  --name <user-session-id> \
  --yes
```

- Expected result: Active session count on SHFIN-01-A is 0.

3. Restart the affected Windows VM.
- Azure portal path/options: Azure portal > Virtual machines > SHFIN-01-A > Overview > Restart > Confirm.
- Azure CLI:

```bash
az vm restart --resource-group <rg-vm> --name SHFIN-01-A
```

- Expected result: VM returns to Running, then AVD session host status returns to Available.

4. Confirm host registration and settings after restart.
- Azure portal path/options: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A.
- Verify options/fields:
  - Status = Available
  - Agent status = Available
  - Allow new sessions = No (still drained during validation)
- Azure CLI:

```bash
az desktopvirtualization session-host show \
  --resource-group <rg-avd> \
  --host-pool-name POOL-FIN-01 \
  --name SHFIN-01-A \
  --query "{Status:status,AllowNew:allowNewSession,Sessions:sessions,LastHeartbeat:lastHeartBeat}" \
  -o table
```

- Expected result: Host is healthy enough to test, but isolated from new user load.

5. Validate post-restart event signature before re-enable.
- Exact Windows log paths/options:
  - Event Viewer > Windows Logs > Application > Filter Current Log > Event IDs: 1000 > Source: Application Error
  - Event Viewer > Windows Logs > System > Filter Current Log > Event IDs: 9009 > Source: Desktop Window Manager
  - Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational > Filter Current Log > Event IDs: 21,40
- PowerShell quick check on SHFIN-01-A:

```powershell
$since = (Get-Date).AddMinutes(-15)

Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$since} |
  Where-Object { $_.Message -match 'dwm.exe' -and $_.Message -match 'igdumd64.dll' } |
  Select-Object TimeCreated, Id, ProviderName, Message

Get-WinEvent -FilterHashtable @{LogName='System'; Id=9009; StartTime=$since} |
  Select-Object TimeCreated, Id, ProviderName, Message

Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=@(21,40); StartTime=$since} |
  Select-Object TimeCreated, Id, Message
```

- Expected result: no fresh Event 1000 (dwm.exe/igdumd64.dll) and no fresh Event 9009 after reboot.

6. Controlled return to service.
- Azure portal path/options: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Allow new sessions = Yes > Save.
- Azure CLI:

```bash
az desktopvirtualization session-host update \
  --resource-group <rg-avd> \
  --host-pool-name POOL-FIN-01 \
  --name SHFIN-01-A \
  --allow-new-session true
```

- Expected result: host receives sessions and remains stable for test users.

## Verification
Confirm all items before closure:
- 1. Verify AVD host state and options.
  - Azure portal path/options: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
  - Confirm:
    - SHFIN-01-A Status = Available
    - SHFIN-01-A Allow new sessions = Yes
    - SHFIN-02-A remains Available (comparison)
  - Azure CLI:

```bash
az desktopvirtualization session-host list \
  --resource-group <rg-avd> \
  --host-pool-name POOL-FIN-01 \
  --query "[].{Host:name,Status:status,AllowNew:allowNewSession,Sessions:sessions}" \
  -o table
```

- 2. Verify no rapid reconnect/drop pattern.
  - Azure portal path/options: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Sessions.
  - Confirm sessions on SHFIN-01-A remain connected for 10+ minutes.
  - Azure CLI:

```bash
az desktopvirtualization user-session list \
  --resource-group <rg-avd> \
  --host-pool-name POOL-FIN-01 \
  --query "[].{Session:name,Host:sessionHostName,User:userPrincipalName,State:sessionState,Type:sessionType}" \
  -o table
```

- 3. Verify event logs on SHFIN-01-A remain clean.
  - Exact log paths/options:
    - Event Viewer > Windows Logs > Application > Filter Event ID 1000
    - Event Viewer > Windows Logs > System > Filter Event ID 9009
    - Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational > Filter Event IDs 21,40
  - PowerShell:

```powershell
$since = (Get-Date).AddMinutes(-30)

$e1000 = Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$since} |
  Where-Object { $_.Message -match 'dwm.exe' -and $_.Message -match 'igdumd64.dll' }

$e9009 = Get-WinEvent -FilterHashtable @{LogName='System'; Id=9009; StartTime=$since}

$ts = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=@(21,40); StartTime=$since}

[pscustomobject]@{
  Event1000Count = ($e1000 | Measure-Object).Count
  Event9009Count = ($e9009 | Measure-Object).Count
  TS2140Count = ($ts | Measure-Object).Count
}
```

- 4. Verify image/reference did not drift during remediation.
  - Azure portal path/options: Azure portal > Virtual machines > SHFIN-01-A > Settings > Properties > Image details.
  - Azure CLI:

```bash
az vm show \
  --resource-group <rg-vm> \
  --name SHFIN-01-A \
  --query "storageProfile.imageReference" \
  -o json
```

- 5. Closure criteria:
  - Two test users stay connected for 10+ minutes.
  - Event1000Count = 0 for dwm.exe/igdumd64.dll in verification window.
  - Event9009Count = 0 in verification window.
  - No new helpdesk reports during validation window.

## Rollback
If change worsens impact, execute immediately:

1. Immediately re-drain SHFIN-01-A.
- Azure portal path/options: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Allow new sessions = No > Save.
- Azure CLI:

```bash
az desktopvirtualization session-host update \
  --resource-group <rg-avd> \
  --host-pool-name POOL-FIN-01 \
  --name SHFIN-01-A \
  --allow-new-session false
```

- Expected result: no new users land on unstable host.

2. Force sign-out of users on SHFIN-01-A.
- Azure portal path/options: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Sessions > Filter: Session host = SHFIN-01-A > Sign out.
- Azure CLI:

```bash
az desktopvirtualization user-session list \
  --resource-group <rg-avd> \
  --host-pool-name POOL-FIN-01 \
  --query "[?contains(name, 'SHFIN-01-A')].name" -o tsv

az desktopvirtualization user-session delete \
  --resource-group <rg-avd> \
  --host-pool-name POOL-FIN-01 \
  --session-host-name SHFIN-01-A \
  --name <user-session-id> \
  --yes
```

- Expected result: active impact removed from affected host.

3. Keep host out of service and revert to known-good image path.
- Azure portal path/options:
  - Azure portal > Virtual machines > SHFIN-01-A > Settings > Properties > Image details (record current image version).
  - Azure portal > Azure Compute Gallery > <golden-image-definition> > Versions (identify known-good previous version).
  - Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > Add (or replace host) using known-good image version.
- Azure CLI (image check):

```bash
az vm show \
  --resource-group <rg-vm> \
  --name SHFIN-01-A \
  --query "storageProfile.imageReference" \
  -o json
```

- Expected result: rollback path is pinned to known-good image and bad host stays isolated.

4. Recover pool capacity from healthy hosts.
- Azure portal path/options: Azure portal > Virtual machines > <healthy-session-host> > Overview > Start.
- Azure CLI:

```bash
az vm start --resource-group <rg-vm> --name <healthy-session-host>
```

- Expected result: pool capacity restored without re-enabling SHFIN-01-A.

5. Post-rollback verification on unaffected control.
- Azure portal path/options: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts > <control-host>.
- Confirm control host remains healthy and available.
- PowerShell on control host:

```powershell
$since=(Get-Date).AddMinutes(-30)
Get-WinEvent -FilterHashtable @{LogName='System'; Id=9011; StartTime=$since} |
  Select-Object TimeCreated, Id, ProviderName, Message
```

- Expected result: Event 9011 present on POOL-FIN-02 control host; no widespread platform issue.

6. Escalate with complete evidence package.
- Include:
  - Host and pool: SHFIN-01-A, POOL-FIN-01
  - Event IDs: 1000, 9009, 21, 40, 1 with timestamps
  - Control evidence: POOL-FIN-02 Event 9011
  - Image reference before/after rollback decision
- Expected result: platform/image team can execute final rebuild or permanent image remediation.

## Preventive
Implement specific controls to prevent recurrence:

1. Pre-production image gate for graphics/session stack.
- Owner/Timing/Type: Image owner, before deployment, automated [REQUIRES: Azure Image Builder promotion gate + test harness].
- Signal and pass: 30-minute soak on validation host; pass only if Event IDs 1000 and 9009 counts are both 0 and reconnect success rate >= 98%.
- Fail criteria and action: any 1000/9009 event or reconnect success rate < 98% fails gate; release engineer blocks image promotion and opens P1 defect to DWP engineer.

2. Ring-based deployment with canary host and hold point.
- Owner/Timing/Type: Release engineer, during deployment, manual.
- Signal and pass: deploy to exactly 1 canary host/pool and hold 60 minutes; pass only if Event IDs 1000 and 9009 are 0 and 21->40 disconnect-pair count <= 2.
- Fail criteria and action: if thresholds breach, change manager freezes ring progression, keeps canary drained, and assigns DWP engineer for triage; Automation note: can be automated by rollout orchestration API gate.

3. Azure Monitor alerting for crash signature.
- Owner/Timing/Type: DWP engineer, during deployment and after deployment, automated [REQUIRES: Log Analytics workspace with AVD host logs + alert action group].
- Signal and pass: alert fires when same Computer has >= 3 Event ID 1000 (message contains dwm.exe and igdumd64.dll) in 10 minutes or Event ID 9009 >= 5 in 10 minutes.
- Fail criteria and action: if alert path test does not create Teams + ticket within 5 minutes, change manager marks monitoring control failed and halts active rollout until routing is fixed.

4. Automatic host quarantine workflow.
- Owner/Timing/Type: DWP engineer, during deployment and after deployment, automated [REQUIRES: Logic App or Azure Automation runbook + AVD RBAC].
- Signal and pass: on alert, workflow sets Allow new sessions = No within 3 minutes and posts host, pool, and evidence link to service desk queue.
- Fail criteria and action: if drain action not applied in 3 minutes, service desk lead performs manual drain immediately and escalates failed automation incident to release engineer.

5. Structured comparison check in incident template.
- Owner/Timing/Type: Service desk lead, after deployment, manual [REQUIRES: ITSM incident template field enforcement].
- Signal and pass: incident cannot move from "Investigating" to "Escalate" unless Host A/B status, Event ID counts (1000/9009/21/40), and update state are populated.
- Fail criteria and action: missing fields fail QA; ticket is returned to analyst within 15 minutes; Automation note: enforce mandatory fields and transition rule in ITSM workflow.

6. In-flight monitoring during rollout window.
- Owner/Timing/Type: Change manager, during deployment, manual.
- Signal and pass: every 15 minutes during rollout, review dashboard for per-host counts of Event IDs 1000 and 9009; pass if all hosts remain below 3 events/10 minutes.
- Fail criteria and action: threshold breach triggers immediate pause of rollout and incident bridge start; Automation note: replace manual checks with scheduled workbook query + alert.

7. Post-deployment validation before change closure.
- Owner/Timing/Type: Release engineer, after deployment, manual.
- Signal and pass: at +2 hours and +24 hours, validate host health report shows 0 hosts with >= 3 Event ID 1000 in 10 minutes and reconnect success rate >= 98% across pool.
- Fail criteria and action: if either checkpoint fails, keep change open, revert to containment runbook, and assign DWP engineer for remediation.

8. Rollback trigger threshold.
- Owner/Timing/Type: Change manager, during deployment, manual.
- Signal and pass: continue rollout only while <= 1 host/ring breaches Event ID 1000 >= 3 in 10 minutes; this is the rollback threshold.
- Fail criteria and action: if >= 2 hosts in a ring breach threshold, execute rollback to last known-good image within 30 minutes and block further promotion.

9. Knowledge update from incident learnings.
- Owner/Timing/Type: Service desk lead, after deployment, manual.
- Signal and pass: within 2 business days, runbook and L1 checklist are updated with this signature (1000 dwm.exe/igdumd64.dll + 9009) and CAB note links are attached.
- Fail criteria and action: if update not completed by SLA, change manager records process non-compliance and prevents closure of related problem record.

## Related
- Runbook used for this KB:
  - Day5/runbook-avd-session-host-instability-pool-fin-01.md
- RCA source:
  - Day4/RCA-avd-session-host-instability-pool-fin-01-2026-08-06.md
- End-user communication reference:
  - Day5/L1-self-service-remote-desktop-disconnects.md
- Similar investigation pattern:
  - Day4/RCA-cthompson-login-failure-resolved-2026-08-07-detailed.md
