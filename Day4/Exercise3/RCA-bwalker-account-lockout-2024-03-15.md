# Root Cause Analysis (RCA): User Account Lockout - bwalker

## Incident Summary
- Incident type: User account lockout
- Affected account: FINBRIDGE\bwalker
- Observation window: 14:01:02 to 14:22:09 on 2024-03-15 (approximately 21 minutes)
- Primary host involved: Remote Desktop Services (RDP)
- Source IP: 10.10.5.44
- Security context: Windows Security Event Log, System Event Log

## Event ID Explanations

### Event ID 56 — TermDD (System Log, Error)
Records that the Terminal Server security layer detected a protocol stream error and disconnected the client.

- In this incident:
  - 14:01:02: The RDP security layer detected an error and forcibly disconnected client 10.10.5.44, consistent with a failed authentication exchange.

### Event ID 140 — RemoteDesktopServices-RdpCoreTS (System Log, Warning)
Records that an RDP connection attempt failed due to incorrect username or password.

- In this incident:
  - 14:01:02: Connection from 10.10.5.44 rejected because the username or password was incorrect.

### Event ID 4625 (Security Log, Audit Failure)
Records a failed logon attempt. Includes account name, failure reason, logon type, and source IP.

- In this incident:
  - 14:01:04: Failed RemoteInteractive logon (logon type 10) for bwalker — bad password, from 10.10.5.44.
  - 14:03:18: Second failed RemoteInteractive logon for bwalker — bad password, from 10.10.5.44.
  - 14:05:33: Third failed RemoteInteractive logon for bwalker — bad password, from 10.10.5.44.

### Event ID 4740 (Security Log, Audit Failure)
Records that an account was locked out after reaching the domain lockout threshold for bad password attempts.

- In this incident:
  - 14:05:34: Account FINBRIDGE\bwalker was locked out. Caller/source: 10.10.5.44.

### Event ID 131 — RemoteDesktopServices-RdpCoreTS (System Log, Information)
Records that the RDP server accepted a new TCP connection from a client.

- In this incident:
  - 14:22:07: Server accepted a new TCP connection from 10.10.5.44:52341, indicating a fresh RDP session attempt after the lockout period.

### Event ID 4624 (Security Log, Audit Success)
Records a successful logon.

- In this incident:
  - 14:22:09: Successful RemoteInteractive logon (logon type 10) for bwalker from 10.10.5.44, confirming account access was restored and correct credentials were used.

## Reconstructed Sequence of Events (Plain English)
1. At 14:01:02, bwalker attempted to connect via RDP from 10.10.5.44. The RDP security layer rejected the authentication and disconnected the client (Event IDs 56 and 140).
2. At 14:01:04, a failed logon (type 10 — RemoteInteractive) was recorded for bwalker due to an incorrect password submitted from 10.10.5.44 (Event ID 4625).
3. At 14:03:18, a second failed RemoteInteractive logon attempt was recorded for bwalker from the same source IP (Event ID 4625).
4. At 14:05:33, a third failed RemoteInteractive logon attempt was recorded for bwalker from 10.10.5.44 (Event ID 4625).
5. At 14:05:34, the account lockout threshold was reached and FINBRIDGE\bwalker was locked out (Event ID 4740).
6. At 14:22:07, a new TCP connection was accepted from 10.10.5.44 on a new source port (52341), indicating the account had been unlocked and bwalker was retrying (Event ID 131).
7. At 14:22:09, bwalker successfully authenticated via RDP from 10.10.5.44 (Event ID 4624), confirming access was restored.

## Most Likely Cause of Lockout
Three consecutive failed RDP logon attempts from IP 10.10.5.44 using incorrect credentials for FINBRIDGE\bwalker exceeded the configured account lockout threshold, resulting in a temporary lockout.

## Evidence Supporting the Cause
- Three explicit bad-password failures for bwalker occurred before lockout, all via RemoteInteractive (logon type 10) from the same source IP:
  - 14:01:04 (4625, type 10, bad password, 10.10.5.44)
  - 14:03:18 (4625, type 10, bad password, 10.10.5.44)
  - 14:05:33 (4625, type 10, bad password, 10.10.5.44)
- The lockout event immediately follows the third failure:
  - 14:05:34 (4740, account locked out, caller 10.10.5.44)
- RDP-layer events corroborate the failed authentication at the protocol level:
  - 14:01:02 (Event ID 56 — TermDD disconnect; Event ID 140 — bad credentials)
- A successful logon ~17 minutes later confirms the account was unlocked and valid credentials were used:
  - 14:22:07 (Event ID 131 — new TCP connection accepted)
  - 14:22:09 (Event ID 4624 — successful logon)

## Root Cause Statement
FINBRIDGE\bwalker entered incorrect credentials three consecutive times during RDP logon attempts from 10.10.5.44, exceeding the domain account lockout threshold and causing a temporary lockout that required administrative or self-service resolution before access was restored.

## Five Whys Analysis

### Problem
bwalker was locked out and unable to connect via RDP.

### Why 1
Why was bwalker locked out?
- Because the account hit the lockout threshold after three consecutive failed logon attempts.
- Evidence: Event ID 4740 at 14:05:34.

### Why 2
Why were there three failed logon attempts?
- Because incorrect credentials were submitted for bwalker on each attempt.
- Evidence: Event ID 4625 at 14:01:04, 14:03:18, and 14:05:33, all with failure reason "Unknown username or bad password".

### Why 3
Why were incorrect credentials repeatedly submitted?
- Most likely bwalker was using an outdated or mistyped password when attempting to RDP from 10.10.5.44.
- Evidence: All three failures originate from the same source IP (10.10.5.44) with logon type 10 (RemoteInteractive), indicating deliberate repeated attempts rather than a scripted or cached credential replay.

### Why 4
Why did repeated incorrect attempts cause immediate loss of access?
- Because the domain account lockout policy is configured to lock the account after a defined number of bad-password attempts (a standard security control).
- Evidence: Transition from three consecutive 4625 bad-password events to a 4740 lockout event within approximately 4.5 minutes.

### Why 5
Why was the account successfully accessed approximately 17 minutes later?
- Because the account lockout was resolved (likely through an administrative unlock or a lockout duration expiry) and bwalker used the correct credentials on the subsequent attempt.
- Evidence: Event ID 131 (new connection accepted) followed immediately by Event ID 4624 (successful logon) at 14:22:07–14:22:09.

## Contributing Factors
- RDP access from a remote client (10.10.5.44) where password manager or cached credentials may have been stale or incorrect.
- No evidence of a successful logon between the three failure events and lockout, indicating no opportunity for self-correction before threshold was reached.
- Lockout policy threshold set at three attempts — offers security protection but limits user tolerance for credential errors.
- A ~17-minute gap between lockout and recovery suggests dependency on an administrative or automated unlock process.
