<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-Configuration.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida el administrador de configuración del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada, [string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }

. (Join-Path $RutaRaizRepositorio "motor\configuracion\ConfigurationManager.ps1")

$RutaConfiguracionTemporal = Join-Path $RutaRaizRepositorio "pruebas\salida-temporal\kernel-config-test.json"
if (Test-Path -Path $RutaConfiguracionTemporal) { Remove-Item -Path $RutaConfiguracionTemporal -Force }
$AdministradorConfiguracion = New-HermesEnterpriseConfigurationManager -RutaArchivoConfiguracion $RutaConfiguracionTemporal
$ConfiguracionKernel = Get-HermesEnterpriseConfiguration -AdministradorConfiguracion $AdministradorConfiguracion

Assert-HermesEnterpriseCondition (Test-Path $RutaConfiguracionTemporal) "El administrador no creó configuración inicial idempotente."
Assert-HermesEnterpriseCondition ($ConfiguracionKernel.Proyecto -eq "HERMES-ENTERPRISE") "La configuración no contiene el proyecto esperado."
Assert-HermesEnterpriseCondition ($ConfiguracionKernel.Kernel.Version -eq "0.4.0") "La configuración no contiene la versión del Kernel esperada."

Write-Host "Test-Configuration completado correctamente." -ForegroundColor Green
