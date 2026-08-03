# Command Reference

Complete reference for all 21 Hermes.Commands commands.

## Summary

| # | Command | Alias | Category | Description |
|---|---------|-------|----------|-------------|
| 1 | Crear-HermesProyecto | `chp` | Project | Create a new project with full setup |
| 2 | Start-HermesProject | `shp` | Project | Start/initialize an existing project |
| 3 | Abrir-HermesProyecto | `ahp` | Project | Open project in VS Code |
| 4 | Publicar-HermesProyecto | `uhp` | Project | Publish project to GitHub |
| 5 | Cerrar-HermesProyecto | `ghp` | Project | Close project (clean temp files) |
| 6 | Eliminar-HermesProyecto | `ghpe` | Project | Permanently delete a project |
| 7 | Get-HermesProyecto | `shp` | Project | Get project status |
| 8 | Get-HermesProyectos | `php` | Project | List all projects in workspace |
| 9 | Test-HermesPython | `chp2` | Utility | Check Python availability |
| 10 | New-HermesDocumentacion | `nhd` | Utility | Generate project documentation |
| 11 | New-HermesCommit | `nhc` | Git | Commit all tracked changes |
| 12 | New-HermesVenv | `nhv` | Environment | Create Python venv |
| 13 | Enter-HermesVenv | `ehv` | Environment | Get venv activation command |
| 14 | Remove-HermesVenv | `rhv` | Environment | Remove venv |
| 15 | New-HermesConda | `nhc2` | Environment | Create Conda environment |
| 16 | Enter-HermesConda | `ehc` | Environment | Get Conda activation command |
| 17 | Remove-HermesConda | `rhc` | Environment | Remove Conda environment |
| 18 | New-HermesWorkspace | `nhw` | Workspace | Create workspace directory |
| 19 | Open-HermesWorkspace | `ohw` | Workspace | Open workspace in VS Code |
| 20 | Get-HermesWorkspace | `ghw` | Workspace | List registered workspaces |
| 21 | Install-ProjectFromFactory | `ipf` | Utility | Install project (compatibility) |

---

## 1. Crear-HermesProyecto

### Synopsis
Creates a complete Hermes project with optional Git initialization, GitHub repository, and virtual environment.

### Syntax
```
Crear-HermesProyecto -NombreProyecto <string> [-TipoEntorno <string>] [-PythonVersion <string>]
    [-WorkspaceRoot <string>] [-GitHubUser <string>] [-CrearRepositorioGitHub] [-InicializarGit]
    [-AbrirVSCode] [-NoPush]
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| NombreProyecto | string | Yes | Project name |
| TipoEntorno | string | No | Environment type: "venv" or "conda" (default: config or "venv") |
| PythonVersion | string | No | Python version (default: config or "3.14") |
| WorkspaceRoot | string | No | Workspace directory (default: "D:\Proyectos") |
| GitHubUser | string | No | GitHub username (default: "FREDYASARMIENTOT") |
| CrearRepositorioGitHub | switch | No | Create GitHub repository |
| InicializarGit | switch | No | Initialize Git repository |
| AbrirVSCode | switch | No | Open project in VS Code |
| NoPush | switch | No | Skip Git push |

### Output
Returns a `[pscustomobject]` with project context (NombreProyecto, TipoEntorno, WorkspaceRoot, etc.) on success, or `$null` on failure.

### Examples
```powershell
Crear-HermesProyecto -NombreProyecto "MyApp" -TipoEntorno "conda" -InicializarGit
Crear-HermesProyecto -NombreProyecto "MyApp" -CrearRepositorioGitHub -AbrirVSCode
```

### Notes
- Uses RC56 pipeline if available, falls back to ProjectFactory
- Supports both dot-sourcing and pipeline execution
- Telemetry logged to ProjectHistory table

---

## 2. Start-HermesProject

### Synopsis
Initializes a project directory with standard structure and default files.

### Syntax
```
Start-HermesProject [-ProjectPath <string>]
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | No | Path to project directory. If omitted, creates a test project. |

### Output
Returns `[pscustomobject]` with ProjectPath and Status properties.

### Examples
```powershell
Start-HermesProject
Start-HermesProject -ProjectPath "D:\Proyectos\MiProyecto"
```

---

## 3. Abrir-HermesProyecto

### Synopsis
Opens project directory in Visual Studio Code.

