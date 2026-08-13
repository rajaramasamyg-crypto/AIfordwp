# Triage Summary — Copilot Surfaced Draft Settlement From Unassigned Matter

**Logged:** 2026-08-12  
**Analyst:** DWP Service Desk

---

## Summary
Copilot surfaced and summarised a draft settlement from a matter the partner says they are not assigned to. The partner also states they did not realise they could see that folder.

## Impact
- **Who:** Single user (partner; identity to confirm)
- **How many affected:** 1 reported; whether other users can see the same matter folder unexpectedly — to confirm
- **Business urgency:** HIGH — this may indicate overshared legal content or matter-level permissions that need urgent review

## Known Facts
- Copilot surfaced a draft settlement document
- The document appears to belong to a matter the user is not assigned to
- The user was not aware they could access the folder
- The user may already have direct access to the underlying SharePoint or matter repository location — to confirm

## Missing Information to Gather
1. User name, staff ID, and matter or case name
2. Exact location where the draft settlement was found
3. Whether the user can open the document directly in SharePoint or the source system
4. Whether the folder inherits permissions or has unique permissions
5. Whether the user is a member of a broader security group that may allow access
6. Whether the document was recently moved, copied, or re-shared
7. Whether other users not assigned to the matter can also see the folder
8. Whether the document is in SharePoint, OneDrive, Teams, or another repository
9. Whether the file was exposed through search results or directly surfaced by Copilot
10. Whether the matter has a documented access model that was not followed

## Likely Category
**SharePoint / Matter Permissions — Unexpected access to content outside the intended assignment scope**  
Sub-category: Copilot is summarising content that the account can already access because the folder or document permissions are broader than expected

## Suggested First Diagnostic Step
Verify whether the user can open the folder and document directly. If direct access succeeds, this is a permissions governance issue rather than a Copilot-specific defect. Review the matter folder's SharePoint permissions, group membership, and inheritance to confirm whether access is intentionally broad or has been granted in error. If the user should not have access, remove the excess permission and confirm whether similar access exists for other matter folders.