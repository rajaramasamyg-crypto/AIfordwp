# Analysis: DEX Startup-Performance Drop (Ranked Likely Causes)
**Date:** 2026-08-12  
**In-scope group:** Finance-Win11 (215 devices)  
**Comparison group:** IT-Win11 (40 devices, no config change)

## Evidence Anchor (Scope Facts)
- Finance-Win11 startup score dropped from 84 (2026-08-03) to 61 (2026-08-04), a 23-point drop, with startup time increasing from 17.5s to 41.3s (+23.8s).
- Change event: 2026-08-04 02:00 deployment of a new security baseline to Finance-Win11 only.
- IT-Win11 (not changed) remained stable at 84-85 with startup times around 16.8-17.1s.

## Ranked Most Likely Causes

### 1) Startup compliance logging script added by the new baseline is delaying logon initialization
**Why it fits the evidence**
- Timing is exact: degradation starts immediately after the 02:00 deployment window.
- Scope matches cleanly: only Finance-Win11 received the script and only Finance-Win11 degraded.
- Behavior pattern fits: persistent daily median increase suggests deterministic startup-stage overhead, not random transient noise.

**Fastest check to confirm/eliminate**
- On an affected Finance device, temporarily disable only the added startup script assignment for a pilot subset (or move one pilot device out of policy scope), force policy sync, reboot, and compare next startup duration against unchanged Finance peers.

### 2) Additional Defender scan policy in the baseline is triggering heavy scan activity during startup/logon
**Why it fits the evidence**
- Same exact change window and same exclusive scope as the observed regression.
- Defender policy changes commonly produce consistent boot/logon overhead when scan scope/scheduling intersects user sign-in period.
- Comparison group stability strongly supports a policy-linked effect instead of platform-wide service issues.

**Fastest check to confirm/eliminate**
- Compare Defender operational events and CPU/disk activity during first 5-10 minutes after boot on affected Finance devices versus IT-Win11 controls; then run a short pilot rollback of only the added Defender setting and re-measure startup medians.

### 3) Combined baseline interaction effect (script + Defender) causing compounded startup contention
**Why it fits the evidence**
- The baseline introduced multiple startup-relevant controls at once in the same deployment.
- Magnitude (+23.8s median) may exceed what one minor change alone causes, suggesting additive contention (disk/CPU at logon).
- Clean control group again supports a configuration-driven mechanism localized to changed scope.

**Fastest check to confirm/eliminate**
- Use an A/B pilot within Finance-Win11: group A removes script only, group B removes Defender addition only, group C removes both. Reboot and compare startup medians to identify whether one setting dominates or whether the combined effect is required.

## Prioritization Rationale
Ranking is weighted primarily by:
1. Exact temporal alignment with the 2026-08-04 02:00 config deployment.
2. Exclusive impact to the changed group (Finance-Win11).
3. Stable unaffected comparison group (IT-Win11) with no config change.
