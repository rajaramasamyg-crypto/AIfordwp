# Triage Summary — T-1006: 'Everything Is Slow' After Windows 11 Upgrade Two Days Ago

**Logged:** 2026-08-04  
**Analyst:** DWP Service Desk

---

## Summary
User reports general system slowness across all applications since upgrading to Windows 11 two days ago (approximately 2026-08-02).

---

## Impact
- **Who:** Single end user (identity to confirm)
- **How many affected:** 1 reported; whether other users who upgraded at the same time are experiencing the same — to confirm
- **Business urgency:** MEDIUM — user can still work but performance degradation is impacting productivity; urgency increases if role is time-sensitive

---

## Known Facts
- User upgraded to Windows 11 approximately two days ago (circa 2026-08-02)
- Slowness is described as affecting "everything" — not isolated to one application
- The timing directly correlates with the Windows 11 upgrade
- Whether the upgrade was performed in-place (over Win10) or was a fresh build — to confirm
- Whether the device meets the official Windows 11 hardware requirements (TPM 2.0, 4-core CPU, 4 GB RAM minimum) — to confirm

---

## Missing Information to Gather
1. User's name, staff ID, and device asset tag or hostname
2. Device make, model, CPU, RAM, and storage type (HDD vs SSD)
3. Whether the upgrade was in-place from Windows 10 or a clean Windows 11 build
4. Whether the device meets Windows 11 minimum specifications (and ideally the recommended spec: 8 GB RAM, SSD)
5. Task Manager readings — CPU, Memory, Disk, and GPU usage at idle and under load
6. Whether disk usage in Task Manager sits consistently at or near 100% (common on older HDDs post-upgrade)
7. Whether Windows 11 post-upgrade tasks are still running in the background (e.g. Windows Update, delivery optimisation, indexing)
8. Whether anti-virus / EDR software is performing a full post-upgrade scan
9. Whether all Windows 11 drivers (especially chipset, GPU, and storage) have been installed — in-place upgrades sometimes retain outdated Win10 drivers
10. Whether the slowness affects login/boot time specifically, or is constant throughout the session

---

## Likely Category
**Endpoint Performance / Windows 11 — Post-upgrade resource contention or hardware compatibility**  
Sub-category: Background post-upgrade processes, outdated drivers, or underpowered hardware  
*(Whole-system slowness immediately post-upgrade is most commonly caused by: Windows Update/indexing background tasks still completing, an HDD at 100% disk utilisation, or a driver not yet updated for Win11)*

---

## Suggested First Diagnostic Step
Open Task Manager (Ctrl+Shift+Esc) and check the Performance tab — note CPU, Memory, and Disk usage. If Disk is consistently at or near 100%, this is the primary suspect, particularly on a traditional HDD. Check the Processes tab for the heaviest consumers: `MsMpEng.exe` (Defender scanning), `SearchIndexer.exe` (indexing), `TiWorker.exe` (Windows Update), and `WaasMedicSvc.exe` are all common culprits immediately after an upgrade. If the device is an older machine with a spinning HDD, the upgrade itself may have exposed a hardware bottleneck — escalate for hardware review if background tasks complete but slowness persists.
