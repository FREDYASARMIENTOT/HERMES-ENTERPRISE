<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-MockProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida MockProvider end-to-end usando infraestructura local del Provider Framework sin red,
    HTTP, SDKs, IA, credenciales reales ni providers externos.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada, [string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }

. (Join-Path $RutaRaizRepositorio "motor\providers\MockProvider.ps1")

$MockProvider = New-HermesEnterpriseMockProvider
Assert-HermesEnterpriseCondition ($MockProvider.Adapter.EstadoActual -eq "Created") "MockProvider no inicia en Created."
Assert-HermesEnterpriseCondition ($MockProvider.ConfigurationManager.EsquemasConfiguracionProvider.Count -eq 1) "MockProvider no registró esquema de configuración."

$ConfiguracionValida = @{ Modelo = "mock-local"; Region = "local" }
$ResultadoConfiguracion = Validate-HermesEnterpriseMockProviderConfiguration -MockProvider $MockProvider -ConfiguracionProvider $ConfiguracionValida
Assert-HermesEnterpriseCondition $ResultadoConfiguracion.EsValida "MockProvider rechazó configuración válida."
Assert-HermesEnterpriseCondition ($MockProvider.Adapter.EstadoActual -eq "Validated") "MockProvider no llegó a Validated tras validar configuración."

Initialize-HermesEnterpriseMockProvider -MockProvider $MockProvider | Out-Null
Connect-HermesEnterpriseMockProvider -MockProvider $MockProvider | Out-Null
Assert-HermesEnterpriseCondition ($MockProvider.Adapter.EstadoActual -eq "Ready") "MockProvider no llegó a Ready tras conectar."

$Health = Get-HermesEnterpriseMockProviderHealth -MockProvider $MockProvider -EstadoSolicitado "Healthy"
Assert-HermesEnterpriseCondition ($Health.Estado -eq "Healthy") "MockProvider no reportó Healthy."
Assert-HermesEnterpriseCondition ($MockProvider.Adapter.EstadoActual -eq "Healthy") "MockProvider no avanzó a Healthy."

$Capabilities = Get-HermesEnterpriseMockProviderCapabilities -MockProvider $MockProvider
Assert-HermesEnterpriseCondition ($Capabilities.CapacidadesSoportadas -contains "Chat") "MockProvider no declara Chat."
Assert-HermesEnterpriseCondition (-not (Test-HermesEnterpriseProviderCapability -DescriptorCapacidadesProvider $Capabilities -NombreCapacidad "ToolCalling")) "MockProvider declara ToolCalling y no debe."
Assert-HermesEnterpriseCondition (-not (Test-HermesEnterpriseProviderCapability -DescriptorCapacidadesProvider $Capabilities -NombreCapacidad "Streaming")) "MockProvider declara Streaming y no debe."

$Diagnostics = Get-HermesEnterpriseMockProviderDiagnostics -MockProvider $MockProvider -ConfiguracionProvider $ConfiguracionValida
Assert-HermesEnterpriseCondition $Diagnostics.EsListoLocalmente "Diagnostics no marca MockProvider listo localmente."
Assert-HermesEnterpriseCondition $Diagnostics.Configuracion.EsValida "Diagnostics no conserva configuración válida."
Assert-HermesEnterpriseCondition $Diagnostics.Capacidades.EsValida "Diagnostics no conserva capacidades válidas."
Assert-HermesEnterpriseCondition $Diagnostics.Health.EsValido "Diagnostics no conserva health válido."

$Descriptor = Get-HermesEnterpriseMockProviderDescriptor -MockProvider $MockProvider -ConfiguracionProvider $ConfiguracionValida
$ResultadoDescriptor = Test-HermesEnterpriseProviderDescriptor -ProviderDescriptor $Descriptor
Assert-HermesEnterpriseCondition $ResultadoDescriptor.EsValido "Descriptor de MockProvider no es válido."
Assert-HermesEnterpriseCondition ($Descriptor.Configuration.TotalEsquemasRegistrados -eq 1) "Descriptor no conserva Configuration."
Assert-HermesEnterpriseCondition ($Descriptor.Capabilities.CapacidadesSoportadas -contains "Chat") "Descriptor no conserva Capabilities."
Assert-HermesEnterpriseCondition $Descriptor.Diagnostics.EsListoLocalmente "Descriptor no conserva Diagnostics."
Assert-HermesEnterpriseCondition ($Descriptor.Health.Estado -eq "Healthy") "Descriptor no conserva Health."
Assert-HermesEnterpriseCondition ($Descriptor.Observability.CantidadTransiciones -ge 5) "Descriptor no conserva Observability."
Assert-HermesEnterpriseCondition ($Descriptor.Maturity.EstadoMadurez -eq "MockProviderEndToEndCertificado") "Descriptor no conserva Maturity."

$Summary = Get-HermesEnterpriseMockProviderSummary -MockProvider $MockProvider -ConfiguracionProvider $ConfiguracionValida
Assert-HermesEnterpriseCondition $Summary.DescriptorValido "Summary no confirma descriptor válido."
Assert-HermesEnterpriseCondition $Summary.DiagnosticsListoLocalmente "Summary no confirma readiness local."
Assert-HermesEnterpriseCondition (-not $Summary.LimitesIncluidos.HTTP) "Summary no debe declarar HTTP."
Assert-HermesEnterpriseCondition (-not $Summary.LimitesIncluidos.AzureFoundry) "Summary no debe declarar Azure Foundry."

Disconnect-HermesEnterpriseMockProvider -MockProvider $MockProvider | Out-Null
Assert-HermesEnterpriseCondition ($MockProvider.Adapter.EstadoActual -eq "Disposed") "MockProvider no finalizó en Disposed."

$FalloTransicion = $false
try { Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $MockProvider.Adapter -NuevoEstado "Ready" | Out-Null } catch { $FalloTransicion = $true }
Assert-HermesEnterpriseCondition $FalloTransicion "MockProvider permitió transición inválida después de Disposed."

Write-Host "Test-MockProvider completado correctamente." -ForegroundColor Green
