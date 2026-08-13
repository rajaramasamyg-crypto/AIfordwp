# Copilot Support Ticket Triage (Day8)
Date: 2026-08-12

Cause options used (ranked per ticket):
- permissions/access boundary
- data indexing lag
- sensitivity label restriction
- license/client prerequisite issue
- guest/external sharing limitation
- genuine Copilot fault (last resort)

## Ticket Assessments

| ID | Likely cause (ranked most probable first) | Fastest check | Is this actually a Copilot bug? |
|---|---|---|---|
| 1 | 1) data indexing lag 2) sensitivity label restriction 3) permissions/access boundary 4) genuine Copilot fault | Check file "last modified" time in SharePoint and whether the board pack was added/updated very recently. | **No (likely)** - User visibility does not guarantee immediate Copilot grounding; recent content often points to indexing delay first. |
| 2 | 1) data indexing lag 2) license/client prerequisite issue 3) permissions/access boundary 4) genuine Copilot fault | Confirm start date and mailbox activity age (yesterday/new mailbox) before deeper troubleshooting. | **No** - New-hire mail and profile signals commonly need time before Copilot has useful context. |
| 3 | 1) sensitivity label restriction 2) permissions/access boundary 3) license/client prerequisite issue 4) genuine Copilot fault | Check the spreadsheet's sensitivity label and protection settings in M365/Office. | **No** - The explicit "I don't have access" response aligns with policy/access enforcement, not a product defect. |
| 4 | 1) guest/external sharing limitation 2) permissions/access boundary 3) sensitivity label restriction 4) genuine Copilot fault | Verify the contract is from another org and only shared by guest link (not in-tenant access). | **No** - Cross-tenant guest-link content is a classic grounding limitation scenario. |
| 5 | 1) license/client prerequisite issue 2) permissions/access boundary 3) genuine Copilot fault | Check whether Finance users still have required Copilot licenses/service plans assigned this morning. | **Unclear** - Team-wide sudden failure is more consistent with licensing/assignment or tenant config drift first; only call bug after those checks fail. |
| 6 | 1) permissions/access boundary 2) data indexing lag 3) genuine Copilot fault | Validate current effective permissions on that folder/file for the manager account. | **No** - Copilot can use content a user is authorized to access even if they forgot about it; this is expected behavior. |
| 7 | 1) license/client prerequisite issue 2) permissions/access boundary 3) data indexing lag 4) genuine Copilot fault | Confirm the user has the correct Copilot license and is using a supported signed-in client/tenant account. | **Unclear** - Could be broad readiness/prerequisite misconfiguration; treat as non-bug until licensing/client and access scope are verified. |
| 8 | 1) permissions/access boundary 2) license/client prerequisite issue 3) guest/external sharing limitation 4) genuine Copilot fault | Check delegated permissions for the shared mailbox calendar and whether Copilot supports that access path in the current client. | **Unclear** - Shared mailbox/delegated calendar access often behaves differently from primary mailbox context; verify entitlement path first. |

## Notes for Training

- Do not escalate to "genuine Copilot fault" until access, labels, licensing/client prerequisites, and external-sharing constraints are ruled out.
- User-visible access and Copilot-groundable access are related but not identical in many enterprise scenarios.
