# Triage Summary — VDI Connectivity Issue

**Logged:** 2026-08-04  
**Analyst:** DWP Service Desk

---

## Summary
User unable to connect to VDI session from home; error message "cannot connect" displayed on attempt.

---

## Impact
- **Who:** Single end user (identity to confirm)
- **How many affected:** 1 reported; whether wider outage is affecting other remote users — to confirm
- **Business urgency:** User is fully blocked from working; urgency level subject to role/team — to confirm

---

## Known Facts
- VDI connection is failing today (2026-08-04)
- Last known good connection: Friday (2026-08-01)
- User is working from home on a Wi-Fi connection
- Error message presented: "cannot connect" (exact wording to confirm)
- No changes to setup mentioned by user over the weekend — to confirm

---

## Missing Information to Gather
1. Full exact error message text and any error code displayed
2. User's name, staff ID, and device asset tag or hostname
3. VDI client name and version (e.g. Citrix Workspace, VMware Horizon, AVD client)
4. Whether any Windows updates or software installs occurred since Friday
5. Whether the device is DWP-managed (corp build) or personal
6. Wi-Fi connection type — home router direct, mobile hotspot, or other
7. Whether corporate VPN is required separately and if it is connecting successfully
8. Whether other users in same team or location are reporting the same issue
9. Any changes to home network (new router, ISP maintenance) over the weekend
10. Whether the user has tried restarting the VDI client and/or the device

---

## Likely Category
**Remote Access / VDI Connectivity** — sub-category: Client-side or network authentication failure  
*(Infrastructure-side outage should be ruled out first)*

---

## Suggested First Diagnostic Step
Check the DWP service status dashboard or major incident board to rule out a platform-wide VDI outage before troubleshooting the individual device. If no active incident is listed, ask the user to fully restart the VDI client, confirm VPN connectivity (if applicable), and re-attempt the connection while capturing the exact error message and any on-screen error code.
