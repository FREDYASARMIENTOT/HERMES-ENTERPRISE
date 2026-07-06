<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : GitInspector.ps1
Propósito:
    Descubre el estado Git de un proyecto sin ejecutar operaciones destructivas. Solo lectura.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioGitInspector = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioGitInspector "..\providers\GitManager.ps1")

function Get-HermesEnterpriseGitInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Ruta
    )

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($Ruta)
    $TieneGit = Test-HermesEnterpriseGitRepository -Ruta $RutaAbsoluta

    return [pscustomobject][ordered]@{
        Ruta = $RutaAbsoluta
        TieneGit = $TieneGit
        BranchActual = if ($TieneGit) { "main" } else { "" }
        Estado = if ($TieneGit) { "Detected" } else { "NoRepository" }
    }
}