### Syntax
```
Abrir-HermesProyecto -ProjectPath <string>
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | Yes | Path to the project |

### Output
Returns `$true` on success, `$false` if path doesn't exist.

### Example
```powershell
Abrir-HermesProyecto -ProjectPath "D:\Proyectos\MiProyecto"
```

---

## 4. Publicar-HermesProyecto

### Synopsis
Publishes project to GitHub by configuring remote, creating repo (if needed), and pushing.

### Syntax
```
Publicar-HermesProyecto -ProjectPath <string> -GitHubUser <string> -RepoName <string>
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | Yes | Project directory path |
| GitHubUser | string | Yes | GitHub username |
| RepoName | string | Yes | Repository name |

### Output
Returns `$true` on success, `$false` on failure.

### Example
```powershell
Publicar-HermesProyecto -ProjectPath "D:\Proyectos\MyApp" -GitHubUser "FREDYASARMIENTOT" -RepoName "MyApp"
```

---

## 5. Cerrar-HermesProyecto

### Synopsis
Closes a project by cleaning temporary files and virtual environment.

### Syntax
```
Cerrar-HermesProyecto -ProjectPath <string>
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | Yes | Path to the project |

### Output
Returns `$true`.

### Example
```powershell
Cerrar-HermesProyecto -ProjectPath "D:\Proyectos\MiProyecto"
```

---

## 6. Eliminar-HermesProyecto

### Synopsis
Permanently deletes a project directory and all contents.

### Syntax
```
Eliminar-HermesProyecto -ProjectPath <string>
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | Yes | Path to the project to delete |

### Output
Returns `$true`.

### Example
```powershell
Eliminar-HermesProyecto -ProjectPath "D:\Proyectos\MiProyecto"
```

---

## 7. Get-HermesProyecto

### Synopsis
Gets detailed status information about a project.

### Syntax
```
Get-HermesProyecto -ProjectPath <string>
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | Yes | Path to the project |

### Output
Returns `[pscustomobject]` with properties: ProjectPath, Exists, HasGit, HasSrc, HasPruebas, HasDocs, HasVenv, HasReadme, HasGitignore, HasVSCode.

### Example
```powershell
Get-HermesProyecto -ProjectPath "D:\Proyectos\MiProyecto"
```

---

## 8. Get-HermesProyectos

### Synopsis
Lists all projects in a workspace directory.

### Syntax
```
Get-HermesProyectos [-WorkspaceRoot <string>]
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| WorkspaceRoot | string | No | Workspace directory (default: "D:\Proyectos") |

### Output
Returns `[pscustomobject[]]` with properties: Name, Path, HasGit, HasSrc.

### Example
```powershell
Get-HermesProyectos
Get-HermesProyectos -WorkspaceRoot "C:\Users\MiUser\Projects"
```

---

## 9. Test-HermesPython

### Synopsis
Checks if Python is available and returns the version string.

### Syntax
```
Test-HermesPython
```

### Parameters
None.

### Output
Returns Python version string (e.g., "Python 3.12.0") or `$null` if not found.

### Example
```powershell
Test-HermesPython
```

---

## 10. New-HermesDocumentacion

### Synopsis
Generates base documentation files for a project.

### Syntax
```
New-HermesDocumentacion -ProjectPath <string> [-ProjectName <string>]
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | Yes | Project directory path |
| ProjectName | string | No | Project name (default: "HermesProject") |

### Output
Returns the path to the generated README.md file.

### Example
```powershell
New-HermesDocumentacion -ProjectPath "D:\Proyectos\MiProyecto" -ProjectName "MiProyecto"
```

---

## 11. New-HermesCommit

### Synopsis
Stages all changes and creates a Git commit.

### Syntax
```
New-HermesCommit -ProjectPath <string> [-Mensaje <string>]
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | Yes | Project directory path |
| Mensaje | string | No | Commit message (default: "Hermes Enterprise commit") |

### Output
Returns `$true` on success.

### Example
```powershell
New-HermesCommit -ProjectPath "D:\Proyectos\MiProyecto" -Mensaje "Add new features"
```

---

## 12. New-HermesVenv

### Synopsis
Creates a Python virtual environment (venv) in the project.

### Syntax
```
New-HermesVenv -ProjectPath <string> [-PythonVersion <string>] [-ProjectName <string>]
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | Yes | Project directory path |
| PythonVersion | string | No | Python version (default: "3.14") |
| ProjectName | string | No | Project name for telemetry |

### Output
Returns `$true` on success, `$false` on failure.

### Example
```powershell
New-HermesVenv -ProjectPath "D:\Proyectos\MiProyecto"
```

---

## 13. Enter-HermesVenv

### Synopsis
Returns the PowerShell activation command for the venv.

### Syntax
```
Enter-HermesVenv -ProjectPath <string>
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | Yes | Project directory path |

