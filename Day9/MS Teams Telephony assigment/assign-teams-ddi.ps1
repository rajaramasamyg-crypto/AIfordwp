[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$CsvPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$timestamp] [$Level] $Message"
}

function Ensure-TeamsConnection {
    if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
        throw 'MicrosoftTeams module is not installed. Run: Install-Module MicrosoftTeams -Scope CurrentUser'
    }

    Import-Module MicrosoftTeams -ErrorAction Stop

    try {
        $null = Get-CsTenant -ErrorAction Stop
        Write-Log -Message 'Already connected to Microsoft Teams.'
    }
    catch {
        Write-Log -Message 'Connecting to Microsoft Teams...'
        Connect-MicrosoftTeams -ErrorAction Stop
        Write-Log -Message 'Connected to Microsoft Teams.'
    }
}

function Validate-E164 {
    param([string]$PhoneNumber)

    if ($PhoneNumber -notmatch '^\+[1-9]\d{6,14}$') {
        throw "Phone number '$PhoneNumber' is not in valid E.164 format."
    }
}

try {
    Write-Log -Message "Loading CSV: $CsvPath"
    $rows = Import-Csv -Path $CsvPath

    if (-not $rows -or $rows.Count -eq 0) {
        throw 'CSV file is empty.'
    }

    Ensure-TeamsConnection

    foreach ($row in $rows) {
        $upn = $row.UserPrincipalName
        $phone = $row.PhoneNumber
        $type = $row.PhoneNumberType
        $vrp  = $row.VoiceRoutingPolicy
        $tdp  = $row.TenantDialPlan

        if ([string]::IsNullOrWhiteSpace($upn)) {
            Write-Log -Level 'WARN' -Message 'Skipping row with empty UserPrincipalName.'
            continue
        }

        if ([string]::IsNullOrWhiteSpace($phone) -or [string]::IsNullOrWhiteSpace($type)) {
            Write-Log -Level 'WARN' -Message "Skipping $upn due to missing PhoneNumber or PhoneNumberType."
            continue
        }

        try {
            Validate-E164 -PhoneNumber $phone

            if ($PSCmdlet.ShouldProcess($upn, "Assign $phone ($type)")) {
                Set-CsPhoneNumberAssignment -Identity $upn -PhoneNumber $phone -PhoneNumberType $type -EnterpriseVoiceEnabled $true -ErrorAction Stop
                Write-Log -Message "Assigned $phone ($type) to $upn"

                if (-not [string]::IsNullOrWhiteSpace($vrp)) {
                    Grant-CsOnlineVoiceRoutingPolicy -Identity $upn -PolicyName $vrp -ErrorAction Stop
                    Write-Log -Message "Assigned Voice Routing Policy '$vrp' to $upn"
                }

                if (-not [string]::IsNullOrWhiteSpace($tdp)) {
                    Grant-CsTenantDialPlan -Identity $upn -PolicyName $tdp -ErrorAction Stop
                    Write-Log -Message "Assigned Tenant Dial Plan '$tdp' to $upn"
                }
            }
        }
        catch {
            Write-Log -Level 'ERROR' -Message "Failed for $upn: $($_.Exception.Message)"
        }
    }

    Write-Log -Message 'Processing complete.'
}
catch {
    Write-Log -Level 'ERROR' -Message $_.Exception.Message
    throw
}
