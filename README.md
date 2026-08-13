# Azure Entra Security Automation Lab

PowerShell and Python security automation for Azure RBAC, Microsoft Entra ID, Microsoft Graph and security reporting.

## Project Goal

Build practical security automation that can:

* query live Azure and Microsoft Entra environments
* review Azure RBAC permissions
* identify privileged Entra role assignments
* generate security reports
* interact with Microsoft Graph
* safely perform controlled remediation
* process JSON and CSV security data
* call REST APIs using Python
* handle API errors and pagination
* authenticate to APIs using access tokens
* automate repetitive cloud security checks

The project focuses on practical scripting ability for cloud security engineering rather than full-time software development.

## Repository Structure

```text
Azure-Entra-Security-Automation-Lab/
│
├── scripts/
│   ├── 01-powershell-basics.ps1
│   ├── 02-azure-resource-groups.ps1
│   ├── 03-azure-rbac-report.ps1
│   ├── 04-entra-privileged-role-review.ps1
│   ├── 05-safe-remediation.ps1
│   ├── 06-python-security-findings.py
│   ├── 07-python-rest-api.py
│   ├── 08-python-pagination.py
│   ├── 09-python-graph-api.py
│   └── 10-python-user-security-review.py
│
├── data/
│   └── security-findings.json
│
├── reports/
│
├── .gitignore
└── README.md
```

## PowerShell Automation

### 01 - PowerShell Fundamentals

`01-powershell-basics.ps1`

Introduces the PowerShell fundamentals used throughout the automation project.

Topics include:

* variables
* arrays
* hashtables
* `foreach`
* `if/else`
* functions
* parameters
* return values
* `PSCustomObject`
* JSON processing
* error handling with `try/catch`
* `-ErrorAction Stop`
* logging
* CSV reporting
* timestamped report files

The script reads sample security findings from:

```text
data/security-findings.json
```

and applies basic risk classification before generating reports.

## Azure Resource Group Security Review

`02-azure-resource-groups.ps1`

Queries live Azure resource groups using Azure PowerShell and performs a basic security review.

The script:

* retrieves live Azure resource groups
* checks whether tags are present
* applies approved exclusions
* excludes `NetworkWatcherRG`
* assigns:

  * `OK`
  * `REVIEW`
  * `EXCLUDED`
* provides a reason for each result
* exports a full report
* exports a review-only report

This introduced the pattern:

```text
Query Azure
    ↓
Retrieve resources
    ↓
Apply security rules
    ↓
Assign status
    ↓
Explain reason
    ↓
Export reports
```

## Azure RBAC Security Review

`03-azure-rbac-report.ps1`

Queries live Azure RBAC assignments using:

```powershell
Get-AzRoleAssignment
```

The script analyses:

* principal name
* principal type
* assigned role
* assignment scope
* scope type

Scope is classified as:

* Subscription
* Resource Group
* Resource

Security rules identify assignments such as:

* Owner
* subscription-level Contributor
* Role Based Access Control Administrator

Example:

```text
Role: Owner
Scope: Subscription
Status: REVIEW
Reason: Owner provides full control including access management
```

The script also includes:

* full RBAC report
* review-only RBAC report
* timestamped CSV files
* logging
* error handling

## Microsoft Graph

Microsoft Graph PowerShell was used to query Microsoft Entra ID.

Authentication was performed using delegated device-code authentication with explicitly requested Graph scopes.

Examples of permissions used during the lab include:

```text
User.Read.All
AuditLog.Read.All
RoleManagement.Read.Directory
User.EnableDisableAccount.All
```

Graph commands used include:

```powershell
Connect-MgGraph
Get-MgUser
Get-MgDirectoryRole
Get-MgDirectoryRoleMember
Update-MgUser
```

This demonstrated the difference between:

```text
Get-Az...
→ Azure resource management

Get-Mg...
→ Microsoft Graph / Microsoft Entra ID
```

