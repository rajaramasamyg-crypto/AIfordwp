<#
Temp file cleanup script for Windows endpoints.
PowerShell 5.1 compatible and designed for safe, repeatable cleanup.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,

    [ValidateRange(0, 36500)]
    [int]$DaysOld = 0,

    [string[]]$TargetPaths = @(
        $env:TEMP,
        "$env:WINDIR\Temp"
    ),

    [switch]$Rollback,

    [string]$RollbackId
)

# This section sets strict error handling so unexpected failures are surfaced and logged.
$ErrorActionPreference = 'Stop'

# This section creates a timestamped run folder for logs and a separate rollback store.
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$runStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$baseLogPath = Join-Path $scriptRoot 'temp-cleanup-logs'
$runLogPath = Join-Path $baseLogPath $runStamp
$rollbackRoot = Join-Path $baseLogPath 'rollback'
$runRollbackPath = Join-Path $rollbackRoot $runStamp
$logFile = Join-Path $runLogPath 'cleanup.log'
$actionLogPath = Join-Path $runLogPath 'actions.json'

New-Item -Path $runLogPath -ItemType Directory -Force | Out-Null
New-Item -Path $rollbackRoot -ItemType Directory -Force | Out-Null
if (-not $Rollback) {
    New-Item -Path $runRollbackPath -ItemType Directory -Force | Out-Null
}
New-Item -Path $logFile -ItemType File -Force | Out-Null

$actionLog = New-Object System.Collections.Generic.List[object]

# This section writes every action to the timestamped log file and to the console.
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

# This section records each action so the run can be audited and rolled back later.
function Add-ActionRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [string]$BackupPath,

        [Parameter(Mandatory = $true)]
        [string]$Status,

        [string]$Message
    )

    $actionLog.Add([pscustomobject]@{
        TimeStamp  = Get-Date
        Action     = $Action
        SourcePath = $SourcePath
        BackupPath = $BackupPath
        Status     = $Status
        Message    = $Message
    }) | Out-Null
}

# This section saves the JSON action log for the current run.
function Save-ActionLog {
    $actionLog | ConvertTo-Json -Depth 5 | Set-Content -Path $actionLogPath -Encoding UTF8
    Write-Log -Message ("Action log saved to: {0}" -f $actionLogPath)
}

# This section checks whether a file is currently locked so the script can skip it safely.
function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
        return $false
    }
    catch [System.UnauthorizedAccessException] {
        return $true
    }
    catch [System.IO.IOException] {
        return $true
    }
}

# This section resolves the rollback folder to use for restore operations.
function Get-RollbackSourceRoot {
    param(
        [string]$SpecifiedRollbackId
    )

    if ($SpecifiedRollbackId) {
        $target = Join-Path $rollbackRoot $SpecifiedRollbackId
        if (Test-Path -LiteralPath $target) {
            return $target
        }

        return $null
    }

    if (-not (Test-Path -LiteralPath $rollbackRoot)) {
        return $null
    }

    $latestRollback = Get-ChildItem -Path $rollbackRoot -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latestRollback) {
        return $latestRollback.FullName
    }

    return $null
}

# This section collects candidate files older than the configured age from the target paths.
function Get-CleanupCandidates {
    param(
        [string[]]$Paths,
        [datetime]$CutoffDate
    )

    $files = New-Object System.Collections.Generic.List[object]

    foreach ($path in ($Paths | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $path)) {
            Write-Log -Level 'WARN' -Message ("Target path not found: {0}" -f $path)
            continue
        }

        $enumeratedFiles = Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($file in $enumeratedFiles) {
            if ($file.LastWriteTime -lt $CutoffDate) {
                [void]$files.Add($file)
            }
        }
    }

    return $files | Sort-Object FullName | Group-Object FullName | ForEach-Object { $_.Group[0] }
}

