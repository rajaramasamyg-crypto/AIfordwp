# FinBridge Floor 6 Incident Separation & Triage Prioritization
**Date:** 2026-08-14  
**Situation:** FinBridge Floor 6 (Legal, 45 people, Win11 + Intune enrolled) – "chaos"  
**Input:** Three tangled problems reported in Slack message  

---

## The Three Tangled Problems (Separated)

The original report contains three distinct incidents that require separate diagnostic paths and escalations. **Do not treat them as one problem.**

---

## PROBLEM 1: Login Failures — "At least a dozen people can't log in or it's taking forever"

### Classification
- **Type:** Access Failure / Infrastructure Incident
- **Severity:** HIGH → CRITICAL (depends on scope)
- **Affected users:** "At least a dozen" out of 45 (minimum 12/45 = 27% of floor)
- **Business impact:** Legal operations degraded; work stoppage possible
- **Root cause domain:** VDI / Citrix infrastructure, Identity, or Network

### Diagnostic Path (Order of Urgency)

#### **Priority 1: Immediate (< 5 minutes)**
**Check: Citrix Broker Service status and VDA registration health on dc-vdi-02**

**What to check:**
1. On **dc-vdi-02** (Pool-02 delivery controller): Services → "Citrix Broker Service" → Status (should be Running)
2. In **Citrix Director**: Farm → Desktop Groups → FinBridge-VDI-Pool-02 → Machines
   - Count: How many registered vs. provisioned?
   - Threshold: If <50% registered, broker is the blocker
3. **Compare to FinBridge-VDI-Pool-01** (control group): If Pool-01 is healthy (>80% registered) but Pool-02 is degraded (<50%), the issue is isolated to Pool-02 control plane

**Why this first:**
- Error "can't log in / taking forever" + "at least a dozen users" suggests VDI/Citrix session launch failure
- Broker Service stoppage is the #1 cause of mass unregistration and launch failures
- The comparison (Pool-01 vs Pool-02) instantly narrows root cause to Pool-02 infrastructure

**Expected finding:** Likely Broker Service is Stopped or in hung state after Windows Update with pending reboot

---

#### **Priority 2: 5–10 minutes (parallel to Priority 1 if resources allow)**
**Check: Windows Update status and pending reboot state on dc-vdi-02**

**What to check:**
1. On **dc-vdi-02**: PowerShell (as Administrator):
   ```powershell
   Get-HotFix | Where-Object { $_.InstalledOn -gt (Get-Date).AddDays(-1) } | Sort-Object -Property InstalledOn -Descending
   ```
   Look for patches installed in the last 24 hours.

2. Check if reboot is required:
   ```powershell
   systeminfo | findstr "System Boot Time"
   ```
   Compare boot time to patch installation time.

3. Check Citrix event log for errors:
   - Event Viewer → Applications and Services Logs → Citrix → Broker Service
   - Look for entries around patch installation time and Broker Service stop/start events

**Why this second:**
- Post-Windows Update with pending reboot is a known pattern for Broker Service stoppage
- If the service stopped but reboot was not completed, the system is in a degraded state
- This is often the full chain: Update → Reboot required → Service stopped → VDA unregistration → Launch failures

**Expected finding:** Pending reboot after patching + Broker Service stopped

---

#### **Priority 3: 10–15 minutes (escalation if Priorities 1 & 2 don't explain the issue)**
**Check: Network connectivity between VDAs and dc-vdi-02; check Citrix Licensing Service**

**What to check:**
1. **Network isolation between VDAs and controller:**
   - On any VDA in Pool-02: `ping dc-vdi-02` (should resolve and respond)
   - On dc-vdi-02: `netstat -an | findstr 2598` (should show listener on port 2598 for Broker communication)
   - Firewall rules: Confirm port 2598 (Citrix Broker) is open between VDI subnet and dc-vdi-02

2. **Licensing service health:**
   - On **dc-vdi-02**: Services → "Citrix Licensing" → Status (should be Running)
   - On **licensing server** (if separate): Verify service is running and reachable

**Why this third:**
- This is a less common root cause but must be ruled out if Broker Service and reboot are healthy
- Network/firewall blocking or licensing service outage can prevent registration and launch

**Expected finding:** Either a firewall rule was accidentally modified during network changes, OR Licensing Service crashed during update

---

#### **Priority 4: Escalation (30+ minutes, if not resolved)**
If Priorities 1–3 do not identify the root cause or if resolution requires infrastructure restart:
- Escalate to **VDI/EUC Platform Team Lead**
- Request post-incident review to understand why Broker Service was not monitored post-patch
- Document evidence for follow-up RCA

