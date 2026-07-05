<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-PluginFrameworkMaturity.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida el reporte consolidado de madurez y compatibilidad del Plugin Framework sin integrar
    proveedores reales ni modificar comportamiento del Kernel.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition {
    param([bool]$CondicionEvaluada, [string]$MensajeError)
    if (-not $CondicionEvaluada) { throw $MensajeError }
}

. (Join-Path $RutaRaizRepositorio "motor\plugins\PluginManager.ps1")

$AdministradorPlugins = New-HermesEnterprisePluginManager -RutaRaizRepositorio $RutaRaizRepositorio -VersionKernelActual "0.4.0" -AccionFallaPlugin "Continue"
Initialize-HermesEnterprisePlugins -AdministradorPlugins $AdministradorPlugins | Out-Null

$ReporteMadurez = Get-HermesEnterprisePluginFrameworkMaturityReport -AdministradorPlugins $AdministradorPlugins

Assert-HermesEnterpriseCondition ($ReporteMadurez.NombreComponente -eq "Enterprise Plugin Framework") "El reporte no identifica el componente evaluado."
Assert-HermesEnterpriseCondition ($ReporteMadurez.EstadoMadurez -eq "AptoParaProveedoresReales") "El reporte no declaró el framework apto para proveedores reales."
Assert-HermesEnterpriseCondition ($ReporteMadurez.VersionKernelActual -eq "0.4.0") "El reporte no conserva la versión del Kernel evaluada."
Assert-HermesEnterpriseCondition ($ReporteMadurez.TotalPluginsCargados -ge 1) "El reporte no consolidó plugins cargados."
Assert-HermesEnterpriseCondition ($ReporteMadurez.TotalPluginsFaulted -eq 0) "El reporte marcó fallas inexistentes en HelloPlugin."
Assert-HermesEnterpriseCondition ($ReporteMadurez.TotalPluginsDeshabilitados -eq 0) "El reporte marcó plugins deshabilitados inexistentes."
Assert-HermesEnterpriseCondition ($ReporteMadurez.AccionFallaPlugin -eq "Continue") "El reporte no consolidó la política de falla aplicada."

Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.Discovery "El reporte no certifica Discovery."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.Manifest "El reporte no certifica Manifest Loader."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.SemVer "El reporte no certifica SemVer."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.Lifecycle "El reporte no certifica Lifecycle."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.SandboxV1 "El reporte no certifica Sandbox v1."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.FaultPolicy "El reporte no certifica FaultPolicy."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.Observability "El reporte no certifica Observability."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.ProviderRegistry "El reporte no certifica ProviderRegistry."

Assert-HermesEnterpriseCondition (-not $ReporteMadurez.LimitesIncluidos.ProvidersReales) "El reporte no debe declarar proveedores reales implementados."
Assert-HermesEnterpriseCondition (-not $ReporteMadurez.LimitesIncluidos.AzureFoundry) "El reporte no debe declarar Azure Foundry implementado."
Assert-HermesEnterpriseCondition (-not $ReporteMadurez.LimitesIncluidos.MCP) "El reporte no debe declarar MCP implementado."
Assert-HermesEnterpriseCondition (-not $ReporteMadurez.LimitesIncluidos.IA) "El reporte no debe declarar IA implementada."
Assert-HermesEnterpriseCondition (-not $ReporteMadurez.LimitesIncluidos.RecoveryAutomatico) "El reporte no debe declarar recovery automático."

Assert-HermesEnterpriseCondition ($ReporteMadurez.PruebasRecomendadas -contains "pruebas/unitarias/Test-PluginManager.ps1") "El reporte no incluye Test-PluginManager como prueba recomendada."
Assert-HermesEnterpriseCondition ($ReporteMadurez.PruebasRecomendadas -contains "pruebas/unitarias/Test-PluginObservability.ps1") "El reporte no incluye Test-PluginObservability como prueba recomendada."
Assert-HermesEnterpriseCondition ($ReporteMadurez.ProximaFaseRecomendada -eq "IntegracionControladaDeProvidersReales") "El reporte no recomienda la siguiente fase correcta."

Write-Host "Test-PluginFrameworkMaturity completado correctamente." -ForegroundColor Green
