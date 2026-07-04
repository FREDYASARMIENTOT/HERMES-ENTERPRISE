<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-PluginManager.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida que el Administrador de Plugins descubra, ordene, cargue e inicialice HelloPlugin.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada,[string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }
. (Join-Path $RutaRaizRepositorio "motor\plugins\PluginManager.ps1")
$AdministradorPlugins = New-HermesEnterprisePluginManager -RutaRaizRepositorio $RutaRaizRepositorio -VersionKernelActual "0.4.0"
Initialize-HermesEnterprisePlugins -AdministradorPlugins $AdministradorPlugins | Out-Null
$HelloPlugin = Get-HermesEnterprisePlugin -AdministradorPlugins $AdministradorPlugins -NombrePlugin "HelloPlugin"
Assert-HermesEnterpriseCondition ($null -ne $HelloPlugin) "El administrador no cargó HelloPlugin."
Assert-HermesEnterpriseCondition ($HelloPlugin.EstadoActual -eq "Started") "HelloPlugin no quedó en estado Started."
Assert-HermesEnterpriseCondition ($AdministradorPlugins.ProveedorRegistry.ProveedoresRegistrados.ContainsKey("HelloProvider")) "HelloPlugin no registró HelloProvider."
Write-Host "Test-PluginManager completado correctamente." -ForegroundColor Green
