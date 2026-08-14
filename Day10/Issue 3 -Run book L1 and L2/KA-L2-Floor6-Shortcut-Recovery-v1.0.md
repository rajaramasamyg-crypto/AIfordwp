# KA L2 - Floor 6 Shortcut Recovery (Technical)

Version: 1.0  
Date: 2026-08-14  
Audience: EUC/Intune engineers

## Scope
Incident where Floor 6 Legal users report vanished desktop shortcuts after Friday deployment of FinBridge Document Management app on Win11 Intune-managed devices.

## Trigger
Two or more tickets within same location/ring, with rollout timing correlation under 24 hours.

## Root-cause hypothesis order
1. Most likely: Win32 app deployment/install or uninstall command removed or replaced .lnk objects on Public Desktop/user Desktop.
2. Less likely: Profile/container corruption from Win11 migration.
3. Less likely: OneDrive KFM redirection anomaly.

## Evidence collection
Run on an affected endpoint:

```powershell
.\collect-floor6-shortcut-evidence-final.ps1 -DryRun
.\collect-floor6-shortcut-evidence-final.ps1 -LookbackHours 72
```

Collect and review:
1. summary.json
2. steps.json
3. deployment-log-hits.csv
4. IntuneManagementExtension.log
5. AgentExecutor.log
6. public-desktop-links.csv and user-desktop-links.csv

## Containment
1. Remove SG-INTUNE-APP-FLOOR6-LEGAL assignment from impacted app via Graph.
2. Force Intune sync on impacted managed devices.
3. Deploy controlled shortcut restore script.

## Verification criteria
1. No new shortcut-loss tickets for 4 hours.
2. At least 5 users confirm restored shortcut opens correct executable path.
3. Graph assignment list confirms Floor 6 target removed.
4. Post-fix evidence shows no fresh deletion patterns in IME logs.

## Escalation
Escalate to Packaging Engineering if install/uninstall command line includes wildcard file deletion or profile-scope cleanup beyond app path.
