# Disk Health Reporter

This folder contains a PowerShell 5.1 script that reports disk health and optimization status.

Script: [disk-health-reporter.ps1](disk-health-reporter.ps1)

## What it does

The script checks logical disks, attempts to read physical disk health when available, and reports the scheduled optimization task status.

## Parameters

`-DriveLetters <string[]>`

Optional list of drive letters to inspect, such as `C` or `D`. If omitted, the script scans all fixed drives.

## Examples

Report all fixed drives:

```powershell
.\disk-health-reporter.ps1
```

Report only C and D:

```powershell
.\disk-health-reporter.ps1 -DriveLetters C,D
```

## Output

The script writes:

- a timestamped log file
- a CSV report with the collected disk status
- a summary at the end

## Safety notes

- Strictly read-only.
- It does not run defragmentation or optimization.
- Individual failures are logged and do not stop the report.
