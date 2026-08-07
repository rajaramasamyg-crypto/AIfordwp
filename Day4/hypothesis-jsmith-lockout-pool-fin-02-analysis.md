# Hypothesis: Re-ranking Lockout Causes Using the POOL-FIN-02 Timing Clue

## Context
This analysis extends the RCA in `day3/RCA-jsmith-account-lockout-2026-08-06.md`.

## Key Discriminating Evidence
**POOL-FIN-02 was NOT updated and is completely unaffected by the lockout.**

This is a critical timing clue. If the lockout cause were independent of any system change (e.g., pure user error, a phone with saved credentials, a stale mapped drive), we would expect POOL-FIN-02 to have the same probability of being affected as any other machine. The fact that it was *not* updated AND had *zero* lockout events strongly suggests the cause is **co-incident with the update itself**.

---

## Re-ranking Logic: The POOL-FIN-02 Test

For each candidate cause, ask: *"Would this cause affect POOL-FIN-02 if it hadn't been updated?"*

- If **yes** → the cause is weakened by the POOL-FIN-02 evidence.
- If **no** → the cause is strengthened by the POOL-FIN-02 evidence.

---

## Re-ranked Candidate Causes

### Rank 1 — Update-triggered credential cache invalidation or authentication behavior change
**Most consistent with POOL-FIN-02 being unaffected.**

A patch or configuration pushed alongside the update (GPO, Windows Update, endpoint agent update) invalidated cached credentials or changed Kerberos/NTLM negotiation behavior on updated machines. POOL-FIN-02, having not received the update, retained working credentials and had no lockout. This cause *requires* the update to be present, which explains the clean split between updated and non-updated hosts.

---

### Rank 2 — Group Policy Object (GPO) change applied during the update window
**Strongly consistent with POOL-FIN-02 being unaffected.**

If a GPO was linked or refreshed as part of the update deployment, it may have applied a stricter lockout threshold or forced a credential re-prompt on affected machines. POOL-FIN-02, not in the update scope, would not have received the GPO refresh and would remain unaffected.

---

### Rank 3 — Service or scheduled task using stale credentials, re-triggered by machine restart post-update
**Partially consistent.**

If updated machines were rebooted as part of the update process, any background service or scheduled task using jsmith's old credentials would have re-authenticated on restart, hammering the account. POOL-FIN-02, not rebooted, would not have triggered this. However, this requires jsmith to already have stale credentials stored on multiple machines, which is less parsimonious.

---

### Rank 4 — Mobile device or secondary device with saved old password
**Weakened by POOL-FIN-02 evidence.**

A phone or tablet with a saved incorrect password continuously retrying in the background is a common lockout cause — but it is entirely independent of whether POOL-FIN-02 was updated. This cause does not explain why POOL-FIN-02 was clean.

---

### Rank 5 — Pure user error (manual mistyping at DESKTOP-FB001)
**Weakened by POOL-FIN-02 evidence.**

The event log supports repeated bad-password entries at DESKTOP-FB001, but user mistyping has no causal relationship to an update. POOL-FIN-02 being unaffected provides no explanatory value for this cause — it would simply be coincidence. This remains a plausible *proximate* cause (what the log shows) but is the weakest *root* cause given the broader context.

---

## Summary Table

| Rank | Cause | Explains POOL-FIN-02 unaffected? |
|------|-------|----------------------------------|
| 1 | Update-triggered credential/auth change | Yes — directly tied to update |
| 2 | GPO change pushed with update | Yes — directly tied to update |
| 3 | Stale service credentials re-triggered by reboot | Partially — tied to reboot, not update itself |
| 4 | Mobile/secondary device with saved wrong password | No — independent of update |
| 5 | Pure user error at DESKTOP-FB001 | No — independent of update |

---

## Recommended Next Steps
1. Confirm which machines received the update and cross-reference with lockout events — if the sets match, Rank 1/2 is confirmed.
2. Review GPO change history around 08:00–08:06 on 2026-08-06.
3. Check Windows Update / SCCM/Intune deployment logs for DESKTOP-FB001 vs POOL-FIN-02.
4. If no update-related evidence is found, pivot investigation to mapped drives and scheduled tasks on DESKTOP-FB001 (Rank 3).
