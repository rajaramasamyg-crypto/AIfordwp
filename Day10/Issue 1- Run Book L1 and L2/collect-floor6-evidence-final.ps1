[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$OutputRoot = "C:\ProgramData\FinBridge\Floor6Evidence",
    [ValidateRange(1, 168)]
    [int]$LookbackHours = 48
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outDir = Join-Path -Path $OutputRoot -ChildPath $timestamp
$steps = New-Object System.Collections.Generic.List[object]

function Add-StepResult {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Details,
        [string]$OutputFile = ""
    )

    $steps.Add([pscustomobject]@{
        step = $Name
        status = $Status
        details = $Details
        outputFile = $OutputFile
        timestamp = (Get-Date).ToString("s")
    }) | Out-Null
}

function Invoke-CollectionStep {
    param(
        [string]$Name,
        [scriptblock]$Action,
        [string]$OutputFile = ""
    )

    if ($DryRun) {
        Add-StepResult -Name $Name -Status "planned" -Details "Dry run: command not executed." -OutputFile $OutputFile
        return
    }

    try {
        & $Action
        Add-StepResult -Name $Name -Status "ok" -Details "Completed" -OutputFile $OutputFile
    }
    catch {
        Add-StepResult -Name $Name -Status "failed" -Details $_.Exception.Message -OutputFile $OutputFile
    }
}

