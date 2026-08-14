# Section 3a - Evidence Script (AI First vs Hand-Corrected)

Version: 1.0  
Date: 2026-08-14  
Owner: EUC Incident Response

Top-ranked cause being tested: Friday Intune app deployment for the new document management app removed or replaced desktop shortcuts on Floor 6 devices.

| AI-generated first draft | Hand-corrected production script |
|---|---|
| ```powershell
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$AppName = "FinBridge Document Management",
    [int]$LookbackHours = 72,
    [string]$OutputRoot = "C:\ProgramData\FinBridge\Floor6ShortcutEvidence"
)

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

if ($DryRun) {
    Write-Host "DRY RUN: Would collect shortcut evidence into $outDir"
    Write-Host "DRY RUN: Would capture desktop links, Intune logs, app install events, and uninstall entries"
    return
}

Get-ChildItem "$env:PUBLIC\Desktop" -Filter "*.lnk" -ErrorAction SilentlyContinue |
    Select-Object Name, FullName, LastWriteTime |
    Export-Csv -NoTypeInformation -Path (Join-Path $outDir "public-desktop-links.csv")

Get-ChildItem "$env:USERPROFILE\Desktop" -Filter "*.lnk" -ErrorAction SilentlyContinue |
    Select-Object Name, FullName, LastWriteTime |
    Export-Csv -NoTypeInformation -Path (Join-Path $outDir "user-desktop-links.csv")

$imeLogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
if (Test-Path $imeLogPath) {
    Select-String -Path $imeLogPath -Pattern "$AppName|shortcut|\.lnk|Public\\Desktop|Remove-Item" -SimpleMatch |
        Select-Object LineNumber, Line |
        Export-Csv -NoTypeInformation -Path (Join-Path $outDir "ime-log-hits.csv")
}

$start = (Get-Date).AddHours(-1 * $LookbackHours)
Get-WinEvent -LogName Application -MaxEvents 400 |
    Where-Object { $_.TimeCreated -ge $start -and $_.ProviderName -match "MsiInstaller" } |
    Select-Object TimeCreated, Id, ProviderName, Message |
    Export-Csv -NoTypeInformation -Path (Join-Path $outDir "msi-events.csv")

Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*$AppName*" } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, UninstallString |
    Export-Csv -NoTypeInformation -Path (Join-Path $outDir "app-uninstall-registry.csv")

$summary = [ordered]@{
    CollectedAt = (Get-Date).ToString("s")
    Computer = $env:COMPUTERNAME
    User = "$env:USERDOMAIN\$env:USERNAME"
    AppName = $AppName
    Hypothesis = "Friday app deployment removed or replaced desktop shortcuts through deployment script behavior"
    EvidenceFolder = $outDir
}

$summary | ConvertTo-Json -Depth 4 | Out-File (Join-Path $outDir "summary.json") -Encoding utf8
Write-Host "Evidence collection complete at $outDir"
``` | ```powershell
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$AppName = "FinBridge Document Management",
    [ValidateRange(1, 168)]
    [int]$LookbackHours = 72,
    [string]$OutputRoot = "C:\ProgramData\FinBridge\Floor6ShortcutEvidence"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outDir = Join-Path -Path $OutputRoot -ChildPath $timestamp
$stepResults = New-Object System.Collections.Generic.List[object]

function Add-StepResult {
    param(
        [string]$Step,
        [string]$Status,
        [string]$Details,
        [string]$OutputFile = ""
    )

    $stepResults.Add([pscustomobject]@{
        step = $Step
        status = $Status
        details = $Details
        outputFile = $OutputFile
        timestamp = (Get-Date).ToString("s")
    }) | Out-Null
}

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Action,
        [string]$OutputFile = ""
    )

    if ($DryRun) {
        Add-StepResult -Step $Name -Status "planned" -Details "Dry run only. Step not executed." -OutputFile $OutputFile
        return
    }

    try {
        & $Action
        Add-StepResult -Step $Name -Status "ok" -Details "Completed" -OutputFile $OutputFile
    }
    catch {
        Add-StepResult -Step $Name -Status "failed" -Details $_.Exception.Message -OutputFile $OutputFile
    }
}

function Export-DesktopLinks {
    param(
        [string]$DesktopPath,
        [string]$Label,
        [string]$OutputFileName
    )

    $outputFile = Join-Path -Path $outDir -ChildPath $OutputFileName

    if (-not (Test-Path -Path $DesktopPath)) {
        [pscustomobject]@{
            scope = $Label
            path = $DesktopPath
            linkCount = 0
            note = "Path not found"
        } | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $outputFile
        return
    }

    $links = Get-ChildItem -Path $DesktopPath -Filter "*.lnk" -File -ErrorAction Stop |
        Select-Object @{Name="Scope";Expression={$Label}}, Name, FullName, Length, CreationTime, LastWriteTime

    $links | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $outputFile
}

function Get-RecentAppEvents {
    param(
        [datetime]$StartTime,
        [string]$ExportPath
    )

    try {
        Get-WinEvent -FilterHashtable @{ LogName = "Application"; StartTime = $StartTime } -ErrorAction Stop |
            Where-Object { $_.ProviderName -eq "MsiInstaller" -or $_.ProviderName -eq "Application Error" } |
            Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
            Export-Csv -NoTypeInformation -Encoding UTF8 -Path $ExportPath

        return @{ Count = (Import-Csv -Path $ExportPath).Count; Error = $null }
    }
    catch {
        return @{ Count = 0; Error = $_.Exception.Message }
    }
}

New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$plan = [ordered]@{
    version = "1.0"
    collectedAt = (Get-Date).ToString("s")
    dryRun = [bool]$DryRun
    appName = $AppName
    hypothesis = "A Friday Intune app deployment changed or removed desktop shortcuts through install/uninstall script behavior."
    outputPath = $outDir
    collectionSteps = @(
        "Snapshot desktop shortcut state (Public and user profiles)",
        "Collect Intune Management Extension and AgentExecutor logs",
        "Extract log lines showing link deletion or app assignment actions",
        "Collect app install/uninstall events and registry entries",
        "Write machine-readable summary and step results"
    )
}
$plan | ConvertTo-Json -Depth 6 | Out-File -Encoding UTF8 -FilePath (Join-Path $outDir "collection-plan.json")

if ($DryRun) {
    Add-StepResult -Step "collection-plan" -Status "planned" -Details "Dry run complete. Execute without -DryRun to collect evidence." -OutputFile "collection-plan.json"
    $stepResults | ConvertTo-Json -Depth 6 | Out-File -Encoding UTF8 -FilePath (Join-Path $outDir "steps.json")
    Write-Output "Dry run complete. Plan: $(Join-Path $outDir "collection-plan.json")"
    return
}

$publicDesktopPath = Join-Path -Path $env:PUBLIC -ChildPath "Desktop"
$userDesktopPath = Join-Path -Path $env:USERPROFILE -ChildPath "Desktop"

Invoke-Step -Name "desktop-links-public" -OutputFile "public-desktop-links.csv" -Action {
    Export-DesktopLinks -DesktopPath $publicDesktopPath -Label "PublicDesktop" -OutputFileName "public-desktop-links.csv"
}

Invoke-Step -Name "desktop-links-user" -OutputFile "user-desktop-links.csv" -Action {
    Export-DesktopLinks -DesktopPath $userDesktopPath -Label "UserDesktop" -OutputFileName "user-desktop-links.csv"
}

$imeLogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
$agentLogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log"

Invoke-Step -Name "copy-ime-log" -OutputFile "IntuneManagementExtension.log" -Action {
    if (-not (Test-Path -Path $imeLogPath)) {
        throw "IntuneManagementExtension.log not found"
    }

    Copy-Item -Path $imeLogPath -Destination (Join-Path $outDir "IntuneManagementExtension.log") -Force
}

Invoke-Step -Name "copy-agentexecutor-log" -OutputFile "AgentExecutor.log" -Action {
    if (-not (Test-Path -Path $agentLogPath)) {
        throw "AgentExecutor.log not found"
    }

    Copy-Item -Path $agentLogPath -Destination (Join-Path $outDir "AgentExecutor.log") -Force
}

$logHitsPath = Join-Path $outDir "deployment-log-hits.csv"
Invoke-Step -Name "extract-log-hits" -OutputFile "deployment-log-hits.csv" -Action {
    $patterns = @(
        [regex]::Escape($AppName),
        "\\.lnk",
        "Public\\Desktop",
        "Remove-Item",
        "del ",
        "shortcut",
        "assignment",
        "Install command line",
        "Uninstall command line"
    )
    $combinedPattern = ($patterns -join "|")

    $hits = @()
    foreach ($f in @($imeLogPath, $agentLogPath)) {
        if (Test-Path -Path $f) {
            $hits += Select-String -Path $f -Pattern $combinedPattern -CaseSensitive:$false
        }
    }

    $hits |
        Select-Object Path, LineNumber, Line |
        Export-Csv -NoTypeInformation -Encoding UTF8 -Path $logHitsPath
}

$startTime = (Get-Date).AddHours(-1 * $LookbackHours)
$appEventsPath = Join-Path $outDir "app-events.csv"
$appEvents = Get-RecentAppEvents -StartTime $startTime -ExportPath $appEventsPath
if ($appEvents.Error) {
    Add-StepResult -Step "app-events" -Status "failed" -Details $appEvents.Error -OutputFile "app-events.csv"
}
else {
    Add-StepResult -Step "app-events" -Status "ok" -Details "Exported $($appEvents.Count) app events" -OutputFile "app-events.csv"
}

$registryPath = Join-Path $outDir "app-uninstall-registry.csv"
Invoke-Step -Name "app-uninstall-registry" -OutputFile "app-uninstall-registry.csv" -Action {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*$AppName*" } |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, UninstallString |
        Export-Csv -NoTypeInformation -Encoding UTF8 -Path $registryPath
}

$publicLinkCount = if (Test-Path (Join-Path $outDir "public-desktop-links.csv")) { (Import-Csv (Join-Path $outDir "public-desktop-links.csv")).Count } else { 0 }
$userLinkCount = if (Test-Path (Join-Path $outDir "user-desktop-links.csv")) { (Import-Csv (Join-Path $outDir "user-desktop-links.csv")).Count } else { 0 }
$logHitCount = if (Test-Path $logHitsPath) { (Import-Csv $logHitsPath).Count } else { 0 }
$registryHitCount = if (Test-Path $registryPath) { (Import-Csv $registryPath).Count } else { 0 }

$summary = [ordered]@{
    version = "1.0"
    collectedAt = (Get-Date).ToString("s")
    hostname = $env:COMPUTERNAME
    user = "$env:USERDOMAIN\$env:USERNAME"
    appName = $AppName
    lookbackHours = $LookbackHours
    topHypothesis = "Friday app deployment script removed/replaced desktop shortcuts"
    indicators = [ordered]@{
        publicDesktopShortcutCount = $publicLinkCount
        userDesktopShortcutCount = $userLinkCount
        deploymentLogHitCount = $logHitCount
        appRegistryMatchCount = $registryHitCount
        appEventCount = $appEvents.Count
    }
    immediateRecommendation = "If deployment logs show link deletion or uninstall step side effects, remove Floor 6 assignment from the app ring and push shortcut restore script."
    evidenceFolder = $outDir
}

$summary | ConvertTo-Json -Depth 8 | Out-File -Encoding UTF8 -FilePath (Join-Path $outDir "summary.json")
$stepResults | ConvertTo-Json -Depth 6 | Out-File -Encoding UTF8 -FilePath (Join-Path $outDir "steps.json")

Write-Output "Evidence collection complete. Summary: $(Join-Path $outDir "summary.json")"
``` |

One-line correction note: I replaced the loose draft with a strict, step-tracked collector that always emits structured JSON outputs, handles partial failures safely, and avoids silent misses in log and path capture.

Required reflection: My first instinct was profile corruption from Win11 migration, but log-focused script outputs are designed to prove or reject deployment-script side effects first; the timing (Friday app rollout + immediate shortcut loss reports) shifted the hypothesis ranking.
