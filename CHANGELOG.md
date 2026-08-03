# CHANGELOG

## Sprint History
- A.26: Memoria persistente y normalización documental

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