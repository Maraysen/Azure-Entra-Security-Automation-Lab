# Phase 5D - Entra Privileged Role Review

$LogFile = ".\reports\automation.log"

function Write-Log {
    param (
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp [INFO] $Message" | Out-File -FilePath $LogFile -Append
}

try {
    Write-Host "Retrieving Entra directory roles..."
    Write-Log "Starting Entra privileged role review"

    $DirectoryRoles = Get-MgDirectoryRole -ErrorAction Stop

    Write-Log "Retrieved $($DirectoryRoles.Count) Entra directory roles"
}
catch {
    Write-Log "ERROR: Failed to retrieve Entra directory roles - $($_.Exception.Message)"
    Write-Error "Failed to retrieve Entra directory roles: $($_.Exception.Message)"
    exit 1
}

$Results = foreach ($Role in $DirectoryRoles) {

    $Members = Get-MgDirectoryRoleMember -DirectoryRoleId $Role.Id

    foreach ($Member in $Members) {

        $User = Get-MgUser `
            -UserId $Member.Id `
            -Property DisplayName,UserPrincipalName,AccountEnabled

            $Status = "OK"
$Reason = "No high-risk condition detected"

if ($HighRiskRoles -contains $Role.DisplayName) {
    $Status = "REVIEW"
    $Reason = "$($Role.DisplayName) is a privileged Entra directory role"
}
elseif ($User.AccountEnabled -eq $false) {
    $Status = "REVIEW"
    $Reason = "Disabled account still holds a privileged directory role"
}

       [PSCustomObject]@{
    DisplayName       = $User.DisplayName
    UserPrincipalName = $User.UserPrincipalName
    AccountEnabled    = $User.AccountEnabled
    DirectoryRole     = $Role.DisplayName
    Status            = $Status
    Reason            = $Reason
}
    }
}

$Results

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$Results |
    Export-Csv `
        -Path ".\reports\entra-privileged-full-$Timestamp.csv" `
        -NoTypeInformation

$Results |
    Where-Object { $_.Status -eq "REVIEW" } |
    Export-Csv `
        -Path ".\reports\entra-privileged-review-$Timestamp.csv" `
        -NoTypeInformation

Write-Log "Exported full Entra privileged role report"
Write-Log "Exported review-only Entra privileged role report"

Write-Host "Entra privileged role reports exported successfully."