# This section restores files from the newest backup set or from a specific rollback ID.
function Invoke-Rollback {
    param(
        [string]$SpecifiedRollbackId
    )

    $restoredCount = 0
    $failedCount = 0
    $rollbackSourceRoot = Get-RollbackSourceRoot -SpecifiedRollbackId $SpecifiedRollbackId

    if (-not $rollbackSourceRoot) {
        Write-Log -Level 'ERROR' -Message 'No rollback set was found.'
        return [pscustomobject]@{
            Mode        = 'Rollback'
            Restored    = 0
            Failed      = 0
            LogFile     = $logFile
            RollbackDir = $rollbackRoot
            ActionLog   = $actionLogPath
        }
    }

    Write-Log -Message ("Rollback source : {0}" -f $rollbackSourceRoot)

    $rollbackEntries = Get-ChildItem -Path $rollbackSourceRoot -Directory -ErrorAction SilentlyContinue
    if (-not $rollbackEntries) {
        Write-Log -Level 'WARN' -Message 'No backup entries were found for rollback.'
        return [pscustomobject]@{
            Mode        = 'Rollback'
            Restored    = 0
            Failed      = 0
            LogFile     = $logFile
            RollbackDir = $rollbackRoot
            ActionLog   = $actionLogPath
        }
    }

    foreach ($entry in $rollbackEntries) {
        $metadataPath = Join-Path $entry.FullName 'metadata.json'

        try {
            if (-not (Test-Path -LiteralPath $metadataPath)) {
                Write-Log -Level 'WARN' -Message ("Rollback metadata not found, skipped: {0}" -f $entry.FullName)
                Add-ActionRecord -Action 'Rollback' -SourcePath $entry.FullName -Status 'Skipped' -Message 'Missing metadata.json'
                continue
            }

            $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
            $backupFile = Get-ChildItem -Path $entry.FullName -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -ne 'metadata.json' } |
                Select-Object -First 1

            if (-not $backupFile) {
                Write-Log -Level 'WARN' -Message ("Rollback backup file not found, skipped: {0}" -f $entry.FullName)
                Add-ActionRecord -Action 'Rollback' -SourcePath $entry.FullName -Status 'Skipped' -Message 'Missing backup file'
                continue
            }

            $restorePath = $metadata.OriginalPath
            $restoreDirectory = Split-Path -Parent $restorePath
            if ($restoreDirectory -and -not (Test-Path -LiteralPath $restoreDirectory)) {
                New-Item -Path $restoreDirectory -ItemType Directory -Force | Out-Null
            }

            Copy-Item -LiteralPath $backupFile.FullName -Destination $restorePath -Force -ErrorAction Stop
            Write-Log -Level 'SUCCESS' -Message ("Restored: {0}" -f $restorePath)
            Add-ActionRecord -Action 'Rollback' -SourcePath $restorePath -BackupPath $backupFile.FullName -Status 'Restored' -Message 'File restored from rollback backup'
            $restoredCount++
        }
        catch {
            $failedCount++
            Write-Log -Level 'ERROR' -Message ("Rollback failed for {0}: {1}" -f $entry.FullName, $_.Exception.Message)
            Add-ActionRecord -Action 'Rollback' -SourcePath $entry.FullName -Status 'Failed' -Message $_.Exception.Message
        }
    }

    return [pscustomobject]@{
        Mode        = 'Rollback'
        Restored    = $restoredCount
        Failed      = $failedCount
        LogFile     = $logFile
        RollbackDir = $rollbackRoot
        ActionLog   = $actionLogPath
    }
}

