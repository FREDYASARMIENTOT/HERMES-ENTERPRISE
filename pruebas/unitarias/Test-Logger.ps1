<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-Logger.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida el sistema de logging estructurado del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada, [string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }

. (Join-Path $RutaRaizRepositorio "motor\logging\Logger.ps1")

$RutaTemporalLogs = Join-Path $RutaRaizRepositorio "pruebas\salida-temporal\kernel-logger-test.jsonl"
$LoggerKernel = New-HermesEnterpriseLogger -RutaArchivoLog $RutaTemporalLogs -NombreComponente "PruebaLogger"
Write-HermesEnterpriseLogEvent -LoggerKernel $LoggerKernel -Nivel "INFO" -Mensaje "Evento de prueba" -DatosEvento @{ Caso = "Logger" } | Out-Null

Assert-HermesEnterpriseCondition (Test-Path $RutaTemporalLogs) "El logger no creó el archivo JSONL esperado."
$LineaLog = Get-Content -Path $RutaTemporalLogs -Raw
Assert-HermesEnterpriseCondition ($LineaLog.Contains('"Nivel":"INFO"')) "El logger no registró el nivel esperado."
Assert-HermesEnterpriseCondition ($LineaLog.Contains('"Mensaje":"Evento de prueba"')) "El logger no registró el mensaje esperado."

Write-Host "Test-Logger completado correctamente." -ForegroundColor Green
