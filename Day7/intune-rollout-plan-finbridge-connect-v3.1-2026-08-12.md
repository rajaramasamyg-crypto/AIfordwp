# FinBridge Connect v3.1 Intune Rollout Plan

Date: 2026-08-12  
Deployment window: 3 weeks (deadline 2026-09-02)  
Target: 10,000 Windows 11 endpoints

## 1. RING STRUCTURE

### Ring design summary

| Ring | Size | Duration | Population | Purpose | Intune assignment group type |
|---|---:|---|---|---|---|
| Ring 1 (Pilot) | 300 devices (3%) | 3 calendar days + 2-day monitoring gate | IT Engineering, Service Desk power users, App owners, 30 devices from each major business unit, and 30 devices from 4GB RAM cohort | Validate packaging, detection, install path, uninstall path, and top workflow stability in controlled real usage | Azure AD security group (Assigned, static membership) for tight control and known participants |
| Ring 2 (Early) | 2,700 devices (27%) | 5 calendar days + 2-day monitoring gate | Early adopters from all business units, includes Finance 500 users, plus mixed hardware sample including at-risk 4GB RAM devices | Validate scale behavior, policy timing, network impact, and business workflow reliability before broad deployment | Azure AD security group (Assigned, dynamic device/user rules per department + hardware tags) |
| Ring 3 (Broad) | 7,000 devices (70%) | 7 calendar days (staggered waves) | Remaining production users and shared endpoints | Complete enterprise rollout with controlled wave pacing and rapid exception handling | Azure AD security group (Assigned, dynamic membership by exclusion of Ring 1/Ring 2/exception groups) |

### Ring sequencing and calendar

- Day 1-3: Ring 1 deployment active.
- Day 4-5: Ring 1 monitoring gate and go/no-go decision.
- Day 6-10: Ring 2 deployment active (Finance included in this ring).
- Day 11-12: Ring 2 monitoring gate and go/no-go decision.
- Day 13-19: Ring 3 rollout in 3 sub-waves (35% / 35% / 30% of Ring 3 population).
- Day 20-21: Stabilization, exceptions, and closure reporting.

### Required Intune groups

- APP-FinBridge-v3_1-Ring1-Required
- APP-FinBridge-v3_1-Ring2-Required
- APP-FinBridge-v3_1-Ring3-Required
- APP-FinBridge-v3_1-Hold-Exclude
- APP-FinBridge-v3_1-4GB-AtRisk
- APP-FinBridge-v3_0-Rollback-Required

### App assignment intent

- FinBridge Connect v3.1: Required assignment to each active ring group.
- FinBridge Connect v3.1: Exclude APP-FinBridge-v3_1-Hold-Exclude and APP-FinBridge-v3_0-Rollback-Required.
- FinBridge Connect v3.0: Keep available in catalog; no required assignment unless rollback trigger occurs.

## 2. ADVANCE CRITERIA

### Ring 1 to Ring 2 advance gate (evaluate after minimum monitoring window)

- Install success rate: >= 97.0% across Ring 1 devices.
- Error rate threshold: <= 2.0% (Intune app install status = Failed).
- User-reported issue rate: <= 3.0 tickets per 100 users per day, averaged over the monitoring window.
- Monitoring period: minimum 48 continuous hours after Ring 1 assignment completes to 95% of targeted devices.
- Required evidence sources:
- Intune admin center Win32 app install status report for v3.1 (Success/Failed/Pending).
- Endpoint analytics crash signals and service desk ticket dashboard tagged FinBridge-v3.1.

### Ring 2 to Ring 3 advance gate

- Install success rate: >= 98.0% across Ring 2 devices.
- Error rate threshold: <= 1.5% (Failed) and <= 4.0% combined Failed + Not applicable due to requirement mismatch.
- User-reported issue rate: <= 2.0 tickets per 100 users per day, averaged over 72 hours.
- Monitoring period: minimum 72 continuous hours after Ring 2 assignment reaches 95% targeted devices.
- Required evidence sources:
- Intune app install status trend for prior 72 hours.
- Helpdesk ticket trend by category (login, transaction submit, launch failure).

### Hold condition (pause without full rollback)

- Trigger: Any single critical workflow defect affecting 5% to 15% of active users in current ring within 24 hours, while install success remains above advance minimum.
- Action: Pause next-ring assignment only; keep current ring active while hotfix triage runs.
- Example: 9% of Ring 2 users can launch the app but cannot submit payment batch approvals due to API timeout after upgrade. Hold Ring 3, isolate affected subgroup in APP-FinBridge-v3_1-Hold-Exclude, continue root cause analysis.

