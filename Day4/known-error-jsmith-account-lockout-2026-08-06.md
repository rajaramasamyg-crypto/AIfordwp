# Known-Error Record: User Account Lockout (jsmith) — 2026-08-06

**Knowledge Base Reference:** KE-ACCT-001
**Date Recorded:** 2026-08-07
**Source Incident:** jsmith account lockout — 2026-08-06

---

## Symptom
The user is unable to sign in or unlock their workstation and receives an "Account locked out" failure. In this incident, jsmith was locked out at DESKTOP-FB001 from 08:06:01 and could not regain access without helpdesk intervention.

## Cause
The account lockout threshold was exceeded after jsmith submitted incorrect credentials multiple times during interactive sign-in (logon type 2) at DESKTOP-FB001. Two bad-password failures (Event ID 4625 at 08:02:14 and 08:04:22) triggered the lockout policy, recorded as Event ID 4740 at 08:06:01.

## Scope
The affected account is a domain user account in the FINBRIDGE domain. The lockout originated from a single endpoint (DESKTOP-FB001) and prevented all interactive access until an administrator re-enabled the account.

## Workaround
A member of the helpdesk team must re-enable the account via an administrative action (Event ID 4722). In this incident, FINBRIDGE\helpdesk-admin re-enabled the account at 08:22:10, after which the user successfully logged on at 08:23:44.

## Permanent Fix
Investigate why the user repeatedly entered incorrect credentials — for example, a recently changed password not communicated to the user, a cached credential on a device, or a compromised account using automated attempts. Address the underlying credential issue and review whether the lockout threshold and observation window settings are appropriately tuned for the environment.

## How to Spot It
- **Event ID 4625** (logon type 2 or 7) with failure reason "Unknown username or bad password" or "Account locked out" on the source endpoint.
- **Event ID 4740** records the lockout itself; the Caller Computer Name field identifies the originating machine (DESKTOP-FB001 in this incident).
- **Event ID 4722** confirms helpdesk re-enablement; **Event ID 4624** (logon type 2) confirms successful restoration of access.
