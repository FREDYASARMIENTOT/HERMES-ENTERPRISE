<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-Registry.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida registro de módulos, servicios y contenedor de dependencias del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada, [string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }

. (Join-Path $RutaRaizRepositorio "motor\registro\ModuleRegistry.ps1")
. (Join-Path $RutaRaizRepositorio "motor\dependencias\DependencyInjection.ps1")
. (Join-Path $RutaRaizRepositorio "motor\dependencias\ServiceLocator.ps1")

$RegistroModulos = New-HermesEnterpriseModuleRegistry
Register-HermesEnterpriseModule -RegistroModulos $RegistroModulos -NombreModulo "ModuloPrueba" -VersionModulo "0.0.1" -RutaModulo "motor/prueba" -CapacidadesModulo @("Prueba") | Out-Null
Assert-HermesEnterpriseCondition ((Get-HermesEnterpriseRegisteredModules -RegistroModulos $RegistroModulos).Count -eq 1) "El registro de módulos no registró el módulo esperado."

$ContenedorDependencias = New-HermesEnterpriseDependencyContainer
Register-HermesEnterpriseService -ContenedorDependencias $ContenedorDependencias -NombreServicio "ServicioPrueba" -InstanciaServicio @{ Nombre = "Instancia" } | Out-Null
$ServicioResuelto = Resolve-HermesEnterpriseService -ContenedorDependencias $ContenedorDependencias -NombreServicio "ServicioPrueba"
Assert-HermesEnterpriseCondition ($ServicioResuelto.Nombre -eq "Instancia") "El contenedor no resolvió el servicio esperado."

$LocalizadorServicios = New-HermesEnterpriseServiceLocator -ContenedorDependencias $ContenedorDependencias
Assert-HermesEnterpriseCondition ((Get-HermesEnterpriseService -LocalizadorServicios $LocalizadorServicios -NombreServicio "ServicioPrueba").Nombre -eq "Instancia") "El ServiceLocator no resolvió el servicio esperado."

Write-Host "Test-Registry completado correctamente." -ForegroundColor Green
