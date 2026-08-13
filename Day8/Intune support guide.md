# Intune Support Guide

## Issue 1: Required Apps Not Installing

### Symptoms
- App assigned as Required in Intune but does not appear on the device
- User reports missing application after enrolment
- App visible in Intune portal with error or no status

### Step-by-Step Resolution

**Step 1 – Confirm app assignment**
1. Open **Microsoft Intune admin center** → **Apps** → **All apps**
2. Select the affected app
3. Go to **Properties** → **Assignments**
4. Confirm the user or device group is listed under **Required**
5. Verify the assignment group contains the affected user/device

**Step 2 – Check app installation status**
1. In Intune admin center → **Apps** → **Monitor** → **App install status**
2. Search for the app and review the device/user status
3. Note any error codes shown (e.g. 0x87D1041C, 0x80070422)

**Step 3 – Verify device compliance and enrolment**
1. Go to **Devices** → **All devices** → locate the device
2. Confirm **MDM authority** is set to Intune
3. Check **Last check-in** — if over 8 hours, sync the device (see Issue 3)
4. Confirm the device is **Compliant**

**Step 4 – Check Intune Management Extension (IME) for Win32 apps**
1. On the affected device, open **Event Viewer**
2. Navigate to: `Applications and Services Logs > Microsoft > Windows > DeviceManagement-Enterprise-Diagnostics-Provider`
3. Filter for errors related to app deployment
4. Also check: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
4. Look for the app name and review error messages

**Step 5 – Check Company Portal**
1. Open **Company Portal** on the device
2. Go to **Apps** and check if the app appears under **Installed** or shows an error
3. If an error is shown, note the error code and escalate if needed

**Step 6 – Force a re-install attempt**
1. In Intune admin center → **Devices** → select the device
2. Click **Sync** to push a policy refresh
3. Wait 15–30 minutes and recheck app status

**Common Error Codes**

| Code | Meaning |
|------|---------|
| 0x87D1041C | App not detected after install — check detection rules |
| 0x80070422 | Windows Update service disabled |
| 0x87D13B64 | App dependency missing |

---

## Issue 2: Installation Stuck in Pending State

### Symptoms
- App status shows **Pending install** in Intune portal for an extended period
- No progress on device after policy sync
- Company Portal shows app as downloading but does not complete

### Step-by-Step Resolution

**Step 1 – Confirm pending duration**
1. In Intune admin center → **Apps** → **Monitor** → **App install status**
2. If pending for more than 1 hour after last sync, proceed to next steps

**Step 2 – Sync the device**
1. On the device: **Settings** → **Accounts** → **Access work or school**
2. Click the work account → **Info** → **Sync**
3. Alternatively, in Intune admin center → **Devices** → select device → **Sync**

**Step 3 – Restart the Intune Management Extension service**
1. On the device, open **Services** (`services.msc`)
2. Locate **Microsoft Intune Management Extension**
3. Right-click → **Restart**
4. Wait 5 minutes and check Company Portal for progress

**Step 4 – Clear the IME cache**
1. Stop the **Microsoft Intune Management Extension** service
2. Navigate to: `C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Staging`
3. Delete the contents of the **Staging** folder
4. Restart the **Microsoft Intune Management Extension** service
5. Trigger a sync and monitor for progress

**Step 5 – Check disk space**
1. Confirm the device has at least **10 GB** of free disk space on the system drive
2. Low disk space can cause installations to stall in a pending state

**Step 6 – Review Delivery Optimization settings**
1. Open **Settings** → **Windows Update** → **Advanced options** → **Delivery Optimization**
2. Confirm Delivery Optimization is not blocking downloads
3. If on a restricted network, ensure the device can reach Microsoft CDN endpoints

**Step 7 – Re-deploy the app**
1. In Intune admin center → **Apps** → select the app → **Properties** → **Assignments**
2. Remove the device/user group assignment, save, then re-add and save
3. This triggers a fresh deployment cycle

**Step 8 – Escalate if unresolved**
- Collect IME logs from `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\`
- Note the app name, version, device name, and Intune device ID
- Raise with Tier 2 / Microsoft Support if the issue persists after all steps above

---

## Issue 3: Verify Device Sync Status

### Symptoms
- Policies or apps are not applying to a device
- Device shows stale **Last check-in** time in Intune
- User reports settings reverting or apps disappearing

### Step-by-Step Resolution

**Step 1 – Check last sync time in Intune**
1. Open **Microsoft Intune admin center** → **Devices** → **All devices**
2. Search for the device by name or user
3. Review the **Last check-in** column
4. If last check-in is over **8 hours** ago on an active device, investigate further

**Step 2 – Initiate a manual sync from the device**
1. **Windows 11/10**: **Settings** → **Accounts** → **Access work or school** → select account → **Info** → **Sync**
2. Wait up to 15 minutes for the sync to complete
3. Recheck **Last check-in** in Intune admin center

**Step 3 – Initiate a remote sync from Intune**
1. In Intune admin center → **Devices** → **All devices**
2. Select the affected device
3. Click **Sync** in the top action bar
4. Confirm the action and allow up to 15 minutes

**Step 4 – Verify device enrolment status**
1. On the device: **Settings** → **Accounts** → **Access work or school**
2. Confirm the device shows a connected work or school account
3. If not connected, re-enrol the device:
   - Disconnect the existing account
   - Re-add via **Connect** → enter corporate credentials

**Step 5 – Check MDM diagnostic logs on the device**
1. Open **Settings** → **Accounts** → **Access work or school** → **Info**
2. Scroll down and click **Create report** under **Device sync status**
3. Open the generated report and review for errors

**Step 6 – Run MDM diagnostics via command line**
1. Open **Command Prompt** as Administrator
2. Run: `mdmdiagnosticstool.exe -out C:\MDMLogs`
3. Review the output in `C:\MDMLogs` for sync or certificate errors

**Step 7 – Check Intune device status in the portal**
1. In Intune admin center → **Devices** → select the device
2. Check the following:
   - **Compliance state** — must be Compliant
   - **Device category** — must match policy scope
   - **Primary user** — confirm correct user is assigned
   - **Ownership** — confirm Corporate or Personal as expected

**Step 8 – Verify network connectivity to Intune endpoints**
1. Confirm the device can reach required Microsoft endpoints:
   - `enrollment.manage.microsoft.com`
   - `dm.microsoft.com`
   - `*.manage.microsoft.com`
2. If on a corporate network, confirm proxy/firewall rules allow these endpoints

**Step 9 – Re-enrol if sync cannot be restored**
1. In Intune admin center → **Devices** → select device → **Delete** (removes MDM record)
2. On the device, go to **Settings** → **Accounts** → **Access work or school** → disconnect the account
3. Re-enrol the device by connecting the work account again
4. Monitor sync status after re-enrolment

---

## Quick Reference Checklist

| Check | Required Apps | Pending Install | Sync Status |
|-------|--------------|-----------------|-------------|
| App assignment verified | ✓ | ✓ | |
| Device last check-in < 8 hrs | ✓ | ✓ | ✓ |
| Manual sync triggered | ✓ | ✓ | ✓ |
| IME service running | | ✓ | |
| Disk space sufficient | | ✓ | |
| Device compliant | ✓ | | ✓ |
| MDM enrolment active | ✓ | | ✓ |
| Network endpoints reachable | | ✓ | ✓ |

---

*Guide last updated: 2026-08-12*
