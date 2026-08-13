# Runbook: MS Teams Issues

## Purpose
Use this runbook when users report that calls are failing, audio is broken, or calling features are unavailable in the Microsoft Teams desktop or mobile client. This covers the most common causes: Microsoft 365 service health, Teams Phone licensing, dial plan and calling policy, network/media path issues, and client-side problems. Follow the phases in order to identify and restore calling functionality.

## Prerequisites
- [ ] You have access to Microsoft Teams Admin Center (`https://admin.teams.microsoft.com`).
- [ ] You have access to Microsoft 365 Admin Center (`https://admin.microsoft.com`).
- [ ] You have access to Microsoft 365 Service Health Dashboard (`https://admin.microsoft.com -> Health -> Service health`).
- [ ] You have read access to Azure Active Directory / Entra ID for user account and licence checks.
- [ ] You have access to the Call Quality Dashboard (`https://cqd.teams.microsoft.com`) if call quality investigation is required.
- [ ] You have access to the Incident Management Tool and can create or update tickets.

### Mandatory Information From End User (Do Not Start Without This)
- [ ] Affected user's full UPN (example: `jbrown@organisation.gov.uk`).
- [ ] Description of the exact problem: cannot make calls, cannot receive calls, no audio, calls drop, or Teams Phone tab missing.
- [ ] Time the issue was first noticed.
- [ ] Teams client type: desktop app (Windows/Mac), mobile (iOS/Android), or web browser.
- [ ] Client version number (`Teams -> Help -> About` or `Settings -> About`).
- [ ] Whether the issue affects only this user or multiple users.
- [ ] Whether the user can join Teams meetings (to distinguish calling-specific from general Teams issues).
- [ ] Whether the user recently had a licence change, account move, or device rebuild.
- [ ] Network environment: corporate network, VPN, or home broadband.

### Required Tools
- [ ] Microsoft Teams Admin Center (`https://admin.teams.microsoft.com`).
- [ ] Microsoft 365 Admin Center and Service Health Dashboard.
- [ ] Azure AD / Microsoft Entra ID admin portal.
- [ ] Call Quality Dashboard (`https://cqd.teams.microsoft.com`) — for quality/drop investigations.
- [ ] Teams client on a test account for comparison.
- [ ] PowerShell with the `MicrosoftTeams` module installed (for policy and licence checks).

### Log Locations
- Microsoft 365 service health alerts:
  - `Microsoft 365 Admin Center -> Health -> Service health -> Microsoft Teams`.
- Teams Admin Center — user calling configuration:
  - `Teams Admin Center -> Users -> Manage users -> [user] -> Policies tab`.
  - `Teams Admin Center -> Users -> Manage users -> [user] -> Account tab` (for phone number assignment).
- Teams Admin Center — call history:
  - `Teams Admin Center -> Analytics & reports -> Usage reports -> PSTN and SMS usage`.
  - `Teams Admin Center -> Users -> Manage users -> [user] -> Call history tab`.
- Call Quality Dashboard:
  - `https://cqd.teams.microsoft.com -> Summary Reports or Detailed Reports` — filter by UPN, date, and call type.
- Azure AD sign-in logs:
  - `Azure AD / Entra ID -> Users -> [user] -> Sign-in logs` — for authentication failures.

## Procedure

### Phase 1: Check Microsoft 365 Service Health

1. Open the Microsoft 365 Service Health Dashboard (`https://admin.microsoft.com -> Health -> Service health`). Check for any active advisories or incidents under `Microsoft Teams` and `Exchange Online`. Expected result: Either a known Microsoft-side incident is found (escalate to Microsoft and inform users of ETA), or service health is green and investigation continues.
2. If a Microsoft-side incident is active, copy the incident ID (example: `TM123456`), note the estimated resolution time, and update the user ticket with this information. Expected result: Ticket reflects the external dependency and users are informed without further internal investigation until Microsoft resolves it.
3. If service health is green, continue to Phase 2.

### Phase 2: Validate Teams Phone Licence

