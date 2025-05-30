<#
.SYNOPSIS
Deploys Azure Bicep templates for resource groups and main deployment.
.DESCRIPTION
This function orchestrates two Azure Bicep deployments: one for creating or updating a resource group,
and another for deploying resources within that group. It supports pipeline input and verbose logging,
ensures TLS 1.2 enforcement, and includes proper error handling and Azure DevOps log grouping.
.PARAMETER RootDirectory
Path to the root directory containing the Bicep modules and parameter files. Default is current directory.
.EXAMPLE
Invoke-ResourceDeployment -RootDirectory "C:\Project\Infra"
#>

[CmdletBinding()]
param (
    # Path to the root directory containing Bicep templates and parameters
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [System.String] $RootDirectory
)
Begin {
    # Fail fast on any error
    $ErrorActionPreference = 'Stop'

    # Azure module import
    Write-Verbose "## Importing Az.Resources module"
    try {
        $moduleParams = @{ Name = 'Az.Resources'; ErrorAction = 'Stop' }
        Import-Module @moduleParams
    }
    catch {
        throw
    }

    # Static defaults
    Write-Verbose "##[group] Prepare variables"
    $Location = 'westeurope'    # Azure deployment location
    $ResourceGroupName = 'lzca-p-dash-rg001'  # Target resource group name
    Write-Verbose "##[endgroup]"
}
Process {
    # Enforce TLS 1.2 for all outbound requests
    Write-Verbose "Enforcing TLS 1.2"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Resource group deployment
    Write-Host "##[group] Deploy Resource Group"
    $rgParams = @{
        Location              = $Location
        TemplateFile          = "${RootDirectory}\src\bicep\modules\resource-group.bicep"
        TemplateParameterFile = "${RootDirectory}\src\bicep\.config\resource-group.bicepparam"
        ErrorAction           = 'Stop'
    }
    New-AzDeployment @rgParams
    Write-Host "##[endgroup]"

    # Main deployment to resource group
    Write-Host "##[group] Deploy Main Bicep"
    $mainParams = @{
        ResourceGroupName     = $ResourceGroupName
        Location              = $Location
        TemplateFile          = "${RootDirectory}\src\bicep\main.bicep"
        TemplateParameterFile = "${RootDirectory}\src\bicep\.config\main.bicepparam"
        ErrorAction           = 'Stop'
    }
    New-AzResourceGroupDeployment @mainParams
    Write-Host "##[endgroup]"
}
End {
    Write-Verbose 'Initialization complete.'
}
