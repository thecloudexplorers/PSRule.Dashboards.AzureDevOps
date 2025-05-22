
<#
.SYNOPSIS
Exports Azure DevOps data to a specified output path.

.DESCRIPTION
This function imports necessary modules, prepares variables, generates a bearer token for Azure DevOps API, 
connects to Azure DevOps, and exports organization rule data to a specified output path.

.PARAMETER TargetAzureDevOpsOrganizationName
The name of the target Azure DevOps organization.

.PARAMETER TargetAzureDevOpsOrganizationID
The ID of the target Azure DevOps organization.

.PARAMETER LogAnalyticsWorkspaceId
The ID of the Log Analytics workspace.

.PARAMETER LogAnalyticsSharedKey
The shared key for the Log Analytics workspace.

.PARAMETER TenantId
The tenant ID for Azure authentication.

.PARAMETER ClientId
The client ID for Azure authentication.

.PARAMETER ClientSecret
The client secret for Azure authentication.

.PARAMETER ReportOutputPath
The path where the exported data will be saved.

.EXAMPLE
Export-AzDevOpsData -TargetAzureDevOpsOrganizationName "MyOrg" -TargetAzureDevOpsOrganizationID "12345" `
                    -LogAnalyticsWorkspaceId "workspaceId" -LogAnalyticsSharedKey "sharedKey" `
                    -TenantId "tenantId" -ClientId "clientId" -ClientSecret "clientSecret" `
                    -ReportOutputPath "C:\path\to\output"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetAzureDevOpsOrganizationName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetAzureDevOpsOrganizationID,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$LogAnalyticsWorkspaceId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$LogAnalyticsSharedKey,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ClientSecret,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ReportOutputPath
)

begin {
    Write-Host "##[group]Importing PowerShell Modules"
        
    try {
        Import-Module -Name PSRule -Force -ErrorAction Stop
        Write-Host "PSGallery modules imported."
    }
    catch {
        throw $_
    }

    Write-Host "##[endgroup]"

    Write-Host "##[group]Prepare variables"
        
    # Static defaults declared in Begin
    $scopeId = "499b84ac-1321-427f-aa17-267ca6975798" # Azure DevOps API Scope ID - It never changes

    Write-Host "##[endgroup]"

    Write-Host "##[group]Import custom module [PSRule.Rules.AzureDevOps]"
        
    try {
        Import-Module -Name PSRule.Rules.AzureDevOps -ErrorAction Stop
    }
    catch {
        throw $_
    }

    Write-Host "##[endgroup]"
}

process {
    Write-Host "##[group]Exporting Azure DevOps Data"
        
    Write-Host "Generates a new bearer token for Azure DevOps API"
        
    $params = @{
        Uri    = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        Method = 'Post'
        Body   = @{
            client_id     = $ClientId
            client_secret = $ClientSecret
            scope         = "$scopeId/.default"
            grant_type    = 'client_credentials'
        }
    }
        
    $tokenResponse = Invoke-RestMethod @params
    $bearerToken = $tokenResponse.access_token

    Write-Host "Connecting to Azure DevOps"
        
    Connect-AzDevOps -Organization $TargetAzureDevOpsOrganizationName -OrganizationId $TargetAzureDevOpsOrganizationID -AccessToken $bearerToken

    Write-Host "Creating output directory"
        
    New-Item -ItemType Directory -Path $ReportOutputPath -Force

    Write-Host "Exporting Azure DevOps Data"
        
    Export-AzDevOpsOrganizationRuleData -Organization $TargetAzureDevOpsOrganizationName -OrganizationId $TargetAzureDevOpsOrganizationID -OutputPath $ReportOutputPath

    Write-Host "##[endgroup]"
}

end {
    Write-Verbose 'Data export complete.'
}