# This section deletes cleanup candidates one file at a time and keeps going on errors.
function Invoke-Cleanup {
    param(
        [datetime]$CutoffDate,
        [string[]]$Paths,
        [switch]$DryRun
    )

    $deletedCount = 0
    $skippedCount = 0
    $lockedCount = 0
    $failedCount = 0

    $candidates = @(Get-CleanupCandidates -Paths $Paths -CutoffDate $CutoffDate)
    $candidateCount = $candidates.Count

    if ($DryRun) {
        Write-Log -Message 'Dry run enabled. No files will be deleted.'
        if ($candidateCount -eq 0) {
            Write-Log -Message 'No files matched the cleanup criteria.'
        }
        foreach ($file in $candidates) {
            Write-Log -Message ("Would delete: {0}" -f $file.FullName)
            Add-ActionRecord -Action 'DryRun' -SourcePath $file.FullName -Status 'WouldDelete' -Message 'Candidate file older than cutoff'
        }

        return [pscustomobject]@{
            Mode        = 'DryRun'
            DryRun      = $true
            Candidates  = $candidateCount
            Deleted     = 0
            Skipped     = 0
            Locked      = 0
            Failed      = 0
            LogFile     = $logFile
            RollbackDir = $rollbackRoot
            ActionLog   = $actionLogPath
        }
    }

    foreach ($file in $candidates) {
        try {
            if (-not (Test-Path -LiteralPath $file.FullName)) {
                $skippedCount++
                Write-Log -Level 'WARN' -Message ("File no longer exists, skipped: {0}" -f $file.FullName)
                Add-ActionRecord -Action 'Delete' -SourcePath $file.FullName -Status 'Missing' -Message 'File disappeared before cleanup'
                continue
            }

            if (Test-FileLocked -Path $file.FullName) {
                $lockedCount++
                Write-Log -Level 'WARN' -Message ("Locked file skipped: {0}" -f $file.FullName)
                Add-ActionRecord -Action 'Delete' -SourcePath $file.FullName -Status 'Locked' -Message 'File was in use and skipped'
                continue
            }

            $entryId = [guid]::NewGuid().Guid
            $backupDirectory = Join-Path $runRollbackPath $entryId
            New-Item -Path $backupDirectory -ItemType Directory -Force | Out-Null

            $backupPath = Join-Path $backupDirectory $file.Name
            $metadataPath = Join-Path $backupDirectory 'metadata.json'

            Copy-Item -LiteralPath $file.FullName -Destination $backupPath -Force -ErrorAction Stop
            Write-Log -Message ("Backup created: {0}" -f $backupPath)
            Add-ActionRecord -Action 'Backup' -SourcePath $file.FullName -BackupPath $backupPath -Status 'Created' -Message 'File copied for rollback'

            $metadata = [pscustomobject]@{
                OriginalPath = $file.FullName
                OriginalName = $file.Name
                BackupPath   = $backupPath
                DeletedOn    = Get-Date
                RollbackId   = $runStamp
            }
            $metadata | ConvertTo-Json -Depth 3 | Set-Content -Path $metadataPath -Encoding UTF8

            Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
            Write-Log -Level 'SUCCESS' -Message ("Deleted: {0}" -f $file.FullName)
            Add-ActionRecord -Action 'Delete' -SourcePath $file.FullName -BackupPath $backupPath -Status 'Deleted' -Message 'File backed up and deleted'
            $deletedCount++
        }
        catch [System.UnauthorizedAccessException] {
            $lockedCount++
            Write-Log -Level 'WARN' -Message ("Locked or inaccessible, skipped: {0} - {1}" -f $file.FullName, $_.Exception.Message)
            Add-ActionRecord -Action 'Delete' -SourcePath $file.FullName -Status 'LockedOrInaccessible' -Message $_.Exception.Message
            continue
        }
        catch [System.IO.IOException] {
            $lockedCount++
            Write-Log -Level 'WARN' -Message ("Locked file skipped: {0} - {1}" -f $file.FullName, $_.Exception.Message)
            Add-ActionRecord -Action 'Delete' -SourcePath $file.FullName -Status 'LockedOrInaccessible' -Message $_.Exception.Message
            continue
        }
        catch {
            $failedCount++
            Write-Log -Level 'ERROR' -Message ("Failed to delete {0}: {1}" -f $file.FullName, $_.Exception.Message)
            Add-ActionRecord -Action 'Delete' -SourcePath $file.FullName -Status 'Failed' -Message $_.Exception.Message
            continue
        }
    }

    return [pscustomobject]@{
        Mode        = 'Cleanup'
        DryRun      = $false
        Candidates  = $candidateCount
        Deleted     = $deletedCount
        Skipped     = $skippedCount
        Locked      = $lockedCount
        Failed      = $failedCount
        LogFile     = $logFile
        RollbackDir = $rollbackRoot
        ActionLog   = $actionLogPath
    }
}

# This section prints the current run settings so the log captures the operator request.
Write-Log -Message 'Temp cleanup script started.'
Write-Log -Message ("Dry run   : {0}" -f $DryRun)
Write-Log -Message ("Rollback  : {0}" -f $Rollback)
Write-Log -Message ("Days old  : {0}" -f $DaysOld)
Write-Log -Message ("Targets   : {0}" -f ($TargetPaths -join ', '))

# This section calculates the cutoff date so only files older than the requested age are targeted.
$cutoffDate = (Get-Date).AddDays(-1 * $DaysOld)
Write-Log -Message ("Cutoff date : {0}" -f $cutoffDate)

# This section runs either rollback or cleanup and then saves the action log.
if ($Rollback) {
    $summary = Invoke-Rollback -SpecifiedRollbackId $RollbackId
}
else {
    $summary = Invoke-Cleanup -CutoffDate $cutoffDate -Paths $TargetPaths -DryRun:$DryRun
}

Save-ActionLog

# This section prints a compact summary so operators can confirm the result quickly.
Write-Host ''
Write-Log -Message ('{0} completed.' -f $summary.Mode)
$summary | Format-List