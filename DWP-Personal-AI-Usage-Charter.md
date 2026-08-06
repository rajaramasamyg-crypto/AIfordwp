# Personal AI Usage Charter (DWP Engineer, Public AI Assistants)

**Version:** 1.0  
**Date:** 03 Aug 2026

## Purpose
I use public AI assistants to improve speed and quality in desktop and endpoint engineering work, while protecting DWP data, users, and services. AI is a drafting and troubleshooting aid, not an authority.

## Scope
This charter applies when I use public AI tools for endpoint tasks such as Windows desktop support, PowerShell scripting, Intune/SCCM packaging, software deployment, patching, endpoint hardening, and incident triage.

## 1) Appropriate DWP Tasks For Public LLM Help
I may use public AI for low-risk, non-sensitive engineering support, including:
1. Drafting or improving generic PowerShell/Bash logic using placeholder values.
2. Explaining Windows errors, event IDs, and command syntax from publicly known documentation.
3. Creating script templates for software install/uninstall, logging, retry logic, and detection rules.
4. Generating checklists for endpoint rollout, patch validation, and rollback planning.
5. Refactoring existing internal scripts after I remove all sensitive identifiers and data.
6. Producing plain-language summaries for technical options, trade-offs, and troubleshooting paths.
7. Building test cases and validation steps for lab or non-production endpoint changes.

## 2) Tasks That Are Not Appropriate
I will not use public AI for any task involving sensitive DWP content or privileged operations, including:
1. Uploading or pasting production logs, tickets, screenshots, configs, hostnames, usernames, email addresses, device IDs, IPs, case references, or architecture details that are not already public.
2. Sharing user data, claimant data, staff records, or any personal/special-category information.
3. Sharing credentials, secrets, tokens, certificates, private keys, connection strings, or recovery codes.
4. Requesting advice that bypasses security controls, monitoring, hardening baselines, or change governance.
5. Using AI output directly in production for endpoint changes without testing and peer/approval checks.
6. Asking AI to make risk decisions that require DWP policy interpretation or security sign-off.

## 3) Data-Handling Rule (PII and Credentials)
Single rule: If data could identify a person, system, or provide access, it must not be entered into a public AI tool.

In practice, I must:
1. Use placeholders such as USER_EMAIL, DEVICE_ID, TENANT_ID, SERVER_NAME.
2. Redact all identifiers before prompting.
3. Keep prompts generic and pattern-based, not case-specific.
4. Treat all credentials and secrets as never-share items, with no exceptions.

## 4) Personal Generate Then Verify Rule (Scripts and System Changes)
I follow this sequence every time:
1. Generate: Ask AI for a draft script or procedure using only sanitized inputs.
2. Review: Read every line and confirm I understand intent, dependencies, and failure behavior.
3. Validate safety: Check for destructive commands, privilege escalation, external downloads, or insecure defaults.
4. Test: Run in lab/test endpoint first with logging enabled and expected outcomes defined.
5. Verify: Confirm idempotency, error handling, rollback path, and least-privilege execution.
6. Approve: Follow change process before production use (peer review and required approvals).
7. Deploy and monitor: Roll out in stages, monitor telemetry, and be ready to roll back.

## Accountability Statement
I remain responsible for all actions taken from AI-generated output. If unsure, I stop and escalate to security, service owner, or change authority before proceeding.

**Personal commitment:** I will use public AI to accelerate safe engineering, never to bypass data protection or operational controls.
