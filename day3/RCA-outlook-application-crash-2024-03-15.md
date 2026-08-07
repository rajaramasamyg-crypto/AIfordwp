# Root Cause Analysis (RCA): Outlook Application Crash

## Incident Summary
- Incident type: Application crash
- Affected application: Microsoft Outlook (OUTLOOK.EXE)
- Impacted component path: C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE
- Observation window: 2024-03-15 09:14:22 to 09:18:05
- Log sources reviewed:
  - Application Error (Event ID 1000)
  - Windows Error Reporting (Event ID 1001)
  - .NET Runtime (Event ID 1026)

## Event ID Explanations

### Event ID 1000 (Application Error)
Records a process crash and the faulting module/exception details.

- In this incident:
  - OUTLOOK.EXE crashed repeatedly.
  - Faulting module: KERNELBASE.dll
  - Exception code: 0xc0000005 (Access Violation)
  - Fault offset: 0x000000000003a4b2 (same across crashes)

### Event ID 1001 (Windows Error Reporting)
Records crash bucketing/telemetry generated for the fault.

- In this incident:
  - Event Name: APPCRASH
  - Fault bucket: 1847362910
  - Indicates WER grouped this as a known crash signature.

### Event ID 1026 (.NET Runtime)
Records unhandled exceptions in .NET runtime context.

- In this incident:
  - Process terminated due to unhandled exception.
  - Exception type: System.AccessViolationException.

## Reconstructed Sequence of Events (Plain English)
1. Outlook started at 09:13:44.
2. At 09:14:22, Outlook crashed (Event 1000) with access violation in KERNELBASE.dll.
3. At 09:17:45, Outlook crashed again with the same crash signature (same exception code and fault offset).
4. At 09:18:01, Windows Error Reporting logged APPCRASH bucket data (Event 1001).
5. At 09:18:05, .NET Runtime logged an unhandled System.AccessViolationException (Event 1026), confirming abnormal process termination.

## Technical Interpretation
- 0xc0000005 indicates an invalid memory access.
- KERNELBASE.dll is frequently the module where the crash is surfaced, not always the originating logic defect.
- Repetition of identical signature (same app version/module/offset/exception) suggests deterministic trigger rather than random transient OS instability.
- Presence of .NET unhandled AccessViolationException indicates likely managed/unmanaged boundary issue, commonly seen with COM add-ins, extension code, or corrupted runtime interaction during app initialization.

## Most Likely Cause
A deterministic Outlook crash path is being triggered during or shortly after launch, most likely by a problematic Outlook add-in or profile/data interaction that results in an access violation and unhandled .NET runtime exception.

## Evidence Supporting the Cause
- Multiple Event 1000 crashes for the same executable and version.
- Same faulting module, exception code, and fault offset across events.
- Event 1026 confirms unhandled AccessViolationException in the same process.
- Event 1001 APPCRASH bucket confirms recurring crash signature recognized by WER.

## Root Cause Statement
Outlook 16.0.17126.20132 repeatedly entered a consistent crash path (access violation 0xc0000005 at a fixed fault offset surfaced via KERNELBASE.dll), with .NET runtime reporting an unhandled AccessViolationException, most consistent with a faulty add-in or corrupted Outlook runtime/profile interaction during startup.

## Impact
- User unable to use Outlook reliably.
- At least two crash occurrences within approximately 4 minutes.
- Business impact: interruption to email/calendar workflows and probable support escalation.

## Immediate Containment Actions (Recommended)
1. Launch Outlook in safe mode (`outlook.exe /safe`) to bypass add-ins and confirm add-in involvement.
2. Disable all COM add-ins, then re-enable one at a time to isolate trigger.
3. Create a new Outlook profile and test behavior.
4. Run Office Quick Repair, then Online Repair if issue persists.
5. Apply latest Office and Windows updates.

## Corrective and Preventive Actions (Recommended)
1. Remove, update, or replace the identified faulty add-in.
2. Standardize approved add-in versions across endpoints.
3. Implement monitoring for recurring Event 1000 + 1026 signature combinations on Office processes.
4. Document a support runbook for Outlook crash triage:
   - safe mode test
   - add-in isolation
   - profile rebuild
   - Office repair
5. If unresolved after isolation, capture full crash dump and analyze stack in WinDbg for exact failing call path.

## Five Whys Analysis

### Problem
Outlook crashed repeatedly and terminated unexpectedly.

### Why 1
Why did Outlook terminate?
- Because it hit an access violation (0xc0000005).

### Why 2
Why was there an access violation?
- Because code in the Outlook execution path attempted invalid memory access, surfaced via KERNELBASE.dll.

### Why 3
Why did this become a full app crash?
- Because the exception was unhandled at runtime (.NET Event 1026).

### Why 4
Why did it recur?
- Because the signature was deterministic (same module/offset), indicating repeated triggering condition (startup workflow/add-in/profile interaction).

### Why 5
Why was the trigger not self-correcting?
- Because the underlying component state or extension path remained unchanged between launches.

## Confidence and Gaps
- Confidence level: Medium-High for crash classification and deterministic behavior.
- Remaining gaps:
  - No crash dump/stack trace to name exact offending function or add-in DLL.
  - No explicit add-in inventory from the affected endpoint.
  - No confirmation yet from safe mode/profile-rebuild testing.

## Timeline (Condensed)
- 09:13:44 - Outlook process start
- 09:14:22 - Event 1000: OUTLOOK.EXE crash, KERNELBASE.dll, 0xc0000005
- 09:17:45 - Event 1000: repeated identical crash signature
- 09:18:01 - Event 1001: WER APPCRASH bucket logged
- 09:18:05 - Event 1026: .NET unhandled System.AccessViolationException