4. In Microsoft 365 Admin Center, open the affected user's account and check assigned licences. Confirm the user has:
   - A base Microsoft 365 or Office 365 licence that includes Teams.
   - A **Teams Phone** (or Teams Phone Standard) add-on licence — required for PSTN calling.
   - A **Calling Plan** or **Operator Connect** or **Direct Routing** licence for PSTN connectivity (if PSTN calls are affected).

   Or use PowerShell:

   ```powershell
   Connect-MicrosoftTeams
   Get-CsOnlineUser -Identity "jbrown@organisation.gov.uk" | Select-Object DisplayName, EnterpriseVoiceEnabled, HostedVoiceMail, AssignedPlan
   ```

   Expected result: `EnterpriseVoiceEnabled` is `True` for a user who should have PSTN calling. If `False`, proceed to Step 5.

5. If `EnterpriseVoiceEnabled` is `False`, enable voice for the user:

   ```powershell
   Set-CsPhoneNumberAssignment -Identity "jbrown@organisation.gov.uk" -EnterpriseVoiceEnabled $true
   ```

   Wait 5 minutes and ask the user to sign out of Teams and back in, then test calling. Expected result: Calling features become available after re-sign-in.

6. Confirm a phone number is assigned to the user:

   ```powershell
   Get-CsPhoneNumberAssignment -AssignedPstnTargetId "jbrown@organisation.gov.uk"
   ```

   Expected result: A phone number in E.164 format (example: `+441234567890`) is assigned. If not, assign the number from the available pool.

### Phase 3: Validate Teams Calling Policies

7. In Teams Admin Center, open `Users -> Manage users -> [user] -> Policies tab`. Confirm:
   - `Calling policy` — the assigned policy must allow `Make private calls` and `PSTN calling` as required.
   - `Dial plan` — the user's dial plan must match their site/region.
   - `Voice routing policy` (Direct Routing only) — must be assigned if the organisation uses Direct Routing.

   Or use PowerShell:

   ```powershell
   Get-CsUserPolicyAssignment -Identity "jbrown@organisation.gov.uk" | Select-Object PolicyType, PolicyName
   ```

   Expected result: The user has a Calling policy that matches the expected configuration for their site.

8. Compare the affected user's policy assignments against a working user in the same team or site. Expected result: Policies are identical. Any difference in calling policy or dial plan is a likely root cause.

9. If the calling policy is incorrect, assign the correct policy:

   ```powershell
   Grant-CsTeamsCallingPolicy -Identity "jbrown@organisation.gov.uk" -PolicyName "AllowCalling"
   ```

   Wait 5 minutes and ask the user to re-test. Expected result: Calling features become available after policy propagation.

### Phase 4: Validate Direct Routing Configuration (If Applicable)

10. If the organisation uses Direct Routing (on-premises SBC), check SBC health in Teams Admin Center under `Voice -> Direct Routing`. Confirm:
    - SBC status is `Active`.
    - The SBC FQDN and port are reachable from the Microsoft network (Teams performs an SBC connectivity check).

    Expected result: SBC shows `Active` with no connectivity failures.

11. Check the voice routing policy and PSTN usage assigned to the user has a valid route to the SBC:

    ```powershell
    Get-CsOnlineVoiceRoutingPolicy -Identity "DepartmentCallingPolicy" | Select-Object OnlinePstnUsages
    Get-CsOnlinePstnUsage
    Get-CsOnlineVoiceRoute | Select-Object Name, NumberPattern, OnlinePstnGatewayList
    ```

    Expected result: The PSTN usage chain resolves to an active SBC and the number pattern matches the dialled number format.

12. If the SBC shows a connectivity error, escalate to the UC/telephony infrastructure team. This is outside Teams Admin Center control. Expected result: The infrastructure team investigates SBC certificate, SIP trunk, and firewall state.

### Phase 5: Check Teams Client and Network

13. Ask the user to sign out of the Teams client completely and sign back in. Expected result: A fresh sign-in clears stale token and policy cache. Re-test calling after sign-in.

14. Ask the user to check their Teams client version (`Help -> About` or `Settings -> About -> Version`). If the client is more than two months out of date, ask the user to update through the Microsoft Store or company software portal. Expected result: An up-to-date client eliminates known calling bugs from older versions.

15. Ask the user to open Teams in a web browser (`https://teams.microsoft.com`) and attempt the same call. Expected result: If the call works in the browser but not the desktop app, the issue is client-specific. Ask the user to use the web version as a workaround while the desktop app is investigated further.

16. Check whether the issue is network-related by asking the user to run the Teams network assessment tool or perform a quick test in Teams Settings:

    - `Teams -> Settings -> Devices` — confirm the correct microphone and speaker are selected and not blocked by Windows privacy settings.
    - `Teams -> Settings -> App Permissions` — confirm microphone access is allowed.

    Expected result: The correct audio devices are selected and access is not blocked.

