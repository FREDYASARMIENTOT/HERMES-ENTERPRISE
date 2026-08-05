# Hermes Enterprise

Enterprise-grade PowerShell framework for project automation, virtual environment management, and observability.

## Status

**RC68 — Azure Shared Infrastructure + Canonical Commands — 100% Test Coverage**

- 25 canonical PowerShell commands in pure English (project lifecycle, workspace, environment, system)
- 7 Azure providers: Resource Group, App Service Plan, Storage Account, App Insights, Log Analytics, Key Vault, Managed Identity
- 4 Azure orchestration use cases: Create, Verify, Delete, Export Report
- 86/86 Pester unit tests passing (Pester 3.4.0 compatible)
- 10 comprehensive documentation guides
- 0 PSScriptAnalyzer errors in module and manifest
- Environment providers: VenvEnvironment and CondaEnvironment
- SQLite persistence via HermesSQLiteProvider

## Quick Start

```powershell
Import-Module .\motor\kernel\Module\Hermes.Commands\Hermes.Commands.psd1 -Force

# Create a new project
New-HermesProject -ProjectPath "D:\Workspace\MiProyecto" -TipoEntorno venv

# Open the project in VS Code
Open-HermesProject -Path "D:\Workspace\MiProyecto"

# Get workspace info
Get-HermesWorkspace
```

## Key Components

| Module | Description |
|--------|-------------|
| `Hermes.Commands.psm1` | 25 public commands: project, workspace, environment, system |
| `Hermes.Commands.psd1` | Module manifest with aliases and exports |
| `Providers/EnvironmentProvider.ps1` | Virtual environment provider (venv/conda) |
| `Providers/ProviderBase.ps1` | Base provider contract implementation |
| `pruebas/unitarias/Hermes.Commands.RC63.Tests.ps1` | 64 Pester unit tests |

## 25 Public Commands

### Project Lifecycle (13)
| Command | Alias | Description |
|---------|-------|-------------|
| `New-HermesProject` | `nhp` | Create new Hermes project with optional venv/conda |
| `Open-HermesProject` | `ohp` | Open project in VS Code |
| `Close-HermesProject` | `chp` | Close project (cleanup logs, .venv) |
| `Remove-HermesProject` | `rhp` | Permanently delete project |
| `Update-HermesProject` | `uhp` | Update project structure and dependencies |
| `Publish-HermesProject` | `php` | Publish project to GitHub repository |
| `Clone-HermesProject` | `clhp` | Clone a project from Git |
| `Import-HermesProject` | `ihp` | Import project from archive |
| `Export-HermesProject` | `ehp` | Export project to archive |
| `Backup-HermesProject` | `bhp` | Backup project data |
| `Restore-HermesProject` | `rshp` | Restore project from backup |
| `Rename-HermesProject` | `rnhp` | Rename an existing project |
| `Get-HermesProject` | `ghp` | Get project status and structure |

### Workspace Management (3)
| Command | Alias | Description |
|---------|-------|-------------|
| `Get-HermesWorkspace` | `ghw` | Get workspace info |
| `Open-HermesWorkspace` | `ohw` | Open workspace in VS Code |
| `Close-HermesWorkspace` | `chw` | Close workspace session |

### Environment Management (5)
| Command | Alias | Description |
|---------|-------|-------------|
| `Get-HermesEnvironment` | `ghe` | Get environment details |
| `New-HermesEnvironment` | `nhe` | Create venv/conda environment |
| `Enter-HermesEnvironment` | `ehe` | Activate environment |
| `Update-HermesEnvironment` | `uhe` | Update environment packages |
| `Remove-HermesEnvironment` | `rhe` | Delete environment |

### System Commands (4)
| Command | Alias | Description |
|---------|-------|-------------|
| `Get-HermesVersion` | `ghv` | Get Hermes version info |
| `Get-HermesConfiguration` | `ghc` | Read Hermes configuration |
| `Set-HermesConfiguration` | `shc` | Write configuration settings |
| `Repair-HermesInstallation` | `rhi` | Fix module path, symlinks, DB, env vars |

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