# Prevention Note - Floor 6 Login Incident

Version: 1.0  
Date: 2026-08-14  
Owner: EUC/VDI Operations

## Specific Process Change
Implement a named control: Post-Patch Broker Health Gate (PPBHG).

## Control Definition
No VDI maintenance change on a delivery controller can be closed until an automated gate confirms all three checks:
1. Citrix Broker Service is running and stable for 10 minutes.
2. Target desktop pool registration is above the agreed minimum threshold.
3. Three-user synthetic login test passes.

## Evidence Requirement
Attach the PPBHG output (timestamped health report + test results) to the change record before handover to business hours.

## Why this would have caught Monday risk
If PPBHG had been mandatory, the controller would not have been handed back while unstable, and the mass login failures would have been detected and corrected before users arrived.
