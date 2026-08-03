<#
Module manifest for Hermes.Commands
Hermes Enterprise — Capa pública de comandos del Kernel
#>

@{

    # Module identifier
    RootModule        = 'Hermes.Commands.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Fredy Alejandro Sarmiento Torres'
    CompanyName       = 'Hermes Enterprise'
    Copyright         = '(c) Hermes Enterprise. All rights reserved.'
    Description       = 'Capa pública de comandos del Kernel Hermes Enterprise. Proporciona cmdlets avanzados para gestionar proyectos Hermes.'

    # Minimum PowerShell version
    PowerShellVersion = '5.0'

    # Functions to export (21 commands total)
    FunctionsToExport = @(
        'Crear-HermesProyecto',
        'Start-HermesProject',
        'Abrir-HermesProyecto',
        'Publicar-HermesProyecto',
        'Cerrar-HermesProyecto',
        'Eliminar-HermesProyecto',
        'Get-HermesProyecto',
        'Get-HermesProyectos',
        'Test-HermesPython',
        'New-HermesDocumentacion',
        'New-HermesCommit',
        'New-HermesVenv',
        'Enter-HermesVenv',
        'Remove-HermesVenv',
        'New-HermesConda',
        'Enter-HermesConda',
        'Remove-HermesConda',
        'New-HermesWorkspace',
        'Open-HermesWorkspace',
        'Get-HermesWorkspace',
        'Install-ProjectFromFactory'
    )

    # Cmdlets to export (none)
    CmdletsToExport   = @()

    # Variables to export
    VariablesToExport = @()

    # Aliases to export (21 aliases)
    AliasesToExport   = @(
        'chp',
        'ehp',
        'ahp',
        'uhp',
        'ghp',
        'ghpe',
        'shp',
        'php',
        'chp2',
        'nhd',
        'nhc',
        'nhv',
        'ehv',
        'rhv',
        'nhc2',
        'ehc',
        'rhc',
        'nhw',
        'ohw',
        'ghw',
        'ipf'
    )

    # Module dependencies
    # Private module files (loaded internally, not exported)
    NestedModules     = @()
    RequiredModules   = @()
    ModuleList        = @()

    # File list
    FileList = @('Hermes.Commands.psm1')

    # Private data
    PrivateData = @{
        PSData = @{
            Tags         = @('Hermes', 'Enterprise', 'Kernel', 'Project')
            ProjectUri   = 'https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE'
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ReleaseNotes = 'RC56 — 21 comandos: 12 proyecto, 6 entorno, 3 workspace + EnvironmentProvider, pipeline RC56, historicos SQLite'
        }
    }

    # Help info
    HelpInfoURI = 'https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE'
}