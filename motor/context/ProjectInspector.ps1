<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProjectInspector.ps1
Propósito:
    Descubre el proyecto dentro de un workspace sin modificar el sistema de archivos. Solo lectura.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioProjectInspector = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioProjectInspector "..\providers\ProjectDescriptor.ps1")

function Get-HermesEnterpriseProjectInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Ruta
    )

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($Ruta)
    $NombreProyecto = Split-Path -Path $RutaAbsoluta -Leaf

    return New-HermesEnterpriseProjectDescriptor -NombreProyecto $NombreProyecto -RutaLocal $RutaAbsoluta
}
