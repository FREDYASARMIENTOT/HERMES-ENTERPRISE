<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ContextBuilder.ps1
Propósito:
    Orquesta los inspectores para construir un DeveloperContext completo. No persiste estado.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioContextBuilder = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioContextBuilder "WorkspaceInspector.ps1")
. (Join-Path $RutaDirectorioContextBuilder "ProjectInspector.ps1")
. (Join-Path $RutaDirectorioContextBuilder "GitInspector.ps1")
. (Join-Path $RutaDirectorioContextBuilder "GitHubInspector.ps1")
. (Join-Path $RutaDirectorioContextBuilder "EnvironmentInspector.ps1")
. (Join-Path $RutaDirectorioContextBuilder "DeveloperContext.ps1")

function Build-HermesEnterpriseDeveloperContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaWorkspace,

        [Parameter(Mandatory = $false)]
        [string]$NombreProyecto = "",

        [Parameter(Mandatory = $false)]
        [string]$Modelo = "ur-hermes-mini",

        [Parameter(Mandatory = $false)]
        [string]$ProveedorIA = "AzureFoundryProvider",

        [Parameter(Mandatory = $false)]
        [string[]]$Plugins = @(),

        [Parameter(Mandatory = $false)]
        [psobject]$Session = $null
    )

    $Workspace = Get-HermesEnterpriseWorkspaceInfo -Ruta $RutaWorkspace
    $Nombre = if ([string]::IsNullOrWhiteSpace($NombreProyecto)) { $Workspace.Nombre } else { $NombreProyecto }
    $Proyecto = Get-HermesEnterpriseProjectInfo -Ruta $Workspace.Ruta -NombreProyecto $Nombre
    $Git = Get-HermesEnterpriseGitInfo -Ruta $Workspace.Ruta
    $GitHub = Get-HermesEnterpriseGitHubInfo -NombreProyecto $Nombre
    $Entorno = Get-HermesEnterpriseEnvironmentInfo

    return New-HermesEnterpriseDeveloperContext `
        -Workspace $Workspace `
        -Proyecto $Proyecto `
        -Git $Git `
        -GitHub $GitHub `
        -Provider $ProveedorIA `
        -Modelo $Modelo `
        -Plugins $Plugins `
        -Session $Session `
        -Preferencias @{ Idioma = $Entorno.IdiomaPreferido; Region = $Entorno.Region } `
        -VariablesEntorno $Entorno.VariablesEntorno `
        -EstadoKernel $null
}
