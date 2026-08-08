# Architecture State — Hermes Enterprise RC74-C

## Current Phase
**RC74-C**: Autonomous Project Factory — Closed
Previous: RC70-D (Python Runtime), RC73 (Guardian)

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
| **Python Runtime** | ✅ **RC70-D** | **Shared venv at D:\HermesRuntime\Environments\HermesEnterprise\** |

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

## RC70-D — Python Runtime Hermes Enterprise Layer

### Problem Solved
- Hermes depended on Conda, global Python, and PATH-based discovery
- Each project had its own `.venv`, causing duplication and inconsistency
- No canonical configuration for the Python interpreter
- Deployment scripts used raw `pip`/`uvicorn`/`gunicorn` instead of `python -m`

### Solution
- **Single shared venv** at `D:\HermesRuntime\Environments\HermesEnterprise\`
- **Canonical config** at `config/Hermes.Python.json` (reads all Runtime paths)
- **All execution** via `python -m pip`, `python -m uvicorn`, `python -m gunicorn`
- **No Conda**, no global Python, no PATH dependency

### Files Added (RC70-D)

| File | Purpose |
|------|---------|
| `config/Hermes.Python.json` | Canonical Python Runtime configuration |
| `Install-HermesPythonRuntime.ps1` | Script to create the shared venv and install deps |

### Files Modified (RC70-D)

| File | Change |
|------|--------|
| `tools/VerifyEnvironment.ps1` | Removed all Conda/PATH/global Python lookups; reads only `Hermes.Python.json` |
| `motor/bootstrap/engine/BootstrapWizard.ps1` | Added `Invoke-HermesBootstrapValidacionRuntime` phase |
| `motor/kernel/Module/Hermes.Commands/Public/New-HermesProject.ps1` | Removed `conda`, removed `.venv` creation, uses Runtime from config |
| `Hermes.Web/deployment/startup.sh` | Uses `python3 -m pip` / `python -m gunicorn` instead of raw commands |
| `requirements.txt` (root) | References `Hermes.Web/requirements.txt`; removed `pyyaml` |
| `Hermes.Web/requirements.txt` | Clean deps: removed `sqlite3` (built-in), removed duplicate `httpx` |

### Files Removed (RC70-D)

| File | Reason |
|------|--------|
| `environment.yml` (root) | Conda environment file no longer needed |

### Schema (`config/Hermes.Python.json`)

```json
{
    "VersionPython": "3.14",
    "RutaEntornoVirtual": "D:\\HermesRuntime\\Environments\\HermesEnterprise",
    "RutaPython":
        "D:\\HermesRuntime\\Environments\\HermesEnterprise\\Scripts\\python.exe",
    "RutaPip":
        "D:\\HermesRuntime\\Environments\\HermesEnterprise\\Scripts\\pip.exe",
    "ArchivoRequirements":
        "requirements.txt"
}
```

### Runtime Validation (BootstrapWizard)

The `Invoke-HermesBootstrapValidacionRuntime` phase validates:
1. `config/Hermes.Python.json` exists
2. `python.exe` exists at configured path
3. `pip.exe` exists at configured path
4. The venv directory exists
5. `pyvenv.cfg` exists in the venv
6. `requirements.txt` exists at configured path

If any check fails, the wizard reports errors and instructs the user to run `Install-HermesPythonRuntime.ps1`.

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

## RC70-D Final — Closure
**Closed:** 2026-08-07  
**Status:** ✅ DEFINITIVAMENTE COMPLETADO  
**Runtime definitivo:** `D:\HermesRuntime\Environments\HermesEnterprise\` (shared venv, Python 3.14)  
**Config definitiva:** `config/Hermes.Python.json` (canonical source of truth)  
**CI/CD definitivo:** `.github/workflows/ci.yml` — 4 jobs (Python, PowerShell, Docs, Deploy)  
**Arquitectura definitiva:** Sin Conda, sin PATH, sin global Python — solo Runtime oficial

### Architecture Frozen at RC70-D
The following components are frozen and must NOT be modified:
- Runtime Python (`D:\HermesRuntime\Environments\HermesEnterprise\`)
- CI/CD pipeline (`.github/workflows/ci.yml`)
- BootstrapWizard (`motor/bootstrap/engine/BootstrapWizard.ps1`)
- VerifyEnvironment (`tools/VerifyEnvironment.ps1`)
- Hermes.Python.json (`config/Hermes.Python.json`)
- Hermes.Azure.json (`config/Hermes.Azure.json`)
- Hermes Web structure (MetaPathFinder, directory layout)

## Test Coverage (RC70-D)
- **86/86 tests passing** (Baseline from RC68)
- RC69 test suite added: `AzureConfiguration` (parser, PSSA, stub)
- RC70-D test suite added: `Hermes.Runtime.RC70-D.Tests.ps1` (Runtime validation)

## RC71-A — Technical Debt Audit

### Current Phase
**Audit-only release**: No source code modifications. Comprehensive technical debt analysis of 23 Python files, ~80+ PowerShell cmdlets, Azure deployment, CI/CD, and testing infrastructure.

### Key Findings

| Severity | Count | Top Issues |
|----------|-------|------------|
| CRÍTICO | 6 | MetaPathFinder fragility, HermesWebPackageLoader exec delegation, 0 Python tests, subprocess dependency for data |
| ALTO | 12 | 3 duplicated subprocess implementations, `sys.path.insert` global, `sys.executable` instead of `Hermes.Python.json`, God Object (main.py ~570 lines), missing Pester tests |
| MEDIO | 18 | Logger init before basicConfig, circular import risk, API stubs, no HTTPS config, unorganized requirements |
| BAJO | 25 | Dead code ($null, temp_analysis.txt), absolute Windows paths in docstrings, no ruff/black/isort/mypy |

### Hermes.Web Architecture Assessment

**RECOMMENDATION: Maintain current structure for RC71.** The MetaPathFinder + `sys.path.insert` approach, while fragile, is functional and tested. Migration to `Hermes/Web/` (which would eliminate the Finder) is deferred to RC72 when:
- Full pytest suite exists
- CI/CD pipeline validates each release
- Rollback plan is documented

**Justification:** The dot in `Hermes.Web/` is incompatible with Python's standard import system. Renaming the directory would modify all imports, deployment files, and Azure scripts. Risk of current refactor > risk of maintaining Finder.

### Dependency Audit

| Package | In requirements.txt? | Actually imported? | Verdict |
|---------|---------------------|-------------------|---------|
| fastapi | ✅ | ✅ | Keep |
| uvicorn | ✅ | ✅ | Keep |
| jinja2 | ✅ | ✅ | Keep |
| pydantic | ✅ | ✅ | Keep |
| httpx | ✅ | ❌ (error msg only) | Remove |
| aiofiles | ✅ | ❌ | Remove |
| python-multipart | ✅ | ❌ | Remove |
| pydantic-settings | ✅ | ❌ | Remove |
| gunicorn | ✅ | ❌ (uses uvicorn) | Remove |

### Testing Gaps

| Type | Existing | Needed |
|------|---------|--------|
| Python (pytest) | 0 tests | ~100+ tests for backend, API, middleware |
| PowerShell (Pester) | 85 tests | +40 tests for new RC70 cmdlets |
| Coverage | None | Target: ≥80% for Python, 100% pass for Pester |

### Action Plan (RC71-B → RC72-B)

| Phase | Focus | Duration | Priority |
|-------|-------|----------|----------|
| RC71-B | Tests, unify subprocess, startup validation | 5-7 days | CRÍTICA |
| RC71-C | Cleanup dead code, add HTTPS, config ruff | 3-5 days | ALTA |
| RC72-A | pyproject.toml, classified requirements, CI/CD | 5-8 days | MEDIA |
| RC72-B | Hermes.Web→Hermes/Web/, remove Finder, docs | 8-12 days | BAJA |

**Full details:** See `docs/TechnicalDebt_RC71.md`

## RC73-A — Azure Infrastructure Guardian (Protection Layer)

**Status:** ✅ COMPLETADO  
**Date:** 2026-08-07  

### Problem Solved
- Destructive Azure operations (Remove-HermesAzureResourceGroup, etc.) had no protection layer
- A single mistake could delete production infrastructure (RG-Hermes-Proyectos)
- No policy-based guardrail existed to prevent accidental destruction of shared resources
- Each provider had its own `-Force` switch but no centralized validation

### Solution
- **Policy file**: `config/Hermes.InfrastructureProtection.json` defines protected resources
- **Guardian module**: `motor/kernel/Security/AzureInfrastructureGuardian.ps1` with `Invoke-InfrastructureGuardian`
- **Wired into all 8 Azure providers**: Every `Remove-*` function invokes Guardian before executing
- **Immutability**: Protected resources cannot be deleted even with `-Force`

### New Files
| File | Purpose |
|------|---------|
| `config/Hermes.InfrastructureProtection.json` | Policy: Protected RGs, ASPs, Storage, Key Vaults |
| `motor/kernel/Security/AzureInfrastructureGuardian.ps1` | Guardian: `Get-HermesInfrastructurePolicy`, `Invoke-InfrastructureGuardian` |

### Modified Files
| File | Change |
|------|--------|
| 8 Azure Providers | Added Guardian call in each `Remove-*` function |
| `Eliminar-InfraestructuraAzure.usecase.ps1` | Displays Guardian policy, protected resources, protection status |

### Architecture
```
motor/kernel/Security/
└── AzureInfrastructureGuardian.ps1
    ├── Get-HermesInfrastructurePolicy     → reads config/Hermes.InfrastructureProtection.json
    └── Invoke-InfrastructureGuardian       → validates Operation/ResourceName against policy
        ├── If protected → throws [Guardian] BLOCKED error
        └── If not protected → returns $true (operation allowed)
        
