$ExcludedResourceGroups = @(
    "NetworkWatcherRG"
)
$ResourceGroups = Get-AzResourceGroup

$Results = foreach ($ResourceGroup in $ResourceGroups) {
    $HasTags = ($null -ne $ResourceGroup.Tags -and $ResourceGroup.Tags.Count -gt 0)

    $IsExcluded = $ExcludedResourceGroups -contains $ResourceGroup.ResourceGroupName

    $Status = if ($IsExcluded) {
        "EXCLUDED"
    }
    elseif ($HasTags) {
        "OK"
    }
    else {
        "REVIEW"
    }

    $Reason = if ($IsExcluded) {
    "Azure-managed resource group"
    }
    elseif ($HasTags) {
    "Required tags are present"
    }
    else {
    "Missing required tags"
    }

    [PSCustomObject]@{
        ResourceGroup = $ResourceGroup.ResourceGroupName
        Location      = $ResourceGroup.Location
        State         = $ResourceGroup.ProvisioningState
        HasTags       = $HasTags
        IsExcluded    = $IsExcluded
        Status        = $Status
        Reason        = $Reason
    }
}

$Results |
    Sort-Object Status, ResourceGroup |
    Export-Csv ".\reports\Azure-Resource-Groups.csv" -NoTypeInformation

$ReviewResults = $Results |
    Where-Object { $_.Status -eq "REVIEW" }

$ReviewResults |
    Export-Csv ".\reports\Azure-Resource-Groups-Review.csv" -NoTypeInformation

$Results