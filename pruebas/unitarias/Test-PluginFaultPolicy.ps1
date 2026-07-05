<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-PluginFaultPolicy.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida la política explícita de manejo de plugins en estado Faulted sin implementar retry,
    recovery automático ni aislamiento pesado.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
$RutaRepositorioTemporal = Join-Path $RutaRaizRepositorio "pruebas\salida-temporal\plugin-fault-policy"
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

function New-HermesEnterpriseFaultPolicyTestRepository {
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
function Start-FaultyPlugin { param([psobject]$ContextoPlugin) throw "Error controlado de política en Start-FaultyPlugin" }
function Pause-FaultyPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Paused"); $ContextoPlugin.EstadoActual = "Paused"; return $ContextoPlugin }
function Resume-FaultyPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Resumed"); $ContextoPlugin.EstadoActual = "Resumed"; return $ContextoPlugin }
function Stop-FaultyPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Stopped"); $ContextoPlugin.EstadoActual = "Stopped"; return $ContextoPlugin }
function Dispose-FaultyPlugin { param([psobject]$ContextoPlugin) $ContextoPlugin.EstadosEjecutados.Add("Disposed"); $ContextoPlugin.EstadoActual = "Disposed"; return $ContextoPlugin }
'@

    Write-HermesEnterpriseTestFile -RutaArchivo (Join-Path $RutaDirectorioPluginsTemporal "GoodPlugin\plugin.json") -Contenido $ManifestPluginValido
    Write-HermesEnterpriseTestFile -RutaArchivo (Join-Path $RutaDirectorioPluginsTemporal "GoodPlugin\GoodPlugin.ps1") -Contenido $ScriptPluginValido
    Write-HermesEnterpriseTestFile -RutaArchivo (Join-Path $RutaDirectorioPluginsTemporal "FaultyPlugin\plugin.json") -Contenido $ManifestPluginDefectuoso
    Write-HermesEnterpriseTestFile -RutaArchivo (Join-Path $RutaDirectorioPluginsTemporal "FaultyPlugin\FaultyPlugin.ps1") -Contenido $ScriptPluginDefectuoso
}

. (Join-Path $RutaRaizRepositorio "motor\plugins\PluginManager.ps1")

$PoliticaContinue = New-HermesEnterprisePluginFaultPolicy -AccionPorDefecto "Continue"
Assert-HermesEnterpriseCondition ($PoliticaContinue.AccionesPermitidas -contains "Continue") "La política no declara Continue como acción permitida."
Assert-HermesEnterpriseCondition ($PoliticaContinue.AccionesPermitidas -contains "Disable") "La política no declara Disable como acción permitida."
Assert-HermesEnterpriseCondition ($PoliticaContinue.AccionesPermitidas -contains "Abort") "La política no declara Abort como acción permitida."

New-HermesEnterpriseFaultPolicyTestRepository
$AdministradorContinue = New-HermesEnterprisePluginManager -RutaRaizRepositorio $RutaRepositorioTemporal -VersionKernelActual "0.4.0" -AccionFallaPlugin "Continue"
Initialize-HermesEnterprisePlugins -AdministradorPlugins $AdministradorContinue | Out-Null
$GoodPluginContinue = Get-HermesEnterprisePlugin -AdministradorPlugins $AdministradorContinue -NombrePlugin "GoodPlugin"
$FaultyPluginContinue = Get-HermesEnterprisePlugin -AdministradorPlugins $AdministradorContinue -NombrePlugin "FaultyPlugin"
Assert-HermesEnterpriseCondition ($GoodPluginContinue.EstadoActual -eq "Started") "Continue no permitió continuar con el plugin válido."
Assert-HermesEnterpriseCondition ($FaultyPluginContinue.AccionFallaPlugin -eq "Continue") "La política Continue no quedó registrada en el plugin defectuoso."
Assert-HermesEnterpriseCondition (-not $FaultyPluginContinue.PluginDeshabilitado) "Continue no debe deshabilitar explícitamente el plugin defectuoso."

New-HermesEnterpriseFaultPolicyTestRepository
$AdministradorDisable = New-HermesEnterprisePluginManager -RutaRaizRepositorio $RutaRepositorioTemporal -VersionKernelActual "0.4.0" -AccionFallaPlugin "Disable"
Initialize-HermesEnterprisePlugins -AdministradorPlugins $AdministradorDisable | Out-Null
$FaultyPluginDisable = Get-HermesEnterprisePlugin -AdministradorPlugins $AdministradorDisable -NombrePlugin "FaultyPlugin"
$GoodPluginDisable = Get-HermesEnterprisePlugin -AdministradorPlugins $AdministradorDisable -NombrePlugin "GoodPlugin"
Assert-HermesEnterpriseCondition ($GoodPluginDisable.EstadoActual -eq "Started") "Disable no permitió continuar con el plugin válido."
Assert-HermesEnterpriseCondition ($FaultyPluginDisable.AccionFallaPlugin -eq "Disable") "La política Disable no quedó registrada en el plugin defectuoso."
Assert-HermesEnterpriseCondition $FaultyPluginDisable.PluginDeshabilitado "Disable no marcó el plugin defectuoso como deshabilitado."

New-HermesEnterpriseFaultPolicyTestRepository
$AdministradorAbort = New-HermesEnterprisePluginManager -RutaRaizRepositorio $RutaRepositorioTemporal -VersionKernelActual "0.4.0" -AccionFallaPlugin "Abort"
$AbortDetuvoInicializacion = $false
try {
    Initialize-HermesEnterprisePlugins -AdministradorPlugins $AdministradorAbort | Out-Null
}
catch {
    $AbortDetuvoInicializacion = $true
}
Assert-HermesEnterpriseCondition $AbortDetuvoInicializacion "Abort no detuvo explícitamente la inicialización ante un plugin defectuoso."

Write-Host "Test-PluginFaultPolicy completado correctamente." -ForegroundColor Green