---

### Resolution Sequence (If Broker Service is Stopped)
1. On **dc-vdi-02**: Start the Citrix Broker Service
2. Allow 2–3 minutes for VDAs to re-register
3. In **Citrix Director**, verify registration recovery in FinBridge-VDI-Pool-02
4. If registration is still low (<50%), reboot dc-vdi-02 and repeat
5. Monitor for 10 minutes; if recovery is stable, begin user testing

---

## PROBLEM 2: Login Delays — "It's taking forever"

### Classification
- **Type:** Performance Degradation / Access Delay
- **Severity:** MEDIUM → HIGH (depends on delay duration)
- **Affected users:** Unknown subset of the "at least a dozen"
- **Business impact:** Work-from-home users experience latency; meetings delayed
- **Root cause domain:** Network, DNS, Intune MDM, GPO processing, or VDI performance

### Diagnostic Path (Order of Urgency)

#### **Priority 1: Immediate (< 5 minutes)**
**Check: Are "slow to log in" users on Win11 that recently enrolled in Intune?**

**What to check:**
1. Ask affected users: "Are you on Windows 11?" and "When did you last restart?"
2. Correlation: Do ALL slow-login users have Win11 + Intune enrollment? Or only a subset?
3. Check **Intune Device Compliance** for affected users:
   - Intune admin center → Devices → Windows Devices
   - Filter by Floor 6 Legal users; check for Compliance Status = "Compliant" vs "Non-compliant"
   - Check for pending policy deployments or assignment conflicts

**Why this first:**
- Win11 recently migrated + Intune enrolled = high probability of post-enrollment GPO processing delays
- Intune policy evaluation at login can add 30+ seconds if policies are queued or conflicting
- This narrows the problem to identity/enrollment-related delay vs. VDI infrastructure latency

**Expected finding:** Slow-login users are all on Win11 with Intune enrollment; fast-login users are on Win10 or unenrolled

---

#### **Priority 2: 5–10 minutes (parallel to Priority 1)**
**Check: DNS resolution time and Kerberos authentication latency**

**What to check:**
1. On an affected user's Win11 device:
   ```powershell
   Resolve-DnsName -Name FINBRIDGE-DC01.finbridge.local -Type A
   ```
   Look for resolution time (should be <50ms). If >200ms, DNS is the bottleneck.

2. Check network path to domain controller:
   ```powershell
   tracert FINBRIDGE-DC01.finbridge.local
   ```
   Look for unexpected hops or timeouts.

3. Check Kerberos auth logs (on domain controller) for slow ticket issuance:
   - Event Viewer → Windows Logs → Security
   - Filter for Event ID 4769 (Kerberos TGS issued) for affected users
   - Look for delay patterns between ticket request and issuance

**Why this second:**
- Win11 with Intune enrollment may have changed DNS servers during MDM enrollment
- Slow DNS → slow Kerberos → slow login
- This is quicker to diagnose than full GPO processing and points to network/identity infrastructure

**Expected finding:** DNS resolution is slow (>200ms) due to outdated or unreachable DNS servers assigned by DHCP or Intune MDM

---

#### **Priority 3: 10–15 minutes (if Priorities 1 & 2 don't explain delays)**
**Check: GPO processing time on Win11 devices**

**What to check:**
1. On affected Win11 device, enable verbose GPO logging:
   ```powershell
   gpresult /h C:\gpresult.html
   ```
   Save report and examine:
   - "Computer Configuration" and "User Configuration" sections
   - Look for policies marked as "Denied" or "Not Applied"
   - Note any processing times listed

2. Check Event Viewer → Windows Logs → System for Group Policy errors during login
   - Look for Event ID 1096 (Group Policy processing error) or 1085 (policy failed to apply)

3. Check if there are conflicting Intune policies vs. on-premises GPOs:
   - In Intune, check if any Configuration Profiles or Compliance Policies are set to "Fail" for non-compliant devices
   - This can block login until compliance is achieved

**Why this third:**
- GPO processing on Win11 can be slow if there are conflicts with Intune policies
- Intune MDM can override or delay GPO application if there are assignment conflicts
- This is the most common cause of post-Intune-enrollment login delays

**Expected finding:** GPO processing is taking 60+ seconds due to Intune policy conflicts or a large number of applied policies on Win11

---

