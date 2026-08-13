# DEX Signal – Startup Performance: Scope Facts
**Date:** 2026-08-12 | **Metric:** Median startup time (login to usable desktop)

---

**Affected device group:** Finance-Win11 — 215 devices.

**What changed and when:** A new security baseline configuration profile was deployed to Finance-Win11 only at **2026-08-04 02:00**. It added a startup compliance logging script and an additional Defender scan policy.

**Magnitude of the score drop:**
- Median startup time jumped from **17.5 s (score 84)** on 2026-08-03 to **41.3 s (score 61)** on 2026-08-04 — a rise of **23.8 seconds** and a score drop of **23 points**.
- The degraded state persisted across all three post-change days (scores 59–61), confirming it is not a one-day spike.

**Comparison group:** IT-Win11 (40 devices) was explicitly excluded from the config change. Its median startup time remained stable across the same period (16.8–17.1 s, scores 84–85), showing no corresponding degradation.

**Scope boundary confirmed:** The degradation is isolated entirely to Finance-Win11 and coincides exactly with the config deployment. IT-Win11, which received no change, is unaffected.

---

## Supporting Data

### Finance-Win11 (affected)

| Date | Median Startup (sec) | Score (0–100) | Note |
|---|---|---|---|
| 2026-08-01 | 18.2 | 82 | |
| 2026-08-02 | 17.9 | 83 | |
| 2026-08-03 | 17.5 | 84 | Last pre-change day |
| 2026-08-04 | 41.3 | 61 | Config deployed 02:00 |
| 2026-08-05 | 43.8 | 59 | |
| 2026-08-06 | 42.1 | 60 | |

### IT-Win11 (unaffected comparison group)

| Date | Median Startup (sec) | Score (0–100) |
|---|---|---|
| 2026-08-03 | 16.8 | 85 |
| 2026-08-04 | 17.1 | 84 |
| 2026-08-05 | 16.9 | 85 |
