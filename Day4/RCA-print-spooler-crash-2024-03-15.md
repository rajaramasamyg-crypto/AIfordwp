# Root Cause Analysis (RCA): Print Spooler Service Crash

## Incident Summary
- Incident type: Windows service crash (repeated)
- Affected service: Print Spooler (spoolsv.exe)
- Observation window: 2024-03-15 10:01:14 to 10:03:50 (approximately 2 minutes 36 seconds)
- Log sources reviewed:
  - System Log (Service Control Manager — Event IDs 7034, 7031, 7023, 7038)

## Event ID Explanations

### Event ID 7034 (Error — Service Control Manager)
Records that a service terminated unexpectedly. The count increments with each recurrence.

- In this incident:
  - 10:01:14: Print Spooler terminated unexpectedly (1st occurrence)
  - 10:01:45: Print Spooler terminated unexpectedly (2nd occurrence)
  - 10:02:16: Print Spooler terminated unexpectedly (3rd occurrence)

### Event ID 7031 (Error — Service Control Manager)
Records an unexpected service termination and logs the configured recovery/corrective action.

- In this incident:
  - 10:02:47: Print Spooler terminated for the 4th time; SCM scheduled a service restart in 60,000 milliseconds (60 seconds) as its configured corrective action.

### Event ID 7023 (Error — Service Control Manager)
Records a service termination with a specific Windows error code.

- In this incident:
  - 10:03:49: Print Spooler terminated with error "The specified module could not be found."
  - This indicates the service could not load a required DLL or driver module at startup.

### Event ID 7038 (Error — Service Control Manager)
Records a failure to log on as the configured service account.

- In this incident:
  - 10:03:50: Print Spooler was unable to log on as NT AUTHORITY\SYSTEM.
  - Failure reason: "Logon failure: the user has not been granted the requested logon type at this computer."
  - This indicates the SYSTEM account has been explicitly denied the logon rights required to run the service.

## Reconstructed Sequence of Events (Plain English)
1. At 10:01:14, the Print Spooler service crashed and was restarted by the Service Control Manager (1st crash).
2. At 10:01:45, it crashed again immediately after restart (2nd crash).
3. At 10:02:16, it crashed a third time (3rd crash).
4. At 10:02:47, it crashed a fourth time (4th crash); SCM triggered its configured recovery action — restart after 60 seconds.
5. At 10:03:49, on the next startup attempt, the service terminated with a specific error: a required DLL or driver module could not be found.
6. At 10:03:50, SCM also reported that the Print Spooler could not log on as NT AUTHORITY\SYSTEM, indicating a local security policy is blocking the required logon type for the account.

