# Frequently Asked Questions

## General

### What is Hermes Enterprise?

Hermes Enterprise is an enterprise-grade PowerShell framework for system automation, project scaffolding, and environment management. It provides a complete workflow for creating, managing, and deploying Python projects.

### What PowerShell version do I need?

PowerShell 5.0 or higher. PowerShell 7.x is recommended for the best experience.

### Is Hermes Enterprise cross-platform?

Hermes Enterprise is designed primarily for Windows, leveraging PowerShell and Windows-specific features. Some commands may work on PowerShell Core (macOS/Linux) with limitations.

## Project Management

### How do I create a project?

```powershell
Crear-HermesProyecto -NombreProyecto "MyProject"
```

### How do I delete a project?

```powershell
Eliminar-HermesProyecto -ProjectPath "D:\Proyectos\MyProject"
```

**Warning**: This permanently removes the project directory and all contents.

### Can I change the default workspace directory?

Yes, set `-WorkspaceRoot` parameter when creating a project:

```powershell
Crear-HermesProyecto -NombreProyecto "MyProject" -WorkspaceRoot "C:\MyProjects"
```

## Environment Management

### What's the difference between venv and Conda?

- **venv**: Python's built-in virtual environment manager. Lightweight and included with Python.
- **Conda**: Environment manager from Anaconda/Miniconda. Supports non-Python dependencies and different Python versions.

### How do I switch environment types?

```powershell
# For venv (default)
Crear-HermesProyecto -NombreProyecto "MyProject" -TipoEntorno "venv"

# For Conda
Crear-HermesProyecto -NombreProyecto "MyProject" -TipoEntorno "conda"
```

### How do I activate a virtual environment?

```powershell
# For venv
$cmd = Enter-HermesVenv -ProjectPath "D:\Proyectos\MyProject"
Invoke-Expression $cmd

# For Conda
Enter-HermesConda -EnvironmentName "MyProject"
```

## Git & GitHub

### How do I initialize Git in my project?

```powershell
Crear-HermesProyecto -NombreProyecto "MyProject" -InicializarGit
```

### How do I create a GitHub repository?

```powershell
Crear-HermesProyecto -NombreProyecto "MyProject" -CrearRepositorioGitHub
```

### How do I push to GitHub?

```powershell
Publicar-HermesProyecto -ProjectPath "D:\Proyectos\MyProject" -GitHubUser "YOUR_USERNAME" -RepoName "MyProject"
```

## Commands

### How many commands are available?

Hermes.Commands exports **21 commands** for project, environment, workspace, and utility management.

### How do I see all commands?

```powershell
Get-Command -Module Hermes.Commands
```

### Are there aliases?

Yes, all 21 commands have aliases. For example:
- `chp` = `Crear-HermesProyecto`
- `nhv` = `New-HermesVenv`
- `nhc` = `New-HermesCommit`

## Troubleshooting

### Module won't import

Ensure you're in the HERMES-ENTERPRISE root directory and try:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force
```

### Python not found

Install Python 3.8+ from [python.org](https://python.org) or add it to your PATH.

### "Command not recognized"

Make sure the module is imported:

```powershell
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force
Get-Command -Module Hermes.Commands
```

## Updates

### How do I update Hermes Enterprise?

```powershell
git pull origin main
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force
```

### How do I check my current version?

Check the module version:

```powershell
Get-Module Hermes.Commands | Select-Object Version