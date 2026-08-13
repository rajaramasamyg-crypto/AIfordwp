# Runbook: Cisco Issues

## Purpose
Use this runbook when one or more Cisco IP phones fail to register to the Cisco Unified Communications Manager (CUCM) cluster and users cannot place or receive calls. This runbook covers the most common causes: VLAN/DHCP/TFTP failure, CUCM service issues, ITL/CTL trust mismatch, and device configuration problems. Follow the phases in order to contain impact and restore registration.

## Prerequisites
- [ ] You have read access to the CUCM Administration web interface (`https://<CUCM-IP>/ccmadmin`).
- [ ] You have read access to the CUCM Serviceability web interface (`https://<CUCM-IP>/ccmservice`).
- [ ] You have read access to the CUCM Real-Time Monitoring Tool (RTMT).
- [ ] You can SSH to CUCM publisher and subscriber nodes.
- [ ] You can access a managed switch to verify voice VLAN port configuration.
- [ ] You have physical or remote access to at least one affected phone for reboot and trust reset.
- [ ] You have access to the DHCP server console (Windows DHCP or Cisco IOS) for the voice VLAN scope.
- [ ] You have access to the Incident Management Tool and can create or update tickets.

### Mandatory Information From End User (Do Not Start Without This)
- [ ] Extension number(s) and device name(s) of the affected phone(s) (example: `SEP1C1728F0A1B2`).
- [ ] Physical location of the affected phone(s) (floor, room, desk).
- [ ] What the phone display shows (example: `Registering…`, `Registration Rejected`, `No IP Address`, `Check Network Settings`).
- [ ] Time the issue was first noticed.
- [ ] Whether the issue affects a single phone, a group in one area, or phones across multiple sites.
- [ ] Whether any recent changes occurred: CUCM upgrade, certificate renewal, VLAN change, or phone move.
- [ ] Whether soft phone (Cisco Jabber) or other CUCM endpoints on the same site are working normally.

### Required Tools
- [ ] CUCM Administration (`https://<CUCM-IP>/ccmadmin`).
- [ ] CUCM Serviceability (`https://<CUCM-IP>/ccmservice`).
- [ ] CUCM Real-Time Monitoring Tool (RTMT) — for device registration status and trace collection.
- [ ] SSH client to CUCM publisher/subscriber (example: PuTTY or Windows Terminal).
- [ ] Managed switch CLI or GUI for voice VLAN and CDP neighbour verification.
- [ ] DHCP server console for voice VLAN scope health.

### Log Locations
- CUCM device registration status:
  - `CUCM Admin -> Device -> Phone` — search by device name or extension; `Status` column shows `Registered` / `Unregistered`.
- CUCM Serviceability traces:
  - `CUCM Serviceability -> Trace -> Trace Configuration` — enable `Cisco CallManager` and `Cisco TFTP` service traces at `Detailed` level.
  - Trace download: `CUCM Serviceability -> Trace -> Trace Collection Tool`.
- RTMT registration stats:
  - `RTMT -> Voice/Video -> Device -> Device Search` — filter by device pool or site.
- CUCM ITL/CTL status on phone:
  - Phone Settings button > `Admin Settings` > `Security Configuration` > `ITL File` or `CTL File`.
- Switch CLI:
  - `show cdp neighbors <interface> detail` — verify phone is seen on correct voice VLAN.
  - `show interfaces <interface> switchport` — confirm `Voice VLAN` is configured.

## Procedure

### Phase 1: Confirm Scope and Collect Evidence

