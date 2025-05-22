<#
.SYNOPSIS
    Initialize and register an Azure DevOps Artifacts feed as a PowerShell PSResource repository, and install custom modules.

.DESCRIPTION
    Imports required modules, enforces TLS 1.2, configures a SecretStore vault,
    stores a PAT-based PSCredential, registers the specified Azure Artifacts feed,
    and installs any custom modules from that feed.

.PARAMETER OrganizationName
    Azure DevOps organization name.

.PARAMETER ProjectName
    Azure DevOps project name.

.PARAMETER FeedName
    Azure Artifacts feed name.

.PARAMETER PatUser
    Username for the Azure DevOps PAT credential.

.PARAMETER PatToken
    Azure DevOps Personal Access Token (PAT) with feed-read permissions.

.PARAMETER CustomModules
    Array of module names to install after registering the repository. Defaults to @('PSRule.Rules.AzureDevOps').

.EXAMPLE
    .\Initialize-ArtifactFeed.ps1 `
      -OrganizationName Contoso `
      -ProjectName WebApp `
      -FeedName Modules `
      -PatUser build `
      -PatToken abc123 `
      -CustomModules 'PSRule.Rules.AzureDevOps','Another.Module' `
      -Verbose
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $OrganizationName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ProjectName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $FeedName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $PatUser,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $PatToken,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $CustomModules
)

Begin {
    $vaultName = 'SecretVault'
    $secretName = 'MyCredential'
    $repositoryName = 'PowershellPSResourceRepository'
    $passwordTimeout = -1
    $password = -join ((97..122) | Get-Random -Count 10 | ForEach-Object { [char]$_ })

    Write-Host "##[group]Importing PowerShell Modules"
    try {
        Import-Module Microsoft.PowerShell.SecretStore     -Force -ErrorAction Stop
        Import-Module Microsoft.PowerShell.SecretManagement -Force -ErrorAction Stop
        Import-Module Microsoft.PowerShell.PSResourceGet    -Force -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to import modules: $_"
        throw
    }
    Write-Host "##[endgroup]"   

        
    
}
    
Process {
    Write-Verbose 'Enforcing TLS 1.2'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Host "##[group]Prepare variables"
    $feedUrl = "https://pkgs.dev.azure.com/$OrganizationName/$ProjectName/_packaging/$FeedName/nuget/v3/index.json"
    $secureToken = ConvertTo-SecureString -String $PatToken -AsPlainText -Force
    # $credentials = New-Object PSCredential($PatUser, $secureToken)
    $credentials = New-Object System.Management.Automation.PSCredential($PatUser, $secureToken)

    Write-Host "##[endgroup]"

    Write-Host "##[group]Set secret vault and secret store"
    if (Get-SecretVault -Name $vaultName -ErrorAction SilentlyContinue) {
        Write-Host "Vault [$vaultName] exists; removing."
        Unregister-SecretVault -Name $vaultName -ErrorAction Stop
    }
    Register-SecretVault -Name $vaultName -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault -ErrorAction Stop
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    Reset-SecretStore -Scope CurrentUser -Authentication Password -Interaction None `
        -Password $securePassword -PasswordTimeout $passwordTimeout -Force -ErrorAction Stop
    Unlock-SecretStore -Password $securePassword -ErrorAction Stop

    Set-Secret -Name $secretName -Secret $credentials -Vault $vaultName -ErrorAction Stop
    $credentialInfo = [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSCredentialInfo]::new($vaultName, $secretName)
    Write-Host "##[endgroup]"

    Write-Host "##[group]Set Azure Artifacts as PowerShell Repository"
    if (Get-PSResourceRepository -Name $repositoryName -ErrorAction SilentlyContinue) {
        Write-Host "Removing existing PSResource repo [$repositoryName]"
        Unregister-PSResourceRepository -Name $repositoryName -ErrorAction Stop
    }
    Register-PSResourceRepository -Name $repositoryName -Uri $feedUrl -Trusted -CredentialInfo $credentialInfo -ErrorAction Stop
    Write-Host "##[endgroup]"

    Write-Host "##[group]Import custom modules [$($CustomModules -join ', ')]"
    foreach ($module in $CustomModules) {
        Write-Host "Installing module [$module] from repository [$FeedName]"
        Install-PSResource -Name $module -Repository $repositoryName -Credential $credentials -ErrorAction Stop
    }
    Write-Host "##[endgroup]"
}

End {
    Write-Verbose 'Initialization complete.'
}