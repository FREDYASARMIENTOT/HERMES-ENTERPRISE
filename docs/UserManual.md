# Hermes Enterprise User Manual (RC70-D)

## Table of Contents

1. [Introduction](#introduction)
2. [System Requirements](#system-requirements)
3. [Installation](#installation)
4. [Getting Started](#getting-started)
5. [Project Management](#project-management)
6. [Environment Management](#environment-management)
7. [Workspace Management](#workspace-management)
8. [Git Integration](#git-integration)
9. [GitHub Integration](#github-integration)
10. [Documentation](#documentation)
11. [Troubleshooting](#troubleshooting)

## Introduction

Hermes Enterprise is an enterprise-grade PowerShell framework for system automation, project scaffolding, and environment management. It provides a complete workflow for creating, managing, and deploying Python projects with a centralized Hermes Python Runtime (venv-based), Git integration, and GitHub publishing.

> **Architecture Update (RC70-D):** Hermes Enterprise now uses a **single centralized Python Runtime** at `D:\HermesRuntime\Environments\HermesEnterprise\`. All Python execution uses the interpreter configured in `config/Hermes.Python.json`. No Conda, no global Python, no PATH dependency.

## System Requirements

- **PowerShell**: Version 5.0 or higher (PowerShell 7 recommended)
- **Hermes Python Runtime**: Installed via `Install-HermesPythonRuntime.ps1`
- **Git**: Version 2.30 or higher
- **GitHub CLI**: Version 2.0 or higher (for GitHub features)
- **VS Code**: Latest version (optional, for workspace features)

> **Note:** Python is bundled in the Hermes Python Runtime. No separate Python installation is required.

## Installation

See [Installation Guide](Installation.md) for detailed instructions.

### Quick Install

```powershell
git clone https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE.git
cd HERMES-ENTERPRISE
.\Install-HermesPythonRuntime.ps1
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force
```

## Getting Started

### Import the Module

```powershell
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force
```

### List Available Commands

```powershell
Get-Command -Module Hermes.Commands
```

### Get Help

```powershell
Get-Help Crear-HermesProyecto -Full
Get-Help Get-HermesProyecto -Examples
```

## Project Management

### Create a New Project

Creates a complete project structure with optional Git initialization and GitHub repository.

```powershell
# Basic project
Crear-HermesProyecto -NombreProyecto "MiProyecto"

# Full setup with Git and GitHub
Crear-HermesProyecto -NombreProyecto "MiProyecto" -InicializarGit -CrearRepositorioGitHub

# Open in VS Code after creation
Crear-HermesProyecto -NombreProyecto "MiProyecto" -AbrirVSCode

# Custom workspace root
Crear-HermesProyecto -NombreProyecto "MiProyecto" -WorkspaceRoot "C:\Users\MiUser\Projects"
```

### Start an Existing Project

```powershell
# Auto-create a test project
Start-HermesProject

# Initialize an existing directory
Start-HermesProject -ProjectPath "D:\Proyectos\MiProyecto"
```

### Open Project in VS Code

```powershell
Abrir-HermesProyecto -ProjectPath "D:\Proyectos\MiProyecto"
```

### Publish to GitHub

```powershell
Publicar-HermesProyecto -ProjectPath "D:\Proyectos\MiProyecto" -GitHubUser "FREDYASARMIENTOT" -RepoName "MiProyecto"
```

### Close a Project

Closes the project by cleaning temporary files.

```powershell
Cerrar-HermesProyecto -ProjectPath "D:\Proyectos\MiProyecto"
```

### Delete a Project

Permanently removes the project directory and all its contents.

```powershell
Eliminar-HermesProyecto -ProjectPath "D:\Proyectos\MiProyecto"
```

### Check Project Status

```powershell
Get-HermesProyecto -ProjectPath "D:\Proyectos\MiProyecto"
```

### List All Projects

```powershell
Get-HermesProyectos
Get-HermesProyectos -WorkspaceRoot "C:\Users\MiUser\Projects"
```

## Environment Management

All environment operations use the **Hermes Python Runtime** at `D:\HermesRuntime\Environments\HermesEnterprise\`.

### Create Project Environment

```powershell
New-HermesEnvironment -NombreProyecto "MiProyecto" -TipoEntorno "venv"
```

Creates a `.venv` symlink/copy inside the project referencing the Hermes Python Runtime.

### Activate Environment

Returns the activation command for PowerShell:

```powershell
$activateCmd = Enter-HermesEnvironment -NombreProyecto "MiProyecto"
Invoke-Expression $activateCmd
```

### Remove Environment

```powershell
Remove-HermesEnvironment -NombreProyecto "MiProyecto"
```

## Workspace Management

### Create a Workspace

```powershell
New-HermesWorkspace -WorkspaceRoot "D:\Proyectos"
```

### Open Workspace in VS Code

```powershell
Open-HermesWorkspace -WorkspaceRoot "D:\Proyectos"
```

### List Workspaces

```powershell
Get-HermesWorkspace
```

## Git Integration

### Initialize Git in a Project

```powershell
Crear-HermesProyecto -NombreProyecto "MiProyecto" -InicializarGit
```

### Commit Changes

```powershell
New-HermesCommit -ProjectPath "D:\Proyectos\MiProyecto" -Mensaje "Add new features"
```

## GitHub Integration

### Create Repository

```powershell
Crear-HermesProyecto -NombreProyecto "MiProyecto" -CrearRepositorioGitHub
```

### Push to GitHub

```powershell
Publicar-HermesProyecto -ProjectPath "D:\Proyectos\MiProyecto" -GitHubUser "FREDYASARMIENTOT" -RepoName "MiProyecto"
```

## Documentation

### Generate Project Documentation

```powershell
New-HermesDocumentacion -ProjectPath "D:\Proyectos\MiProyecto" -ProjectName "MiProyecto"
```

## Python Verification

```powershell
Test-HermesPython
```

Verifies that the Hermes Python Runtime is properly configured and all dependencies are installed.

## Complete Workflow Example

```powershell
# 1. Import module
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force

# 2. Create project
Crear-HermesProyecto -NombreProyecto "DemoProject" -InicializarGit

# 3. Generate documentation
New-HermesDocumentacion -ProjectPath "D:\Proyectos\DemoProject" -ProjectName "DemoProject"

# 4. Create environment (uses Hermes Python Runtime)
New-HermesEnvironment -NombreProyecto "DemoProject" -TipoEntorno "venv"

# 5. Commit
New-HermesCommit -ProjectPath "D:\Proyectos\DemoProject" -Mensaje "Initial setup"

# 6. Open in VS Code
Abrir-HermesProyecto -ProjectPath "D:\Proyectos\DemoProject"
```

## Troubleshooting

See [Troubleshooting Guide](Troubleshooting.md) for common issues and solutions.