## Entra Privileged Role Review

`04-entra-privileged-role-review.ps1`

Queries active Microsoft Entra directory roles and their members.

The script:

* retrieves Entra directory roles
* retrieves members of each role
* resolves member IDs to user accounts
* checks account status
* identifies high-impact privileged roles
* assigns `OK` or `REVIEW`
* provides a reason
* exports full and review-only reports
* logs execution
* handles Graph errors

High-impact roles reviewed include:

```text
Global Administrator
Privileged Role Administrator
Security Administrator
User Administrator
```

A Global Administrator assignment, for example, is classified as:

```text
Status: REVIEW
Reason: Global Administrator is a privileged Entra directory role
```

## Safe Automated Remediation

`05-safe-remediation.ps1`

Demonstrates how security automation can safely move from detection to remediation.

The lab remediation disables a designated Entra test account using Microsoft Graph.

The important part of the exercise is not the individual `Update-MgUser` command, but the safeguards placed around it.

Safeguards include:

* exact target lookup
* user ID validation
* protected-account list
* existing account-state check
* `-WhatIf` simulation mode
* explicit `-ConfirmRemediation` requirement
* error handling
* logging
* post-change verification

Safe simulation:

```powershell
.\scripts\05-safe-remediation.ps1 -WhatIf
```

Example:

```text
Target: Lab User 04
Proposed action: Disable account
Enabled: True
WHATIF MODE: Would disable the account. No changes made.
```

Live remediation requires explicit confirmation:

```powershell
.\scripts\05-safe-remediation.ps1 -ConfirmRemediation
```

The script then verifies that the requested state change actually occurred.

The workflow is:

```text
Identify target
      ↓
Verify target
      ↓
Check protected accounts
      ↓
Check current state
      ↓
WhatIf simulation
      ↓
Explicit authorisation
      ↓
Perform remediation
      ↓
Verify result
      ↓
Log action
```

## Python Security Automation

Python was introduced as a second automation language for processing security data and working directly with REST APIs.

### 06 - JSON and CSV Processing

`06-python-security-findings.py`

Reads:

```text
data/security-findings.json
```

and converts the JSON into Python objects.

The script demonstrates:

* Python lists
* dictionaries
* loops
* `if/else`
* security classification
* CSV output

Example logic:

```text
Risk >= 4
→ REVIEW

Risk < 4
→ OK
```

## REST API Integration

`07-python-rest-api.py`

Introduces direct REST API calls from Python.

The script demonstrates:

* HTTPS requests
* JSON API responses
* HTTP error handling
* connection error handling
* unexpected exception handling

A controlled invalid request was used to verify that the script handles HTTP `404` responses without crashing.

## API Pagination

`08-python-pagination.py`

Demonstrates retrieving data from APIs that return results across multiple pages.

Example:

```text
Page 1 → 5 results
Page 2 → 5 results
Page 3 → 5 results
             ↓
       15 combined results
```

This demonstrates an important real-world API requirement: security automation must often retrieve multiple pages before the complete dataset is available.

It also demonstrated that different APIs may implement pagination differently and that automation should follow the API's documented pagination model.

## Microsoft Graph REST API with Python

`09-python-graph-api.py`

Uses Python to make an authenticated REST request directly to Microsoft Graph.

An access token is obtained using Azure CLI and stored temporarily as an environment variable:

```powershell
$env:GRAPH_TOKEN = az account get-access-token `
    --resource-type ms-graph `
    --query accessToken `
    -o tsv
```

Python reads the token without storing it in source code:

```python
token = os.environ["GRAPH_TOKEN"]
```

The token is passed using the HTTP authorization header:

```text
Authorization: Bearer <access-token>
```

The script successfully retrieved live users from Microsoft Entra ID.

The authentication flow is:

```text
Azure authentication
       ↓
Access token
       ↓
Environment variable
       ↓
Python
       ↓
Bearer token
       ↓
Microsoft Graph REST API
       ↓
