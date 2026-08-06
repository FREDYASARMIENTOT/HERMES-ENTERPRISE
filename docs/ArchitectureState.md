# Architecture State — Hermes Enterprise RC70-D

## Current Phase
**RC69 → RC70-D**: Python Runtime Hermes Enterprise

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

## Known Issues / Next Steps
- [x] RC69: Azure Configuration Canonical — COMPLETED
- [x] RC70-D: Python Runtime Hermes Enterprise — COMPLETED
- [x] RC71-A: Technical Debt Audit — COMPLETED
- [x] RC71-B: Hardening (tests, subprocess unify, startup validation)
- [ ] RC71-C: Quality (HTTPS, ruff, cleanup)
- [ ] RC72-A: Packaging + CI/CD
- [ ] RC72-B: Directory restructure (Hermes.Web → Hermes/Web/)
- [ ] RC73: Azure deployment pipeline + SQL Database
