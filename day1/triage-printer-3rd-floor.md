# Triage Summary — 3rd Floor Shared Printer Offline

**Logged:** 2026-08-04  
**Analyst:** DWP Service Desk

---

## Summary
Shared printer on 3rd floor is non-functional; whole team affected with a hard deadline of a 2pm client meeting.

---

## Impact
- **Who:** Entire team based on 3rd floor (team name and size — to confirm)
- **How many affected:** Multiple users; exact headcount — to confirm
- **Business urgency:** HIGH — client-facing meeting at 2pm today creates a firm time constraint; time of report and time remaining before meeting — to confirm

---

## Known Facts
- The shared/networked printer on the 3rd floor is not working
- Issue is described as affecting the whole team, not a single user
- A client meeting is scheduled at 2pm today (2026-08-04) with an implied need for print capability
- Printer is described as "the big one" — likely a shared floor-level MFD (multifunction device) — to confirm

---

## Missing Information to Gather
1. Printer make, model, and asset tag or hostname/queue name
2. Exact failure symptom — offline in print queue, paper jam, error light/code on device, no power, or jobs stuck in queue
3. Any error message shown on the printer control panel or in the Windows print queue
4. When the printer was last working successfully
5. Whether any jobs are currently stuck in the print queue
6. Whether the printer appears online or offline in Windows (check via `\\SERVER\PrinterName` or Devices and Printers)
7. Whether this follows any recent changes — e.g. driver update, Windows update, network change, physical move of device
8. Whether the printer is network-connected (wired/wireless) or USB-connected to a print server
9. Name, staff ID, and contact details of the reporter
10. Whether an alternative printer is available on a nearby floor as a short-term workaround for the 2pm meeting

---

## Likely Category
**Printer / Peripherals — Shared Device Offline**  
Sub-category: Floor-level MFD failure affecting multiple users  
*(Could be hardware fault, print spooler issue, network/queue issue, or driver problem — to confirm after initial checks)*

---

## Suggested First Diagnostic Step
Physically check the printer for any error codes, warning lights, paper jams, or power issues. Simultaneously, check the Windows print queue on an affected user's machine to see if jobs are stuck or if the device shows as offline. If the queue is the issue, restart the Print Spooler service. Given the 2pm deadline, identify and communicate an alternative printing location to the team immediately while the fault is being diagnosed.
