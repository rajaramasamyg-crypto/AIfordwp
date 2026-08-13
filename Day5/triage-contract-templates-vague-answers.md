# Triage Summary — Copilot Gives Vague Answers in Contract Templates Library

**Logged:** 2026-08-12  
**Analyst:** DWP Service Desk

---

## Summary
The contract specialist reports that Copilot gives vague, generic answers when asked about clauses in the contract templates library. This suggests Copilot may not be getting enough usable content from the library or the query is too broad for the indexed content.

## Impact
- **Who:** Single user (contract specialist; identity to confirm)
- **How many affected:** 1 reported; whether other users get the same generic answers from the library — to confirm
- **Business urgency:** MEDIUM — the user can still work, but Copilot is not providing useful legal context from the templates library

## Known Facts
- The issue is tied to the contract templates library
- Copilot returns generic or vague responses rather than specific clause references
- The library likely contains legal template documents that should be searchable
- The user is asking about clauses, which usually requires text-based content and good indexing

## Missing Information to Gather
1. Name and location of the templates library
2. Whether the content is Word documents, PDFs, scanned files, or images
3. Whether the library was recently created, moved, or migrated
4. Whether the user can search and open the templates directly in SharePoint
5. Whether specific document names produce better results than general prompts
6. Whether the library has unique permissions or broad access restrictions
7. Whether the files are protected, encrypted, or marked as restricted
8. Whether other users can get clause-specific answers from the same library
9. Whether the documents contain selectable text or only scanned pages
10. Whether the user is asking about a specific template or the whole library at once

## Likely Category
**SharePoint / Content Indexing and Prompt Scope — Library content is not well indexed or the prompts are too broad**  
Sub-category: Copilot cannot produce specific answers if the source material is poorly text-encoded, not fully indexed, or too large and ambiguous

## Suggested First Diagnostic Step
Check whether the templates are stored as searchable text documents rather than scanned PDFs or images, and test Copilot with a specific document name or clause reference instead of the whole library. If the documents are text-based and still return generic answers, verify that the library has been indexed and that the user can open the source files directly. If the library is newly added or recently migrated, indexing delay is a likely cause.