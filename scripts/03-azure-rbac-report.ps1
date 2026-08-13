# Phase 5C - Azure RBAC Security Review

$LogFile = ".\reports\automation.log"

function Write-Log {
    param (
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp [INFO] $Message" | Out-File -FilePath $LogFile -Append
}

try {
    Write-Host "Retrieving Azure RBAC assignments..."
    Write-Log "Starting Azure RBAC security review"

    $RoleAssignments = Get-AzRoleAssignment -ErrorAction Stop

    Write-Host "Successfully retrieved $($RoleAssignments.Count) RBAC assignments."
    Write-Log "Retrieved $($RoleAssignments.Count) RBAC assignments"
}
catch {
    Write-Log "ERROR: Failed to retrieve RBAC assignments - $($_.Exception.Message)"
    Write-Error "Failed to retrieve Azure RBAC assignments: $($_.Exception.Message)"
    exit 1
}

$Results = foreach ($Assignment in $RoleAssignments) {

    $Status = "OK"
    $Reason = "No high-risk condition detected"

    if ($Assignment.RoleDefinitionName -eq "Owner") {
        $Status = "REVIEW"
        $Reason = "Owner provides full control including access management"
    }
    elseif ($Assignment.RoleDefinitionName -eq "Role Based Access Control Administrator") {
        $Status = "REVIEW"
        $Reason = "Can manage Azure RBAC role assignments within this scope"
    }
    elseif ($Assignment.RoleDefinitionName -eq "Contributor" -and
            $Assignment.Scope -match "^/subscriptions/[^/]+$") {
        $Status = "REVIEW"
        $Reason = "Contributor assigned at subscription scope"
    }

    $ScopeType = if ($Assignment.Scope -match "^/subscriptions/[^/]+$") {
        "Subscription"
    }
    elseif ($Assignment.Scope -match "/resourceGroups/[^/]+$") {
        "Resource Group"
    }
    else {
        "Resource"
    }

    [PSCustomObject]@{
        DisplayName = $Assignment.DisplayName
        ObjectType  = $Assignment.ObjectType
        Role        = $Assignment.RoleDefinitionName
        Scope       = $Assignment.Scope
        ScopeType   = $ScopeType
        Status      = $Status
        Reason      = $Reason
    }
}

$Results

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$Results |
    Export-Csv `
        -Path ".\reports\rbac-full-$Timestamp.csv" `
        -NoTypeInformation

$Results |
    Where-Object { $_.Status -eq "REVIEW" } |
    Export-Csv `
        -Path ".\reports\rbac-review-$Timestamp.csv" `
        -NoTypeInformation

Write-Log "Exported full RBAC report"
Write-Log "Exported review-only RBAC report"

Write-Host "RBAC reports exported successfully."