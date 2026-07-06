<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : WorkspaceInspector.ps1
Propósito:
    Descubre el workspace actual sin modificar el sistema de archivos. Solo lectura.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Get-HermesEnterpriseWorkspaceInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Ruta
    )

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($Ruta)
    $Existe = Test-Path -Path $RutaAbsoluta -PathType Container
    $Nombre = Split-Path -Path $RutaAbsoluta -Leaf
    $TieneWorkspaceVSCode = Test-Path -Path (Join-Path $RutaAbsoluta "*.code-workspace") -PathType Leaf

    return [pscustomobject][ordered]@{
        Ruta = $RutaAbsoluta
        Existe = $Existe
        Nombre = $Nombre
        TieneWorkspaceVSCode = $TieneWorkspaceVSCode
    }
}
