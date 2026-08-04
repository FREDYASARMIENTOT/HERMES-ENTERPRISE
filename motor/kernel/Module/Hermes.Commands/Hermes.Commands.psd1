<#
Module manifest for Hermes.Commands
Hermes Enterprise — RC63 Global PowerShell Module
Stable Public API — Professional PowerShell Module
#>

@{

    # Module identifier
    RootModule           = 'Hermes.Commands.psm1'
    ModuleVersion        = '63.0.0'
    GUID                 = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author               = 'Fredy Alejandro Sarmiento Torres'
    CompanyName          = 'Hermes Enterprise'
    Copyright            = '(c) Hermes Enterprise. All rights reserved.'
    Description          = 'Hermes Enterprise — Global PowerShell Module. Proporciona cmdlets profesionales para gestionar proyectos Hermes: creacion, apertura, cierre, eliminacion, publicacion, actualizacion, clonacion, importacion, exportacion, respaldo, restauracion, renombrado, entornos virtuales (venv/conda), workspaces, configuracion y diagnostico.'

    # Minimum PowerShell version (PowerShell 7+)
    PowerShellVersion    = '7.0'

    # Compatible PowerShell Editions
    CompatiblePSEditions = @('Core', 'Desktop')

    # Functions to export — 25 commands (API pública estable)
    FunctionsToExport = @(
        # Proyecto (13)
        'New-HermesProject',
        'Open-HermesProject',
        'Close-HermesProject',
        'Remove-HermesProject',
        'Update-HermesProject',
        'Publish-HermesProject',
        'Clone-HermesProject',
        'Import-HermesProject',
        'Export-HermesProject',
        'Backup-HermesProject',
        'Restore-HermesProject',
        'Rename-HermesProject',
        'Get-HermesProject',

        # Workspace (3)
        'Get-HermesWorkspace',
        'Open-HermesWorkspace',
        'Close-HermesWorkspace',

        # Entorno (5)
        'Get-HermesEnvironment',
        'New-HermesEnvironment',
        'Enter-HermesEnvironment',
        'Update-HermesEnvironment',
        'Remove-HermesEnvironment',

        # Sistema (4)
        'Get-HermesVersion',
        'Get-HermesConfiguration',
        'Set-HermesConfiguration',
        'Repair-HermesInstallation'
    )

    # Cmdlets to export (none)
    CmdletsToExport      = @()

    # Variables to export
    VariablesToExport    = @()

    # Aliases to export
    AliasesToExport      = @(
        # Proyecto
        'nhp',    # New-HermesProject
        'ohp',    # Open-HermesProject
        'chp',    # Close-HermesProject
        'rhp',    # Remove-HermesProject
        'uhp',    # Update-HermesProject
        'php',    # Publish-HermesProject
        'clhp',   # Clone-HermesProject
        'ihp',    # Import-HermesProject
        'ehp',    # Export-HermesProject
        'bhp',    # Backup-HermesProject
        'rhp2',   # Restore-HermesProject
        'rnhp',   # Rename-HermesProject
        'ghp',    # Get-HermesProject

        # Workspace
        'ghw',    # Get-HermesWorkspace
        'ohw',    # Open-HermesWorkspace
        'chw',    # Close-HermesWorkspace

        # Entorno
        'ghe',    # Get-HermesEnvironment
        'nhe',    # New-HermesEnvironment
        'ehe',    # Enter-HermesEnvironment
        'uhe',    # Update-HermesEnvironment
        'rhe',    # Remove-HermesEnvironment

        # Sistema
        'ghv',    # Get-HermesVersion
        'ghc',    # Get-HermesConfiguration
        'shc',    # Set-HermesConfiguration
        'rhi'     # Repair-HermesInstallation
    )

    # Module dependencies
    NestedModules        = @()
    RequiredModules      = @()

    # Required assemblies
    RequiredAssemblies   = @()

    # File list
    FileList = @(
        'Hermes.Commands.psd1',
        'Hermes.Commands.psm1',
        'Public\New-HermesProject.ps1',
        'Public\Open-HermesProject.ps1',
        'Public\Close-HermesProject.ps1',
        'Public\Remove-HermesProject.ps1',
        'Public\Update-HermesProject.ps1',
        'Public\Publish-HermesProject.ps1',
        'Public\Clone-HermesProject.ps1',
        'Public\Import-HermesProject.ps1',
        'Public\Export-HermesProject.ps1',
        'Public\Backup-HermesProject.ps1',
        'Public\Restore-HermesProject.ps1',
        'Public\Rename-HermesProject.ps1',
        'Public\Get-HermesProject.ps1',
        'Public\Get-HermesWorkspace.ps1',
        'Public\Open-HermesWorkspace.ps1',
        'Public\Close-HermesWorkspace.ps1',
        'Public\Get-HermesEnvironment.ps1',
        'Public\New-HermesEnvironment.ps1',
        'Public\Enter-HermesEnvironment.ps1',
        'Public\Update-HermesEnvironment.ps1',
        'Public\Remove-HermesEnvironment.ps1',
        'Public\Get-HermesVersion.ps1',
        'Public\Get-HermesConfiguration.ps1',
        'Private\HermesHelpers.ps1',
        'Private\DatabaseOperations.ps1',
        'Private\PathResolver.ps1',
        'Private\Validation.ps1',
        'Providers\EnvironmentProvider.ps1',
        'Providers\ProviderBase.ps1',
        'Providers\GitHubProvider.ps1',
        'Providers\WorkspaceProvider.ps1',
        'ProjectManager\ProjectFactory.ps1',
        'ProjectManager\ProjectManager.ps1',
        'Install\Install-Hermes.ps1',
        'Install\Uninstall-Hermes.ps1',
        'Install\Update-Hermes.ps1',
        'en-US\about_Hermes.Commands.help.txt',
        'es-ES\about_Hermes.Commands.help.txt'
    )

    # Private data
    PrivateData = @{
        PSData = @{
            Tags         = @('Hermes', 'Enterprise', 'Project', 'Python', 'Venv', 'Conda', 'Git', 'GitHub', 'DevOps', 'PowerShell')
            ProjectUri   = 'https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE'
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            IconUri      = ''
            ReleaseNotes = 'RC63 — Global PowerShell Module. 25 comandos públicos: 13 proyecto, 3 workspace, 5 entorno, 4 sistema. Instalación global via PSModulePath. PowerShell 7+.'
            Prerelease   = ''
            RequireLicenseAcceptance = $false
            ExternalModuleDependencies = @()
        }
    }

    # Help info
    HelpInfoURI = 'https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE/blob/main/docs/HelpInfo/Hermes.Commands-help.xml'

    # Default prefix
    DefaultCommandPrefix = ''
}