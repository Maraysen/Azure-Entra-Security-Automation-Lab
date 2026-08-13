# Phase 5E - Safe Automated Remediation

param (
    [switch]$WhatIf,
    [switch]$ConfirmRemediation
)

$LogFile = ".\reports\automation.log"

function Write-Log {
    param (
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp [INFO] $Message" | Out-File -FilePath $LogFile -Append
}

$TargetUser = "Lab User 04"
$ProposedAction = "Disable account"

try {
    $User = Get-MgUser `
        -Filter "displayName eq '$TargetUser'" `
        -Property Id,DisplayName,UserPrincipalName,AccountEnabled `
        -ErrorAction Stop
}
catch {
    Write-Host "ERROR: Failed to retrieve target user."
    Write-Host $_.Exception.Message
    Write-Log "ERROR: Failed to retrieve target user - $($_.Exception.Message)"
    exit 1
}

if (-not $User) {
    Write-Host "STOP: Target user was not found."
    Write-Log "STOP: Target user '$TargetUser' was not found"
    exit 1
}

if ($User.Count -gt 1) {
    Write-Host "STOP: More than one user matched '$TargetUser'."
    Write-Log "STOP: Multiple users matched '$TargetUser'"
    exit 1
}

$ProtectedUsers = @(
    "Mahdi Kobeissi"
)

if ($ProtectedUsers -contains $User.DisplayName) {
    Write-Host "STOP: Target is a protected account. No changes allowed."
    Write-Log "STOP: Protected account targeted - $($User.UserPrincipalName)"
    exit 1
}

if ($User.AccountEnabled -eq $false) {
    Write-Host "STOP: Target account is already disabled. No action required."
    Write-Log "STOP: Account already disabled - $($User.UserPrincipalName)"
    exit 0
}

Write-Host "Safe remediation script started."
Write-Host "Target: $($User.DisplayName)"
Write-Host "User ID: $($User.Id)"
Write-Host "UPN: $($User.UserPrincipalName)"
Write-Host "Enabled: $($User.AccountEnabled)"
Write-Host "Proposed action: $ProposedAction"

Write-Log "Safe remediation started for $($User.UserPrincipalName)"

if ($WhatIf) {
    Write-Host "WHATIF MODE: Would disable $($User.UserPrincipalName). No changes made."
    Write-Log "WHATIF: Would disable $($User.UserPrincipalName)"
}
elseif (-not $ConfirmRemediation) {
    Write-Host "STOP: Live remediation requires -ConfirmRemediation."
    Write-Log "STOP: Live remediation attempted without confirmation"
    exit 1
}
else {
    Write-Host "LIVE MODE: Remediation is authorised."

    try {
        Update-MgUser `
            -UserId $User.Id `
            -AccountEnabled:$false `
            -ErrorAction Stop

        Write-Host "Account disable request succeeded."

        $VerifiedUser = Get-MgUser `
            -UserId $User.Id `
            -Property Id,DisplayName,UserPrincipalName,AccountEnabled `
            -ErrorAction Stop

        if ($VerifiedUser.AccountEnabled -eq $false) {
            Write-Host "Verification successful: Account is disabled."

            Write-Log "Disabled account $($User.UserPrincipalName)"
            Write-Log "Verification result: AccountEnabled=False"
        }
        else {
            Write-Host "WARNING: Verification failed. Account still appears enabled."
            Write-Log "WARNING: Verification failed for $($User.UserPrincipalName)"
            exit 1
        }
    }
    catch {
        Write-Host "ERROR: Remediation failed."
        Write-Host $_.Exception.Message

        Write-Log "ERROR: Remediation failed for $($User.UserPrincipalName) - $($_.Exception.Message)"
        exit 1
    }
}