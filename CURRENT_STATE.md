# CURRENT_STATE

Date: 2026-08-05

## Last Milestone: Azure Configuration Canonical — RC69

### ✅ 86/86 Pester Unit Tests Passing (Baseline)
```
Total Tests : 86
Passed      : 86
Failed      : 0
Pass Rate   : 100%
```

### PSScriptAnalyzer: 0 Errors, 0 Warnings, 493 Information
```
Errors      : 0
Warnings    : 0
Information : 493 (trailing whitespace, comment help, output type)
```

### What was accomplished (RC68 → RC69)

| # | Change | Component |
|---|--------|-----------|
| 1 | Created `config/Hermes.Azure.json` — canonical configuration file | Config |
| 2 | Created `AzureConfigurationProvider.ps1` (`Private/AzureConfiguration.ps1`) — read/validate/resolve | Kernel/Commands |
| 3 | Created `Get-HermesAzureConfiguration.ps1` — public command to read config | Command |
| 4 | Created `Set-HermesAzureConfiguration.ps1` — public command to update config | Command |
| 5 | Created `Resolve-HermesAppServicePlanId.ps1` — resolve ASP resource ID | Command |
| 6 | Updated `New-HermesProject.ps1` — accepts `-AzureConfigPath` optional param | Command |
| 7 | Added SQLite persistence — `AzureConfigurationHistory` table | Persistence |
| 8 | Added `Invoke-HermesBootstrapAzureConfig` — interactive Azure phase in BootstrapWizard | Bootstrap |
| 9 | Updated `docs/ArchitectureState.md` for RC69 | Documentation |
| 10 | Updated `CURRENT_STATE.md` for RC69 | Documentation |
| 11 | Updated `CHANGELOG.md` for RC69 | Documentation |

### Architecture: Azure Configuration Layer

```
config/
└── Hermes.Azure.json                    # Canonical config (single source of truth)

motor/kernel/Module/Hermes.Commands/
├── Private/AzureConfiguration.ps1        # AzureConfigurationProvider (read/validate/resolve)
├── Public/Get-HermesAzureConfiguration.ps1
├── Public/Set-HermesAzureConfiguration.ps1
├── Public/Resolve-HermesAppServicePlanId.ps1
├── Public/New-HermesProject.ps1          # Updated: -AzureConfigPath param

motor/bootstrap/engine/
└── BootstrapWizard.ps1                   # Updated: Invoke-HermesBootstrapAzureConfig

motor/persistence/
└── HermesSQLiteProvider/                  # AzureConfigurationHistory table
```

### Canonical Configuration Schema (`config/Hermes.Azure.json`)

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

### Public Commands (RC69 additions)

```
Get-HermesAzureConfiguration     [-ConfigPath] [-SubscriptionId]
Set-HermesAzureConfiguration     [-ConfigPath] [-Location] ... [-PassThru]
Resolve-HermesAppServicePlanId   [-ConfigPath] [-SubscriptionId]
New-HermesProject                [-AzureConfigPath] ...
```

### Next Steps

1. **RC70:** Per-project Web App deployment on shared Plan
2. **RC71:** Portal deployment under RG-Hermes-Proyectos
3. **RC72:** DNS + Front Door for global routing
4. **RC73:** SQL Database for per-project data