config/
└── Hermes.InfrastructureProtection.json   ← Policy file (JSON)
    ├── PolicyName, Version
    ├── ProtectedResourceGroups
    │   └── RG-Hermes-Proyectos (PreventDelete: true)
    ├── ProtectedAppServicePlans
    ├── ProtectedStorageAccounts
    └── ProtectedKeyVaults
```

### Design Decisions
1. **Guardian operates at provider level** — Every `Remove-*` function invokes Guardian independently, ensuring protection even when called outside the use case orchestration
2. **Policy is JSON-based** — Non-developers can modify it; no PowerShell changes needed to add/remove protected resources
3. **Immutability by policy** — `PreventDelete: true` is enforced regardless of `-Force` flag; only changing the policy file can bypass protection
4. **New `motor/kernel/Security/` directory** — Separation of concerns: security logic isolated from business providers
5. **No functional changes to frozen components** — Runtime Python, CI/CD, Bootstrap, VerifyEnvironment, Hermes.Python.json, Hermes.Azure.json remain untouched

### Files Changed (detailed)
| Provider | Function Wired |
|----------|---------------|
| AzureResourceGroupProvider.ps1 | Remove-HermesAzureResourceGroup |
| AzureAppServicePlanProvider.ps1 | Remove-HermesAzureAppServicePlan |
| AzureKeyVaultProvider.ps1 | Remove-HermesAzureKeyVault (both) |
| AzureApplicationInsightsProvider.ps1 | Remove-HermesAzureApplicationInsights |
| AzureLogAnalyticsProvider.ps1 | Remove-HermesAzureLogAnalytics |
| AzureStorageProvider.ps1 | Remove-HermesAzureStorageAccount |
| AzureManagedIdentityProvider.ps1 | Remove-HermesAzureManagedIdentityRole + Remove-HermesAzureManagedIdentity |

## Known Issues / Next Steps
- [x] RC69: Azure Configuration Canonical — COMPLETED
- [x] RC70-D: Python Runtime Hermes Enterprise — COMPLETED
- [x] RC71-A: Technical Debt Audit — COMPLETED
- [x] RC71-B: Hardening (tests, subprocess unify, startup validation)
- [x] RC73-A: Azure Infrastructure Guardian — COMPLETED
- [x] RC73-B: Guardian Hardened (10 resource types, 46 tests) — COMPLETED
- [ ] RC73-C: Python Tests + pyproject.toml
- [ ] RC74: Hermes.Web → Hermes/Web/ directory restructure
- [ ] RC75: Azure deployment pipeline + production monitoring

## RC73-B — Guardian Hardened — All 10 Resource Types

**Status:** ✅ COMPLETADO  
**Date:** 2026-08-07  

### What RC73-B delivered
1. **`config/Hermes.InfrastructureProtection.json` v1.1.0** — Expanded to 10 resource types
2. **Guardian hardened** with standardized BLOCKED message, tag protections (Environment=Production, Protected=true, HermesManaged), RG containment, CorrelationId, JSONL logging, Force bypass prevention, fallback safe defaults
3. **46 Pester tests** covering all resource types, tag protections, RG containment, message format, correlation tracking, and logging
4. **`reports/RC73B_Guardian.md`**, `.html`, `.json` — Three-format report
5. **46/46 tests PASSED** — no architectural changes

---

## RC74-C — Autonomous Project Factory (Fixed)

**Status:** ✅ COMPLETADO
**Date:** 2026-08-08

### Architecture Overview

Hermes Enterprise now has a **zero-touch autonomous project factory** closed and fully operational.
The Crear-HermesProyecto orchestrator creates brand-new projects and deploys them to Azure with no human intervention.

### Component Architecture

```
tools/
├── Crear-HermesProyecto.ps1       # Orchestrator (296 lines)
├── Modules/
│   ├── Azure.ps1                  # Read config, validate infra, create Web App, deploy ZIP
│   ├── Git.ps1                    # Init, commit, status
│   ├── GitHub.ps1                 # Create repo, push
│   ├── Guardian.ps1               # Validate infrastructure protection
│   ├── HermesProjectFactory.psm1  # Single entry point (10 modules aggregated)
│   ├── Packaging.ps1              # Create deploy.zip, verify SHA256/size/structure
│   ├── RenderEngine.ps1           # Template rendering, landing page
│   ├── Reporting.ps1              # MD/JSON/HTML reports
│   ├── SmokeTests.ps1             # Smoke test suite (10+ endpoints)
│   ├── SQLite.ps1                 # Database, events, metadata
│   └── Workspace.ps1              # Workspace init
└── Templates/
    ├── backend/                   # main.py, requirements.txt, startup.sh
    ├── database/schema.sql        # SQLite schema
    ├── github/deploy.yml          # GitHub Actions CI/CD
    └── project/                   # .gitignore, README.md
