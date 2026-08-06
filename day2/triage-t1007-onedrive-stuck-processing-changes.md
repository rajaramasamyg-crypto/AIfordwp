# Triage Summary — T-1007: OneDrive Stuck 'Processing Changes' Since Migration; Files Missing Locally

**Logged:** 2026-08-04  
**Analyst:** DWP Service Desk

---

## Summary
User's OneDrive has been stuck in a "processing changes" state since a recent migration, and files that were previously available locally are now missing.

---

## Impact
- **Who:** Single end user (identity to confirm)
- **How many affected:** 1 reported; whether other users migrated at the same wave are seeing the same — to confirm
- **Business urgency:** HIGH — locally missing files may mean the user cannot access work documents; risk of data loss perception even if files are safe in the cloud — requires prompt investigation and clear communication

---

## Known Facts
- OneDrive has shown "processing changes" since a migration (type of migration — tenant-to-tenant, SharePoint restructure, or account move — to confirm)
- Files that were previously available locally are no longer present on the device
- Whether the files are still visible in OneDrive online (via browser) — to confirm
- Whether the user's OneDrive account is correctly signed in post-migration — to confirm

---

## Missing Information to Gather
1. User's name, staff ID, and primary email / UPN
2. Type of migration — tenant-to-tenant move, SharePoint/OneDrive admin restructure, or other
3. Whether files are visible and accessible at onedrive.live.com or via the Microsoft 365 portal in a browser
4. Whether the OneDrive client is signed into the correct (post-migration) account — check the system tray icon > sign-in details
5. Whether OneDrive is showing any specific error in addition to "processing changes" — click the system tray icon for details
6. Whether the "Files On-Demand" feature is enabled — files may show as online-only placeholders rather than being locally downloaded
7. How long OneDrive has been stuck — has it made any progress, or has the status not changed at all since migration
8. Whether selective sync is configured and whether the missing files' folders are included in the sync scope
9. Whether the device has sufficient local storage space for OneDrive sync
10. Whether the user's OneDrive storage quota has been exceeded post-migration

---

## Likely Category
**Cloud Storage / OneDrive — Post-migration sync stall and local file availability**  
Sub-category: OneDrive account reconfiguration required after migration, or Files On-Demand showing online-only files as missing  
*(Most common cause after a tenant migration: OneDrive client is still connected to the old tenant/account and needs to be signed out, unlinked, and re-signed in to the new account)*

---

## Suggested First Diagnostic Step
First, reassure the user that the files are very likely still safe in the cloud — verify by opening OneDrive in a browser using the new account credentials. Then check the OneDrive sync client: click the system tray cloud icon and confirm which account is signed in. If it still shows the old tenant email address, the client needs to be unlinked from the old account and re-connected to the new one (system tray > Settings > Account > Unlink this PC, then sign in with the new credentials). Do not delete any local OneDrive folder contents before confirming they are safely stored online. If files on-demand is active, files appearing "missing" locally may simply be cloud-only placeholders that need to be re-synced.
