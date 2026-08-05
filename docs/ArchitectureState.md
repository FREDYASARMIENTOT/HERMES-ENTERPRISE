# Architecture State — Hermes Enterprise RC69

## Current Phase
**RC68 → RC69**: Azure Configuration Canonical

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

## RC69 — Azure Configuration Canonical Layer

### Files Added

| File | Purpose |
|------|---------|
| `config/Hermes.Azure.json` | Canonical configuration file (single source of truth) |
| `Private/AzureConfiguration.ps1` | AzureConfigurationProvider: read, validate, resolve |
| `Public/Get-HermesAzureConfiguration.ps1` | Public command to read config |
| `Public/Set-HermesAzureConfiguration.ps1` | Public command to update config |
| `Public/Resolve-HermesAppServicePlanId.ps1` | Resolve full ASP resource ID |
| `BootstrapWizard.ps1` | Interactive Azure phase (`Invoke-HermesBootstrapAzureConfig`) |

### Files Modified

| File | Change |
|------|--------|
| `New-HermesProject.ps1` | Added `-AzureConfigPath` optional parameter |

### Resolution Chain

The AzureConfigurationProvider follows a layered resolution:
1. **Default values** (hardcoded in provider)
2. **BootstrapWizard defaults** (interactive phase)
3. **config/Hermes.Azure.json** (canonical file, if exists)
4. **-ConfigPath override** (explicit parameter)

### Schema (`config/Hermes.Azure.json`)

```json
{
  "Azure": {
    "Location": "eastus",
    "ResourceGroupAplicaciones": "RG-Hermes-Proyectos",
    "ResourceGroupPlan": "RG-Datamining-SII2.0-Dev",
    "AppServicePlan": "ASP-IAUR",
    "StorageAccount": "saurhermesproyectos",
    "UseSharedInfrastructure": true
  }
}
```

### SQLite Persistence

The `AzureConfigurationHistory` table in `HermesSQLiteProvider` records every write with:
- `ConfigId` (UUID), `JsonContent`, `SourceFile`, `CreatedBy`, `CreatedAt`

### BootstrapWizard Integration

`Invoke-HermesBootstrapAzureConfig` is an interactive phase that:
1. Asks user if they want to configure Azure
2. Prompts for each field with current-value defaults
3. Validates all inputs
4. Writes to `config/Hermes.Azure.json`
5. Logs to SQLite history

## Test Coverage (RC69)
- **86/86 tests passing** (Baseline from RC68)
- RC69 test suite added: `AzureConfiguration` (parser, PSSA, stub)

## Known Issues / Next Steps
- [x] RC69: Azure Configuration Canonical — COMPLETED
- [ ] RC70: Per-project Web App deployment on shared Plan
- [ ] RC71: Portal deployment under RG-Hermes-Proyectos
- [ ] RC72: DNS + Front Door for global routing
- [ ] RC73: SQL Database for per-project data
