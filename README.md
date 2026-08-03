# Hermes Enterprise

Enterprise-grade PowerShell framework for project automation, virtual environment management, and observability.

## Status

**RC62 — Hermes Commands Finalized with 100% Test Coverage**

- 21 PowerShell commands for project lifecycle, environment management, and workspace operations
- 64/64 Pester unit tests passing (Pester 3.4.0 compatible)
- 10 comprehensive documentation guides (Installation, Quick Start, User Manual, Troubleshooting, FAQ, Command Reference, Examples, Architecture Overview, User Acceptance Tests)
- 0 PSScriptAnalyzer errors in module and manifest
- Environment providers: VenvEnvironment and CondaEnvironment
- SQLite persistence via HermesSQLiteProvider

## Quick Start

```powershell
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force

# Create a new project
Crear-HermesProyecto -NombreProyecto "MiProyecto" -TipoEntorno venv

# Start a session
Start-HermesProject -ProjectPath "D:\Workspace\MiProyecto"
```

## Key Components

| Module | Description |
|--------|-------------|
| `Hermes.Commands.psm1` | 21 public commands: project, environment, workspace, utility |
| `Hermes.Commands.psd1` | Module manifest with aliases and exports |
| `Providers/EnvironmentProvider.ps1` | Virtual environment provider (venv/conda) |
| `Providers/ProviderBase.ps1` | Base provider contract implementation |
| `Pruebas/Unitarias/Hermes.Commands.Tests.ps1` | 64 Pester unit tests |

## 21 Public Commands

### Project Lifecycle (8)
| Command | Alias | Description |
|---------|-------|-------------|
| `Crear-HermesProyecto` | `chp` | Create new Hermes project |
| `Start-HermesProject` | `shp` | Initialize project workspace |
| `Abrir-HermesProyecto` | `ahp` | Open project in VS Code |
| `Publicar-HermesProyecto` | `uhp` | Publish to GitHub |
| `Cerrar-HermesProyecto` | `ghp` | Close project (cleanup) |
| `Eliminar-HermesProyecto` | `ghpe` | Delete project permanently |
| `Get-HermesProyecto` | — | Get project status |
| `Get-HermesProyectos` | `php` | List all projects in workspace |

### Environment Management (6)
| Command | Alias | Description |
|---------|-------|-------------|
| `New-HermesVenv` | `nhv` | Create Python venv |
| `Enter-HermesVenv` | `ehv` | Activate venv |
| `Remove-HermesVenv` | `rhv` | Remove venv |
| `New-HermesConda` | `nhc2` | Create Conda environment |
| `Enter-HermesConda` | `ehc` | Activate Conda environment |
| `Remove-HermesConda` | `rhc` | Remove Conda environment |

### Workspace & Utilities (7)
| Command | Alias | Description |
|---------|-------|-------------|
| `New-HermesWorkspace` | `nhw` | Create workspace directory |
| `Open-HermesWorkspace` | `ohw` | Open workspace in VS Code |
| `Get-HermesWorkspace` | `ghw` | Get workspace info |
| `New-HermesDocumentacion` | `nhd` | Generate documentation |
| `New-HermesCommit` | `nhc` | Create git commit |
| `Test-HermesPython` | `chp2` | Test Python availability |
| `Install-ProjectFromFactory` | `ipf` | Install from project factory |

## Test Results

```
Total Tests : 64
Passed      : 64
Failed      : 0
Pass Rate   : 100%
```

## Documentation

See `/docs/` for user-facing documentation:
- [Installation Guide](docs/Installation.md)
- [Quick Start Guide](docs/QuickStart.md)
- [User Manual](docs/UserManual.md)
- [Troubleshooting Guide](docs/Troubleshooting.md)
- [FAQ](docs/FAQ.md)
- [Command Reference](docs/CommandReference.md)
- [Examples](docs/Examples.md)
- [Architecture Overview](docs/ArchitectureOverview.md)
- [User Acceptance Tests](docs/UserAcceptanceTests.md)

See `/documentacion/` for architecture, contracts, and design decisions.