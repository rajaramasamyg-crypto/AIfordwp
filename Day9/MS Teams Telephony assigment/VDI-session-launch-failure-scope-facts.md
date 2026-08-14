# VDI Session Launch Failure - Scope Facts

## 1. Affected pool and user impact
- Affected pool: FinBridge-VDI-Pool-02
- Impacted users: 22 of 30
- Unaffected pool: FinBridge-VDI-Pool-01 (same site, different pool)

## 2. Exact broker error
- Session launch failed with error 1030: No machines available in the desktop group
- Preceding broker event: Timeout waiting for machine registration response (30000ms exceeded)

## 3. Machine catalog registration status
- FinBridge-VDI-Pool-02 catalog: 25 provisioned, 3 registered, 22 unregistered, 0 in maintenance mode
- FinBridge-VDI-Pool-01 catalog: 20 provisioned, 19 registered, 1 unregistered

## 4. Delivery Controller health check
- dc-vdi-02: Citrix Broker Service STOPPED; last known running yesterday 23:40; Windows Update installed today 00:15; reboot required flag set; host not rebooted
- dc-vdi-01: Citrix Broker Service RUNNING; uptime 14 days
