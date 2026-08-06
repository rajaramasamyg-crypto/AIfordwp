# Large File Finder

This folder contains a PowerShell 5.1 script that reads and reports large files without making changes.

Script: [large-file-finder.ps1](large-file-finder.ps1)

## What it does

The script scans one or more paths, finds files at or above a configurable size threshold, and reports the results.

## Parameters

`-ThresholdMB <int>`

Sets the minimum file size in megabytes. Default: `100`.

`-TargetPaths <string[]>`

Sets the folders to scan. Default targets are the current user profile and the system drive root.

## Examples

Scan with the default threshold:

```powershell
.\large-file-finder.ps1
```

Find files larger than 250 MB:

```powershell
.\large-file-finder.ps1 -ThresholdMB 250
```

Scan custom locations:

```powershell
.\large-file-finder.ps1 -TargetPaths @('C:\Users','D:\Data')
```

## Output

The script writes:

- a timestamped log file
- a CSV report of matching files
- a summary at the end of the run

## Safety notes

- Read-only only: no files are changed or deleted.
- Errors for individual paths are logged and the scan continues.
