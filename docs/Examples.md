# Examples

This guide provides practical examples for common Hermes Enterprise workflows.

## Basic Usage

### Create a Simple Project

```powershell
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force
Crear-HermesProyecto -NombreProyecto "HolaMundo"
```

### Create Project with Conda

```powershell
Crear-HermesProyecto -NombreProyecto "DataScience" -TipoEntorno "conda" -PythonVersion "3.12"
```

### Create Project with Git and GitHub

```powershell
Crear-HermesProyecto -NombreProyecto "OpenSourceApp" -InicializarGit -CrearRepositorioGitHub
```

## Environment Examples

### venv Workflow

```powershell
# Create project
Crear-HermesProyecto -NombreProyecto "WebApp" -TipoEntorno "venv"

# Create virtual environment
New-HermesVenv -ProjectPath "D:\Proyectos\WebApp"

# Activate it
$cmd = Enter-HermesVenv -ProjectPath "D:\Proyectos\WebApp"
Invoke-Expression $cmd

# Install packages
pip install flask requests

# Deactivate when done
deactivate
```

### Conda Workflow

```powershell
# Create project with Conda
Crear-HermesProyecto -NombreProyecto "MLProject" -TipoEntorno "conda"

# Create Conda environment
New-HermesConda -ProjectPath "D:\Proyectos\MLProject" -EnvironmentName "ml-env" -PythonVersion "3.12"

# Activate
Enter-HermesConda -EnvironmentName "ml-env"

# Install packages
conda install numpy pandas scikit-learn
```

## Git Workflow

### Initialize and Commit

```powershell
# Create project with Git
Crear-HermesProyecto -NombreProyecto "MyApp" -InicializarGit

# Make some changes, then commit
New-HermesCommit -ProjectPath "D:\Proyectos\MyApp" -Mensaje "Initial setup"
```

### Full Git + GitHub Workflow

```powershell
# Create project with everything
Crear-HermesProyecto -NombreProyecto "MyLibrary" -InicializarGit -CrearRepositorioGitHub

# Make changes
New-HermesDocumentacion -ProjectPath "D:\Proyectos\MyLibrary" -ProjectName "MyLibrary"
New-HermesCommit -ProjectPath "D:\Proyectos\MyLibrary" -Mensaje "Add documentation"

# Publish to GitHub
Publicar-HermesProyecto -ProjectPath "D:\Proyectos\MyLibrary" -GitHubUser "FREDYASARMIENTOT" -RepoName "MyLibrary"
```

## Workspace Examples

### Create and Open Workspace

```powershell
# Create workspace
New-HermesWorkspace -WorkspaceRoot "D:\Proyectos"

# Open in VS Code
Open-HermesWorkspace -WorkspaceRoot "D:\Proyectos"

# List workspaces
Get-HermesWorkspace
```

## Project Inspection Examples

### Check Project Status

```powershell
Get-HermesProyecto -ProjectPath "D:\Proyectos\MyApp"
```

### List All Projects

```powershell
Get-HermesProyectos
Get-HermesProyectos -WorkspaceRoot "D:\Proyectos"
```

### Check Python

```powershell
Test-HermesPython
```

## Advanced Scenarios

### Scenario: Data Science Project

```powershell
# Create project
Crear-HermesProyecto -NombreProyecto "DataAnalysis" -TipoEntorno "conda" -PythonVersion "3.12"

# Create Conda environment
New-HermesConda -ProjectPath "D:\Proyectos\DataAnalysis" -EnvironmentName "data-env" -PythonVersion "3.12"

# Generate documentation
New-HermesDocumentacion -ProjectPath "D:\Proyectos\DataAnalysis" -ProjectName "DataAnalysis"

# Initialize Git and commit
Crear-HermesProyecto -NombreProyecto "DataAnalysis" -InicializarGit
New-HermesCommit -ProjectPath "D:\Proyectos\DataAnalysis" -Mensaje "Initial data science project"
```

### Scenario: Web API Project

```powershell
# Create project
Crear-HermesProyecto -NombreProyecto "WebAPI" -TipoEntorno "venv"

# Create venv
New-HermesVenv -ProjectPath "D:\Proyectos\WebAPI"

# Open in VS Code
Abrir-HermesProyecto -ProjectPath "D:\Proyectos\WebAPI"
```

### Scenario: Open Source Library

```powershell
# Create with full GitHub integration
Crear-HermesProyecto -NombreProyecto "AwesomeLib" -InicializarGit -CrearRepositorioGitHub -AbrirVSCode

# Add documentation
New-HermesDocumentacion -ProjectPath "D:\Proyectos\AwesomeLib" -ProjectName "AwesomeLib"

# First commit
New-HermesCommit -ProjectPath "D:\Proyectos\AwesomeLib" -Mensaje "Initial release"

# Publish
Publicar-HermesProyecto -ProjectPath "D:\Proyectos\AwesomeLib" -GitHubUser "FREDYASARMIENTOT" -RepoName "AwesomeLib"
```

## Batch Operations

### Create Multiple Projects

```powershell
$projects = @("Frontend", "Backend", "SharedLib")
foreach ($proj in $projects) {
    Crear-HermesProyecto -NombreProyecto $proj
}
```

### Commit All Projects

```powershell
$projects = Get-HermesProyectos
foreach ($proj in $projects) {
    New-HermesCommit -ProjectPath $proj.Path -Mensaje "Weekly update"
}