# Hermes Project Factory — Unified Module
# Dot-sources all individual module files

$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load all module files
Get-ChildItem "$moduleRoot/*.ps1" | ForEach-Object {
    . $_.FullName
}

# Export all public functions
Export-ModuleMember -Function @(
    # Workspace
    'Initialize-ProyectoWorkspace',
    'New-ProyectoWorkspaceFile',
    # SQLite
    'Initialize-ProyectoDatabase',
    'Set-ProyectoInfo',
    'Register-TimelineEvent',
    'Get-ProyectoInfo',
    # Git
    'Initialize-ProyectoGit',
    'New-ProyectoGitCommit',
    'Get-ProyectoGitStatus',
    # GitHub
    'Initialize-ProyectoGitHubRepo',
    'Push-ProyectoToGitHub',
    # Azure
    'Read-AzureConfiguration',
    'Validate-AzureInfrastructure',
    'New-ProyectoWebApp',
    'Deploy-ProyectoZipToAzure',
    'Wait-ProyectoWebAppReady',
    # Packaging
    'New-ProyectoDeployZip',
    'Test-DeployZipIntegrity',
    # Guardian
    'Test-GuardianRestrictions',
    'Assert-ProyectoSafeToProceed',
    'Get-GuardianSummary',
    # SmokeTests
    'Invoke-ProyectoSmokeTests',
    'Test-ProyectoLanding',
    # Reporting
    'New-ProyectoReportMD',
    'New-ProyectoReportJSON',
    'New-ProyectoReportHTML',
    'New-BlankMetadata',
    # RenderEngine
    'New-ProyectoLanding'
)