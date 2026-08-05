<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : HermesArchitectureAnalyzer.psd1
Autor    : Cline AI
Proposito: Manifiesto del modulo Hermes Architecture Analyzer (HAA)
====================================================================================================
#>

@{
    RootModule        = 'HermesArchitectureAnalyzer.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Hermes Enterprise Team'
    CompanyName       = 'Hermes Enterprise'
    Copyright         = '(c) Hermes Enterprise. All rights reserved.'
    Description       = 'Hermes Architecture Analyzer - Analizador arquitectonico automatico con Canonical Source Policy, Redirect Stubs, Quality Gate y Architecture Score'

    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Invoke-HermesArchitectureAnalyzer'
        'Test-HermesArchitecture'
        'Get-HermesArchitectureReport'
        'Export-HermesArchitectureReport'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}