1. Log into CUCM Administration. Go to `Device -> Phone` and search for an affected device by name or extension. Record the `Registration Status`, `IP Address`, `Last Known Active`, and `Device Pool`. Expected result: You have a documented baseline showing the current unregistered state.
2. In RTMT, run `Device -> Device Search`, filter by the affected device pool or site, and note the count of unregistered phones vs the expected baseline. Expected result: You can distinguish a single-phone fault from a site-wide or cluster-wide event.
3. Ask the user what message appears on the phone display and record it. Use the table below to guide the next phase:

   | Phone Display Message | Likely Cause | Go to Phase |
   |---|---|---|
   | No IP Address / Configuring IP | DHCP or VLAN issue | Phase 2 |
   | Registering… (no progress) | CUCM unreachable or service down | Phase 3 |
   | Registration Rejected | ITL/CTL trust mismatch or config error | Phase 4 |
   | Check Network Settings | Network/switch layer issue | Phase 2 |
   | Security Error / Trust List | ITL/CTL mismatch | Phase 4 |

### Phase 2: Validate Network, VLAN, DHCP, and TFTP

4. At the managed switch, confirm the port connected to the affected phone has the correct voice VLAN:

   ```
   show interfaces <interface> switchport
   show cdp neighbors <interface> detail
   ```

   Expected result: `Voice VLAN` matches the provisioned voice VLAN ID and CDP shows the correct phone model.

5. On the DHCP server, check the voice VLAN scope is active and has available addresses. Review the lease table for the affected phone MAC address:

   - Windows DHCP: `DHCP console -> Scope [voice VLAN subnet] -> Address Leases`.
   - Cisco IOS: `show ip dhcp binding | include <phone-MAC>`.

   Expected result: A valid lease exists for the phone's MAC address with correct gateway and Option 150 (TFTP server IP).

6. Verify DHCP Option 150 points to the correct CUCM TFTP server IP. Expected result: The TFTP address matches the CUCM publisher or a dedicated TFTP node.

7. From a device on the same VLAN as the phone, test TFTP server reachability:

   ```powershell
   Test-NetConnection -ComputerName <CUCM-TFTP-IP> -Port 69
   ```

   Expected result: Port reachable. If not, investigate firewall or routing between voice VLAN and CUCM.

8. From a device on the same VLAN, ping the CUCM publisher IP and test port 2000 (SCCP) or 5060/5061 (SIP):

   ```powershell
   Test-NetConnection -ComputerName <CUCM-Publisher-IP> -Port 2000
   Test-NetConnection -ComputerName <CUCM-Publisher-IP> -Port 5060
   ```

   Expected result: At least one port is reachable. Failure here indicates a network or firewall issue requiring network team escalation.

### Phase 3: Verify CUCM Services

9. Log into CUCM Serviceability (`https://<CUCM-IP>/ccmservice`). Go to `Tools -> Control Center – Feature Services`. Verify the following services are `Started`:
   - `Cisco CallManager`
   - `Cisco TFTP`
   - `Cisco CTIManager` (if applicable)

   Expected result: All listed services are in `Started` state.

10. Go to `Tools -> Control Center – Network Services`. Verify the following are `Started`:
    - `Cisco RIS Data Collector`
    - `Cisco Serviceability Reporter`

    Expected result: All listed services are in `Started` state.

11. If any required service is `Stopped`, start it from the Serviceability console. Record the service name and the time it was started. Expected result: Service transitions to `Started` within 2 minutes.

12. In CUCM Administration, go to `Device -> Phone`, search for an affected phone, and click `Reset`. Expected result: Phone requests a fresh TFTP configuration file after reset.

13. Monitor RTMT for 3 to 5 minutes after reset. Confirm the device changes from `Unregistered` to `Registered`. Expected result: Registration count recovers. If not, continue to Phase 4.

### Phase 4: Diagnose and Resolve ITL/CTL Trust Mismatch

14. On the affected phone, navigate to `Settings -> Admin Settings -> Security Configuration -> ITL File`. Check the issuer and the date. Expected result: ITL file issuer matches the current CUCM cluster certificate. If it shows an old or mismatched certificate, a trust reset is required.