function Get-RecentEvents {
    param(
        [string]$LogName,
        [int[]]$Ids,
        [datetime]$StartTime,
        [string]$ExportPath
    )

    try {
        $filter = @{ LogName = $LogName; StartTime = $StartTime }
        if ($Ids -and $Ids.Count -gt 0) {
            $filter.Id = $Ids
        }

        Get-WinEvent -FilterHashtable $filter -ErrorAction Stop |
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
    collectedAt = (Get-Date).ToString("s")
    dryRun = [bool]$DryRun
    hypothesis = "Mis-scoped Entra/Intune ring assignment (plus unresolved SharePoint inheritance) is causing Floor 6 login friction and Copilot overexposure."
    outputPath = $outDir
    collectionSteps = @(
        "Capture device and enrollment identity"
        "Capture token groups for suspicious ring/licensing membership"
        "Capture AAD and MDM diagnostics"
        "Capture sign-in related event logs"
        "Produce structured evidence summary"
    )
}

$plan | ConvertTo-Json -Depth 6 | Out-File -Encoding UTF8 -FilePath (Join-Path $outDir "collection-plan.json")

if ($DryRun) {
    Add-StepResult -Name "plan" -Status "planned" -Details "Dry run only. Use without -DryRun to execute collection." -OutputFile "collection-plan.json"
    $steps | ConvertTo-Json -Depth 6 | Out-File -Encoding UTF8 -FilePath (Join-Path $outDir "steps.json")
    Write-Output "Dry run complete. Plan: $(Join-Path $outDir "collection-plan.json")"
    return
}

$computerInfoPath = Join-Path $outDir "computer-info.json"
Invoke-CollectionStep -Name "computer-info" -OutputFile "computer-info.json" -Action {
    Get-ComputerInfo |
        Select-Object CsName, CsDomain, WindowsProductName, WindowsVersion, OsBuildNumber, OsHardwareAbstractionLayer |
        ConvertTo-Json -Depth 4 |
        Out-File -Encoding UTF8 -FilePath $computerInfoPath
}

$dsregPath = Join-Path $outDir "dsreg-status.txt"
Invoke-CollectionStep -Name "dsreg-status" -OutputFile "dsreg-status.txt" -Action {
    $dsreg = & dsregcmd /status
    $dsreg | Out-File -Encoding UTF8 -FilePath $dsregPath
}

$tokenCsvPath = Join-Path $outDir "token-groups.csv"
Invoke-CollectionStep -Name "token-groups" -OutputFile "token-groups.csv" -Action {
    $whoamiCsv = & whoami /groups /fo csv /nh
    $whoamiCsv | Out-File -Encoding UTF8 -FilePath $tokenCsvPath
}

$enrollmentPath = Join-Path $outDir "enrollments.csv"
Invoke-CollectionStep -Name "enrollment-registry" -OutputFile "enrollments.csv" -Action {
    Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Enrollments" |
        ForEach-Object {
            Get-ItemProperty -Path $_.PSPath |
                Select-Object PSChildName, UPN, TenantId, DiscoveryServiceFullURL, ProviderID, EnrollmentType, EnrollmentState
        } |
        Export-Csv -NoTypeInformation -Encoding UTF8 -Path $enrollmentPath
}

$aadEventsPath = Join-Path $outDir "aad-events.csv"
$mdmEventsPath = Join-Path $outDir "mdm-events.csv"
$start = (Get-Date).AddHours(-1 * $LookbackHours)

$aadResult = Get-RecentEvents -LogName "Microsoft-Windows-AAD/Operational" -Ids @(1006, 1097, 1098) -StartTime $start -ExportPath $aadEventsPath
if ($aadResult.Error) {
    Add-StepResult -Name "aad-events" -Status "failed" -Details $aadResult.Error -OutputFile "aad-events.csv"
}
else {
    Add-StepResult -Name "aad-events" -Status "ok" -Details "Exported $($aadResult.Count) events" -OutputFile "aad-events.csv"
}

$mdmResult = Get-RecentEvents -LogName "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" -Ids @(404, 454, 809, 814) -StartTime $start -ExportPath $mdmEventsPath
if ($mdmResult.Error) {
    Add-StepResult -Name "mdm-events" -Status "failed" -Details $mdmResult.Error -OutputFile "mdm-events.csv"
}
else {
    Add-StepResult -Name "mdm-events" -Status "ok" -Details "Exported $($mdmResult.Count) events" -OutputFile "mdm-events.csv"
}

$mdmCabPath = Join-Path $outDir "mdm-diag.cab"
Invoke-CollectionStep -Name "mdm-diagnostic-cab" -OutputFile "mdm-diag.cab" -Action {
    $mdmTool = Join-Path $env:WINDIR "System32\MdmDiagnosticsTool.exe"
    if (-not (Test-Path $mdmTool)) {
        throw "MdmDiagnosticsTool.exe not found"
    }

    & $mdmTool -area "DeviceEnrollment;DeviceProvisioning;Autopilot" -cab $mdmCabPath | Out-Null
}

$groups = @()
if (Test-Path $tokenCsvPath) {
    $groups = Import-Csv -Path $tokenCsvPath -Header GroupName, Type, Sid, Attributes
}

$pattern = "Copilot|Pilot|Finance|Ring|All Staff|All Legal"
$suspiciousGroups = $groups |
    Where-Object { $_.GroupName -match $pattern } |
    Select-Object -ExpandProperty GroupName

$dsregText = @()
if (Test-Path $dsregPath) {
    $dsregText = Get-Content -Path $dsregPath
}

$aadPrtMatch = ($dsregText | Select-String -Pattern "AzureAdPrt\s*:\s*(YES|NO)" | Select-Object -First 1).Matches
$aadPrt = if ($aadPrtMatch.Count -gt 0) { $aadPrtMatch[0].Groups[1].Value } else { "UNKNOWN" }

$summary = [ordered]@{
    version = "1.0"
    collectedAt = (Get-Date).ToString("s")
    hostname = $env:COMPUTERNAME
    user = "$env:USERDOMAIN\$env:USERNAME"
    hypothesis = "Mis-scoped Entra/Intune ring assignment and premature Copilot license exposure"
    indicators = [ordered]@{
        azureAdPrt = $aadPrt
        suspiciousGroupHits = $suspiciousGroups
        aadEventCount = $aadResult.Count
        mdmEventCount = $mdmResult.Count
        enrollmentRecordCount = if (Test-Path $enrollmentPath) { (Import-Csv -Path $enrollmentPath).Count } else { 0 }
    }
    recommendedAction = "If suspiciousGroupHits includes Copilot/Pilot/Finance ring groups, remove impacted users/devices from the Floor 6 deployment ring and Copilot pilot group immediately; then force Intune sync and re-test login."
    evidenceFolder = $outDir
}

$summary | ConvertTo-Json -Depth 8 | Out-File -Encoding UTF8 -FilePath (Join-Path $outDir "summary.json")
$steps | ConvertTo-Json -Depth 6 | Out-File -Encoding UTF8 -FilePath (Join-Path $outDir "steps.json")

Write-Output "Evidence collection complete. Summary: $(Join-Path $outDir "summary.json")"