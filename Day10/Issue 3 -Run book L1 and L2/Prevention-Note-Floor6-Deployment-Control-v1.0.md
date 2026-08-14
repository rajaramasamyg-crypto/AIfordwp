# Prevention Note - Floor 6 Deployment Control

Version: 1.0  
Date: 2026-08-14  
Owner: Change and Release Management

Specific process change: Mandatory Shortcut Impact Gate (SIG) for all Intune Win32 app deployments.

Control definition:
1. Every Win32 package must include a pre/post desktop inventory check in pilot validation:
   - Count and list .lnk files in Public Desktop and user Desktop before deployment.
   - Re-check 30 minutes after deployment and compare automatically.
2. Change record cannot move from pilot to broad rollout unless the SIG report shows zero unexpected shortcut deletions.
3. SIG report (CSV diff + approver sign-off) must be attached to CAB evidence.

Why this would have prevented Monday chaos:
- It would have surfaced shortcut deletion behavior during pilot, blocking broad Floor 6 rollout until packaging was corrected.
