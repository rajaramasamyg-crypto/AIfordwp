# Triage Summary — T-1004: Company App Fails to Install from Company Portal, Error 0x87D1041C

**Logged:** 2026-08-04  
**Analyst:** DWP Service Desk

---

## Summary
A user is unable to install a company application via Microsoft Intune Company Portal; the installation fails with error code 0x87D1041C.

---

## Impact
- **Who:** Single end user (identity to confirm)
- **How many affected:** 1 reported; whether the error affects all users attempting to install this specific app — to confirm
- **Business urgency:** MEDIUM — user cannot access a required application; urgency depends on how critical the app is to the user's role — to confirm

---

## Known Facts
- Installation is being attempted via Microsoft Intune Company Portal
- Error code returned: **0x87D1041C** — this is a well-known Intune error indicating the application was not detected after installation completed, or a dependency/prerequisite is missing
- The specific application failing — to confirm
- Whether the app has ever installed successfully on this device — to confirm

---

## Missing Information to Gather
1. User's name, staff ID, and device asset tag or hostname
2. Name and version of the application that is failing to install
3. Whether the app has installed successfully before on this device, or is being installed for the first time
4. Whether the device is Azure AD joined or hybrid-joined and fully enrolled in Intune
5. Whether the Intune Management Extension (IME) is present and running on the device (check Services for `Microsoft Intune Management Extension`)
6. IME log location: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` — any errors logged around the time of the failed install
7. Whether the device has a valid, current Intune check-in (last sync time in Company Portal)
8. Whether any prerequisite applications or Visual C++ Redistributables are missing
9. Whether Windows version or .NET version does not meet the app's minimum requirements
10. Whether the error occurs for all apps in Company Portal or only this specific one

---

## Likely Category
**Endpoint Management / Intune — Application installation detection failure**  
Sub-category: Intune app install completed but detection rule not met, or prerequisite missing  
*(Error 0x87D1041C specifically means Intune could not confirm the app installed successfully — the install may have run but the detection rule [registry key, file path, or MSI product code] did not match)*

---

## Suggested First Diagnostic Step
Review the Intune Management Extension log at `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` on the affected device — filter for the failing application name to identify the exact point of failure. In parallel, check the Intune admin portal (Devices > the affected device > App install status) to see the detailed install status and any sub-error codes. Confirm the device has synced with Intune recently; if not, trigger a manual sync via Company Portal > Settings > Sync and retry the installation.
