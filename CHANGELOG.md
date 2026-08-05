# CHANGELOG

## Sprint History
- A.26: Memoria persistente y normalización documental

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