#### **Priority 4: Escalation (30+ minutes, if not resolved)**
If Priorities 1–3 do not explain delays:
- Escalate to **Identity & Access Management Team** (Intune/MDM focus)
- Request review of Win11 + Intune enrollment policies for Floor 6
- Collect Intune diagnostic logs for affected devices

---

### Resolution Sequence (If DNS is the Issue)
1. On affected Win11 devices: Update DNS servers via DHCP or static configuration to use `10.10.0.10` (new DNS server)
2. Clear DNS cache: `ipconfig /flushdns`
3. Reboot device and test login speed
4. If resolved, update DHCP scope for Floor 6 subnet to ensure all new devices get correct DNS

---

## PROBLEM 3: Unauthorized Data Exposure via Copilot — "Paralegal says Copilot pulled up a client matter she swears she's never had access to"

### Classification
- **Type:** Security Incident — Unauthorized Data Access
- **Severity:** CRITICAL
- **Regulatory risk:** GDPR, FCA, Client Contract Breach
- **Root cause domain:** SharePoint Permissions / Data Governance (NOT Copilot)
- **Affected scope:** Unknown (1 paralegal confirmed; potentially others)

### Diagnostic Path (Order of Urgency)

#### **Priority 1: IMMEDIATE (< 5 minutes — Escalate in Parallel)**
**Check: Confirm the paralegal CAN directly open the document in SharePoint (verify underlying permissions)**

**What to check:**
1. Ask the paralegal: "Can you open this file directly in SharePoint, using the same browser and device, without Copilot?"
2. If YES → Underlying permission is confirmed; go to Priority 2 (permissions audit)
3. If NO → Different issue (Copilot indexing stale data, or delegated access path unknown to user); still escalate but different sequence

**Why this first:**
- Copilot ONLY surfaces content the signed-in user has read access to in SharePoint/OneDrive
- If she can open it, Copilot is working correctly; the problem is permissions
- If she cannot open it, Copilot may be surfacing cached/stale content; escalate to security team for index review

**Expected finding:** YES — paralegal can open the file directly, confirming inherited SharePoint access

---

#### **Priority 2: IMMEDIATE (< 10 minutes — Parallel to Priority 1)**
**Check: SharePoint folder permissions and security group membership for the settlement matter**

**What to check:**
1. In **SharePoint** → Settlement Matter folder (e.g., "Client-XYZ-Settlement-2026") → Settings → Permissions
2. List all groups/users with access; look for:
   - The paralegal's user account directly listed
   - The paralegal's department/team group listed
   - Over-permissive groups like "All Company", "All Staff", "All Legal", "All Finance"
3. For each group found, check membership:
   - Does the paralegal's account belong to this group?
   - Is she nested inside this group (e.g., "Legal Team" → "All Staff")?
4. Check if folder has inherited permissions (rather than unique):
   - If inherited, trace permissions up to parent library
   - Identify the inheritance chain that gives her access

**Why this second:**
- Pre-deployment audit identified unaudited 2019 migration permissions as the #1 risk
- If she has access, it's because of inherited or over-permissive group nesting
- This is the data governance failure that Copilot exposed

**Expected finding:** Paralegal's account or her Legal Team group has inherited access via "All Legal" or "All Staff" groups, or folder inherits from parent library with overly broad permissions

---

#### **Priority 3: 10–30 minutes (Confirm with Leadership & Compliance)**
**Check: Is the paralegal's access intentional or a legacy artifact?**

**What to check:**
1. Ask Finance/Legal leadership: "Should this paralegal have access to this matter?"
2. Check **Active Directory group membership history** (if available):
   - When was she added to the relevant group?
   - Has she been removed from any groups recently?
3. Interview the **matter custodian** (attorney/partner assigned to client):
   - Is she assigned to this workstream or case?
   - Should she have access?

**Why this third:**
- Not all permission findings are breaches; she may have legitimate delegated access
- Distinguishing intentional from unintended access determines next action (remove vs. document vs. reassign)

**Expected finding:** Paralegal was added to "All Legal" 18 months ago for an unrelated project; never removed; has no current legitimate need for this matter access

---

#### **Priority 4: 30–60 minutes (Containment & Escalation, Parallel to Priority 2)**
**If the paralegal should NOT have access: REMEDIATE IMMEDIATELY**

**Actions required:**
1. **Remove access immediately** (coordinated with Legal/Finance leadership):
   - Remove her account or Legal Team group from the settlement matter folder
   - OR remove her account from the over-permissive group (e.g., remove from "All Legal" if needed)
