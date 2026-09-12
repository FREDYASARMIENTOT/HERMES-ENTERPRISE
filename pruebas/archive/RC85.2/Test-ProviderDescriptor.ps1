<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProviderDescriptor.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida ProviderDescriptor como objeto raíz de metainformación local del Provider Framework,
    sin Adapter Base, Azure, HTTP, SDKs, IA, credenciales reales ni providers externos.
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

. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderDescriptor.ps1")

$Metadata = [pscustomobject][ordered]@{ Nombre = "DescriptorProvider"; Version = "0.1.0"; Autor = "HERMES-ENTERPRISE" }
$Configuration = [pscustomobject][ordered]@{ NombreComponente = "Provider Configuration Manager"; TotalEsquemasRegistrados = 1 }
$Capabilities = [pscustomobject][ordered]@{ NombreProvider = "DescriptorProvider"; CapacidadesSoportadas = @("Chat", "Embeddings") }
$Diagnostics = [pscustomobject][ordered]@{ NombreComponente = "Provider Diagnostics"; EsListoLocalmente = $true }
$Health = [pscustomobject][ordered]@{ Estado = "Healthy"; Mensaje = "Provider localmente saludable." }
$Observability = [pscustomobject][ordered]@{ TotalProvidersRegistrados = 1; TotalProvidersUnhealthy = 0 }
$Maturity = [pscustomobject][ordered]@{ EstadoMadurez = "InfraestructuraBaseCertificada" }
$RuntimeState = [pscustomobject][ordered]@{ Estado = "Created"; EstaInicializado = $false }

$Descriptor = New-HermesEnterpriseProviderDescriptor `
    -Metadata $Metadata `
    -Configuration $Configuration `
    -Capabilities $Capabilities `
    -Diagnostics $Diagnostics `
    -Health $Health `
    -Observability $Observability `
    -Maturity $Maturity `
    -RuntimeState $RuntimeState

Assert-HermesEnterpriseCondition ($Descriptor.Nombre -eq "DescriptorProvider") "El descriptor no expone Nombre desde Metadata."
Assert-HermesEnterpriseCondition ($Descriptor.Version -eq "0.1.0") "El descriptor no expone Version desde Metadata."
Assert-HermesEnterpriseCondition ($Descriptor.Autor -eq "HERMES-ENTERPRISE") "El descriptor no expone Autor desde Metadata."
Assert-HermesEnterpriseCondition ($Descriptor.Configuration.TotalEsquemasRegistrados -eq 1) "El descriptor no conserva Configuration."
Assert-HermesEnterpriseCondition ($Descriptor.Capabilities.CapacidadesSoportadas -contains "Chat") "El descriptor no conserva Capabilities."
Assert-HermesEnterpriseCondition $Descriptor.Diagnostics.EsListoLocalmente "El descriptor no conserva Diagnostics."
Assert-HermesEnterpriseCondition ($Descriptor.Health.Estado -eq "Healthy") "El descriptor no conserva Health."
Assert-HermesEnterpriseCondition ($Descriptor.Observability.TotalProvidersRegistrados -eq 1) "El descriptor no conserva Observability."
Assert-HermesEnterpriseCondition ($Descriptor.Maturity.EstadoMadurez -eq "InfraestructuraBaseCertificada") "El descriptor no conserva Maturity."
Assert-HermesEnterpriseCondition ($Descriptor.RuntimeState.Estado -eq "Created") "El descriptor no conserva RuntimeState."
Assert-HermesEnterpriseCondition (-not $Descriptor.LimitesIncluidos.AdapterBase) "El descriptor no debe declarar Adapter Base implementado."
Assert-HermesEnterpriseCondition (-not $Descriptor.LimitesIncluidos.AzureFoundry) "El descriptor no debe declarar Azure Foundry implementado."
Assert-HermesEnterpriseCondition (-not $Descriptor.LimitesIncluidos.HTTP) "El descriptor no debe declarar HTTP implementado."

$Resumen = Get-HermesEnterpriseProviderDescriptorSummary -ProviderDescriptor $Descriptor
Assert-HermesEnterpriseCondition ($Resumen.Nombre -eq "DescriptorProvider") "El resumen no conserva Nombre."
Assert-HermesEnterpriseCondition $Resumen.TieneConfiguration "El resumen no marca Configuration presente."
Assert-HermesEnterpriseCondition $Resumen.TieneCapabilities "El resumen no marca Capabilities presente."
Assert-HermesEnterpriseCondition $Resumen.TieneDiagnostics "El resumen no marca Diagnostics presente."
Assert-HermesEnterpriseCondition $Resumen.TieneHealth "El resumen no marca Health presente."
Assert-HermesEnterpriseCondition $Resumen.TieneObservability "El resumen no marca Observability presente."
Assert-HermesEnterpriseCondition $Resumen.TieneMaturity "El resumen no marca Maturity presente."
Assert-HermesEnterpriseCondition $Resumen.EsListoLocalmente "El resumen no refleja readiness local."

$ResultadoValido = Test-HermesEnterpriseProviderDescriptor -ProviderDescriptor $Descriptor
Assert-HermesEnterpriseCondition $ResultadoValido.EsValido "El validador rechazó un descriptor completo."
Assert-HermesEnterpriseCondition ($ResultadoValido.Errores.Count -eq 0) "El descriptor completo produjo errores inesperados."

$DescriptorIncompleto = New-HermesEnterpriseProviderDescriptor `
    -Metadata $Metadata `
    -Configuration $Configuration `
    -Capabilities $Capabilities `
    -Diagnostics $Diagnostics `
    -Health $Health

$ResultadoInvalido = Test-HermesEnterpriseProviderDescriptor -ProviderDescriptor $DescriptorIncompleto
Assert-HermesEnterpriseCondition (-not $ResultadoInvalido.EsValido) "El validador aceptó descriptor incompleto."
Assert-HermesEnterpriseCondition ($ResultadoInvalido.Errores -contains "Falta sección requerida: Observability") "El validador no reportó Observability faltante."
Assert-HermesEnterpriseCondition ($ResultadoInvalido.Errores -contains "Falta sección requerida: Maturity") "El validador no reportó Maturity faltante."

Write-Host "Test-ProviderDescriptor completado correctamente." -ForegroundColor Green
