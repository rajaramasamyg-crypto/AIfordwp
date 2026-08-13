# Cisco CUCM DDI Assignment - Step by Step (Day 9)

## Purpose
This guide explains how to assign a DDI (Direct Dial-In) number to an end user in Cisco Unified Communications Manager (CUCM).

It covers:
- Single user assignment in CUCM Administration
- Bulk assignment option with BAT
- CLI and command-mode checks for verification

## Important Note About Command Mode
Cisco CUCM does not normally assign DDI numbers to end users directly from the server CLI.

In most environments, DDI assignment is done in:
- Cisco Unified CM Administration (web GUI)
- BAT (Bulk Administration Tool) for bulk changes
- AXL/API automation for advanced integrations

The CUCM CLI is mainly used for:
- Service checks
- Database and platform validation
- Troubleshooting after the number is assigned

If someone asks for "command mode" in CUCM, the technically correct approach is:
1. Use CUCM Administration for the actual DDI assignment.
2. Use CLI commands only for validation and troubleshooting.

## Prerequisites
1. You have access to Cisco Unified CM Administration.
2. You have the correct administrative role to modify users, directory numbers, and phones.
3. The DDI number is available and has not already been assigned.
4. A route pattern or inbound DID translation already exists from the voice gateway or SIP trunk to CUCM.
5. The target user already exists in CUCM End User configuration.
6. The target phone or device is already registered in CUCM.

## Quick Validation Checklist
Before you start, confirm:
1. The end user exists under User Management > End User.
2. The device exists under Device > Phone.
3. The line or extension for the user is known.
4. The external DDI is available.
5. The partition and calling search space design is confirmed.
6. The gateway, SIP trunk, or provider routing is already sending the DDI toward CUCM.

---

## Method A - Assign DDI to a Single End User in CUCM Administration

### Step 1: Log in to CUCM Administration
1. Open a browser.
2. Go to the CUCM Administration URL.
3. Sign in with an admin account.

Example:
```text
https://<cucm-server>/ccmadmin
```

### Step 2: Identify the target user and device
1. Go to User Management > End User.
2. Search for the target user.
3. Open the user record and note the associated device.
4. Confirm the correct primary extension.

### Step 3: Check or create the internal extension
1. Go to Call Routing > Directory Number.
2. Search for the internal extension used by the user.
3. If it already exists, open it.
4. If it does not exist, create a new directory number with the required partition.

Typical items to confirm on the directory number:
- Directory Number
- Partition
- Alerting Name
- ASCII Alerting Name
- External Phone Number Mask

### Step 4: Set the External Phone Number Mask to the DDI
This is the key field commonly used to map a user line to a full external DID/DDI.

1. Open the target Directory Number.
2. Find External Phone Number Mask.
3. Enter the full DDI number.
4. Save the change.

Example:
```text
+442071234567
```

Use the format required by your dial plan. Many environments use:
- Full national format
- Full E.164 format

### Step 5: Associate the line to the user device
1. Go to Device > Phone.
2. Open the target phone.
3. Under Association Information, open Line [1] or the correct line position.
4. Confirm the directory number is assigned to the device.
5. Save the phone configuration.
6. Click Apply Config if prompted.

### Step 6: Associate the user to the device
1. Go back to User Management > End User.
2. Open the target user.
3. Under Device Information, associate the correct phone if needed.
4. Set the primary extension to the correct line.
5. Save the user record.

### Step 7: Verify inbound DDI routing
The DDI must be routed from the PSTN or SIP provider to CUCM and then to the user line.

Common inbound methods include:
- Translation Pattern
- Route Pattern
- Direct Inward Dial mapping on the voice gateway
- SIP trunk normalization depending on the provider

Verify that the called number sent by the provider matches the DDI or a translation that CUCM expects.

### Step 8: Test the assignment
1. Call the DDI from an external phone.
2. Confirm the user phone rings.
3. Place an outbound call from the user phone.
4. Confirm the expected caller ID is presented.

---

## Method B - Assign DDI by Updating the Directory Number Mask
If the extension already exists and only the public number needs to change:

1. Go to Call Routing > Directory Number.
2. Open the user extension.
3. Update External Phone Number Mask with the new DDI.
4. Save.
5. Apply Config if requested.
6. Retest inbound and outbound calling.

