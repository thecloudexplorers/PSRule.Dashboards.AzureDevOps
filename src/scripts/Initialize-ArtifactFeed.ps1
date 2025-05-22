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

.PARAMETER VaultName
    Name for the SecretStore vault. Defaults to 'SecretVault'.

.PARAMETER SecretName
    Name under which to store the PSCredential. Defaults to 'MyCredential'.

.PARAMETER RepositoryName
    PSResource repository name to register. Defaults to 'PowershellPSResourceRepository'.

.PARAMETER Password
    Password to secure the SecretStore vault. Defaults to 'P@ssW0rD!'.

.PARAMETER PasswordTimeout
    Time in seconds before the vault auto-locks. Defaults to -1 (never).

.PARAMETER CustomModules
    Array of module names to install after registering the repository. Defaults to @('PSRule.Rules.AzureDevOps').

.PARAMETER CustomModuleRepository
    PSResource repository from which to install custom modules. Defaults to the same as RepositoryName.

.EXAMPLE
    .\Initialize-ArtifactFeed.ps1 \
      -OrganizationName Contoso \
      -ProjectName WebApp \
      -FeedName Modules \
      -PatUser build \
      -PatToken abc123 \
      -CustomModules 'PSRule.Rules.AzureDevOps','Another.Module' \
      -Verbose
#>
Initialize-ArtifactFeed {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName#,
        # [Parameter(Mandatory)]
        # [ValidateNotNullOrEmpty()]
        # [string] $ProjectName,
        # [Parameter(Mandatory)]
        # [ValidateNotNullOrEmpty()]
        # [string] $FeedName,
        # [Parameter(Mandatory)]
        # [ValidateNotNullOrEmpty()]
        # [string] $PatUser,
        # [Parameter(Mandatory)]
        # [ValidateNotNullOrEmpty()]
        # [string] $PatToken,
        # [Parameter()]
        # [ValidateNotNullOrEmpty()]
        # [string] $VaultName = 'SecretVault',
        # [Parameter()]
        # [ValidateNotNullOrEmpty()]
        # [string] $SecretName = 'MyCredential',
        # [Parameter()]
        # [ValidateNotNullOrEmpty()]
        # [string] $RepositoryName = 'PowershellPSResourceRepository',
        # [Parameter()]
        # [int] $PasswordTimeout = -1,
        # [Parameter()]
        # [string[]] $CustomModules = @('PSRule.Rules.AzureDevOps'),
        # [Parameter()]
        # [string] $CustomModuleRepository = ''
    )

    Write-Host "OrgName: $OrganizationName"

    Begin {
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

        # Default custom repository to the registered repository
        if (-not $CustomModuleRepository) { $CustomModuleRepository = $RepositoryName }

        
        $Password = -join ((97..122) | Get-Random -Count 10 | ForEach-Object { [char]$_ })
    }
    
    Process {
        Write-Verbose 'Enforcing TLS 1.2'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        Write-Host "##[group]Prepare variables"
        $feedUrl = "https://pkgs.dev.azure.com/$OrganizationName/$ProjectName/_packaging/$FeedName/nuget/v3/index.json"
        $secureToken = ConvertTo-SecureString -String $PatToken -AsPlainText -Force
        $credentials = New-Object PSCredential($PatUser, $secureToken)
        Write-Host "##[endgroup]"

        Write-Host "##[group]Set secret vault and secret store"
        if (Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue) {
            Write-Host "Vault [$VaultName] exists; removing."
            Unregister-SecretVault -Name $VaultName -ErrorAction Stop
        }
        Register-SecretVault -Name $VaultName -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault -ErrorAction Stop
        $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
        Reset-SecretStore -Scope CurrentUser -Authentication Password -Interaction None `
            -Password $securePassword -PasswordTimeout $PasswordTimeout -Force -ErrorAction Stop
        Unlock-SecretStore -Password $securePassword -ErrorAction Stop

        Set-Secret -Name $SecretName -Secret $credentials -Vault $VaultName -ErrorAction Stop
        $credentialInfo = [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSCredentialInfo]::new($VaultName, $SecretName)
        Write-Host "##[endgroup]"

        Write-Host "##[group]Set Azure Artifacts as PowerShell Repository"
        if (Get-PSResourceRepository -Name $RepositoryName -ErrorAction SilentlyContinue) {
            Write-Host "Removing existing PSResource repo [$RepositoryName]"
            Unregister-PSResourceRepository -Name $RepositoryName -ErrorAction Stop
        }
        Register-PSResourceRepository -Name $RepositoryName -Uri $feedUrl -Trusted -CredentialInfo $credentialInfo -ErrorAction Stop
        Write-Host "##[endgroup]"

        Write-Host "##[group]Import custom modules [$($CustomModules -join ', ')]"
        foreach ($module in $CustomModules) {
            Write-Host "Installing module [$module] from repository [$CustomModuleRepository]"
            Install-PSResource -Name $module -Repository $CustomModuleRepository -Credential $credentials -ErrorAction Stop
        }
        Write-Host "##[endgroup]"
    }

    End {
        Write-Verbose 'Initialization complete.'
    }

}
