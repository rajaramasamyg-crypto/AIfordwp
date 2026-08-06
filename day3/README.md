# Temp File Cleanup Script

This folder contains a PowerShell 5.1 script for safely cleaning temp files on Windows endpoints.

Script: [endpoint-health-report.ps1](endpoint-health-report.ps1)

## What it does

The script scans one or more temp locations, targets only files older than the configured age, and processes each file individually.

Safety features:

- Dry run mode prints the files that would be deleted.
- Locked or inaccessible files are skipped and logged.
- Every run writes a timestamped log file.
- Deleted files are backed up for rollback.
- A summary is shown at the end.
- One file failing does not stop the whole run.

## Parameters

`-DryRun`

Preview mode. No files are deleted. The script prints every file that matches the cleanup criteria and writes the same details to the log.

`-DaysOld <int>`

Only files older than this many days are targeted. Default: `0`.

`-TargetPaths <string[]>`

Overrides the temp folders to scan. Default targets are the current user temp folder and `C:\Windows\Temp`.

`-Rollback`

Restores files from the latest rollback set or from a specific rollback folder when `-RollbackId` is provided.

`-RollbackId <string>`

Selects a specific rollback run folder to restore from.

## Examples

Preview the default temp locations:

```powershell
.\endpoint-health-report.ps1 -DryRun
```

Delete only files older than 7 days:

```powershell
.\endpoint-health-report.ps1 -DaysOld 7
```

Preview custom locations:

```powershell
.\endpoint-health-report.ps1 -DryRun -TargetPaths @('C:\Temp','C:\Windows\Temp')
```

Restore from the latest backup set:

```powershell
.\endpoint-health-report.ps1 -Rollback
```

Restore from a specific backup set:

```powershell
.\endpoint-health-report.ps1 -Rollback -RollbackId 20260805-143000
```

## Logging and rollback

Each run creates a timestamped folder under `temp-cleanup-logs` in the script directory.

That folder contains:

- `cleanup.log` for human-readable logging
- `actions.json` for the per-file action history
- `rollback\<RunId>\` folders with the backed up files and metadata

Rollback restores the original file path from the stored metadata. If a backup set is missing or incomplete, the script logs the issue and continues.

## Idempotence and safety

- Running cleanup again only targets files that still exist and are still older than the cutoff.
- Running rollback again overwrites the restored file with the backed-up copy.
- Dry run makes no changes.
- Run from an elevated PowerShell session if the target temp paths require it.
