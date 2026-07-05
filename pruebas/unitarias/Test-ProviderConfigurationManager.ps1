<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProviderConfigurationManager.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida el Configuration Manager específico de providers sin leer secretos, archivos externos,
    HTTP, IA ni proveedores reales.
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

. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderConfigurationManager.ps1")

$AdministradorConfiguracionProviders = New-HermesEnterpriseProviderConfigurationManager

$EsquemaConfiguracion = [pscustomobject][ordered]@{
    NombreProvider = "ConfigurableProvider"
    VersionEsquema = "0.1.0"
    ClavesRequeridas = @("Modelo", "Region")
    ClavesPermitidas = @("Modelo", "Region", "TimeoutSegundos", "Modo")
    ValoresPorDefecto = @{ TimeoutSegundos = 30; Modo = "Local" }
}

Register-HermesEnterpriseProviderConfigurationSchema `
    -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders `
    -EsquemaConfiguracionProvider $EsquemaConfiguracion | Out-Null

Assert-HermesEnterpriseCondition (Test-HermesEnterpriseProviderConfigurationSchemaRegistered -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders -NombreProvider "ConfigurableProvider") "El esquema de configuración no quedó registrado."

$ConfiguracionResuelta = Resolve-HermesEnterpriseProviderConfiguration `
    -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders `
    -NombreProvider "ConfigurableProvider" `
    -ConfiguracionSolicitada @{ Modelo = "mock-model"; Region = "local" }

Assert-HermesEnterpriseCondition ($ConfiguracionResuelta.Modelo -eq "mock-model") "La configuración resuelta no conserva parámetros solicitados."
Assert-HermesEnterpriseCondition ($ConfiguracionResuelta.Region -eq "local") "La configuración resuelta no conserva región solicitada."
Assert-HermesEnterpriseCondition ($ConfiguracionResuelta.TimeoutSegundos -eq 30) "La configuración resuelta no aplicó valores por defecto."
Assert-HermesEnterpriseCondition ($ConfiguracionResuelta.Modo -eq "Local") "La configuración resuelta no aplicó modo por defecto."

$ResultadoValido = Test-HermesEnterpriseProviderConfiguration `
    -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders `
    -NombreProvider "ConfigurableProvider" `
    -ConfiguracionSolicitada $ConfiguracionResuelta

Assert-HermesEnterpriseCondition $ResultadoValido.EsValida "El manager rechazó configuración local válida."
Assert-HermesEnterpriseCondition ($ResultadoValido.Errores.Count -eq 0) "La validación válida devolvió errores inesperados."

$ResultadoFaltante = Test-HermesEnterpriseProviderConfiguration `
    -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders `
    -NombreProvider "ConfigurableProvider" `
    -ConfiguracionSolicitada @{ Modelo = "mock-model" }

Assert-HermesEnterpriseCondition (-not $ResultadoFaltante.EsValida) "El manager aceptó configuración sin clave requerida."
Assert-HermesEnterpriseCondition ($ResultadoFaltante.Errores -contains "Falta clave requerida: Region") "El manager no reportó la clave requerida faltante."

$ResultadoNoPermitido = Test-HermesEnterpriseProviderConfiguration `
    -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders `
    -NombreProvider "ConfigurableProvider" `
    -ConfiguracionSolicitada @{ Modelo = "mock-model"; Region = "local"; ApiKey = "NO-DEBE-USARSE" }

Assert-HermesEnterpriseCondition (-not $ResultadoNoPermitido.EsValida) "El manager aceptó una clave no permitida o sensible."
Assert-HermesEnterpriseCondition ($ResultadoNoPermitido.Errores -contains "Clave sensible no permitida: ApiKey") "El manager no bloqueó la clave sensible ApiKey."

$EstadoConfiguracion = Get-HermesEnterpriseProviderConfigurationManagerState -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders
Assert-HermesEnterpriseCondition ($EstadoConfiguracion.TotalEsquemasRegistrados -eq 1) "El estado no consolida esquemas registrados."
Assert-HermesEnterpriseCondition (-not $EstadoConfiguracion.LimitesIncluidos.CredencialesReales) "El estado no debe declarar credenciales reales."
Assert-HermesEnterpriseCondition (-not $EstadoConfiguracion.LimitesIncluidos.ArchivosExternos) "El estado no debe declarar archivos externos."
Assert-HermesEnterpriseCondition (-not $EstadoConfiguracion.LimitesIncluidos.HTTP) "El estado no debe declarar HTTP."

Write-Host "Test-ProviderConfigurationManager completado correctamente." -ForegroundColor Green
