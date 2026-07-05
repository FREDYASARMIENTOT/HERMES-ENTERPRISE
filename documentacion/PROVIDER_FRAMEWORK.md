# Provider Framework HERMES-ENTERPRISE

| Campo | Valor |
|---|---|
| Proyecto | HERMES-ENTERPRISE |
| AutorPrincipal | Fredy Alejandro Sarmiento Torres |
| Estado | Documento vivo |

## Responsabilidades

El Provider Framework gestiona el ciclo de vida de providers externos sin acoplarse a implementaciones concretas. Provee contratos comunes para:

- Registro (`ProviderRegistry`).
- Configuración (`ProviderConfigurationManager`).
- Estado (`ProviderAdapter`).
- Capacidades (`ProviderCapabilityDescriptor`).
- Diagnósticos (`ProviderDiagnostics`).
- Descriptor consolidado (`ProviderDescriptor`).

## Azure Foundry Provider

`motor/providers/AzureFoundryProvider.ps1` es el primer provider real. A partir de la Fase 4.4 actúa exclusivamente como orquestador y delega en módulos especializados.

### Módulos de seguridad

| Módulo | Responsabilidad |
|---|---|
| `motor/security/AzureAdResolver.ps1` | Obtener token de Azure AD y construir header `Authorization`. |
| `motor/security/KeyVaultResolver.ps1` | Leer secretos de Azure Key Vault sin persistirlos. |
| `motor/security/CredentialResolver.ps1` | Decidir origen de credenciales: Environment, Azure AD o Key Vault; probar autenticación. |

### Módulos de provider

| Módulo | Responsabilidad |
|---|---|
| `motor/providers/AzureFoundryRest.ps1` | Construir URIs, ejecutar GET/POST y serializar JSON. |
| `motor/providers/AzureFoundryHealth.ps1` | Health check e interpretación de códigos HTTP. |
| `motor/providers/AzureFoundryDeployment.ps1` | Descubrimiento y descripción de deployments. |
| `motor/providers/AzureFoundryChat.ps1` | Envío de conversaciones a un deployment. |
| `motor/providers/AzureFoundryTelemetry.ps1` | CorrelationId, métricas, costo estimado y sanitización de logs. |

## Telemetría

Cada operación del provider genera:

- `CorrelationId`: identificador único de trazabilidad.
- `LatenciaMs`: duración de la llamada.
- `TokensEntrada` / `TokensSalida`: uso del modelo.
- `CostoEstimadoUSD`: estimación simplificada por modelo.
- `Deployment` y `Modelo`: contexto de la operación.
- `Estado` y `Error`: resultado de la operación.

Los logs se escriben mediante Logger Enterprise y nunca contienen credenciales, tokens ni API keys.

## Contrato público estable

Las funciones públicas del Azure Foundry Provider no cambian:

- `New-HermesEnterpriseAzureFoundryProvider`
- `ValidateConfiguration-AzureFoundryProvider`
- `Initialize-AzureFoundryProvider`
- `Connect-AzureFoundryProvider`
- `Disconnect-AzureFoundryProvider`
- `Get-AzureFoundryProviderHealth`
- `Get-AzureFoundryDeployments`
- `Get-AzureFoundryDeploymentDescription`
- `Invoke-AzureFoundryHealth`
- `Invoke-AzureFoundryChat`
- `Get-AzureFoundryProviderDiagnostics`
- `Get-AzureFoundryProviderObservability`
- `Get-AzureFoundryProviderDescriptor`
- `Get-AzureFoundryProviderSummary`

## Límites actuales

- No Streaming.
- No Responses API avanzada.
- No Tool Calling.
- No MCP.
- No Agents.
- No Embeddings.
