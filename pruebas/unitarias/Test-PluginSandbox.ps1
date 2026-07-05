<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-PluginSandbox.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida Sandbox v1 de plugins: un plugin defectuoso no debe detener la inicialización
    del PluginManager ni impedir la carga de otros plugins válidos.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
$RutaRepositorioTemporal = Join-Path $RutaRaizRepositorio "pruebas\salida-temporal\plugin-sandbox"
$RutaDirectorioPluginsTemporal = Join-Path $RutaRepositorioTemporal "plugins"

function Assert-HermesEnterpriseCondition {
    param([bool]$CondicionEvaluada, [string]$MensajeError)
    if (-not $CondicionEvaluada) { throw $MensajeError }
}

function Write-HermesEnterpriseTestFile {
    param(
        [Parameter(Mandatory = $true)][string]$RutaArchivo,
        [Parameter(Mandatory = $true)][string]$Contenido
    )

    $DirectorioArchivo = Split-Path -Parent $RutaArchivo
    if (-not (Test-Path -Path $DirectorioArchivo)) {
        New-Item -Path $DirectorioArchivo -ItemType Directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($RutaArchivo, $Contenido, [System.Text.UTF8Encoding]::new($false))
}

if (Test-Path -Path $RutaRepositorioTemporal) {
    Remove-Item -Path $RutaRepositorioTemporal -Recurse -Force
}
New-Item -Path $RutaDirectorioPluginsTemporal -ItemType Directory -Force | Out-Null

$ManifestPluginValido = @'
{
  "Nombre": "GoodPlugin",
  "Version": "0.4.0",
  "Autor": "Fredy Alejandro Sarmiento Torres",
  "KernelMinimo": "0.4.0",
  "ScriptPrincipal": "GoodPlugin.ps1",
  "Dependencias": [],
  "Eventos": [],
  "Servicios": [],
  "Proveedores": [],
  "Configuracion": "plugin.settings.json",
  "Permisos": []
}
'@

$ScriptPluginValido = @'
Set-StrictMode -Version Latest
function Install-GoodPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Installed"); $ContextoPlugin.EstadoActual = "Installed"; return $ContextoPlugin }
function Initialize-GoodPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Initialized"); $ContextoPlugin.EstadoActual = "Initialized"; return $ContextoPlugin }
function Start-GoodPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Started"); $ContextoPlugin.EstadoActual = "Started"; return $ContextoPlugin }
function Pause-GoodPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Paused"); $ContextoPlugin.EstadoActual = "Paused"; return $ContextoPlugin }
function Resume-GoodPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Resumed"); $ContextoPlugin.EstadoActual = "Resumed"; return $ContextoPlugin }
function Stop-GoodPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Stopped"); $ContextoPlugin.EstadoActual = "Stopped"; return $ContextoPlugin }
function Dispose-GoodPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Disposed"); $ContextoPlugin.EstadoActual = "Disposed"; return $ContextoPlugin }
'@

$ManifestPluginDefectuoso = @'
{
  "Nombre": "FaultyPlugin",
  "Version": "0.4.0",
  "Autor": "Fredy Alejandro Sarmiento Torres",
  "KernelMinimo": "0.4.0",
  "ScriptPrincipal": "FaultyPlugin.ps1",
  "Dependencias": [],
  "Eventos": [],
  "Servicios": [],
  "Proveedores": [],
  "Configuracion": "plugin.settings.json",
  "Permisos": []
}
'@

$ScriptPluginDefectuoso = @'
Set-StrictMode -Version Latest
function Install-FaultyPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Installed"); $ContextoPlugin.EstadoActual = "Installed"; return $ContextoPlugin }
function Initialize-FaultyPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Initialized"); $ContextoPlugin.EstadoActual = "Initialized"; return $ContextoPlugin }
function Start-FaultyPlugin { param([psobject]$ContextoPlugin) throw "Error controlado de prueba en Start-FaultyPlugin" }
function Pause-FaultyPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Paused"); $ContextoPlugin.EstadoActual = "Paused"; return $ContextoPlugin }
function Resume-FaultyPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Resumed"); $ContextoPlugin.EstadoActual = "Resumed"; return $ContextoPlugin }
function Stop-FaultyPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Stopped"); $ContextoPlugin.EstadoActual = "Stopped"; return $ContextoPlugin }
function Dispose-FaultyPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Disposed"); $ContextoPlugin.EstadoActual = "Disposed"; return $ContextoPlugin }
'@

Write-HermesEnterpriseTestFile -RutaArchivo (Join-Path $RutaDirectorioPluginsTemporal "GoodPlugin\plugin.json") -Contenido $ManifestPluginValido
Write-HermesEnterpriseTestFile -RutaArchivo (Join-Path $RutaDirectorioPluginsTemporal "GoodPlugin\GoodPlugin.ps1") -Contenido $ScriptPluginValido
Write-HermesEnterpriseTestFile -RutaArchivo (Join-Path $RutaDirectorioPluginsTemporal "FaultyPlugin\plugin.json") -Contenido $ManifestPluginDefectuoso
Write-HermesEnterpriseTestFile -RutaArchivo (Join-Path $RutaDirectorioPluginsTemporal "FaultyPlugin\FaultyPlugin.ps1") -Contenido $ScriptPluginDefectuoso

. (Join-Path $RutaRaizRepositorio "motor\plugins\PluginManager.ps1")

$AdministradorPlugins = New-HermesEnterprisePluginManager -RutaRaizRepositorio $RutaRepositorioTemporal -VersionKernelActual "0.4.0"
Initialize-HermesEnterprisePlugins -AdministradorPlugins $AdministradorPlugins | Out-Null

$GoodPlugin = Get-HermesEnterprisePlugin -AdministradorPlugins $AdministradorPlugins -NombrePlugin "GoodPlugin"
$FaultyPlugin = Get-HermesEnterprisePlugin -AdministradorPlugins $AdministradorPlugins -NombrePlugin "FaultyPlugin"

Assert-HermesEnterpriseCondition ($null -ne $GoodPlugin) "El plugin válido no fue cargado después de fallar otro plugin."
Assert-HermesEnterpriseCondition ($GoodPlugin.EstadoActual -eq "Started") "El plugin válido no quedó en estado Started."
Assert-HermesEnterpriseCondition ($null -ne $FaultyPlugin) "El plugin defectuoso no quedó registrado para diagnóstico."
Assert-HermesEnterpriseCondition ($FaultyPlugin.EstadoActual -eq "Faulted") "El plugin defectuoso no quedó en estado Faulted."
Assert-HermesEnterpriseCondition ($FaultyPlugin.EstadoSandbox -eq "Faulted") "El Sandbox v1 no marcó el estado Faulted."
Assert-HermesEnterpriseCondition ($FaultyPlugin.ErroresSandbox.Count -ge 1) "El Sandbox v1 no conservó el error del plugin defectuoso."

Write-Host "Test-PluginSandbox completado correctamente." -ForegroundColor Green