### Output
Returns activation command string (e.g., `& "D:\Proyectos\MiProyecto\.venv\Scripts\Activate.ps1"`) or `$null` if not found.

### Example
```powershell
$cmd = Enter-HermesVenv -ProjectPath "D:\Proyectos\MiProyecto"
Invoke-Expression $cmd
```

---

## 14. Remove-HermesVenv

### Synopsis
Removes the Python virtual environment from the project.

### Syntax
```
Remove-HermesVenv -ProjectPath <string> [-ProjectName <string>]
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | Yes | Project directory path |
| ProjectName | string | No | Project name for telemetry |

### Output
Returns `$true` on success.

### Example
```powershell
Remove-HermesVenv -ProjectPath "D:\Proyectos\MiProyecto"
```

---

## 15. New-HermesConda

### Synopsis
Creates a Conda environment for the project.

### Syntax
```
New-HermesConda -ProjectPath <string> -EnvironmentName <string> [-PythonVersion <string>] [-ProjectName <string>]
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| ProjectPath | string | Yes | Project directory path |
| EnvironmentName | string | Yes | Conda environment name |
| PythonVersion | string | No | Python version (default: "3.14") |
| ProjectName | string | No | Project name for telemetry |

### Output
Returns `$true` on success, `$false` on failure.

### Example
```powershell
New-HermesConda -ProjectPath "D:\Proyectos\MiProyecto" -EnvironmentName "mi-entorno"
```

---

## 16. Enter-HermesConda

### Synopsis
Returns the Conda activation command.

### Syntax
```
Enter-HermesConda -EnvironmentName <string>
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| EnvironmentName | string | Yes | Conda environment name |

### Output
Returns activation command string: `conda activate <name>`.

### Example
```powershell
Enter-HermesConda -EnvironmentName "mi-entorno"
```

---

## 17. Remove-HermesConda

### Synopsis
Removes a Conda environment.

### Syntax
```
Remove-HermesConda -EnvironmentName <string> [-ProjectName <string>]
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| EnvironmentName | string | Yes | Conda environment name to remove |
| ProjectName | string | No | Project name for telemetry |

### Output
Returns `$true`.

### Example
```powershell
Remove-HermesConda -EnvironmentName "mi-entorno"
```

---

## 18. New-HermesWorkspace

### Synopsis
Creates a new workspace directory and registers it.

### Syntax
```
New-HermesWorkspace -WorkspaceRoot <string>
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| WorkspaceRoot | string | Yes | Path for the workspace directory |

### Output
Returns `$true`.

### Example
```powershell
New-HermesWorkspace -WorkspaceRoot "D:\Proyectos"
```

---

## 19. Open-HermesWorkspace

### Synopsis
Opens a workspace directory in VS Code.

### Syntax
```
Open-HermesWorkspace -WorkspaceRoot <string>
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| WorkspaceRoot | string | Yes | Workspace directory path |

### Output
Returns `$true` on success, `$false` if not found.

### Example
```powershell
Open-HermesWorkspace -WorkspaceRoot "D:\Proyectos"
```

---

## 20. Get-HermesWorkspace

### Synopsis
Lists all registered workspaces from the database.

### Syntax
```
Get-HermesWorkspace
```

### Parameters
None.

### Output
Displays workspace paths to console. No explicit return value.

### Example
```powershell
Get-HermesWorkspace
```

---

## 21. Install-ProjectFromFactory

### Synopsis
Full project installation with all features. Compatibility command (RC53 pattern).

### Syntax
```
Install-ProjectFromFactory [-NombreProyecto <string>] [-WorkspaceRoot <string>] [-GitHubUser <string>]
    [-TipoEntorno <string>] [-PythonVersion <string>] [-InicializarGit] [-CrearRepositorioGitHub] [-AbrirVSCode]
```

### Parameters
| Name | Type | Mandatory | Description |
|------|------|-----------|-------------|
| NombreProyecto | string | No | Project name (default not specified) |
| WorkspaceRoot | string | No | Workspace directory (default: "D:\Proyectos") |
| GitHubUser | string | No | GitHub username (default: "FREDYASARMIENTOT") |
| TipoEntorno | string | No | Environment type (default: "conda") |
| PythonVersion | string | No | Python version (default: "3.14") |
| InicializarGit | switch | No | Initialize Git repository |
| CrearRepositorioGitHub | switch | No | Create GitHub repository |
| AbrirVSCode | switch | No | Open in VS Code |

### Output
Returns `[pscustomobject]` with ProjectPath and Status properties on success.

### Example
```powershell
Install-ProjectFromFactory -NombreProyecto "MyApp" -TipoEntorno "venv"