15. Perform an ITL trust reset on the phone. The method depends on the phone model and CUCM security mode:

    - **Option A – Erase Phone Trust List (non-secure or mixed mode):**  
      On the phone, go to `Settings -> Security Configuration -> ITL File -> Erase` (or `Settings -> Admin Settings -> Unlock -> Reset Trust List`). Confirm the reset. Expected result: Phone downloads a fresh ITL from CUCM after restart.

    - **Option B – CTL Client update (if CTL is in use):**  
      Update the CTL file on CUCM and push to affected phones via `CUCM Admin -> Bulk Administration -> Phones -> Reset/Restart`. Expected result: Phones receive updated CTL and complete registration.

    - **Option C – Delete ITL via CUCM Admin (remote, if CUCM 10.5+):**  
      In `CUCM Admin -> Device -> Phone`, select affected phones, choose `Delete Trust List` from the actions menu. Expected result: Phone is forced to re-download a fresh trust list on next TFTP request.

16. After the trust reset, reboot the affected phone (unplug power or use `CUCM Admin -> Device -> Phone -> Reset`). Expected result: Phone powers on, requests TFTP config, downloads ITL/CTL, and completes registration.

17. Monitor RTMT or `Device -> Phone` in CUCM Admin for registration state change. Expected result: Device shows `Registered` within 3 minutes of reboot completing.

### Phase 5: Check CUCM Device Configuration

18. In CUCM Admin, go to `Device -> Phone`, open the affected phone record. Confirm:
    - `Device Pool` is correct for the phone's site.
    - `Phone Button Template` matches the phone model.
    - `SIP Profile` or `SCCP settings` are configured correctly.
    - Extension (Directory Number) is assigned and in the correct partition.

    Expected result: Configuration is consistent with working phones in the same device pool.

19. If configuration is missing or incorrect, correct it in CUCM Admin and click `Apply Config` (preferred over full reset). Expected result: Phone receives the updated configuration without a full firmware reload.

## Verification

1. In RTMT, confirm the previously unregistered phone(s) now show `Registered` state and the site registration count is back to the expected baseline. Expected result: No unexplained unregistered devices remain in the affected device pool.
2. Ask a user at an affected extension to dial an internal extension. Confirm the call connects and both parties can hear each other clearly. Expected result: Inbound and outbound calls succeed with no audio issues.
3. If the incident was site-wide, ask a user at a different extension in the same location to perform the same dial test. Expected result: Multiple phones in the same device pool are fully operational.
4. Confirm no new `Registration Rejected` events appear in CUCM traces for affected phones after the fix. Expected result: CUCM traces show clean registration sequences.
5. Update the incident ticket with the confirmed root cause (VLAN/DHCP, CUCM service, ITL/CTL trust, or device config) and close only after user confirmation. Expected result: Ticket reflects accurate root cause and verified resolution.

## Rollback

1. If an ITL/CTL reset causes further registration failures on additional phones, halt the reset process immediately and raise the scope to a cluster-wide trust incident. Expected result: The reset does not propagate instability to previously working phones.
2. If a CUCM service was restarted and causes call processing disruptions, monitor active call counts in RTMT and roll back to the previous service state if active calls are dropped unexpectedly. Expected result: Minimal disruption to in-progress calls.
3. If a phone configuration change causes the device to lose its extension, revert the change in CUCM Admin and click `Apply Config`. Expected result: Extension is restored without further disruption.

## Notes

- Always confirm whether the issue is isolated to one phone, one floor/site, or the entire cluster before starting remediation.
- ITL/CTL trust mismatches are the most common cause of `Registration Rejected` after CUCM certificate renewals or cluster upgrades.
- Phones retain their ITL even across power cycles. A DHCP, VLAN, or TFTP fix will not resolve a trust mismatch.
- `Apply Config` is preferred over `Reset` where possible — Reset causes a phone firmware reload and is more disruptive.
- If the CUCM `Cisco CallManager` service is stopped on multiple nodes simultaneously, treat as a P1 UC platform incident and escalate to the UC infrastructure team.
- Related RCA: `RCA-ip-phones-not-registered-cucm-2026-08-06.md`.
