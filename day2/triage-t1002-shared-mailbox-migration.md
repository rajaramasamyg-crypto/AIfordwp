# Triage Summary — T-1002: Finance User Cannot Open Shared Mailbox After Migration

**Logged:** 2026-08-04  
**Analyst:** DWP Service Desk

---

## Summary
A Finance team user is unable to open a shared mailbox in Outlook following a recent migration, likely an Exchange Online or tenant migration.

---

## Impact
- **Who:** Single Finance user (identity to confirm)
- **How many affected:** 1 reported; whether other Finance users are affected — to confirm
- **Business urgency:** MEDIUM–HIGH — Finance teams typically have time-sensitive mailbox dependencies; business impact subject to what the shared mailbox is used for — to confirm

---

## Known Facts
- User is in the Finance team
- A migration has recently taken place (type — Exchange on-premises to Exchange Online, tenant-to-tenant, or other — to confirm)
- The user cannot open a specific shared mailbox post-migration
- Prior to migration the user had access to this shared mailbox — to confirm

---

## Missing Information to Gather
1. User's name, staff ID, and primary email address
2. Name/email address of the shared mailbox the user cannot open
3. Exact error message displayed when attempting to open the mailbox (e.g. "You do not have permission", "The mailbox could not be found")
4. Type of migration carried out — on-prem Exchange to Exchange Online, or tenant-to-tenant move
5. Whether the shared mailbox itself was migrated or remains in its original location
6. Whether the user's own mailbox was migrated at the same time, or at a different wave
7. Whether the user's Outlook profile has been updated/recreated post-migration
8. Whether the shared mailbox appears in the Global Address List (GAL)
9. Whether the user's permissions to the shared mailbox were re-granted post-migration (permissions do not always carry over)
10. Whether other Finance users who had the same access are experiencing the same problem

---

## Likely Category
**Email / Shared Mailbox Access — Post-migration permission or profile issue**  
Sub-category: Permissions not re-applied or Outlook profile not updated after mailbox migration  
*(Most common cause: delegate/full access permissions not re-granted in new environment, or Outlook profile still pointing to old mailbox location)*

---

## Suggested First Diagnostic Step
Verify in the Exchange Admin Centre (or Microsoft 365 Admin Centre) that the user still has Full Access permission on the shared mailbox in the target environment — permissions are frequently lost during migration and must be re-granted manually. If the permission is present but the mailbox still does not appear, ask the user to remove and re-add the shared mailbox in Outlook (File > Account Settings > Account Settings > More Settings, or simply remove the shared mailbox entry and allow Outlook to auto-map if auto-mapping is enabled). Also confirm the shared mailbox was successfully migrated and is active in the target tenant.