---

## Method C - Bulk Assignment with BAT
Use this method when multiple users need DDI assignment.

### Step 1: Export existing line or phone details
1. Go to Bulk Administration > Phones > Export Phones > All Details.
2. Or go to Bulk Administration > Users > Export Users if your process is user-driven.
3. Download the export file.

### Step 2: Update the file
1. Open the exported file in Excel.
2. Locate the directory number or line fields.
3. Update the External Phone Number Mask column with the target DDI.
4. Save the file as the required BAT format.

### Step 3: Import the file
1. Go to Bulk Administration > Upload/Download Files.
2. Upload the updated CSV or BAT file.
3. Confirm the file appears in the upload list.

### Step 4: Run the BAT job
1. Go to Bulk Administration > Phones > Update Phones > Query.
2. Select the phones to update.
3. Choose the uploaded file or update template.
4. Submit the job.
5. Monitor job status under Bulk Administration > Job Scheduler.

### Step 5: Validate the result
1. Open a sample user phone.
2. Open the line configuration.
3. Confirm the External Phone Number Mask contains the new DDI.
4. Perform a live call test.

---

## Command Mode / CLI Verification
These commands do not assign the DDI, but they help validate server health and troubleshoot the configuration.

### Step 1: Connect to CUCM CLI
Use SSH to connect to the publisher or relevant node.

Example:
```text
ssh admin@<cucm-server>
```

### Step 2: Check core services
```text
utils service list
```

Review whether key services such as Cisco CallManager are running.

### Step 3: Check database replication status
```text
utils dbreplication runtimestate
```

Use this if changes appear inconsistent across cluster nodes.

### Step 4: Check phone registration
```text
show perf query class "Cisco CallManager" object "RegisteredPhones"
```

Use this to confirm the cluster is generally registering endpoints.

### Step 5: Run SQL queries for validation
If allowed in your environment, use CLI SQL queries to verify line and mask data.

Example query to find a directory number:
```text
run sql select dnorpattern, fkroutepartition from numplan where dnorpattern='1001'
```

Example query to inspect device and line relationships:
```text
run sql select d.name, n.dnorpattern from device d
inner join devicenumplanmap dmap on d.pkid = dmap.fkdevice
inner join numplan n on n.pkid = dmap.fknumplan
where d.name = 'SEP001122334455'
```

Note:
The exact schema available through `run sql` can vary by CUCM version. Use SQL carefully in production and only for read-only validation.

---

## Example End-to-End Scenario
Goal:
- User: John Smith
- Extension: 1001
- DDI: +442071234567
- Device: SEP001122334455

Steps:
1. Open User Management > End User and select John Smith.
2. Confirm primary extension is 1001.
3. Open Call Routing > Directory Number and locate 1001.
4. Set External Phone Number Mask to +442071234567.
5. Save the line.
6. Open Device > Phone and confirm extension 1001 is assigned to SEP001122334455.
7. Save and Apply Config.
8. Make a live inbound test call to +442071234567.
9. Verify John Smith's phone rings.

---

## Rollback Example
If the DDI was assigned incorrectly:
1. Open the affected Directory Number.
2. Remove or correct the External Phone Number Mask.
3. Save the change.
4. Reapply config if prompted.
5. Retest calls.

---

## Troubleshooting
1. External calls do not reach the user.
   - Confirm the provider is sending the correct called number.
   - Validate route pattern or translation pattern logic.
   - Check gateway or SIP trunk inbound digit manipulation.

2. Outbound caller ID shows the wrong number.
   - Check External Phone Number Mask.
   - Check route pattern, route list, and carrier presentation rules.

3. User is associated but phone does not ring.
   - Confirm the line is on the correct device.
   - Confirm the phone is registered.
   - Confirm partition and CSS allow proper routing.

4. Changes work on one node but not another.
   - Check database replication.
   - Confirm cluster health.

## Operational Notes
- In CUCM, DDI assignment is usually tied to the line configuration rather than only the end user object.
- The most common field used is External Phone Number Mask.
- For large changes, use BAT instead of manual edits.
- Always validate one pilot user before bulk rollout.

Created: 2026-08-13