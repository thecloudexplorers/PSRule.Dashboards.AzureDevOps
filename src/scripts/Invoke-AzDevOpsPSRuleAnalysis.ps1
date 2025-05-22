
<#
    .SYNOPSIS
    Analyzes Azure DevOps exported data with PSRule and sends results to Azure Log Analytics.

    .DESCRIPTION
    This function loads required PSRule modules, prepares necessary variables, analyzes
    exported Azure DevOps JSON reports using PSRule rules, and sends the evaluation results 
    to Azure Log Analytics.

    .PARAMETER LogAnalyticsWorkspaceId
    The workspace ID for the Azure Log Analytics workspace.

    .PARAMETER LogAnalyticsSharedKey
    The shared key for authenticating with the Azure Log Analytics workspace.

    .PARAMETER ReportOutputPath
    The path where the exported JSON report files are stored.

    .EXAMPLE
    Invoke-AzDevOpsPSRuleAnalysis -LogAnalyticsWorkspaceId 'xxxxx' -LogAnalyticsSharedKey 'yyyyy' -ReportOutputPath '$(Build.ArtifactStagingDirectory)/export'
    #>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $LogAnalyticsWorkspaceId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $LogAnalyticsSharedKey,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ReportOutputPath
)

begin {
    Write-Host "##[group]Importing PowerShell Modules"

    try {
        Import-Module -Name PSRule.Monitor -Force -ErrorAction Stop
        Write-Host "PSGallery modules imported."
    }
    catch {
        throw "Failed to import PSRule.Monitor module: $_"
    }

    Write-Host "##[endgroup]"
}

process {
    Write-Host "##[group]Prepare variables"

    # Variables are already passed in from pipeline or task
    Write-Verbose "WorkspaceId and SharedKey retrieved from pipeline variables."
    Write-Verbose "Report output path is '$ReportOutputPath'."

    Write-Host "##[endgroup]"

    #region Analyze Azure DevOps Data
    Write-Host "##[group]Analysing Azure DevOps Data"

    # Enable TLS 1.2
    Write-Verbose "Enforcing TLS 1.2 for secure connections."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Get all directories with JSON files
    $jsonFilesGlob = Get-ChildItem -Path $ReportOutputPath -File -Recurse |
    Select-Object -ExpandProperty DirectoryName -Unique |
    ForEach-Object { Join-Path -Path $_ -ChildPath '*.json' }

    # Run PSRule assertions silently (no output)
    $assertParams = @{
        Module      = 'PSRule.Rules.AzureDevOps'
        InputPath   = $jsonFilesGlob
        ErrorAction = 'SilentlyContinue'
    }
    Assert-PSRule @assertParams

    # Run PSRule evaluation
    $invokeParams = @{
        Module    = @('PSRule.Rules.AzureDevOps', 'PSRule.Monitor')
        InputPath = $jsonFilesGlob
        Format    = 'Detect'
        Culture   = 'en'
    }
    $result = Invoke-PSRule @invokeParams

    Write-Host "Sending results to Log Analytics"

    $sendParams = @{
        WorkspaceId = $LogAnalyticsWorkspaceId
        SharedKey   = $LogAnalyticsSharedKey
        LogName     = 'PSRule'
    }
    $result | Send-PSRuleMonitorRecord @sendParams

    Write-Host "##[endgroup]"
    #endregion
}

end {
    Write-Verbose 'PSRule analysis and export to Log Analytics completed.'
}