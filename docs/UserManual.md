# Hermes Enterprise User Manual

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

Hermes Enterprise is an enterprise-grade PowerShell framework for system automation, project scaffolding, and environment management. It provides a complete workflow for creating, managing, and deploying Python projects with virtual environment support (venv/Conda), Git integration, and GitHub publishing.

## System Requirements

- **PowerShell**: Version 5.0 or higher (PowerShell 7 recommended)
- **Python**: Version 3.8 or higher
- **Git**: Version 2.30 or higher
- **GitHub CLI**: Version 2.0 or higher (for GitHub features)
- **VS Code**: Latest version (optional, for workspace features)
- **SQLite**: Version 3.x (included with Windows 10+)

## Installation

See [Installation Guide](Installation.md) for detailed instructions.

### Quick Install

```powershell
git clone https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE.git
cd HERMES-ENTERPRISE
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

Creates a complete project structure with optional Git initialization, GitHub repository, and virtual environment.

```powershell
# Basic project
Crear-HermesProyecto -NombreProyecto "MiProyecto"

# Project with Conda environment
Crear-HermesProyecto -NombreProyecto "MiProyecto" -TipoEntorno "conda"

# Full setup with Git and GitHub
Crear-HermesProyecto -NombreProyecto "MiProyecto" -InicializarGit -CrearRepositorioGitHub

# Custom Python version
Crear-HermesProyecto -NombreProyecto "MiProyecto" -PythonVersion "3.12"

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

Closes the project by cleaning temporary files and the virtual environment.

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

### Create Virtual Environment (venv)

```powershell
New-HermesVenv -ProjectPath "D:\Proyectos\MiProyecto" -PythonVersion "3.12"
```

### Activate venv

Returns the activation command for PowerShell:

```powershell
$activateCmd = Enter-HermesVenv -ProjectPath "D:\Proyectos\MiProyecto"
Invoke-Expression $activateCmd
```

### Remove venv

```powershell
Remove-HermesVenv -ProjectPath "D:\Proyectos\MiProyecto"
```

### Create Conda Environment

```powershell
New-HermesConda -ProjectPath "D:\Proyectos\MiProyecto" -EnvironmentName "mi-entorno" -PythonVersion "3.12"
```

### Activate Conda Environment

```powershell
Enter-HermesConda -EnvironmentName "mi-entorno"
```

### Remove Conda Environment

```powershell
Remove-HermesConda -EnvironmentName "mi-entorno"
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

## Complete Workflow Example

```powershell
# 1. Import module
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force

# 2. Create project
Crear-HermesProyecto -NombreProyecto "DemoProject" -InicializarGit

# 3. Generate documentation
New-HermesDocumentacion -ProjectPath "D:\Proyectos\DemoProject" -ProjectName "DemoProject"

# 4. Create environment
New-HermesVenv -ProjectPath "D:\Proyectos\DemoProject"

# 5. Commit
New-HermesCommit -ProjectPath "D:\Proyectos\DemoProject" -Mensaje "Initial setup"

# 6. Open in VS Code
Abrir-HermesProyecto -ProjectPath "D:\Proyectos\DemoProject"
```

## Troubleshooting

See [Troubleshooting Guide](Troubleshooting.md) for common issues and solutions.