## Technical Interpretation
- The progression from generic crash (7034/7031) to specific error (7023) indicates the spooler was restarting and getting further in the startup sequence before failing, ultimately exposing the underlying fault.
- **"The specified module could not be found" (7023)** is a strong indicator that a DLL or print driver referenced by the spooler's configuration is missing from disk. Common causes:
  - A corrupt or partially removed print driver left a broken reference in the registry under `HKLM\SYSTEM\CurrentControlSet\Control\Print\Environments`.
  - Security hardening or a patch (e.g., PrintNightmare mitigations) removed a driver DLL from `C:\Windows\System32\spool\drivers\`.
  - Manual or automated cleanup removed a driver file while its registry entries remained.
- **"Logon failure: the user has not been granted the requested logon type" (7038) for NT AUTHORITY\SYSTEM** is abnormal. SYSTEM should always be able to log on locally. This indicates:
  - The "Log on as a service" or "Log on locally" right has been removed from SYSTEM via Local Security Policy or Group Policy.
  - A recent GPO change, security baseline deployment, or misconfiguration is the likely trigger.
- Both failures (7023 and 7038) occurring together suggest two compounding issues: a missing module and a policy restriction on the service account.

## Most Likely Cause
A missing or orphaned print driver DLL is preventing the Print Spooler from loading, compounded by a Local Security Policy or Group Policy change that incorrectly denies NT AUTHORITY\SYSTEM the logon right required to run the service.

## Evidence Supporting the Cause
- Four rapid consecutive crashes (7034/7031) indicate the service cannot stay running even momentarily, consistent with a startup-time failure.
- Event 7023 explicitly reports "The specified module could not be found," directly identifying a missing DLL/driver as the crash cause.
- Event 7038 for NT AUTHORITY\SYSTEM logon failure is abnormal — SYSTEM does not normally require explicit logon grants — pointing to a deliberate or accidental policy change.
- The two final events (7023 at 10:03:49 and 7038 at 10:03:50) occur within one second of each other during the same restart attempt, confirming they are both contributing to the same failure event.

## Root Cause Statement
The Print Spooler service is failing to start due to a missing or unresolvable DLL/driver module referenced in its configuration, and is additionally blocked from starting by a Local Security Policy or Group Policy setting that has removed the required logon right from NT AUTHORITY\SYSTEM.

## Five Whys Analysis

### Problem
The Print Spooler service is crashing continuously and cannot remain running.

### Why 1
Why does the Print Spooler crash on every start attempt?
- Because it cannot find a required module (DLL or print driver) at startup.
- Evidence: Event 7023 — "The specified module could not be found."

### Why 2
Why is the required module missing?
- Because a print driver was removed from disk (or never correctly installed) while its registry reference was not cleaned up, or a security patch/hardening process deleted a driver file from `C:\Windows\System32\spool\drivers\`.
- Evidence: The "module not found" error targets spooler's driver-loading phase; no corresponding successful start is recorded.

### Why 3
Why was the driver file removed without cleaning up its registry entry?
- Because the removal was performed by an automated process (patch, GPO, or security tool) that did not complete the full cleanup, or a manual uninstallation was incomplete.
- Evidence: No preceding scheduled maintenance or controlled uninstall events visible in the provided log window; rapid onset suggests an uncontrolled change.

### Why 4
Why is NT AUTHORITY\SYSTEM also being denied logon rights (Event 7038)?
- Because a Local Security Policy or Group Policy Object was applied that modified the "Log on as a service" or "Allow log on locally" user rights assignment, inadvertently removing SYSTEM.
- Evidence: Event 7038 explicitly states the logon type was not granted to NT AUTHORITY\SYSTEM — a right that is typically implicit for SYSTEM and only absent after deliberate policy change.

### Why 5
Why was the policy change not validated before deployment?
- Likely because the impact of modifying SYSTEM logon rights on core Windows services was not assessed during the change review process, or the policy was deployed without testing on a representative machine.
- Evidence: Inferred from the absence of any preceding corrective action and the abrupt nature of the failure.

## Recommended Actions
1. **Immediate:** Clear the print queue and identify the orphaned driver reference:
   - Open `printmanagement.msc` and remove all installed drivers that have no associated physical printer.
   - Alternatively, from an elevated command prompt: `Get-PrinterDriver | Remove-PrinterDriver` (PowerShell) to remove unused drivers.
2. **Immediate:** Review and restore SYSTEM logon rights:
   - Open `secpol.msc` → Local Policies → User Rights Assignment.
   - Verify NT AUTHORITY\SYSTEM appears in "Log on as a service" and "Allow log on locally."
   - If controlled by GPO, identify the policy via `gpresult /h report.html` and correct the misconfiguration in Group Policy Management.
3. **Short-term:** Clean the spooler driver store to remove broken references:
   - Stop the Print Spooler, clear `C:\Windows\System32\spool\PRINTERS\`, and restart the service.
   - Run `pnputil /enum-drivers` to identify driver packages and remove orphaned ones.
4. **Long-term:** Implement a change review step that validates the impact of User Rights Assignment modifications on core Windows services before GPO deployment.
