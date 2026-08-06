# Triage Summary — T-1003: AVD Session Disconnects After ~10 Minutes Then Reconnects

**Logged:** 2026-08-04  
**Analyst:** DWP Service Desk

---

## Summary
User's Azure Virtual Desktop (AVD) session is dropping and automatically reconnecting approximately every 10 minutes, disrupting work.

---

## Impact
- **Who:** Single end user (identity to confirm)
- **How many affected:** 1 reported; whether other AVD users in the same host pool or location are affected — to confirm
- **Business urgency:** MEDIUM — user can continue working but faces repeated interruption; impact increases for tasks requiring persistent connections (e.g. database sessions, long-running processes)

---

## Known Facts
- User is connecting via Azure Virtual Desktop (AVD)
- Sessions disconnect approximately every 10 minutes
- The session reconnects after the disconnect — this is not a complete loss of access
- Whether the ~10-minute interval is consistent or approximate — to confirm
- Whether in-progress work is lost on disconnect — to confirm

---

## Missing Information to Gather
1. User's name, staff ID, and the AVD host pool / workspace they are connecting to
2. Client device type (Windows, Mac, thin client) and AVD client version
3. Connection method — corporate network on-site, home broadband, VPN, or other
4. Whether the issue is new or has been occurring since the user first used AVD
5. Whether the disconnect interval is consistently ~10 minutes or varies
6. Whether any error or reconnection message is displayed at the point of disconnect
7. Whether other users on the same host pool are experiencing the same disconnect pattern
8. Whether recent changes were made to the AVD environment (session host updates, FSLogix changes, policy updates)
9. AVD session timeout / idle timeout policy settings in Azure — to check with the platform team
10. Whether the user's local network connection drops at the same time (check for Wi-Fi instability or VPN timeouts)

---

## Likely Category
**Remote Access / AVD — Session timeout or network-layer disconnect**  
Sub-category: Session host idle/disconnect timeout policy or intermediate network timeout  
*(~10-minute interval is a common sign of a session timeout policy or a NAT/firewall idle timeout on the network path)*

---

## Suggested First Diagnostic Step
Check the AVD host pool's RDP properties in the Azure portal for session timeout settings — specifically the "Disconnect session" and "End active session" idle timeout values. A value of 10 minutes on either would directly explain the behaviour. Also check whether a firewall or VPN concentrator on the network path has a shorter-than-expected idle session timeout that could be dropping the underlying TCP connection, prompting the AVD client to reconnect. Ask the user to monitor whether the disconnect occurs during active use or only during short periods of inactivity, as this will distinguish a policy timeout from a network-level issue.
