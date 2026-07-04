<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Startup.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Punto interno de arranque del Kernel Enterprise para uso por scripts públicos.
====================================================================================================
#>

Set-StrictMode -Version Latest

$RutaDirectorioStartup = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioStartup "bootstrap\Bootstrap.ps1")

function Start-HermesEnterpriseStartup {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$RutaRaizRepositorio)

    return Start-HermesEnterpriseBootstrap -RutaRaizRepositorio $RutaRaizRepositorio -NombreEntorno "Desarrollo"
}
