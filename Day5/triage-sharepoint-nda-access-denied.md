# Triage Summary — Copilot Cannot Summarise NDA in SharePoint

**Logged:** 2026-08-12  
**Analyst:** DWP Service Desk

---

## Summary
User asked Copilot to summarise a client NDA in SharePoint, but Copilot responded that it does not have access to the content. The file is said to be in a folder the user has not previously opened.

## Impact
- **Who:** Single user (paralegal; identity to confirm)
- **How many affected:** 1 reported; whether other users can access the same SharePoint folder — to confirm
- **Business urgency:** MEDIUM-HIGH — legal work is blocked if the NDA must be reviewed quickly, but this appears limited to one user and one site or folder

## Known Facts
- The user attempted to summarise a client NDA in SharePoint using Copilot
- Copilot returned an access-related response rather than a summary
- The file is in a folder the user has never opened before
- The user may not currently have permission to that folder or document — to confirm

## Missing Information to Gather
1. User name, staff ID, and SharePoint site or library name
2. Exact document name and folder path
3. Whether the user can open the NDA directly in SharePoint without Copilot
4. Whether a colleague in the same team can open the same file
5. Whether the folder inherits permissions or uses unique permissions
6. Whether the file was recently added, moved, or re-permissioned
7. Whether the user can access the site root but not the folder, or cannot access the site at all
8. Whether the document is stored in SharePoint, OneDrive, or a Teams-connected library
9. Whether the file is a standard text document or a protected/scanned file
10. Whether the user has been explicitly granted access to this matter or client folder

## Likely Category
**SharePoint / Copilot Access Control — User does not have permission to the underlying content**  
Sub-category: Copilot is correctly respecting SharePoint permissions and cannot surface content outside the user's access scope

## Suggested First Diagnostic Step
Confirm whether the user can open the NDA directly in SharePoint with the same account. If direct access fails, this is a permissions issue rather than a Copilot defect. Check the folder's permissions and inheritance in SharePoint, then verify whether the user has been granted access to that matter or client folder. If the file is accessible directly but Copilot still says it cannot access the content, check whether the document library has finished indexing and whether the file is in a supported, text-readable format.