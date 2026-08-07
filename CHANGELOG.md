# CHANGELOG

## Sprint History
- A.31: RC73-B — Guardian Hardened (10 resource types, 46 tests)
- A.30: RC73-A — Azure Infrastructure Guardian
- A.29: RC72 — Prueba Integral de Aceptación "Crear-HermesProyecto"
- A.28: Quality & CI — RC71-B
- A.27: Auditoría de deuda técnica RC71-A
- A.26: Memoria persistente y normalización documental

## RC73-B — Guardian Hardened — All 10 Resource Types (2026-08-07)

### Added
- **`config/Hermes.InfrastructureProtection.json` v1.1.0** — Expanded protection lists to 10 resource types: ResourceGroup, AppServicePlan, StorageAccount, KeyVault, WebApp, AIService, ApplicationInsights, LogAnalytics, Database
- **`motor/kernel/Security/AzureInfrastructureGuardian.ps1`** — Hardened with:
  - 10 resource type validation (all types above + ManagedIdentity)
  - Standardized ASCII-safe BLOCKED message with `Detalle:` reason
  - Environment tag protection (`Environment=Production` blocks deletion)
  - Protected tag protection (`Protected=true` blocks deletion)
  - Hermes tag validation (`HermesManaged` tag required)
  - Protected RG containment (resources inside protected RGs are blocked)
  - CorrelationId tracking per operation
  - User and command logging
  - JSONL audit log to `data/logs/guardian_violations.jsonl`
  - Force bypass prevention (`-Force` has no effect on protected resources)
  - Fallback safe defaults when policy file missing
- **`pruebas/unitarias/Hermes.InfrastructureGuardian.Tests.ps1`** — 46 Pester tests covering all resource types, tag protections, RG containment, message format, correlation tracking, and logging
- **`reports/RC73B_Guardian.md`**, `.html`, `.json` — Three-format report with test results, changes, and coverage

### Changed
- All 8 Azure providers continue to use Guardian as before (no provider changes needed)
- No architectural changes — fully non-invasive hardening

### Security
- Production resources (Environment=Production tag) now cannot be deleted
- Protected=true tagged resources now blocked
- Resources without HermesManaged tag are now blocked (prevention of untagged deletion)
- Resources in protected RGs are automatically protected regardless of individual resource lists

### Test Results: 46/46 PASSED

## RC73-A — Azure Infrastructure Guardian (2026-08-07)

### Added
- **`config/Hermes.InfrastructureProtection.json`** — Policy file defining protected Azure resources (RGs, ASPs, Storage, Key Vaults) with configurable `PreventDelete` flag
- **`motor/kernel/Security/AzureInfrastructureGuardian.ps1`** — Guardian module with `Invoke-InfrastructureGuardian` function that validates any destructive operation against the protection policy; blocks destruction of protected resources with clear error message
- **Guardian wired into 8 Azure providers**: `AzureResourceGroupProvider`, `AzureAppServicePlanProvider`, `AzureKeyVaultProvider`, `AzureApplicationInsightsProvider`, `AzureLogAnalyticsProvider`, `AzureStorageProvider`, `AzureManagedIdentityProvider` (2 Remove functions)
- **`Eliminar-InfraestructuraAzure.usecase.ps1`** — Now displays Guardian policy, protected resources, and warning status before execution

### Changed
- All 8 Azure providers now invoke `Invoke-InfrastructureGuardian` in their `Remove-*` functions before executing destructive operations
- `Eliminar-InfraestructuraAzure.usecase.ps1` shows Guardian protection status at startup
- `CURRENT_STATE.md` updated with RC73-A section

### Security
- New `motor/kernel/Security/` directory created for security-related infrastructure
- Protection policy prevents accidental deletion of production resource groups (`RG-Hermes-Proyectos`), App Service Plans, storage accounts, and Key Vaults
- Force flag bypass is prevented for protected resources (immutable protection)

## RC70-D Final — Closure (2026-08-07)

