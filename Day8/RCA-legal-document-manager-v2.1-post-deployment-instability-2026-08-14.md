# RCA — Legal Document Manager v2.1 Post-Deployment Instability

**Date:** 2026-08-14  
**Prepared by:** IT Operations / Endpoint Engineering  
**Incident type:** Post-deployment application instability  
**Affected estate:** Legal-Win11 SCCM collection

---

## 1. Executive Summary

A same-day deployment of Legal Document Manager v2.1 completed successfully to the Legal-Win11 collection at 09:44 (45/45 success, 0 deployment failures). Shortly after deployment, incident behavior captured in Source 1 aligns with the vendor-declared v2.1 known limitation: on devices with less than 8GB RAM, initial auto-save index creation can drive high disk I/O and intermittent crashes during the first hours after installation.

The issue is therefore assessed as **application behavior introduced by v2.1 under low-memory hardware conditions**, not an SCCM delivery failure.

---

## 2. Source Facts (Both Sources)

### Source 1 — Incident/Operations Evidence

From Source 1 (user/operations incident stream), the following facts are established:

1. User-impact symptoms appeared after the v2.1 rollout window.
2. Symptoms included instability consistent with intermittent application crashes and/or severe responsiveness degradation.
3. The affected user population mapped to the Legal Windows 11 estate (same scope as Legal-Win11 rollout target).

### Source 2 — SCCM + Vendor Evidence

1. Deployment started at **09:38:20** to Legal-Win11 collection (**45 devices**).
2. Deployment completed at **09:44:07** with **45/45 success, 0 failures**.
3. Previous stable version: **Document Manager v2.0**, stable for approximately 6 weeks.
4. New version: **Document Manager v2.1**.
5. Vendor release note (known limitation): devices with **<8GB RAM** may experience high disk I/O and intermittent crashes during initial auto-save index build.
6. Legal-Win11 hardware profile:
- 60% at 8GB RAM
- 40% at 4GB RAM

Derived scope math from Source 2:

- Total deployed devices: 45
- Estimated 4GB devices: 45 x 0.40 = **18 devices** (highest-risk cohort)
- Estimated 8GB devices: 45 x 0.60 = **27 devices** (lower-risk cohort)

---

## 3. Correlation Across Sources (Timing + Content)

This section correlates both sources directly, rather than treating them separately.

### 3.1 Timing Correlation

1. Source 2 confirms deployment completion at 09:44:07.
2. Vendor states the risk window is the first few hours after installation while index builds.
3. Source 1 incident pattern begins in the same post-installation time window.

Conclusion: the incident onset window in Source 1 is temporally consistent with v2.1 index-build behavior described in Source 2 vendor notes.

### 3.2 Content/Mechanism Correlation

1. Source 1 symptom pattern: intermittent crash/performance instability.
2. Source 2 mechanism: high disk I/O from auto-save indexing on <8GB endpoints.
3. Hardware mix includes a material low-memory cohort (18 estimated 4GB devices).

Conclusion: symptom type in Source 1 is mechanistically consistent with the vendor-known behavior in Source 2, especially in low-memory devices.

### 3.3 Scope Correlation

1. Source 1 affected population maps to Legal users/devices.
2. Source 2 rollout target is Legal-Win11 (45 devices).
3. No SCCM install failures were recorded, indicating the problem domain is post-install runtime behavior, not deployment delivery.

Conclusion: both sources point to the same population and event chain: successful rollout followed by environment-sensitive runtime instability.

---

## 4. Root Cause Statement

The primary root cause was rollout of Legal Document Manager v2.1, whose new auto-save indexing feature has a vendor-documented limitation on devices with under 8GB RAM. In the Legal-Win11 fleet, approximately 40% of deployed endpoints (about 18 devices) are 4GB RAM and therefore vulnerable to high disk I/O and intermittent crashes during the initial indexing window after installation.

---

## 5. Contributing Factors

1. **Hardware susceptibility in target collection:** A large low-memory cohort increased incident probability.
2. **Version delta risk:** v2.0 had a stable baseline; v2.1 introduced a new indexing behavior.
3. **No pre-deployment ring by memory profile:** 4GB endpoints were included in the same wave instead of a controlled pilot/exclusion path.
4. **Success metric gap:** SCCM success validated delivery, not post-install health/performance.

---

## 6. Why SCCM Reported Success While Users Saw Failures

SCCM install success means package execution/completion succeeded. It does not guarantee that newly introduced runtime features remain stable under endpoint-specific constraints after launch. Here, installation was healthy, but runtime behavior degraded on lower-memory devices during the first-hours indexing phase.

---

## 7. Five Whys

1. Why did users experience crashes after rollout?
- v2.1 introduced auto-save indexing that caused high disk I/O during initial index build.

2. Why did high disk I/O lead to instability for part of the fleet?
- A significant subset of endpoints has 4GB RAM, below the threshold in vendor known limitations.

3. Why were susceptible devices impacted at scale?
- Deployment targeted the full Legal-Win11 collection without memory-based segmentation.

4. Why was this not prevented by deployment validation?
- Validation focused on install completion (45/45) rather than post-install performance telemetry in the first-hours risk window.

5. Why was the rollout allowed without guardrails for this known limitation?
- Release governance did not enforce hardware-risk gating for vendor-known constraints before broad deployment.

---

## 8. Corrective and Preventive Actions

### Immediate (0-24h)

1. Pause further v2.1 expansion to any additional collections.
2. Identify and isolate affected 4GB endpoints in Legal-Win11.
3. Apply temporary mitigation:
- Roll back affected 4GB devices to v2.0 where business impact is high.
- If rollback is not feasible, stagger user launch windows and reduce concurrent load while initial index completes.
4. Issue user advisory to Legal: expected transient instability window and support path.

### Short-Term (1-7 days)

1. Build memory-based deployment rings:
- Ring A: >=8GB devices
- Ring B: <8GB devices with extra controls
2. Add post-install health checkpoint (2-4h after deployment): crash rate, disk queue length, app hang events.
3. Coordinate with vendor for mitigation guidance/patch timeline for low-memory endpoints.

### Long-Term (1-4 weeks)

1. Add release gate: any vendor note tied to hardware constraints requires segmented rollout plan.
2. Enhance deployment KPI set:
- Keep install success, add runtime stability KPI and early-life error budget.
3. Refresh Legal endpoint baseline to minimum 8GB RAM where possible.

---

## 9. Verification Criteria (Exit Conditions)

1. No sustained spike in app crash incidents after initial indexing window.
2. 4GB cohort has either rollback applied or validated stable mitigation in place.
3. Post-install telemetry dashboard shows normal disk I/O and app stability trend.
4. Change record updated with hardware-aware deployment control for future releases.

---

## 10. Final Assessment

Based on cross-source correlation, this incident is classified as a **known-vendor-limitation-triggered runtime instability** on a hardware-constrained subset of devices after an otherwise successful SCCM deployment. The evidence does not support SCCM delivery failure as the primary cause.
