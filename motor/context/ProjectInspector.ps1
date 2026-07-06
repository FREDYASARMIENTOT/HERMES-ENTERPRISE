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
        [string]$Ruta,

        [Parameter(Mandatory = $false)]
        [string]$NombreProyecto = ""
    )

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($Ruta)
    $Nombre = if ([string]::IsNullOrWhiteSpace($NombreProyecto)) { Split-Path -Path $RutaAbsoluta -Leaf } else { $NombreProyecto }

    return New-HermesEnterpriseProjectDescriptor -NombreProyecto $Nombre -RutaLocal $RutaAbsoluta
}