```

### Pipeline Flow (25 steps)

1. CorrelationId → 2. Workspace → 3. SQLite → 4. Register → 5. Render → 6. Landing → 7. README → 8. Workspace File → 9. Git Init → 10. Commit → 11. GitHub → 12. Push → 13. Azure Config → 14. Validate Infra → 15. WebApp → 16. ZIP → 17. Zip Deploy → 18. Wait → 19. Smoke Tests → 20. Update SQLite → 21. Update Landing → 22. Timeline → 23. Reports → 24. Open URL → 25. Git Status → 26. Commit Final → 27. Push Final

### Infrastructure Rules

- Never creates: RGs, Storage, ASPs, Key Vault, AI, Log Analytics, App Insights, Managed ID, DBs
- Only creates: Web App (using existing infrastructure from Hermes.Azure.json)
- Guardian validates every operation against Hermes.InfrastructureProtection.json
- Demo project: "EncuestasPercepcionServiciosUR" — Universidad del Rosario

### Key Fixes Applied

- All `2>$null` → `2>&1` (proper stderr handling)
- Pipeline order corrected to match official specification
- No DemoVentas/Sales/Orders references
- Duplication eliminated: single entry point via HermesProjectFactory.psm1
- New-ProyectoDeployZip simplified: pure packaging, no Azure/Git/SQL logic
