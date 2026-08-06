<#
Startup Program Auditor for Windows endpoints.
PowerShell 5.1 compatible and designed to inventory or disable startup entries safely.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Disable,

    [ValidateNotNullOrEmpty()]
    [string]$ProgramName,

    [string[]]$RegistryPaths = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce'
    ),

    [string[]]$StartupFolderPaths = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    )
)

# This section enables strict error handling so failures are logged and handled per item.
$ErrorActionPreference = 'Stop'

# This section creates a timestamped log folder for the current run and a backup area for disabled items.
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$runStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$baseLogPath = Join-Path $scriptRoot 'startup-auditor-logs'
$runFolder = Join-Path $baseLogPath $runStamp
$backupRoot = Join-Path $baseLogPath 'disabled-items'
$runBackupRoot = Join-Path $backupRoot $runStamp
$logFile = Join-Path $runFolder 'startup-auditor.log'
$actionLogPath = Join-Path $runFolder 'actions.json'

New-Item -Path $runFolder -ItemType Directory -Force | Out-Null
New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null
if ($Disable) {
    New-Item -Path $runBackupRoot -ItemType Directory -Force | Out-Null
}
New-Item -Path $logFile -ItemType File -Force | Out-Null

$actionLog = New-Object System.Collections.Generic.List[object]

# This section writes every message to the console and timestamped log file.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = '[{0}] [{1}] {2}' -f $timestamp, $Level, $Message
    Add-Content -Path $logFile -Value $line
    Write-Host $line
}

# This section records inventory and disable actions so the run can be audited later.
function Add-ActionRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [string]$Status,

        [string]$Location,

        [string]$SourcePath,

        [string]$BackupPath,

        [string]$Message
    )

    $actionLog.Add([pscustomobject]@{
        TimeStamp = Get-Date
        Action    = $Action
        Name      = $Name
        Type      = $Type
        Status    = $Status
        Location  = $Location
        SourcePath = $SourcePath
        BackupPath = $BackupPath
        Message   = $Message
    }) | Out-Null
}

# This section saves the run action log as JSON for audit and recovery purposes.
function Save-ActionLog {
    $actionLog | ConvertTo-Json -Depth 6 | Set-Content -Path $actionLogPath -Encoding UTF8
    Write-Log -Message ("Action log saved to: {0}" -f $actionLogPath)
}

# This section resolves shortcut metadata for startup folder items when the entry is a .lnk file.
function Get-ShortcutInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $result = [pscustomobject]@{
        TargetPath      = ''
        Arguments       = ''
        WorkingDirectory = ''
    }

    $shell = $null
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($Path)
        $result.TargetPath = $shortcut.TargetPath
        $result.Arguments = $shortcut.Arguments
        $result.WorkingDirectory = $shortcut.WorkingDirectory
    }
    catch {
        $result.TargetPath = $Path
        $result.Arguments = ''
        $result.WorkingDirectory = ''
    }
    finally {
        if ($shell) {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
        }
    }

    return $result
}

# This section reads common registry startup locations and returns each enabled entry.
function Get-RegistryStartupItems {
    param(
        [string[]]$Paths
    )

    $items = New-Object System.Collections.Generic.List[object]

    foreach ($path in ($Paths | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $path)) {
            Write-Log -Level 'WARN' -Message ("Registry startup path not found: {0}" -f $path)
            continue
        }

        try {
            $entry = Get-ItemProperty -LiteralPath $path -ErrorAction Stop
            foreach ($property in $entry.PSObject.Properties) {
                if ($property.Name -like 'PS*') {
                    continue
                }

                [void]$items.Add([pscustomobject]@{
                    Name       = $property.Name
                    Type       = 'Registry'
                    Location   = $path
                    SourcePath = $path
                    EntryPath  = $path
                    RegistryValueName = $property.Name
                    Command    = [string]$property.Value
                    Status     = 'Enabled'
                })
            }
        }
        catch {
            Write-Log -Level 'WARN' -Message ("Failed to read registry startup path {0}: {1}" -f $path, $_.Exception.Message)
        }
    }

    return $items
}

