<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-PluginObservability.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida la observabilidad mínima del Plugin Framework para consultar plugins cargados,
    plugins Faulted, plugins deshabilitados, política aplicada y tiempos de ciclo de vida.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
$RutaRepositorioTemporal = Join-Path $RutaRaizRepositorio "pruebas\salida-temporal\plugin-observability"
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
function Start-FaultyPlugin { param([psobject]$ContextoPlugin) throw "Error controlado de observabilidad en Start-FaultyPlugin" }
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

$AdministradorPlugins = New-HermesEnterprisePluginManager -RutaRaizRepositorio $RutaRepositorioTemporal -VersionKernelActual "0.4.0" -AccionFallaPlugin "Disable"
Initialize-HermesEnterprisePlugins -AdministradorPlugins $AdministradorPlugins | Out-Null

$ReporteObservabilidad = Get-HermesEnterprisePluginObservability -AdministradorPlugins $AdministradorPlugins

Assert-HermesEnterpriseCondition ($ReporteObservabilidad.TotalPluginsCargados -eq 2) "La observabilidad no reportó los dos plugins cargados."
Assert-HermesEnterpriseCondition ($ReporteObservabilidad.TotalPluginsFaulted -eq 1) "La observabilidad no reportó un plugin Faulted."
Assert-HermesEnterpriseCondition ($ReporteObservabilidad.TotalPluginsDeshabilitados -eq 1) "La observabilidad no reportó un plugin deshabilitado."
Assert-HermesEnterpriseCondition ($ReporteObservabilidad.AccionFallaPlugin -eq "Disable") "La observabilidad no reportó la política aplicada."

$GoodPluginObservado = $ReporteObservabilidad.Plugins | Where-Object { $_.NombrePlugin -eq "GoodPlugin" }
$FaultyPluginObservado = $ReporteObservabilidad.Plugins | Where-Object { $_.NombrePlugin -eq "FaultyPlugin" }

Assert-HermesEnterpriseCondition ($GoodPluginObservado.EstadoActual -eq "Started") "La observabilidad no reportó GoodPlugin como Started."
Assert-HermesEnterpriseCondition ($FaultyPluginObservado.EstadoActual -eq "Faulted") "La observabilidad no reportó FaultyPlugin como Faulted."
Assert-HermesEnterpriseCondition $FaultyPluginObservado.PluginDeshabilitado "La observabilidad no reportó FaultyPlugin como deshabilitado."
Assert-HermesEnterpriseCondition ($null -ne $GoodPluginObservado.HoraInicio) "La observabilidad no reportó HoraInicio de GoodPlugin."
Assert-HermesEnterpriseCondition ($null -ne $GoodPluginObservado.HoraFin) "La observabilidad no reportó HoraFin de GoodPlugin."
Assert-HermesEnterpriseCondition ($GoodPluginObservado.DuracionMilisegundos -ge 0) "La observabilidad no reportó duración válida de GoodPlugin."
Assert-HermesEnterpriseCondition ($FaultyPluginObservado.ErroresSandbox -ge 1) "La observabilidad no reportó errores del plugin defectuoso."

Write-Host "Test-PluginObservability completado correctamente." -ForegroundColor Green
