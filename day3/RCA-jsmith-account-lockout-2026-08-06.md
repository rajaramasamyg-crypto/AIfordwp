# Root Cause Analysis (RCA): User Account Lockout - jsmith

## Incident Summary
- Incident type: User account lockout
- Affected account: jsmith
- Observation window: 08:02:14 to 08:23:44 (approximately 22 minutes)
- Primary host involved: DESKTOP-FB001
- Security context: Windows Security Event Log

## Event ID Explanations

### Event ID 4625 (Audit Failure)
Records a failed logon attempt. It includes the account name used, failure reason, source computer, and logon type.

- In this incident:
  - 08:02:14 and 08:04:22: failed interactive logons (logon type 2) with reason "Unknown username or bad password"
  - 08:07:45: failed unlock attempt (logon type 7) with reason "Account locked out"

### Event ID 4740 (Audit Failure in supplied data; commonly logged as account management event)
Records that an account was locked out after reaching the domain/account lockout threshold for bad password attempts.

- In this incident:
  - 08:06:01: account jsmith was locked out
  - Caller/source: DESKTOP-FB001

### Event ID 4722 (Audit Success)
Records that a user account was enabled (or re-enabled) by an administrator.

- In this incident:
  - 08:22:10: account jsmith enabled by FINBRIDGE\helpdesk-admin

### Event ID 4624 (Audit Success)
Records a successful logon.

- In this incident:
  - 08:23:44: successful interactive logon for jsmith (logon type 2)

## Reconstructed Sequence of Events (Plain English)
1. At 08:02:14, jsmith tried to sign in at DESKTOP-FB001 and entered an incorrect password (or otherwise invalid credentials), causing a failed interactive logon.
2. At 08:04:22, a second failed interactive sign-in for jsmith occurred from the same machine with the same bad-password reason.
3. By 08:06:01, the account lockout threshold had been reached and jsmith was locked out. The lockout event identifies DESKTOP-FB001 as the caller.
4. At 08:07:45, another attempt was made to unlock/sign in (logon type 7), but it failed because the account was already locked.
5. At 08:22:10, helpdesk admin FINBRIDGE\helpdesk-admin enabled/re-enabled the account.
6. At 08:23:44, jsmith successfully logged on interactively, confirming restoration of access and valid credentials.

## Most Likely Cause of Lockout
The most likely cause is repeated bad-password attempts from DESKTOP-FB001 during interactive sign-in/unlock, which triggered the account lockout policy threshold.

## Evidence Supporting the Cause
- Two explicit bad-password failures for jsmith occurred before lockout:
  - 08:02:14 (4625, type 2, bad password)
  - 08:04:22 (4625, type 2, bad password)
- The lockout event follows shortly after:
  - 08:06:01 (4740, account locked out)
- The caller/source in the lockout event is the same endpoint:
  - DESKTOP-FB001
- A later unlock attempt fails specifically due to lockout state:
  - 08:07:45 (4625, type 7, failure reason: account locked out)
- Administrative intervention is then required, after which logon succeeds:
  - 08:22:10 (4722 by helpdesk-admin)
  - 08:23:44 (4624 successful logon)

## Root Cause Statement
User jsmith entered incorrect credentials multiple times at DESKTOP-FB001 (interactive and unlock contexts), exceeding the configured account lockout threshold and causing a temporary lockout until helpdesk re-enabled the account.

## Five Whys Analysis

### Problem
jsmith was locked out and unable to access their machine.

### Why 1
Why was jsmith locked out?
- Because the account hit the lockout threshold after failed logon attempts.
- Evidence: 4740 at 08:06:01.

### Why 2
Why were there failed logon attempts?
- Because incorrect credentials were submitted for jsmith.
- Evidence: 4625 at 08:02:14 and 08:04:22 with "Unknown username or bad password".

### Why 3
Why were incorrect credentials repeatedly submitted?
- Most likely the user typed an incorrect password more than once during local sign-in/unlock activity on DESKTOP-FB001.
- Evidence: failures are interactive (type 2), then unlock context (type 7), all from DESKTOP-FB001.

### Why 4
Why did repeated incorrect attempts cause immediate loss of access?
- Because account lockout policy is configured to lock the account after a defined number of bad attempts (security control behavior).
- Evidence: transition from 4625 bad password events to 4740 lockout within minutes.

### Why 5
Why did resolution require helpdesk intervention?
- Because once lockout occurred, user self-recovery was insufficient and administrative re-enable/reset action was needed.
- Evidence: 4722 by FINBRIDGE\helpdesk-admin followed by 4624 successful logon.

## Contributing Factors
- Interactive local sign-in attempts under time pressure.
- No successful sign-in before threshold was reached.
- Dependence on helpdesk workflow to restore access.

## Impact
- User access interruption for approximately 17 minutes from lockout (08:06:01) to administrative recovery action (08:22:10), with successful access confirmed at 08:23:44.
- Productivity loss and support desk involvement.

## Corrective Actions Taken
- Helpdesk re-enabled account jsmith (4722).
- User subsequently authenticated successfully (4624).

## Preventive Actions (Recommended)
1. User guidance: verify keyboard layout/Caps Lock before repeated retries.
2. Encourage use of password manager or approved credential workflows to reduce entry errors.
3. Tune support process for faster lockout recovery during business hours.
4. Review lockout threshold/duration settings to balance security and usability.
5. Add alerting correlation: multiple 4625 events followed by 4740 from same host to trigger early support outreach.

## Confidence and Gaps
- Confidence level: High for sequence and immediate trigger (bad password attempts leading to lockout).
- Remaining gap: Raw logs do not prove the precise human behavior (typo vs stale cached credential vs keyboard/layout issue), only that bad credentials were presented from DESKTOP-FB001.

## Timeline (Condensed)
- 08:02:14 - 4625 bad password (interactive) from DESKTOP-FB001
- 08:04:22 - 4625 bad password (interactive) from DESKTOP-FB001
- 08:06:01 - 4740 account locked out, caller DESKTOP-FB001
- 08:07:45 - 4625 account locked out (unlock attempt)
- 08:22:10 - 4722 account enabled by FINBRIDGE\helpdesk-admin
- 08:23:44 - 4624 successful interactive logon for jsmith
