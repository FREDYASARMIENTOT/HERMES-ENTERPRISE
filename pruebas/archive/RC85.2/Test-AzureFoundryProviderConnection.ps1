<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-AzureFoundryProviderConnection.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Prueba de integración TDD para la Fase 4.2. Valida que AzureFoundryProvider pueda:
      1. Conectarse a Azure AI Foundry.
      2. Ejecutar health check.
      3. Descubrir deployments.
    La autenticación debe usar Azure AD primero y, si falla, Azure Key Vault como fallback.
    NO se escriben credenciales en archivos; se recuperan de Azure Key Vault o Azure AD CLI.
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

. (Join-Path $RutaRaizRepositorio "motor\providers\AzureFoundryProvider.ps1")

# Verificar que existe acceso a Azure AD o Key Vault antes de continuar.
$TokenAzureAD = $null
try { $TokenAzureAD = az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv 2>$null } catch { Write-Debug "Azure AD token unavailable" }
$PuedeUsarKeyVault = $false
try { $null = az keyvault secret show --vault-name kv-hermes-enterprise-ur --name AzureOpenAI-Endpoint --query value -o tsv 2>$null; $PuedeUsarKeyVault = $true } catch { Write-Debug "Key Vault access unavailable" }

Assert-HermesEnterpriseCondition ((-not [string]::IsNullOrWhiteSpace($TokenAzureAD)) -or $PuedeUsarKeyVault) "No hay acceso a Azure AD ni a Azure Key Vault. La prueba requiere autenticación real."

$Provider = New-HermesEnterpriseAzureFoundryProvider
Assert-HermesEnterpriseCondition ($Provider.Adapter.EstadoActual -eq "Created") "Provider no inicia en Created."

# Fase 4.2: conexión con Azure AD / Key Vault.
$ResultadoConexion = Connect-AzureFoundryProvider -ContextoProvider $Provider
Assert-HermesEnterpriseCondition ($Provider.Adapter.EstadoActual -in @("Ready", "Healthy")) "Provider no alcanzó Ready/Healthy tras conectar. Estado actual: $($Provider.Adapter.EstadoActual)"

# Health check.
$Health = Invoke-AzureFoundryHealth -ContextoProvider $Provider
Assert-HermesEnterpriseCondition ($Health.Estado -eq "Healthy") "Health Check no reportó Healthy. Mensaje: $($Health.Mensaje)"

# Descubrimiento de deployments.
$Deployments = Get-AzureFoundryDeployments -ContextoProvider $Provider
Assert-HermesEnterpriseCondition ($Deployments.Count -gt 0) "No se detectaron deployments."

$DeploymentObjetivo = $Deployments | Where-Object { $_.Nombre -eq "ur-hermes-mini" } | Select-Object -First 1
Assert-HermesEnterpriseCondition ($null -ne $DeploymentObjetivo) "Deployment objetivo ur-hermes-mini no encontrado. Deployments detectados: $($Deployments.Nombre -join ', ')"

# Summary.
$Summary = Get-AzureFoundryProviderSummary -ContextoProvider $Provider
Assert-HermesEnterpriseCondition $Summary.DescriptorValido "Summary no confirma descriptor válido."
Assert-HermesEnterpriseCondition ($Summary.LimitesIncluidos.AzureFoundry -eq $true) "Summary no declara AzureFoundry."

Disconnect-AzureFoundryProvider -ContextoProvider $Provider | Out-Null
Assert-HermesEnterpriseCondition ($Provider.Adapter.EstadoActual -eq "Disposed") "Provider no finalizó en Disposed."

Write-Host "Test-AzureFoundryProviderConnection completado correctamente." -ForegroundColor Green
