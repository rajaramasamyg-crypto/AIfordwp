<#
.SYNOPSIS
    Reads endpoint health information and prints a simple text report.

.DESCRIPTION
    This script collects read-only information about the computer name, physical memory,
    free space on the C drive, the top memory-consuming processes, recent system error
    events, and stale user profiles.

.AUTHOR
    GitHub Copilot

.HOW TO RUN
    PowerShell 5.1 or later:
    .\inherit.pst

.NOTES
    The script is read-only and does not change Windows configuration, files, or registry
    values.
#>

# Enable advanced PowerShell behavior such as common parameters.
[CmdletBinding()]

# Declare the script parameters that control the report output.
param(
	# Set the number of days before a user profile is considered stale.
	[int]$StaleProfileDays = 90,
	# Set how many top memory-consuming processes to display.
	[int]$TopProcessCount = 5,
	# Set how many system error events to display.
	[int]$EventCount = 10
)

# Stop immediately when an unexpected error occurs so the catch block can report it.
$ErrorActionPreference = 'Stop'

# Define a helper function that prints a named section header.
function Write-Section {
	# Declare the title text to show above each report section.
	param(
		# Require a title so every section header is labeled.
		[Parameter(Mandatory = $true)]
		# Store the section title as text.
		[string]$Title
	)

	# Print a blank line before the next section.
	Write-Host ''
	# Print the section title itself.
	Write-Host $Title
	# Print an underline to make the section easier to read.
	Write-Host ('-' * $Title.Length)
}

# Define a helper function that removes line breaks from event log messages.
function Format-EventMessage {
	# Declare the message text to normalize.
	param(
		# Require the message text as input.
		[Parameter(Mandatory = $true)]
		# Store the event message as text.
		[string]$Message
	)

	# Replace line breaks with spaces so the message stays on one line.
	return ($Message -replace "\r?\n", ' ')
}

# Start the main report logic.
try {
	# Read the computer system information from WMI/CIM.
	$computerSystem = Get-CimInstance Win32_ComputerSystem
	# Read the local C drive object so free space can be reported.
	$systemDrive = Get-PSDrive -Name C -ErrorAction Stop
	# Sort running processes by working set memory and keep the top N results.
	$topProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First $TopProcessCount
	# Calculate the cutoff date for user profiles that are considered stale.
	$staleCutoffDate = (Get-Date).AddDays(-$StaleProfileDays)

	# Try to read recent error events from the System event log.
	try {
		# Read System events, filter to error level, and keep only the requested count.
		$errorEvents = Get-WinEvent -LogName System -MaxEvents 50 -ErrorAction Stop |
			Where-Object { $_.Level -eq 2 } |
			Select-Object -First $EventCount
	}
	# Handle event log failures without stopping the whole report.
	catch {
		# Use an empty list when event log access fails.
		$errorEvents = @()
		# Show the reason the event log could not be read.
		Write-Host "System event log check unavailable: $($_.Exception.Message)"
	}

	# Try to read user profiles and identify profiles that have not been used recently.
	try {
		# Read user profile objects and keep only non-special profiles older than the cutoff.
		$staleProfiles = Get-CimInstance Win32_UserProfile |
			Where-Object {
				# Exclude built-in and special profiles.
				-not $_.Special -and
				# Only include profiles that have a last use time.
				$_.LastUseTime -and
				# Include only profiles older than the stale cutoff date.
				$_.LastUseTime -lt $staleCutoffDate
			}
	}
	# Handle profile query failures without stopping the whole report.
	catch {
		# Use an empty list when user profile access fails.
		$staleProfiles = @()
		# Show the reason the profile check could not be read.
		Write-Host "User profile check unavailable: $($_.Exception.Message)"
	}

	# Print the computer section header.
	Write-Section -Title 'Computer'
	# Print the computer name.
	Write-Host ('Name: {0}' -f $computerSystem.Name)
	# Print total physical memory in gigabytes.
	Write-Host ('Total physical memory: {0} GB' -f ([math]::Round(($computerSystem.TotalPhysicalMemory / 1GB), 2)))

	# Print the disk section header.
	Write-Section -Title 'Disk'
	# Print free space on the C drive in gigabytes.
	Write-Host ('C: free space: {0} GB' -f ([math]::Round(($systemDrive.Free / 1GB), 2)))

	# Print the top processes section header.
	Write-Section -Title 'Top Processes'
	# Loop through each process that was selected for the report.
	foreach ($process in $topProcesses) {
		# Print the process name and memory usage in megabytes.
		Write-Host ('{0} {1} MB' -f $process.Name, ([math]::Round(($process.WS / 1MB), 2)))
	}

	# Print the system errors section header.
	Write-Section -Title 'System Errors'
	# Loop through each error event that was collected.
	foreach ($eventRecord in $errorEvents) {
		# Format the event message on one line, or show a placeholder when no message exists.
		$formattedMessage = if ($eventRecord.Message) { Format-EventMessage -Message $eventRecord.Message } else { '<no message>' }
		# Print the event time and its message.
		Write-Host ('{0} {1}' -f $eventRecord.TimeCreated, $formattedMessage)
	}

	# Print the stale profiles section header.
	Write-Section -Title 'Stale Profiles'
	# Check whether any stale profiles were found.
	if ($staleProfiles.Count -gt 0) {
		# Print the number of stale profiles.
		Write-Host ('Stale profiles: {0}' -f $staleProfiles.Count)
		# Loop through each stale profile and print its details.
		foreach ($profile in $staleProfiles) {
			# Print the profile path and its last use time.
			Write-Host ('{0} {1}' -f $profile.LocalPath, $profile.LastUseTime)
		}
	}
	# Handle the case where no stale profiles were found.
	else {
		# Print a zero count when no stale profiles exist.
		Write-Host 'Stale profiles: 0'
	}
}

# Handle any unexpected error that escaped the earlier checks.
catch {
	# Print the failure message for the operator.
	Write-Host ('Report failed: {0}' -f $_.Exception.Message)
	# Re-throw the error so the script exits as failed.
	throw
}
