<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-Runtime.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida Runtime y EventBus del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada, [string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }

. (Join-Path $RutaRaizRepositorio "motor\eventos\EventBus.ps1")
. (Join-Path $RutaRaizRepositorio "motor\runtime\Runtime.ps1")

$EventBusKernel = New-HermesEnterpriseEventBus
$script:EventoRecibido = $false
Subscribe-HermesEnterpriseEvent -EventBusKernel $EventBusKernel -NombreEvento "Kernel.Prueba" -AccionEvento { param($EventoPublicado) $script:EventoRecibido = ($EventoPublicado.NombreEvento -eq "Kernel.Prueba") }
Publish-HermesEnterpriseEvent -EventBusKernel $EventBusKernel -NombreEvento "Kernel.Prueba" -DatosEvento @{ Valor = 1 } | Out-Null
Assert-HermesEnterpriseCondition $script:EventoRecibido "El EventBus no entregó el evento esperado."

$RuntimeKernel = New-HermesEnterpriseRuntime -EventBusKernel $EventBusKernel
Start-HermesEnterpriseRuntime -RuntimeKernel $RuntimeKernel | Out-Null
Assert-HermesEnterpriseCondition ($RuntimeKernel.EstadoRuntime -eq "EnEjecucion") "El Runtime no inició correctamente."
Stop-HermesEnterpriseRuntime -RuntimeKernel $RuntimeKernel | Out-Null
Assert-HermesEnterpriseCondition ($RuntimeKernel.EstadoRuntime -eq "Detenido") "El Runtime no se detuvo correctamente."

Write-Host "Test-Runtime completado correctamente." -ForegroundColor Green
