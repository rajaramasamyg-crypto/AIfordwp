# Triage Summary — T-1001: BitLocker Prompting for Recovery Key Every Boot

**Logged:** 2026-08-04  
**Analyst:** DWP Service Desk

---

## Summary
New Windows 11 laptop is prompting the user for a BitLocker recovery key on every boot, blocking normal startup.

---

## Impact
- **Who:** Single end user (identity to confirm)
- **How many affected:** 1 reported; whether other new Win11 laptops have the same issue — to confirm
- **Business urgency:** HIGH — user cannot start the device normally without the recovery key; fully blocked each session

---

## Known Facts
- Device is a new Windows 11 laptop
- BitLocker recovery key prompt appears on every boot, not just once
- Issue is recurring — not a one-off prompt after a firmware or TPM change
- Recovery key is being entered successfully (or the issue would have escalated further) — to confirm
- Device is presumably a DWP-managed corporate build — to confirm

---

## Missing Information to Gather
1. User's name, staff ID, and device asset tag or hostname
2. Whether the recovery key is known and accessible to the user, or is being retrieved from another source
3. Whether the device has ever booted successfully without a recovery key prompt (i.e. did it ever work normally)
4. Whether the device is enrolled in Intune / Azure AD joined or hybrid-joined
5. Whether the recovery key is stored in Azure AD / Entra ID (retrievable via the portal)
6. Whether any BIOS/UEFI settings were changed during device setup (Secure Boot, TPM settings)
7. Whether TPM 2.0 is present and showing as healthy in Device Manager
8. Whether any Windows Updates or firmware updates have applied since the device was first used
9. Whether the device was imaged/provisioned via Autopilot or manual build process
10. Whether other new laptops of the same model are exhibiting the same behaviour

---

## Likely Category
**Endpoint Security / BitLocker — TPM or Secure Boot misconfiguration on new device**  
Sub-category: BitLocker unable to bind to TPM; recovery key demanded every boot  
*(Likely cause: TPM not properly initialised, Secure Boot not enabled, or PCR profile mismatch during imaging)*

---

## Suggested First Diagnostic Step
Check whether the device's TPM is enabled and healthy: open `tpm.msc` and confirm TPM 2.0 status is "Ready for use". Also verify Secure Boot is enabled in UEFI/BIOS settings, as a disabled Secure Boot will cause BitLocker to demand a recovery key on every boot. If the TPM appears healthy and Secure Boot is on, check the BitLocker key protectors via `manage-bde -protectors -get C:` in an elevated command prompt — if no TPM protector is listed, BitLocker was configured in recovery-password-only mode and the TPM needs to be added as a protector and the volume re-sealed.
