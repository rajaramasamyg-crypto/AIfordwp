[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$OutputRoot = "C:\ProgramData\FinBridge\Floor6Evidence",
    [int]$LookbackHours = 48
)

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

if ($DryRun) {
    Write-Host "DRY RUN: Would collect evidence into $outDir"
    Write-Host "DRY RUN: Would run dsregcmd, whoami group export, event log collection, and MDM diagnostics"
    return
}

Get-ComputerInfo |
    Select-Object CsName, WindowsProductName, WindowsVersion, OsBuildNumber |
    ConvertTo-Json -Depth 3 |
    Out-File (Join-Path $outDir "computer-info.json") -Encoding utf8

cmd /c "dsregcmd /status > $outDir\dsreg-status.txt"
cmd /c "whoami /groups /fo csv /nh > $outDir\token-groups.csv"

Get-WinEvent -LogName "Microsoft-Windows-AAD/Operational" -MaxEvents 200 |
    Select-Object TimeCreated, Id, LevelDisplayName, Message |
    Export-Csv -NoTypeInformation -Path (Join-Path $outDir "aad-events.csv")

Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" |
    ForEach-Object {
        Get-ItemProperty $_.PSPath |
            Select-Object PSChildName, UPN, TenantId, EnrollmentState, ProviderID
    } |
    Export-Csv -NoTypeInformation -Path (Join-Path $outDir "enrollments.csv")

mdmdiagnosticstool.exe -area "DeviceEnrollment;DeviceProvisioning" -cab (Join-Path $outDir "mdm-diag.cab")

$groups = Import-Csv (Join-Path $outDir "token-groups.csv") -Header GroupName,Type,SID,Attributes
$suspicious = $groups | Where-Object { $_.GroupName -match "Copilot|Pilot|Finance|Ring|All Staff|All Legal" }

$summary = [ordered]@{
    CollectedAt = (Get-Date).ToString("s")
    Host = $env:COMPUTERNAME
    User = "$env:USERDOMAIN\$env:USERNAME"
    Hypothesis = "Mis-targeted Entra/Intune ring assignment caused both login friction and premature Copilot exposure"
    SuspiciousGroupHits = $suspicious.GroupName
    EvidencePath = $outDir
}

$summary | ConvertTo-Json -Depth 5 | Out-File (Join-Path $outDir "summary.json") -Encoding utf8
Write-Host "Evidence collected at $outDir"