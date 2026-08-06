<#
Large File Finder for Windows endpoints.
PowerShell 5.1 compatible and read-only.
#>

[CmdletBinding()]
param(
    [ValidateRange(1, 1048576)]
    [int]$ThresholdMB = 100,

    [string[]]$TargetPaths = @(
        $env:USERPROFILE,
        "$env:SystemDrive\"
    )
)

# This section uses strict error handling so path-level issues are logged without stopping the scan.
$ErrorActionPreference = 'Stop'

# This section creates a timestamped log folder for the current scan.
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$runStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$baseLogPath = Join-Path $scriptRoot 'large-file-finder-logs'
$runFolder = Join-Path $baseLogPath $runStamp
$logFile = Join-Path $runFolder 'large-file-finder.log'
$reportFile = Join-Path $runFolder 'large-files.csv'

New-Item -Path $runFolder -ItemType Directory -Force | Out-Null
New-Item -Path $logFile -ItemType File -Force | Out-Null

$results = New-Object System.Collections.Generic.List[object]

# This section writes each message to both the console and the log file.
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

# This section converts the size threshold from MB to bytes.
$thresholdBytes = $ThresholdMB * 1MB

# This section logs the current scan settings.
Write-Log -Message 'Large file finder started.'
Write-Log -Message ("Threshold : {0} MB" -f $ThresholdMB)
Write-Log -Message ("Targets   : {0}" -f ($TargetPaths -join ', '))

# This section scans each target path and records files larger than the configured threshold.
foreach ($path in ($TargetPaths | Select-Object -Unique)) {
    try {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $path)) {
            Write-Log -Level 'WARN' -Message ("Path not found: {0}" -f $path)
            continue
        }

        $files = Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction Stop
        foreach ($file in $files) {
            if ($file.Length -ge $thresholdBytes) {
                [void]$results.Add([pscustomobject]@{
                    FullName     = $file.FullName
                    SizeMB       = [math]::Round(($file.Length / 1MB), 2)
                    LastWriteTime = $file.LastWriteTime
                    Directory    = $file.DirectoryName
                })
            }
        }
    }
    catch {
        Write-Log -Level 'WARN' -Message ("Scan failed for {0}: {1}" -f $path, $_.Exception.Message)
    }
}

# This section sorts the results so the largest files appear first.
$results = $results | Sort-Object SizeMB -Descending, FullName

# This section writes the report to the console and a CSV file.
if ($results.Count -eq 0) {
    Write-Log -Message 'No files matched the threshold.'
}
else {
    Write-Host ''
    $results | Format-Table -AutoSize
    $results | Export-Csv -Path $reportFile -NoTypeInformation -Encoding UTF8
    Write-Log -Level 'SUCCESS' -Message ("Report saved to: {0}" -f $reportFile)
}

# This section reports the final summary.
$summary = [pscustomobject]@{
    ThresholdMB = $ThresholdMB
    ScannedPaths = ($TargetPaths | Select-Object -Unique).Count
    Matches     = $results.Count
    LogFile     = $logFile
    ReportFile   = $reportFile
}

Write-Host ''
Write-Log -Message 'Large file finder completed.'
$summary | Format-List
