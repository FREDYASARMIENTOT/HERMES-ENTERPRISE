<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : GitHubInspector.ps1
Propósito:
    Descubre información GitHub (modo MOCK) sin usar API reales ni tokens. Solo lectura.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Get-HermesEnterpriseGitHubInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreProyecto
    )

    return [pscustomobject][ordered]@{
        NombreProyecto = $NombreProyecto
        Modo           = "MOCK"
        TieneRemoto    = $false
        UsuarioGitHub  = $env:GITHUB_USER
        UrlRemota      = ""
        Estado         = "MockDetected"
    }
}
