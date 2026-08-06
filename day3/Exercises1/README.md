# Startup Program Auditor

This folder contains a PowerShell 5.1 script for listing and disabling startup entries on Windows endpoints.

Script: [startup-program-auditor.ps1](startup-program-auditor.ps1)

## What it does

The script reads common startup locations and lists the programs it finds. If requested, it can disable matching entries by program name.

## Parameters

`-Disable`

Disables startup entries that match `-ProgramName`.

`-ProgramName <string>`

The startup entry name to disable. This is required when `-Disable` is used and must match the entry name exactly.

`-RegistryPaths <string[]>`

Optional override for the registry startup paths to audit. Defaults to common Run and RunOnce locations for HKCU and HKLM.

`-StartupFolderPaths <string[]>`

Optional override for the startup folders to audit. Defaults to the current user and all users startup folders.

## Examples

List all startup entries:

```powershell
.\startup-program-auditor.ps1
```

Disable a startup entry by name:

```powershell
.\startup-program-auditor.ps1 -Disable -ProgramName OneDrive
```

Audit custom paths:

```powershell
.\startup-program-auditor.ps1 -RegistryPaths @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run') -StartupFolderPaths @('C:\Temp\Startup')
```

Preview a disable operation without making changes:

```powershell
.\startup-program-auditor.ps1 -Disable -ProgramName OneDrive -WhatIf
```

## Logging and backups

Each run creates a timestamped folder under `startup-auditor-logs` in the script directory.

That folder contains:

- `startup-auditor.log` for human-readable logging
- `actions.json` for the run history
- `disabled-items\<RunId>\` folders with backup metadata and any moved startup files

## Safety notes

- The script logs each item it reads and each change it makes.
- Disable operations back up the affected entry before changing anything.
- Running the script again is idempotent because already-disabled entries are no longer listed in the startup locations.
