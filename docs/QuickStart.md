# Quick Start Guide

Create your first Hermes project in under 5 minutes.

## Step 1: Open PowerShell

Open PowerShell 7 (recommended) or PowerShell 5.1.

## Step 2: Import Hermes.Commands

```powershell
cd D:\HERMES-ENTERPRISE
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force
```

## Step 3: Verify the Module Loaded

```powershell
Get-Command -Module Hermes.Commands
```

You should see 21 commands exported.

## Step 4: Create a Project

```powershell
Crear-HermesProyecto -NombreProyecto "MiPrimerProyecto"
```

This creates:
- Project directory at `D:\Proyectos\MiPrimerProyecto`
- Directory structure: `.vscode`, `src`, `pruebas`, `docs`, `scripts`, `data`, `logs`
- Default files: `.gitignore`, `README.md`, `requirements.txt`, `CURRENT_STATE.md`
- Virtual environment (venv by default)

## Step 5: Check Project Status

```powershell
Get-HermesProyecto -ProjectPath "D:\Proyectos\MiPrimerProyecto"
```

## Step 6: Create Documentation

```powershell
New-HermesDocumentacion -ProjectPath "D:\Proyectos\MiPrimerProyecto" -ProjectName "MiPrimerProyecto"
```

## Step 7: Initialize Git

```powershell
# Using Crear-HermesProyecto with Git initialization
Crear-HermesProyecto -NombreProyecto "MiSegundoProyecto" -InicializarGit
```

## Step 8: Open in VS Code

```powershell
Abrir-HermesProyecto -ProjectPath "D:\Proyectos\MiPrimerProyecto"
```

## Common Aliases

| Alias | Command |
|-------|---------|
| `chp` | Crear-HermesProyecto |
| `shp` | Start-HermesProject |
| `ahp` | Abrir-HermesProyecto |
| `ghp` | Get-HermesProyecto |
| `ghpe` | Get-HermesProyectos |
| `nhv` | New-HermesVenv |
| `nhc` | New-HermesCommit |
| `nhd` | New-HermesDocumentacion |

## Need Help?

```powershell
Get-Help Crear-HermesProyecto -Full
Get-Help Get-HermesProyecto -Examples