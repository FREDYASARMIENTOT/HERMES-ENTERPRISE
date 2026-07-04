<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : PluginLoader.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Carga scripts PowerShell de plugins de forma controlada.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Import-HermesEnterprisePluginScript {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$RutaScriptPlugin)

    if (-not (Test-Path -Path $RutaScriptPlugin)) { throw "No existe el script del plugin: $RutaScriptPlugin" }

    # Cargar el script como módulo dinámico global permite que las funciones del plugin
    # queden disponibles para el ciclo de vida aunque el loader se ejecute dentro de una función.
    $ContenidoScriptPlugin = Get-Content -Path $RutaScriptPlugin -Raw
    $NombreModuloPlugin = "HermesEnterprisePlugin_" + [System.IO.Path]::GetFileNameWithoutExtension($RutaScriptPlugin)
    $ModuloPlugin = New-Module -Name $NombreModuloPlugin -ScriptBlock ([scriptblock]::Create($ContenidoScriptPlugin))
    Import-Module $ModuloPlugin -Global -Force -DisableNameChecking

    return [pscustomobject][ordered]@{ Cargado = $true; RutaScriptPlugin = $RutaScriptPlugin; NombreModuloPlugin = $NombreModuloPlugin }
}