# This section reads startup folder entries for the current user and all users.
function Get-StartupFolderItems {
    param(
        [string[]]$Paths
    )

    $items = New-Object System.Collections.Generic.List[object]

    foreach ($path in ($Paths | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $path)) {
            Write-Log -Level 'WARN' -Message ("Startup folder not found: {0}" -f $path)
            continue
        }

        try {
            $files = Get-ChildItem -LiteralPath $path -File -Force -ErrorAction Stop
            foreach ($file in $files) {
                $command = $file.FullName
                if ($file.Extension -ieq '.lnk') {
                    $shortcutInfo = Get-ShortcutInfo -Path $file.FullName
                    if ($shortcutInfo.TargetPath) {
                        $command = $shortcutInfo.TargetPath
                        if ($shortcutInfo.Arguments) {
                            $command = '{0} {1}' -f $shortcutInfo.TargetPath, $shortcutInfo.Arguments
                        }
                    }
                }

                [void]$items.Add([pscustomobject]@{
                    Name       = $file.BaseName
                    Type       = 'StartupFolder'
                    Location   = $path
                    SourcePath = $file.FullName
                    EntryPath  = $file.FullName
                    RegistryValueName = ''
                    Command    = $command
                    Status     = 'Enabled'
                })
            }
        }
        catch {
            Write-Log -Level 'WARN' -Message ("Failed to read startup folder {0}: {1}" -f $path, $_.Exception.Message)
        }
    }

    return $items
}

# This section combines all startup sources into a single inventory list.
function Get-StartupInventory {
    param(
        [string[]]$RegistryPaths,
        [string[]]$StartupFolderPaths
    )

    $inventory = New-Object System.Collections.Generic.List[object]
    foreach ($item in (Get-RegistryStartupItems -Paths $RegistryPaths)) {
        [void]$inventory.Add($item)
    }
    foreach ($item in (Get-StartupFolderItems -Paths $StartupFolderPaths)) {
        [void]$inventory.Add($item)
    }

    return $inventory | Sort-Object Type, Name, Location
}

# This section writes the startup inventory to the console and logs each discovered item.
function Write-StartupInventory {
    param(
        [object[]]$Inventory
    )

    if (-not $Inventory -or $Inventory.Count -eq 0) {
        Write-Log -Message 'No startup entries were found.'
        return
    }

    foreach ($item in $Inventory) {
        Write-Log -Message ("Found: {0} | {1} | {2} | {3}" -f $item.Name, $item.Type, $item.Location, $item.Command)
        Add-ActionRecord -Action 'Inventory' -Name $item.Name -Type $item.Type -Status 'Listed' -Location $item.Location -SourcePath $item.SourcePath -Message 'Startup item listed'
    }

    Write-Host ''
    $Inventory |
        Select-Object Name, Type, Location, Command, Status |
        Format-Table -AutoSize
}

# This section disables a single registry startup entry by removing the registry value after backing it up.
function Disable-RegistryStartupItem {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Item
    )

    if ($PSCmdlet.ShouldProcess($Item.Name, "Disable registry startup entry from $($Item.Location)")) {
        $entryId = [guid]::NewGuid().Guid
        $itemBackupRoot = Join-Path $runBackupRoot $entryId
        New-Item -Path $itemBackupRoot -ItemType Directory -Force | Out-Null

        $backupPath = Join-Path $itemBackupRoot 'registry-backup.json'
        $backup = [pscustomobject]@{
            Name       = $Item.Name
            Type       = $Item.Type
            Location   = $Item.Location
            SourcePath = $Item.SourcePath
            RegistryValueName = $Item.RegistryValueName
            Command    = $Item.Command
            DisabledOn = Get-Date
            RunId      = $runStamp
        }
        $backup | ConvertTo-Json -Depth 6 | Set-Content -Path $backupPath -Encoding UTF8

        Remove-ItemProperty -LiteralPath $Item.SourcePath -Name $Item.RegistryValueName -ErrorAction Stop
        Write-Log -Level 'SUCCESS' -Message ("Disabled registry entry: {0}" -f $Item.Name)
        Add-ActionRecord -Action 'Disable' -Name $Item.Name -Type $Item.Type -Status 'Disabled' -Location $Item.Location -SourcePath $Item.SourcePath -BackupPath $backupPath -Message 'Registry value removed after backup'
        return $true
    }

    return $false
}

# This section disables a startup folder entry by moving it to the backup area.
function Disable-StartupFolderItem {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Item
    )

    if ($PSCmdlet.ShouldProcess($Item.Name, "Move startup file out of $($Item.Location)")) {
        $entryId = [guid]::NewGuid().Guid
        $itemBackupRoot = Join-Path $runBackupRoot $entryId
        New-Item -Path $itemBackupRoot -ItemType Directory -Force | Out-Null

        $destinationPath = Join-Path $itemBackupRoot $Item.Name
        $backupPath = Join-Path $itemBackupRoot 'folder-backup.json'
        $backup = [pscustomobject]@{
            Name       = $Item.Name
            Type       = $Item.Type
            Location   = $Item.Location
            SourcePath = $Item.SourcePath
            Command    = $Item.Command
            DisabledOn = Get-Date
            RunId      = $runStamp
        }
        $backup | ConvertTo-Json -Depth 6 | Set-Content -Path $backupPath -Encoding UTF8

        Move-Item -LiteralPath $Item.SourcePath -Destination $destinationPath -Force -ErrorAction Stop
        Write-Log -Level 'SUCCESS' -Message ("Disabled startup file: {0}" -f $Item.Name)
        Add-ActionRecord -Action 'Disable' -Name $Item.Name -Type $Item.Type -Status 'Disabled' -Location $Item.Location -SourcePath $Item.SourcePath -BackupPath $destinationPath -Message 'Startup file moved to backup area'
        return $true
    }

    return $false
}

