# Phase 5 - PowerShell Fundamentals

$ReportName = "Azure Security Review"
$Environment = "Lab"
$RiskThreshold = 3

$JsonPath = ".\data\security-findings.json"
$LogPath = ".\reports\automation.log"
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] $Message"

    Write-Host $LogEntry
    Add-Content -Path $LogPath -Value $LogEntry
}

try {
    $SecurityChecks = Get-Content $JsonPath -Raw -ErrorAction Stop |
    ConvertFrom-Json

    Write-Log -Message "Loaded security findings successfully."
}
catch {
    Write-Log -Message "Could not load the security findings file." -Level "ERROR"
    Write-Log -Message $_.Exception.Message -Level "ERROR"
    exit 1
}

$LabDetails = @{
    Project     = "Azure Entra Security Automation Lab"
    Environment = $Environment
    Report      = $ReportName
}

Write-Host "Project: $($LabDetails.Project)"
Write-Host "Environment: $($LabDetails.Environment)"
Write-Host "Report: $($LabDetails.Report)"
Write-Host "Risk threshold: $RiskThreshold"
Write-Host ""
Write-Host "Security checks:"

function Get-RiskStatus {
    param (
        [int]$Risk,
        [int]$Threshold
    )

    if ($Risk -ge $Threshold) {
        return "REVIEW"
    }

    return "OK"
}

$Results = @()

foreach ($Check in $SecurityChecks) {
    $Status = Get-RiskStatus -Risk $Check.Risk -Threshold $RiskThreshold

    Write-Host "$Status`: $($Check.Name) (Risk: $($Check.Risk))"

    $Results += [PSCustomObject]@{
        Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Environment = $Environment
        Name        = $Check.Name
        Risk        = $Check.Risk
        Status      = $Status
    }
}

$ReportTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$Results |
    Export-Csv ".\reports\Security-Report.csv" -NoTypeInformation

$ReviewResults = $Results |
    Where-Object { $_.Status -eq "REVIEW" } |
    Sort-Object Risk -Descending

Write-Host "Review findings found: $($ReviewResults.Count)"

$ReviewResults |
    Export-Csv ".\reports\Security-Review-Only.csv" -NoTypeInformation

$TotalFindings = $Results.Count
$ReviewCount = $ReviewResults.Count
$OkCount = $Results.Count - $ReviewCount

Write-Host ""
Write-Host "========== Summary =========="
Write-Host "Total findings : $TotalFindings"
Write-Host "Review findings: $ReviewCount"
Write-Host "OK findings    : $OkCount"
