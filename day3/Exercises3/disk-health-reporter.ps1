<#
Disk Health Reporter for Windows endpoints.
PowerShell 5.1 compatible and strictly read-only.
#>

[CmdletBinding()]
param(
    [string[]]$DriveLetters = @()
)

# This section enables strict error handling so failures are logged without stopping the full report.
$ErrorActionPreference = 'Stop'

# This section creates a timestamped log folder for the current run.
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$runStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$baseLogPath = Join-Path $scriptRoot 'disk-health-logs'
$runFolder = Join-Path $baseLogPath $runStamp
$logFile = Join-Path $runFolder 'disk-health-reporter.log'
$reportFile = Join-Path $runFolder 'disk-health-report.csv'

New-Item -Path $runFolder -ItemType Directory -Force | Out-Null
New-Item -Path $logFile -ItemType File -Force | Out-Null

$results = New-Object System.Collections.Generic.List[object]

# This section writes every message to the console and the timestamped log file.
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

# This section collects the list of logical drives to inspect.
function Get-TargetDrives {
    param(
        [string[]]$RequestedDrives
    )

    if ($RequestedDrives -and $RequestedDrives.Count -gt 0) {
        return $RequestedDrives | ForEach-Object { $_.TrimEnd(':') }
    }

    $logicalDisks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
    return $logicalDisks.DeviceID | ForEach-Object { $_.TrimEnd(':') }
}

# This section reports logical disk health and space usage without making any changes.
function Get-LogicalDiskHealth {
    param(
        [string[]]$Drives
    )

    foreach ($drive in $Drives) {
        try {
            $disk = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}:'" -f $drive) -ErrorAction Stop
            $sizeGB = if ($disk.Size) { [math]::Round(($disk.Size / 1GB), 2) } else { 0 }
            $freeGB = if ($disk.FreeSpace) { [math]::Round(($disk.FreeSpace / 1GB), 2) } else { 0 }
            $freePercent = if ($disk.Size) { [math]::Round((($disk.FreeSpace / $disk.Size) * 100), 2) } else { 0 }

            [void]$results.Add([pscustomobject]@{
                DriveLetter          = $drive
                VolumeName           = $disk.VolumeName
                FileSystem           = $disk.FileSystem
                SizeGB               = $sizeGB
                FreeGB               = $freeGB
                FreePercent          = $freePercent
                HealthStatus         = 'LogicalDisk'
                OptimizationStatus   = 'NotApplicable'
                Notes                = 'Logical disk space report'
            })
        }
        catch {
            Write-Log -Level 'WARN' -Message ("Failed to read logical disk {0}: {1}" -f $drive, $_.Exception.Message)
        }
    }
}

# This section reports physical disk health when storage cmdlets are available.
function Get-PhysicalDiskHealth {
    try {
        $physicalDisks = Get-PhysicalDisk -ErrorAction Stop
        foreach ($disk in $physicalDisks) {
            [void]$results.Add([pscustomobject]@{
                DriveLetter          = ''
                VolumeName           = $disk.FriendlyName
                FileSystem           = ''
                SizeGB               = if ($disk.Size) { [math]::Round(($disk.Size / 1GB), 2) } else { 0 }
                FreeGB               = ''
                FreePercent          = ''
                HealthStatus         = $disk.HealthStatus
                OptimizationStatus   = $disk.OperationalStatus -join ', '
                Notes                = 'Physical disk report'
            })
        }
    }
    catch {
        Write-Log -Level 'WARN' -Message ("Physical disk health not available: {0}" -f $_.Exception.Message)
    }
}

# This section reports the scheduled optimization task status without running any optimization.
function Get-OptimizationTaskStatus {
    try {
        $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' -ErrorAction Stop
        $info = $task | Get-ScheduledTaskInfo

        [void]$results.Add([pscustomobject]@{
            DriveLetter          = ''
            VolumeName           = 'ScheduledDefrag'
            FileSystem           = ''
            SizeGB               = ''
            FreeGB               = ''
            FreePercent          = ''
            HealthStatus         = $task.State
            OptimizationStatus   = ('LastRun: {0}; NextRun: {1}' -f $info.LastRunTime, $info.NextRunTime)
            Notes                = 'Scheduled optimization task status only'
        })
    }
    catch {
        Write-Log -Level 'WARN' -Message ("Scheduled optimization task not available: {0}" -f $_.Exception.Message)
    }
}

# This section logs the run settings so the report is traceable.
Write-Log -Message 'Disk health reporter started.'
Write-Log -Message ("Requested drives: {0}" -f $(if ($DriveLetters.Count -gt 0) { $DriveLetters -join ', ' } else { '<all fixed drives>' }))

# This section gathers the requested drive list and performs the read-only checks.
$targetDrives = Get-TargetDrives -RequestedDrives $DriveLetters
Get-LogicalDiskHealth -Drives $targetDrives
Get-PhysicalDiskHealth
Get-OptimizationTaskStatus

# This section exports the report for audit purposes.
if ($results.Count -gt 0) {
    $results | Export-Csv -Path $reportFile -NoTypeInformation -Encoding UTF8
    Write-Log -Level 'SUCCESS' -Message ("Report saved to: {0}" -f $reportFile)
}
else {
    Write-Log -Message 'No report rows were generated.'
}

# This section prints the summary so the operator can confirm the outcome quickly.
$summary = [pscustomobject]@{
    DrivesScanned = $targetDrives.Count
    Rows          = $results.Count
    LogFile       = $logFile
    ReportFile    = $reportFile
    ReadOnly      = $true
}

Write-Host ''
Write-Log -Message 'Disk health reporter completed.'
$results | Sort-Object VolumeName, DriveLetter | Format-Table -AutoSize
Write-Host ''
$summary | Format-List
