[CmdletBinding()]
param(
    [string]$TenantId,
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath ("intune-windows-devices-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))),
    [switch]$UseDeviceCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section {
    param([string]$Text)
    Write-Host "`n=== $Text ===" -ForegroundColor Cyan
}

function Ensure-Module {
    param([string]$Name)

    if (-not (Get-Module -ListAvailable -Name $Name)) {
        Write-Host "Installing missing module: $Name" -ForegroundColor Yellow
        Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber
    }
}

function Connect-IntuneGraph {
    param(
        [string]$Tenant,
        [switch]$DeviceCode
    )

    $scopes = @(
        'DeviceManagementManagedDevices.Read.All'
    )

    if ($DeviceCode) {
        if ($Tenant) {
            Connect-MgGraph -TenantId $Tenant -Scopes $scopes -UseDeviceAuthentication -NoWelcome | Out-Null
        }
        else {
            Connect-MgGraph -Scopes $scopes -UseDeviceAuthentication -NoWelcome | Out-Null
        }
    }
    else {
        if ($Tenant) {
            Connect-MgGraph -TenantId $Tenant -Scopes $scopes -NoWelcome | Out-Null
        }
        else {
            Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null
        }
    }
}

function Get-WindowsManagedDevices {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'&`$select=id,deviceName,lastSyncDateTime,azureADRegistered,managementState,complianceState,operatingSystem,osVersion"
    $allItems = @()

    do {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri
        if ($response.value) {
            $allItems += @($response.value)
        }

        $uri = $response.'@odata.nextLink'
    }
    while ($uri)

    return $allItems
}

Write-Section 'Prerequisites'
Ensure-Module -Name Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

Write-Section 'Connect to Microsoft Graph (Intune)'
Connect-IntuneGraph -Tenant $TenantId -DeviceCode:$UseDeviceCode
$ctx = Get-MgContext
Write-Host "Connected tenant: $($ctx.TenantId)"
Write-Host "Account: $($ctx.Account)"

Write-Section 'Fetching Windows managed devices'
$devices = Get-WindowsManagedDevices
$registered = @($devices | Where-Object { $_.azureADRegistered -eq $true })

$rows = $devices | ForEach-Object {
    [PSCustomObject]@{
        'Device name' = $_.deviceName
        'Last login date and time' = if ($_.lastSyncDateTime) { (Get-Date $_.lastSyncDateTime).ToString('yyyy-MM-dd HH:mm:ss') } else { '' }
        'Device uptime' = 'Not available from Intune Graph managedDevices API'
        'Registration status' = if ($_.azureADRegistered) { 'Registered' } else { 'Not Registered' }
    }
}

Write-Section 'Saving report'
$rows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Saved: $OutputPath" -ForegroundColor Green

Write-Section 'Summary'
Write-Host "Total Windows devices: $(@($devices).Count)"
Write-Host "Registered Windows devices: $(@($registered).Count)"

Disconnect-MgGraph | Out-Null
Write-Section 'Completed'