17. If the user is on a corporate network or VPN, confirm the following network ports and URLs are reachable for Teams media:

    | Protocol | Port Range | Purpose |
    |---|---|---|
    | UDP | 3478–3481 | Teams media (preferred) |
    | TCP | 443 | Teams signalling and fallback media |
    | TCP | 80 | Teams signalling |

    Expected result: UDP 3478–3481 is not blocked. If blocked, Teams calls fall back to TCP/443 and quality may degrade but calls should still work.

18. If audio is present for meetings but absent for PSTN calls specifically, the issue is PSTN-side (licence, number assignment, Direct Routing, or Calling Plan). Return to Phase 2 or 4.

### Phase 6: Call Quality Investigation (Dropped or Poor Quality Calls)

19. Open the Call Quality Dashboard (`https://cqd.teams.microsoft.com`). Filter by the affected user's UPN and the date range of the reported issue. Check:
    - `Call drop rate` — high rates indicate signalling or network issues.
    - `Poor call rate` — high rates indicate media path or codec issues.
    - `Jitter`, `Packet loss`, `Round trip time` — values above 30ms jitter, 10% packet loss, or 500ms RTT indicate network degradation.

    Expected result: The CQD report either confirms a specific network path issue or shows the call quality is within acceptable bounds.

20. If CQD shows high packet loss or jitter, share the report with the network team for investigation of the path between the user device and Microsoft's media edge. Expected result: Network team can identify congested links or QoS misconfigurations.

## Verification

1. Ask the affected user to make a test call to an internal Teams extension and confirm it connects and both parties can hear each other. Expected result: Call connects successfully and audio is clear in both directions.
2. If PSTN calling was affected, ask the user to dial an external number and confirm the call completes. Expected result: PSTN call connects and audio is clear.
3. Ask the user to receive a test inbound call. Expected result: The Teams client rings and the call is answered successfully.
4. In Teams Admin Center under `Users -> [user] -> Call history`, confirm recent successful call entries appear. Expected result: Call records show completed calls in the expected direction.
5. If `EnterpriseVoiceEnabled` was changed, re-run the PowerShell check to confirm `True`. Expected result: Voice is enabled and the change is persistent.
6. Update the incident ticket with the confirmed root cause (service health, licence, policy, Direct Routing, client, or network) and close only after user confirmation of restored calling. Expected result: Ticket reflects accurate root cause and verified resolution.

## Rollback

1. If a calling policy change causes additional users to lose access to calling features, revert to the previous policy assignment immediately:

   ```powershell
   Grant-CsTeamsCallingPolicy -Identity "jbrown@organisation.gov.uk" -PolicyName "<PreviousPolicyName>"
   ```

   Expected result: Calling features are restored within 5 minutes of policy reversion.

2. If a phone number assignment is changed and an incorrect number is assigned, reassign the correct number from the pool via Teams Admin Center or PowerShell and notify the affected user. Expected result: The correct number is restored and the user can receive calls on the expected number.

3. If `EnterpriseVoiceEnabled` was modified and this causes unintended downstream effects (for example, removed voicemail), restore the previous user configuration from the change record. Expected result: Voicemail and calling features are both present.

## Notes

- Always check Microsoft 365 Service Health first. A Microsoft-side incident invalidates all other investigation steps until resolved.
- Licence and policy changes can take up to 5 to 15 minutes to fully propagate. Ask users to sign out of Teams and back in after any policy or licence change to force a refresh.
- If the user can join Teams meetings but cannot make PSTN calls, the issue is almost always licensing (missing Teams Phone or Calling Plan) or Direct Routing/PSTN connectivity — not a general Teams problem.
- If the issue affects all users in a department simultaneously after a policy change, investigate whether a bulk policy assignment was applied incorrectly.
- If the SBC is involved (Direct Routing), coordinate with the telephony infrastructure team. Teams Admin Center cannot fix SBC-side failures.
- For persistent audio quality issues on a specific network segment, escalate to the network team with a CQD export as evidence.
- Related RCAs: `RCA-teams-common-area-phones-not-registered-2026-08-06.md`, `RCA-teams-video-conferencing-devices-not-registered-2026-08-06.md`.
