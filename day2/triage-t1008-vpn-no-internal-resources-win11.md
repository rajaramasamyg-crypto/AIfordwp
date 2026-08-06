# Triage Summary — T-1008: VPN Connects but No Internal Resources Reachable After Win11 Upgrade

**Logged:** 2026-08-04  
**Analyst:** DWP Service Desk

---

## Summary
User's VPN connection appears to establish successfully, but no internal resources (file shares, intranet, internal applications) are reachable after a Windows 11 upgrade.

---

## Impact
- **Who:** Single end user (identity to confirm)
- **How many affected:** 1 reported; whether other users who upgraded to Win11 at the same time are experiencing the same — to confirm
- **Business urgency:** HIGH — user working remotely has no access to internal resources despite a successful VPN connection; effectively fully blocked from remote working

---

## Known Facts
- VPN client connects and shows as connected (no authentication error)
- Despite the VPN connection, internal resources are not reachable
- Issue started after a Windows 11 upgrade
- The VPN was working correctly on Windows 10 (prior to upgrade) — to confirm
- VPN client name and version — to confirm

---

## Missing Information to Gather
1. User's name, staff ID, and device asset tag or hostname
2. VPN client name and version (e.g. Cisco AnyConnect/Secure Client, GlobalProtect, Zscaler, SSTP, Always On VPN)
3. Whether any internal IP addresses or hostnames are reachable by ping/tracert after VPN connects (run `ping <internal-IP>` from cmd)
4. Whether the issue is DNS resolution only (can ping internal IP but not hostname) or also connectivity to known IPs
5. Whether the VPN adapter appears correctly in Network Connections / `ipconfig /all` — is it receiving an internal IP address
6. Whether split tunnelling is configured on the VPN profile and whether routing is correct post-upgrade
7. Whether Windows Firewall or a third-party firewall is blocking traffic over the VPN adapter (firewall rules can reset after an OS upgrade)
8. Whether the VPN client itself was reinstalled or updated as part of the Win11 upgrade process, or retained from Win10
9. Whether the `ipconfig /all` output shows the correct DNS servers being assigned by VPN (internal DNS servers, not the ISP's)
10. Whether running the VPN client as Administrator makes any difference (permission model can change post-upgrade)

---

## Likely Category
**Network / VPN — Post-Win11-upgrade routing or firewall issue**  
Sub-category: VPN tunnel established but traffic not routed correctly, or Windows Firewall blocking internal traffic over VPN adapter  
*(Common after an in-place OS upgrade: VPN client splits from the OS integration layer, Windows Firewall resets rules, or the VPN adapter's network category changes to "Public" which blocks inbound/outbound traffic)*

---

## Suggested First Diagnostic Step
Run `ipconfig /all` while connected to VPN and confirm the VPN adapter has received an internal IP address and that the DNS servers listed are internal (corporate) DNS servers, not the user's home ISP. If DNS servers are incorrect, the VPN is connected but not passing DNS configuration correctly — reinstalling the VPN client for Windows 11 compatibility is likely needed. Next, check Windows Defender Firewall: open `wf.msc` and confirm the VPN adapter's network profile is set to "Domain" or "Private" rather than "Public" — a "Public" classification will block most internal traffic. If the firewall profile is the issue, changing the network category via PowerShell (`Set-NetConnectionProfile`) or Group Policy should restore connectivity.