2. **Escalate to IT Security + Legal/Compliance Officer:**
   - Document that unauthorized access was discovered via Copilot
   - Determine regulatory reporting obligations (GDPR/FCA/Client contract)
   - Assess whether client needs to be notified
3. **Initiate wider audit:**
   - Run SharePoint permission inheritance report across all Finance/Legal libraries
   - Identify all over-permissive groups and similar exposure risks
   - **This was a pre-deployment requirement in the Copilot readiness plan that was not completed**
4. **Document for compliance:**
   - Record date/time of discovery, affected user, affected content, and remediation action
   - Prepare for potential regulatory reporting if required

**Why this step:**
- Leaving her in the group allows continued unauthorized access
- Compliance requires documented remediation for audit trails
- Similar exposures likely exist; broader audit is essential

**Expected outcome:** Permission removed; matter custodian notified; compliance assessment completed; audit scheduled for broader remediation

---

#### **Priority 5: 1–7 days (Post-Incident)**
**Execute full SharePoint permissions audit for Finance/Legal estate**

**Required actions:**
1. Run SharePoint permission inheritance report across all Finance and Legal sites/libraries
2. Identify all inherited permissions and over-permissive groups
3. Remediate by:
   - Breaking inheritance where needed
   - Removing over-permissive group membership
   - Documenting baseline permissions post-remediation
4. Reapply Sensitivity Labels (from pre-deployment plan) to high-sensitivity libraries:
   - Payroll libraries
   - Settlement/M&A matter libraries
   - Board-level content
5. Sign off with Finance/Legal leadership and IT Security

**Why this step:**
- The pre-deployment Copilot readiness plan made this mandatory before licence assignment
- This incident proves the risk was real and unmitigated
- Doing it now prevents escalation to multiple users and potential compliance breach

**Expected outcome:** All over-permissive permissions identified and remediated; Copilot licence can be safely assigned to compliant Finance/Legal users

---

## Summary Table: Diagnostic Sequence by Urgency

| Rank | Problem | First Check | Owner | Target Time | Escalation Path |
|---|---|---|---|---|---|
| **1A** | VDI Login Failures | Citrix Broker Service status + VDA registration (dc-vdi-02) | VDI Admin | <5 min | VDI/EUC Team Lead |
| **1B** | Windows Update + Pending Reboot | Check patch install time & reboot state on dc-vdi-02 | VDI Admin | 5–10 min | VDI/EUC Team Lead |
| **1C** | Login Delays (if "taking forever") | Are slow-login users on Win11 + Intune enrolled? | Service Desk → Identity Team | <5 min | Identity/Intune Admin |
| **1D** | DNS/Kerberos Auth Delays | DNS resolution time to DC; Kerberos ticket latency | Network/Identity Team | 5–10 min | Network Admin |
| **2A** | Copilot Incident — Permissions Breach | Confirm paralegal can open file in SharePoint directly | Legal/SharePoint Admin | <5 min | **IT Security + Legal/Compliance (IMMEDIATE)** |
| **2B** | Copilot Incident — Permissions Audit | Pull SharePoint folder permissions & group membership | SharePoint Admin | <30 min | IT Security + Legal/Compliance |
| **2C** | Copilot Incident — Intentionality Check | Ask leadership: should she have access? | Legal/Finance Leadership | 10–30 min | Legal/Compliance Officer |
| **2D** | Copilot Incident — Remediation | Remove access if NOT intentional; escalate to compliance | SharePoint Admin | 30–60 min | Legal/Compliance + IT Security |

---

## Key Insights

1. **These are THREE distinct incidents, not one:**
   - VDI infrastructure failure (Problem 1)
   - Win11 + Intune enrollment delay (Problem 2)
   - Permissions misconfiguration exposed by Copilot (Problem 3)

2. **The Copilot incident is the highest regulatory risk:**
   - Requires immediate security escalation
   - Cannot be treated as a support ticket or Copilot defect
   - Indicates pre-deployment audit requirements were not completed

3. **Problems 1 & 2 are solvable within hours; Problem 3 requires governance follow-up:**
   - If Broker Service is stopped, restart and monitor recovery (1–2 hours)
   - If DNS is slow, update DHCP scopes (30 minutes)
   - If Intune policies are conflicting, remediate and roll back (1–2 hours)
   - If permissions are over-permissive, audit and remediate (1–7 days), but immediate containment (<1 hour)

4. **Copilot is NOT the problem:**
   - Copilot is functioning correctly, surfacing content the user has access to
   - The failure is in pre-deployment data governance and SharePoint permissions
   - Closing this as "AI weirdness" would be a misclassification that endangers compliance

