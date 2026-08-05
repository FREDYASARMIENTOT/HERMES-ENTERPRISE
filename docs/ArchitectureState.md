# Architecture State — Hermes Enterprise RC68

## Current Phase
**RC67 → RC68**: Infraestructura Compartida Azure (MVP)

## State Overview

| Component | Status | Description |
|-----------|--------|-------------|
| Kernel (Core) | ✅ Stable | Module system, IoC, event bus operational |
| Module Registry | ✅ Stable | Dynamic discovery and loading |
| Provider Framework | ✅ RC68 | Azure providers implemented (7 total) |
| UseCase Framework | ✅ RC68 | Azure orchestration use cases (4 total) |
| Canonical Framework | ✅ Stable | All providers pass canonical structure validation |
| Testing Framework | ✅ Stable | Parser, PSSA, Pester, Architecture Analyzer |
| Azure Infrastructure | ✅ RC68 | Shared infra model, providers, use cases |
| Distribution Pipeline | ✅ Stable | Fix-StubParameters, New-HermesDistribution |

## RC68 Delivered Components

### New Documentation
- `docs/Azure-Infrastructure-Model.md` — Modelo de infraestructura compartida Azure

### New Providers (7)
| Provider | File | Functions |
|----------|------|-----------|
| Resource Group | `AzureResourceGroupProvider.ps1` | New, Get, Remove |
| App Service Plan | `AzureAppServicePlanProvider.ps1` | New, Get, Remove |
| Storage Account | `AzureStorageProvider.ps1` | New, Get, ConnectionString, Remove |
| Application Insights | `AzureApplicationInsightsProvider.ps1` | New, Get, GetKey, Remove |
| Log Analytics | `AzureLogAnalyticsProvider.ps1` | New, Get, GetWorkspaceId, Remove |
| Key Vault | `AzureKeyVaultProvider.ps1` | New, Get, Set/Get Secret, Remove |
| Managed Identity | `AzureManagedIdentityProvider.ps1` | New, Get, Set/Remove Role, Remove |

### New Use Cases (4)
| Use Case | File | Function |
|----------|------|----------|
| Crear Infraestructura | `Crear-InfraestructuraAzure.usecase.ps1` | Invoke-CrearInfraestructuraAzure |
| Verificar Infraestructura | `Verificar-InfraestructuraAzure.usecase.ps1` | Invoke-VerificarInfraestructuraAzure |
| Eliminar Infraestructura | `Eliminar-InfraestructuraAzure.usecase.ps1` | Invoke-EliminarInfraestructuraAzure |
| Exportar Reporte | `Exportar-ReporteInfraestructuraAzure.usecase.ps1` | Invoke-ExportarReporteInfraestructuraAzure |

## Deployment Order (Azure)
```
1. Managed Identity (id-hermes-infra)
2. Resource Group (RG-Hermes-Proyectos)
3. Storage Account (hermesinfra-<random>)
4. Log Analytics (hermes-logs)
5. Application Insights (hermes-insights) → linked to Log Analytics
6. Key Vault (hermes-kv-<random>) → access policy for MI
7. App Service Plan (Plan-Hermes-Proyectos) → B1 shared
8. RBAC: MI as Contributor on RG + KV Secrets User on KV
```

## Test Coverage (RC67)
- **86/86 tests passing** (Parser, PSSA, Pester, Architecture Analyzer)

## Known Issues / Next Steps
- [ ] RC69: Per-project Web App deployment on shared Plan
- [ ] RC70: Portal deployment under RG-Hermes-Proyectos
- [ ] RC71: DNS + Front Door for global routing
- [ ] RC72: SQL Database for per-project data