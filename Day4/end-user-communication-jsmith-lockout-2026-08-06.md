# End-User Communications: jsmith Account Lockout — 2026-08-06

---

## Audience 1 — Non-Technical Executive

Your team's access and data are completely safe — no unauthorised access occurred.
On 6 August, one staff member's account was temporarily locked after too many
incorrect sign-in attempts on their computer. The helpdesk restored access within
22 minutes and the staff member was back online shortly after. We are enrolling
the user in a self-service recovery tool so future incidents of this type can be
resolved without helpdesk involvement. No action is required from you.

---

## Audience 2 — Affected End-User Team

Hi team,

Your accounts and data are safe — nothing was compromised.
Yesterday morning (6 August), a colleague's account got locked after their
computer registered too many incorrect password attempts in a row, which is a
normal security measure our systems apply automatically.
The helpdesk unlocked the account and everything was back to normal within
22 minutes.

**If this ever happens to you:** stop trying to sign in, and contact the IT
Helpdesk straight away — repeated attempts will keep the lock in place.

Contact: **IT Helpdesk** — raise a ticket or call the support line.

---

## Audience 3 — Engineer-to-Engineer Internal Note

**Incident:** Account lockout — FINBRIDGE\jsmith — 2026-08-06

### Root Cause
Repeated bad-password interactive logons (Logon Type 2) from DESKTOP-FB001
exceeded the domain account lockout threshold, triggering a 4740 lockout event
at 08:06:01. A subsequent unlock attempt (Logon Type 7) at 08:07:45 also failed
with "account locked out", confirming the lockout was already in effect. No
evidence of credential stuffing or external actor — all source events originate
from the single endpoint DESKTOP-FB001.

A parallel hypothesis (see `hypothesis-jsmith-lockout-pool-fin-02-analysis.md`)
flags that POOL-FIN-02 — which was NOT updated — had zero lockout events during
the same window, suggesting a possible update-triggered credential cache
invalidation or GPO refresh as a contributing factor. This was not confirmed
and remains an open investigative thread.

### Event Log Sequence (Windows Security Log, DESKTOP-FB001)
| Time     | Event ID | Details                                              |
|----------|----------|------------------------------------------------------|
| 08:02:14 | 4625     | Failed interactive logon (Type 2) — bad password     |
| 08:04:22 | 4625     | Failed interactive logon (Type 2) — bad password     |
| 08:06:01 | 4740     | Account locked out — caller: DESKTOP-FB001           |
| 08:07:45 | 4625     | Failed unlock attempt (Type 7) — account locked out  |
| 08:22:10 | 4722     | Account re-enabled by FINBRIDGE\helpdesk-admin       |
| 08:23:44 | 4624     | Successful interactive logon (Type 2) — confirmed    |

### Exact Action Taken
`FINBRIDGE\helpdesk-admin` re-enabled the account via Active Directory at
08:22:10 (Event ID 4722). No password reset was performed — credentials were
already valid once the lockout was cleared.

### Config Detail
- Lockout threshold: exceeded within two failed logon attempts across ~4 minutes
  (08:02:14 → 08:06:01), implying a low threshold (likely 3–5 bad attempts) or a
  cached/background retry source supplementing the two visible 4625 events.
- Lockout observation window and duration: not recorded in available logs — check
  Default Domain Policy / Fine-Grained Password Policy for jsmith's OU.

### Verification Step
Event ID 4624 at 08:23:44 (Logon Type 2, interactive) confirms successful logon
post-unlock. Total access interruption: ~21 minutes (08:02:14 → 08:23:44).

### Preventive Actions
1. **SSPR enrolment:** Enrol jsmith in Self-Service Password Reset (SSPR) via
   Azure AD / Entra ID so future lockouts can be self-recovered without helpdesk
   involvement.
2. **Investigate update link:** Cross-reference DESKTOP-FB001 update history with
   the 08:00–08:06 window; compare against POOL-FIN-02. If updated machines
   correlate with lockout events, escalate to GPO change review (see hypothesis
   doc).
3. **Alerting:** Add a detection rule for ≥2 Event ID 4625 events from the same
   source computer within 5 minutes targeting the same account — page on-call
   before lockout threshold is hit.
4. **Runbook:** If this pattern recurs (repeated 4625 Type 2 → 4740 from a single
   endpoint post-update), check for stale cached credentials, service accounts
   using jsmith's UPN, or a GPO-forced credential re-prompt before defaulting to
   user error as root cause.