### Completed
- **Runtime Python**: Migrated from Conda/global Python to single shared venv at `D:\HermesRuntime\Environments\HermesEnterprise\`
- **Config**: `config/Hermes.Python.json` established as canonical source of truth
- **CI/CD**: `.github/workflows/ci.yml` — 4 validation jobs (Python, PowerShell, Docs, Deploy)
- **Quality**: 0 PSScriptAnalyzer errors, Smoke Test plan, Quality Report published
- **Architecture**: No Conda, no PATH, no global Python — exclusively Runtime official
- **All execution**: Via `python -m` patterns (pip, uvicorn, gunicorn)

### Frozen Components
- Runtime Python — no further modifications
- CI/CD pipeline — no further modifications
- BootstrapWizard — no further modifications
- VerifyEnvironment — no further modifications
- Hermes.Python.json — no further modifications
- Hermes.Azure.json — no further modifications
- Hermes Web structure (MetaPathFinder, directory layout) — no further modifications

### Deferred to RC72
- pyproject.toml
- pytest test suite
- Python Quality Tools (ruff, black, isort)
- Hermes.Web→Hermes/Web/ directory restructure → RC73

---

## RC71-B — Quality & CI Execution (2026-08-07)

### Added
- `.github/workflows/ci.yml` — CI/CD pipeline with 4 jobs: Python validation, PowerShell validation, documentation validation, deploy check
- `docs/SmokeTest_RC71.md` — 9-phase smoke test plan covering Runtime Python, dependencies, backend imports, uvicorn, landing page, API endpoints, documentation, CI/CD, and Azure App Service
- `docs/QualityReport_RC71.md` — Quality report documenting all changes, eliminated packages, risks, and next steps
- PSScriptAnalyzer suppression: `gui` pseudo-commandlet excluded from Verb-Noun checks in `PSScriptAnalyzerSettings.psd1`
- 8 dependencies now in `Hermes.Web/requirements.txt` (was 13): `fastapi>=0.110.0`, `uvicorn[standard]>=0.30.0`, `pydantic>=2.7.0`, `jinja2>=3.1.0`, `python-dotenv>=1.0.0`, `gunicorn>=22.0.0` (for Azure Linux), `pytest>=8.0.0`, `pytest-asyncio>=0.24.0`

### Changed
- **`Hermes.Web/requirements.txt`** — Auditado: eliminados `aiofiles`, `python-multipart`, `pydantic-settings`, `httpx`, `pyyaml`, `cryptography`. Agregados `python-dotenv`, `gunicorn`, `pytest`, `pytest-asyncio`. Ahora contiene SOLO dependencias reales con uso comprobado en código
- **`requirements.txt` (raíz)** — Ahora delega exclusivamente en `Hermes.Web/requirements.txt` con `-r`
- **`PSScriptAnalyzerSettings.psd1`** — Excluir `gui` (pseudo-commandlet) de reglas Verb-Noun; eliminar advertencias falsas positivas
- Index.html — Eliminada referencia a `framework` en favicon (no existe); eliminados imports sin usar (`pathlib`, `json`) de `main.py`

### Removed
- `$null` (archivo huérfano en raíz del proyecto)
- `temp_analysis.txt` (archivo temporal de auditoría)
- Paquetes sin uso real en código: `aiofiles`, `python-multipart`, `pydantic-settings`, `httpx`, `pyyaml`, `cryptography`
- Código comentado en `index.html` (referencia a favicon framework)
- Imports no utilizados en `main.py`: `pathlib`, `json`

## RC71-A — Technical Debt Audit (2026-08-05)

### Added
- `docs/TechnicalDebt_RC71.md` — Comprehensive technical debt audit report covering 23 Python files, ~80+ PowerShell cmdlets, Azure deployment, CI/CD, testing, and quality tooling
- FASE 1: Full audit of all imports — identified `sys.path.insert`, `MetaPathFinder`, `HermesWebPackageLoader`, duplicated subprocess logic, circular import risks, dead code, stub endpoints
- FASE 2: Risk classification — 6 critical, 12 high, 18 medium, 25 low findings with impact/probability/complexity scoring
- FASE 3: Hermes.Web vs Hermes/Web/ migration study — recommends maintaining MetaPathFinder for RC71, deferring directory restructure to RC72
- FASE 4: pyproject.toml evaluation — recommends migration in RC72 when test suite and CI/CD are established
- FASE 5: Dependency classification — identified 5 unnecessary packages in requirements.txt (httpx, aiofiles, python-multipart, pydantic-settings, gunicorn); proposed 4-category split (runtime, dev, test, azure)
- FASE 6: Quality tooling proposal — ruff, black, isort, mypy, bandit, pip-audit with recommended configurations
- FASE 7: Testing gap analysis — 0 Python tests, only 85 Pester tests; proposed complete pytest + Pester suite structure
- FASE 8: PowerShell audit — Verb-Noun compliance verified (all 16 cmdlets approved); identified missing tests for ~40 cmdlets
- FASE 9: Azure deployment analysis — verified startup.sh uses `python -m` patterns; proposed environment variables for App Service
- FASE 10: CI/CD pipeline design — full GitHub Actions workflow with quality, test, build, and Azure deploy stages with quality gates
- FASE 11: Documentation audit — verified RC70-D docs are current; identified gaps for RC72

### Changed
- **No source code modifications** — RC71-A is an audit-only release
- **Backlog** defined with 16 prioritized tasks across 4 priority levels (CRITICAL, HIGH, MEDIUM, LOW)

### Removed
- No files removed

## RC70-D — Python Runtime Hermes Enterprise (2026-08-05)

### Added
- `config/Hermes.Python.json` — canonical configuration for the Hermes Enterprise Python Runtime
- `Install-HermesPythonRuntime.ps1` — script to create the shared venv at `D:\HermesRuntime\Environments\HermesEnterprise\`
- `Invoke-HermesBootstrapValidacionRuntime` — new BootstrapWizard phase for Runtime validation (RC70-D)
- Pester tests for Python Runtime validation (`pruebas/unitarias/Hermes.Runtime.RC70-D.Tests.ps1`)

### Changed
- **Architecture**: Migrated from Conda/global Python to a single shared `venv` at `D:\HermesRuntime\Environments\HermesEnterprise\`
- **`New-HermesProject`**: Removed `conda` from `ValidateSet(TipoEntorno)`, removed `environment.yml` creation, changed default `PythonVersion` to `3.14`, uses Runtime from `Hermes.Python.json` instead of local `.venv`
- **`Hermes.Web/requirements.txt`**: Updated all dependency versions to cp314 wheels (Python 3.14+); removed `sqlite3>=2.6.0` (built-in), removed duplicate `httpx`, added `gunicorn` in main section
- **`requirements.txt` (root)**: Updated to reference `Hermes.Web/requirements.txt` as source of truth; removed `pyyaml` dependency
- **`config/Hermes.Python.json`**: Now points to Python 3.14 runtime at `D:\HermesRuntime\Environments\HermesEnterprise`
- **`VerifyEnvironment.ps1`**: Eliminated all `where python`, `Get-Command python`, PATH, Conda, Miniconda, Anaconda lookups. Now reads exclusively from `Hermes.Python.json`
- **`BootstrapWizard.ps1`**: Added `Invoke-HermesBootstrapValidacionRuntime` phase that validates Hermes.Python.json, python.exe, pip.exe, venv, pyvenv.cfg, requirements.txt
- **`startup.sh`**: Azure App Service startup now uses `python3 -m pip` / `python -m gunicorn` instead of raw `pip`/`gunicorn`
- **`requirements.txt` (root)**: Now references `Hermes.Web/requirements.txt` only; removed `pyyaml` dependency
- **`Hermes.Web/requirements.txt`**: Removed `sqlite3>=2.6.0` (built-in), removed duplicate `httpx`, reordered `gunicorn` to main section

### Removed
- Conda references across the entire project (Conda, Miniconda, Anaconda)
- `environment.yml` file and all environment.yml generation
- `where python` / `Get-Command python` from VerifyEnvironment.ps1
- Local `.venv` creation per project (uses shared Runtime instead)
- Dependence on Windows PATH for Python discovery
- Dependence on global Python installation

## RC69 — Azure Configuration Canonical (2026-08-05)

### Added
- `config/Hermes.Azure.json` — canonical single source of truth for Azure shared infrastructure
- `AzureConfigurationProvider.ps1` (`Private/AzureConfiguration.ps1`) — read, validate, resolve resolution chain
- `Get-HermesAzureConfiguration` — public command to read canonical config (with `-ConfigPath`, `-SubscriptionId`)
- `Set-HermesAzureConfiguration` — public command to update config fields with validation
- `Resolve-HermesAppServicePlanId` — resolve full ASP resource ID from config values
- `Invoke-HermesBootstrapAzureConfig` — interactive Azure configuration phase in BootstrapWizard.ps1
- SQLite persistence: `AzureConfigurationHistory` table records every config change

### Changed
- `New-HermesProject` — new optional `-AzureConfigPath` parameter for custom config file
- `docs/ArchitectureState.md` — documented RC69 configuration layer
- `CURRENT_STATE.md` — updated to RC69 milestone
- `CHANGELOG.md` — updated for RC69

## RC68 — Azure Shared Infrastructure (2026-08-05)

### Added
- `docs/Azure-Infrastructure-Model.md` — canonical shared infrastructure model
- 7 Azure providers under `motor/kernel/Providers/Azure/`:
  - Resource Group, App Service Plan, Storage Account, Application Insights, Log Analytics, Key Vault, Managed Identity
- 4 Azure orchestration use cases under `motor/usecases/Azure/`:
  - `Crear-InfraestructuraAzure.usecase.ps1` — full 7-step provisioning + RBAC
  - `Verificar-InfraestructuraAzure.usecase.ps1` — health check with status report
  - `Eliminar-InfraestructuraAzure.usecase.ps1` — reverse-order teardown with confirmation
  - `Exportar-ReporteInfraestructuraAzure.usecase.ps1` — JSON/Markdown export
- Deployment order documented (MI → RG → Storage → LA → AppInsights → KV → Plan → RBAC)
- All providers follow canonical pattern: New-, Get-, Remove- + resource-specific functions

### Changed
- ArchitectureState.md updated for RC68
- CURRENT_STATE.md updated with RC68 milestone
- Context window reset mid-session to maintain quality (128K → 33%)

## RC63 — Canonical Module with 25 Commands (2026-04-08)

### Added
- 25 canonical English PowerShell commands (up from 21 mixed Spanish/English)
- 13 project lifecycle commands: New, Open, Close, Remove, Update, Publish, Clone, Import, Export, Backup, Restore, Rename, Get
- 3 workspace management commands: Get, Open, Close
- 5 environment management commands: Get, New, Enter, Update, Remove
- 4 system commands: Get-HermesVersion, Get-HermesConfiguration, Set-HermesConfiguration, Repair-HermesInstallation
- 64 Pester unit tests (Pester 3.4.0 compatible) in pruebas/unitarias/Hermes.Commands.RC63.Tests.ps1
- All 29 Public/*.ps1 files synchronized with manifest
- Documented aliases for all 25 commands

### Changed
- Single canonical source: RC63 module under `motor/kernel/Module/Hermes.Commands/`
- Legacy `motor/kernel/Hermes.Commands.psd1` (RC56) deprecated
- CURRENT_STATE.md updated with 25-command table, resolved architecture warnings
- ArchitectureState.md updated: dual-canonical conflict RESOLVED
- README.md updated from 21 to 25 commands
- CHANGELOG.md updated with RC63 entry

### Fixed
- Dual-canonical conflict (RC56 vs RC63) — RC63 is the definitive version
- 17 stub files created to match all 25 declared commands
- Manifest FileList synchronized with actual files on disk

## RC62 — Hermes Commands Module (2026-03-08)

### Added
- 21 public PowerShell commands for Hermes Enterprise
- Module manifest (.psd1) with aliases and proper exports
- Environment providers: VenvEnvironment & CondaEnvironment
- 10 comprehensive documentation files in /docs/
- 64 Pester unit tests (Pester 3.4.0 compatible)
- Provider base contract with IProvider pattern

### Fixed
- PSScriptAnalyzer warning: `process` block added to `Get-EnvironmentProviderStatus` accepting pipeline input
- Pester 3.x compatibility: `$cmd.Parameters['X'].Mandatory` returning `$null` for script functions
- Pester 3.x compatibility: `.Attributes.SwitchParameter` → direct `.SwitchParameter` property
- Pester 3.x compatibility: `[ValidateSetAttribute]` → fully qualified `[System.Management.Automation.ValidateSetAttribute]`
- `Publicar-HermesProyecto`: graceful handling of unauthenticated `gh` CLI (catch block)

### Changed
- README.md updated with RC62 status and command tables
- CURRENT_STATE.md updated with full RC62 milestone details

## RC56 — Initial Module (2026-03-06)

### Added
- Initial Hermes.Commands module structure
- Project factory integration
- SQLite persistence integration
- Environment history tracking