## 3. ROLLBACK TRIGGERS

### Trigger matrix and decision framework

| Trigger type | Measurable trigger | Decision owner | Decision window | Exact Intune rollback action |
|---|---|---|---|---|
| Install failure rate | > 8.0% Failed status in any active ring for 4 consecutive hours after assignment convergence | Deployment Manager (primary) + CAB duty manager (approver) | 60 minutes from alert | Remove active ring group from FinBridge v3.1 Required assignment; add same group to APP-FinBridge-v3_0-Rollback-Required (v3.0 Required). Keep v3.1 excluded for this group via APP-FinBridge-v3_0-Rollback-Required exclusion. |
| Application crash rate | >= 6 crashes per 100 active devices in 6-hour window, confirmed by endpoint crash telemetry for FinBridge executable | EUC Platform Lead + Application Owner | 90 minutes | Freeze further ring expansion immediately; move affected ring users to APP-FinBridge-v3_0-Rollback-Required; retain unaffected rings on v3.1 if below threshold. |
| Business-critical failure | Any confirmed inability to complete end-of-day finance settlement export for production finance users (single occurrence) | Incident Commander (Major Incident) | Immediate (<= 15 minutes) | Immediate rollback for Finance scope: unassign Finance group from v3.1 Required, assign Finance group to v3.0 Required, and place Finance in APP-FinBridge-v3_1-Hold-Exclude pending incident closure. |
| 4GB RAM at-risk failures | >= 12.0% Failed install or post-install unusable state in APP-FinBridge-v3_1-4GB-AtRisk during any 24-hour period | Endpoint Engineering Lead | 2 hours | Isolate at-risk cohort: remove APP-FinBridge-v3_1-4GB-AtRisk from v3.1 Required; assign that group to v3.0 Required; continue v3.1 rollout for non-4GB population. |

### Rollback execution detail (Intune)

1. Open FinBridge Connect v3.1 app assignment.
2. Remove Required assignment for the affected ring group(s).
3. Add affected group(s) to exclusion on v3.1 assignment to prevent immediate redeploy.
4. Open FinBridge Connect v3.0 app assignment.
5. Add affected group(s) as Required assignment.
6. Force sync guidance to impacted users (Company Portal sync or device sync action) and monitor reinstall completion in Intune.

## 4. FINANCE DEADLINE RESOLUTION

### Option A: Compress pilot to fit Finance into Ring 2 by end of week 1

- Minimum safe pilot duration: 72 hours active deployment plus 24-hour monitoring (4 days total).
- Risk introduced: lower confidence in low-frequency defects (for example month-end workflow edge cases) before Finance exposure.
- Compensating control: pre-stage a dedicated Finance rollback group and enforce hourly telemetry/ticket review during first 48 hours of Finance deployment.

### Option B: Separate Finance Ring 0 before main pilot

- Ring 0 structure: 500 Finance users deployed first over 2 days, then 48-hour monitoring.
- Ring 0 advance conditions:
- Install success >= 98.5%.
- Failed installs <= 1.0%.
- Finance critical workflow ticket rate <= 2 per 100 users per day.
- Ring 0 rollback plan:
- If failure > 5% for 2 consecutive hours, rollback Finance to v3.0 immediately.
- If end-of-day settlement export fails once, immediate Finance rollback regardless of percentage.

### Recommendation

Recommend Option A.

Justification:
- It meets the Finance end-of-week-1 requirement without exposing the entire rollout to a business-unit-first sequencing bias.
- A 4-day pilot still provides meaningful technical validation, especially because v3.0 had no major rollout issues and v3.1 uses a proven detection pattern (registry version string).
- It keeps standard enterprise change control intact (Ring 1 -> Ring 2 -> Ring 3), reducing governance complexity compared with a separate Ring 0 branch.
- Risk from compressed observation is mitigated by explicit compensating controls: hourly monitoring, pre-authorized Finance rollback assignment, and ring hold logic.

### Week 1 committed timeline with Option A

- Day 1-3: Ring 1 deployment.
- Day 4: accelerated monitoring decision gate.
- Day 5: start Ring 2 including all 500 Finance users.
- Day 6-7: Finance stabilization with elevated monitoring and rollback readiness.