# This section disables all matching entries for the requested program name.
function Disable-StartupEntries {
    param(
        [object[]]$Inventory,
        [string]$Name
    )

    $matches = @($Inventory | Where-Object { $_.Name -ieq $Name })
    if ($matches.Count -eq 0) {
        Write-Log -Level 'WARN' -Message ("No startup entries matched program name: {0}" -f $Name)
        return [pscustomobject]@{
            Mode        = 'Disable'
            ProgramName = $Name
            Matched     = 0
            Disabled    = 0
            Skipped     = 0
            Failed      = 0
            LogFile     = $logFile
            BackupRoot  = $backupRoot
            ActionLog   = $actionLogPath
        }
    }

    $disabledCount = 0
    $skippedCount = 0
    $failedCount = 0

    foreach ($item in $matches) {
        try {
            switch ($item.Type) {
                'Registry' {
                    if (Disable-RegistryStartupItem -Item $item) {
                        $disabledCount++
                    }
                    else {
                        $skippedCount++
                    }
                }
                'StartupFolder' {
                    if (Disable-StartupFolderItem -Item $item) {
                        $disabledCount++
                    }
                    else {
                        $skippedCount++
                    }
                }
                default {
                    $skippedCount++
                    Write-Log -Level 'WARN' -Message ("Unsupported startup item type skipped: {0}" -f $item.Name)
                    Add-ActionRecord -Action 'Disable' -Name $item.Name -Type $item.Type -Status 'Skipped' -Location $item.Location -SourcePath $item.SourcePath -Message 'Unsupported item type'
                }
            }
        }
        catch {
            $failedCount++
            Write-Log -Level 'ERROR' -Message ("Failed to disable {0}: {1}" -f $item.Name, $_.Exception.Message)
            Add-ActionRecord -Action 'Disable' -Name $item.Name -Type $item.Type -Status 'Failed' -Location $item.Location -SourcePath $item.SourcePath -Message $_.Exception.Message
        }
    }

    return [pscustomobject]@{
        Mode        = 'Disable'
        ProgramName = $Name
        Matched     = $matches.Count
        Disabled    = $disabledCount
        Skipped     = $skippedCount
        Failed      = $failedCount
        LogFile     = $logFile
        BackupRoot  = $backupRoot
        ActionLog   = $actionLogPath
    }
}

# This section validates the disable request before any changes are made.
if ($Disable -and [string]::IsNullOrWhiteSpace($ProgramName)) {
    throw 'ProgramName is required when using -Disable.'
}

# This section logs the operator request so the run is fully traceable.
Write-Log -Message 'Startup program auditor started.'
Write-Log -Message ("Disable  : {0}" -f $Disable)
Write-Log -Message ("Program  : {0}" -f $(if ($ProgramName) { $ProgramName } else { '<none>' }))
Write-Log -Message ("Registry : {0}" -f ($RegistryPaths -join ', '))
Write-Log -Message ("Folders  : {0}" -f ($StartupFolderPaths -join ', '))

# This section builds the current startup inventory for either listing or disabling.
$inventory = @(Get-StartupInventory -RegistryPaths $RegistryPaths -StartupFolderPaths $StartupFolderPaths)

if ($Disable) {
    # This section disables the requested startup entry and keeps a backup in the run folder.
    $summary = Disable-StartupEntries -Inventory $inventory -Name $ProgramName
}
else {
    # This section only lists the startup entries and does not change the system.
    Write-StartupInventory -Inventory $inventory
    $summary = [pscustomobject]@{
        Mode        = 'Inventory'
        ProgramName = ''
        Matched     = $inventory.Count
        Disabled    = 0
        Skipped     = 0
        Failed      = 0
        LogFile     = $logFile
        BackupRoot  = $backupRoot
        ActionLog   = $actionLogPath
    }
}

# This section persists the action log for auditability.
Save-ActionLog

# This section prints the final summary so the operator can confirm the result quickly.
Write-Host ''
Write-Log -Message ('{0} completed.' -f $summary.Mode)
$summary | Format-List
