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