JSON response
```

## Python User Security Review

`10-python-user-security-review.py`

Combines the Python skills into a practical security automation workflow.

The script:

* authenticates to Microsoft Graph
* retrieves live Entra users
* reads account status
* applies security rules
* assigns `OK` or `REVIEW`
* explains the reason
* exports the results to CSV
* handles API failures

Example:

```text
Chris Green - OK - Account is enabled
Lab User 04 - OK - Account is enabled
Mahdi Kobeissi - OK - Account is enabled
```

This demonstrates the full Python security automation pattern:

```text
Microsoft Graph
      ↓
REST API
      ↓
JSON
      ↓
Python processing
      ↓
Security rule
      ↓
Status / Reason
      ↓
CSV report
```

## Security Reporting

The PowerShell and Python scripts generate structured reports that can be reviewed manually or consumed by other systems.

Report types include:

* full security inventory
* review-only findings
* Azure RBAC reports
* Entra privileged-role reports
* Python user security reviews
* automation logs

Generated reports and logs are runtime output and should not contain credentials or access tokens.

## Security Practices Demonstrated

This project implements several practical security-engineering principles:

* least privilege
* explicit authentication scopes
* short-lived access tokens
* no credentials stored in source code
* protected accounts
* simulation before remediation
* explicit approval before live changes
* error handling
* action logging
* post-remediation verification
* structured security reporting

## PowerShell vs Python

Both languages were used for different automation scenarios.

### PowerShell

Best suited in this lab for:

* Azure administration
* Azure PowerShell
* Microsoft Graph PowerShell
* Azure RBAC
* Microsoft Entra administration
* controlled Microsoft-specific remediation

### Python

Used for:

* JSON transformation
* CSV processing
* REST APIs
* API pagination
* authentication tokens
* cross-platform security automation
* processing and correlating security data

The same automation principles can later be applied to APIs from platforms such as Azure, Microsoft Graph, Defender, Wiz, GitHub and other security services.

## Validation Evidence

The following were successfully tested:

* local JSON processing with PowerShell
* Azure resource-group inventory
* Azure RBAC inventory
* detection of subscription-level Owner access
* detection of privileged RBAC administration permissions
* Microsoft Graph delegated authentication
* live Entra user queries
* Entra directory-role queries
* privileged-role member resolution
* privileged-role reporting
* full and review-only CSV exports
* automation logging
* safe remediation simulation
* protected-account blocking
* explicit remediation confirmation
* live disabling of a test Entra user
* post-remediation verification
* restoration of the test account
* Python JSON processing
* Python CSV generation
* REST API requests
* API error handling
* API pagination
* access-token authentication
* direct Microsoft Graph REST calls from Python
* live Python-based Entra security review

## Portfolio Skills Demonstrated

* PowerShell automation
* Python automation
* Azure PowerShell
* Microsoft Graph
* Microsoft Entra ID
* Azure RBAC
* privileged-access reviews
* REST APIs
* JSON and CSV processing
* authentication tokens
* error handling
* logging
* security reporting
* API pagination
* controlled remediation
* remediation safeguards
* post-change verification

## Lab Limitation

An inactive-account review using Microsoft Graph `signInActivity` was explored during the lab.

The lab tenant did not provide the licensing required for that sign-in activity data, so the project used privileged-role review as the practical identity-review exercise instead.

## Future Improvements

* add inactive-account reporting in an Entra ID P1/P2 tenant
* add automatic Graph pagination to the live Entra user review
* add service principal and application credential expiry reviews
* detect excessive application permissions
* add group membership security reviews
* add separate configuration files for approved exclusions
* replace interactive authentication with workload identity for unattended automation
* integrate findings with ServiceNow or another ticketing system
* add automated tests
* add GitHub Actions for PowerShell and Python linting/testing
* integrate Defender for Cloud or Wiz APIs
* add structured JSON report output
* add notification workflows for high-risk findings
