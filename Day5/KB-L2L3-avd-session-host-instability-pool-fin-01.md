# L2/L3 Knowledge Base: AVD Session Host Instability - POOL-FIN-01

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

1. Place affected host in drain mode.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A.
- Action: Set Allow new sessions = No.
- Expected result: New sessions no longer land on SHFIN-01-A.

2. Safely remove active sessions from affected host.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Sessions.
- Action: Filter Session host = SHFIN-01-A, notify users, then Sign out active sessions.
- Expected result: Active sessions on SHFIN-01-A are zero.

3. Restart affected VM.
- Azure portal path: Azure portal > Virtual machines > SHFIN-01-A > Overview > Restart.
- Action: Perform controlled restart.
- Expected result: VM state transitions to Running; host later reports Available in AVD.

4. Re-check host status after reboot.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
- Action: Confirm SHFIN-01-A Status = Available while still drained.
- Expected result: Host is online and manageable without accepting new sessions.

5. Re-check crash signature after reboot before re-enabling.
- Log paths:
  - Event Viewer > Windows Logs > Application (Event ID 1000)
  - Event Viewer > Windows Logs > System (Event ID 9009)
  - Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational (Event IDs 21, 40)
- Action: Inspect only post-restart events.
- Expected result: No fresh 1000/9009 events and no immediate 21->40 disconnect pattern.

6. Validate pool capacity with healthy host comparison.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
- Action: Confirm SHFIN-02-A (or equivalent) remains Available with Allow new sessions = Yes.
- Expected result: Users can continue service on healthy host(s) even if SHFIN-01-A remains drained.

7. Controlled reintroduction (only if Step 5 is clean).
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A.
- Action: Set Allow new sessions = Yes and run one approved test sign-in.
- Expected result: Test session remains connected for at least 10 minutes.

8. Broader validation.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Sessions.
- Action: Run second test user sign-in and monitor.
- Expected result: No immediate disconnect and no recurrence of Event ID 1000/9009 signature.

## Verification
Confirm all items before closure:
- User validation: At least two test users can sign in and stay connected for 10+ minutes.
- AVD status check path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
  - SHFIN-01-A and SHFIN-02-A show stable status and expected session behavior.
- Event validation on SHFIN-01-A:
  - No new Event ID 1000 with dwm.exe + igdumd64.dll.
  - No new Event ID 9009 during test window.
  - No repeated Event ID 21 followed by Event ID 40 immediately after sign-in.
- Service desk validation:
  - No new user reports of repeated disconnects during validation window.

## Rollback
If change worsens impact, execute immediately:

1. Re-isolate affected host.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A.
- Action: Set Allow new sessions = No.
- Expected result: New sessions are prevented from landing on unstable host.

2. Remove users from unstable host.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Sessions.
- Action: Filter SHFIN-01-A and Sign out affected sessions.
- Expected result: User impact on unstable host stops.

3. Keep host out of rotation until engineering decision.
- Azure portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
- Action: Leave SHFIN-01-A drained if any new Event ID 1000 (dwm.exe/igdumd64.dll) appears post-restart.
- Expected result: Recurrence is contained to one host.

4. Recover capacity.
- Azure portal path: Azure portal > Virtual machines > (healthy AVD session host VM) > Start.
- Action: Start/add healthy host capacity as needed.
- Expected result: Pool capacity restored without reusing unstable host.

5. Escalate with evidence package.
- Escalation target: AVD platform/image engineering team.
- Include exact artifacts:
  - Hostname (SHFIN-01-A)
  - Restart timestamp
  - Event IDs 1000, 9009, 21, 40, 1 entries with timestamps
  - Comparison evidence from SHFIN-02-A (including Event ID 9011 and no Event ID 1000)
- Expected result: Engineering can decide image rollback, driver remediation, or host rebuild.

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
