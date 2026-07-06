<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : FirstRunWizard.ps1
Propósito:
    Configura preferencias globales la primera vez que se ejecuta HERMES. No crea proyectos.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Start-HermesEnterpriseFirstRunWizard {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject][ordered]@{
        Idioma              = "es"
        ProveedorIA         = "AzureFoundryProvider"
        ModeloIA            = "ur-hermes-mini"
        UbicacionPorDefecto = Join-Path $env:USERPROFILE "HermesProjects"
        GitHubUsuario       = $env:GITHUB_USER
        Configurado         = $true
    }
}
