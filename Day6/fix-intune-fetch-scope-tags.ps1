[CmdletBinding()]
param(
    [string]$TenantId,
    [switch]$AttemptTokenRefresh,
    [switch]$ShowAssignments
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

function Connect-Graph {
    param([string]$Tenant)

    $scopes = @(
        'DeviceManagementRBAC.Read.All',
        'DeviceManagementConfiguration.Read.All'
    )

    if ($Tenant) {
        Connect-MgGraph -TenantId $Tenant -Scopes $scopes -NoWelcome | Out-Null
    }
    else {
        Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null
    }
}

function Invoke-GraphGet {
    param([Parameter(Mandatory = $true)][string]$Uri)

    try {
        $result = Invoke-MgGraphRequest -Method GET -Uri $Uri
        return [PSCustomObject]@{
            Success = $true
            Data = $result
            StatusCode = 200
            ErrorMessage = $null
        }
    }
    catch {
        $statusCode = $null
        $message = $_.Exception.Message

        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        return [PSCustomObject]@{
            Success = $false
            Data = $null
            StatusCode = $statusCode
            ErrorMessage = $message
        }
    }
}

Write-Section 'Prerequisites'
Ensure-Module -Name Microsoft.Graph.Authentication
Ensure-Module -Name Microsoft.Graph.DeviceManagement.Administration
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

Write-Section 'Connecting to Microsoft Graph'
Connect-Graph -Tenant $TenantId
$ctx = Get-MgContext
Write-Host "Connected tenant: $($ctx.TenantId)"
Write-Host "Account: $($ctx.Account)"
Write-Host "Scopes: $($ctx.Scopes -join ', ')"

if ($AttemptTokenRefresh) {
    Write-Section 'Refreshing token/session'
    Disconnect-MgGraph | Out-Null
    Start-Sleep -Milliseconds 500
    Connect-Graph -Tenant $TenantId
    Write-Host 'Token refresh completed.' -ForegroundColor Green
}

Write-Section 'Testing scope tag read API'
$scopeTagResponse = Invoke-GraphGet -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/roleScopeTags'

if ($scopeTagResponse.Success) {
    $count = @($scopeTagResponse.Data.value).Count
    Write-Host "Scope tag API reachable. Tags returned: $count" -ForegroundColor Green
}
else {
    Write-Host "Scope tag API call failed. Status: $($scopeTagResponse.StatusCode)" -ForegroundColor Red
    Write-Host "Error: $($scopeTagResponse.ErrorMessage)" -ForegroundColor Red
}

Write-Section 'Testing role assignments visibility'
$roleAssignmentsResponse = Invoke-GraphGet -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/roleAssignments?$top=50'

if ($roleAssignmentsResponse.Success) {
    $assignmentCount = @($roleAssignmentsResponse.Data.value).Count
    Write-Host "Role assignments API reachable. Assignments returned: $assignmentCount" -ForegroundColor Green

    if ($ShowAssignments -and $assignmentCount -gt 0) {
        $roleAssignmentsResponse.Data.value |
            Select-Object id, displayName, description |
            Format-Table -AutoSize
    }
}
else {
    Write-Host "Role assignments API call failed. Status: $($roleAssignmentsResponse.StatusCode)" -ForegroundColor Red
    Write-Host "Error: $($roleAssignmentsResponse.ErrorMessage)" -ForegroundColor Red
}

Write-Section 'Diagnosis'
if ($scopeTagResponse.Success) {
    Write-Host 'The backend API is accessible for this account.' -ForegroundColor Green
    Write-Host 'If the portal still shows "Fetch scope tags", this is likely browser session/UI caching.'
    Write-Host 'Action: sign out of Intune portal, use InPrivate, retry, and test second browser profile.'
}
elseif ($scopeTagResponse.StatusCode -eq 401 -or $scopeTagResponse.StatusCode -eq 403) {
    Write-Host 'This is likely an RBAC or permission issue.' -ForegroundColor Yellow
    Write-Host 'Action: ensure account has Intune role with scope-tag read visibility and valid role assignment scope groups/tags.'
    Write-Host 'Recommended roles for validation: Intune Administrator (temporary), then least-privilege custom role.'
}
else {
    Write-Host 'Likely transient service issue or conditional access/session problem.' -ForegroundColor Yellow
    Write-Host 'Action: verify Intune service health, refresh token, and retry in 15-30 minutes.'
}

Write-Section 'Completed'
Write-Host 'Use this output as evidence in your incident/compliance ticket.' -ForegroundColor Cyan
