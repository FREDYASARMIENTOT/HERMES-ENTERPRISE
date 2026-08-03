# User Acceptance Tests — RC62

## Test Environment

- **PowerShell**: 7.x or 5.1+
- **OS**: Windows 10/11
- **Python**: 3.8+
- **Git**: 2.30+
- **GitHub CLI**: 2.0+ (optional)
- **VS Code**: Latest (optional)

## Test 1: Module Import

### Steps
1. Open PowerShell
2. Navigate to HERMES-ENTERPRISE root
3. Run:
```powershell
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force
```
4. Verify: No errors, "RC56 Module loaded" message appears
5. Run:
```powershell
Get-Command -Module Hermes.Commands
```
6. Verify: Exactly 21 commands exported

### Expected Result
```
[Hermes.Commands] RC56 Module loaded. 21 commands exported.
```
21 commands listed by Get-Command.

## Test 2: Command Help

### Steps
For each of the 21 commands, verify:
```powershell
Get-Help <CommandName> -Full
```

### Verify
- [ ] Synopsis present
- [ ] Description present
- [ ] All parameters documented
- [ ] Examples present (where applicable)
- [ ] Output type documented (where applicable)

## Test 3: Project Creation

### Steps
```powershell
Crear-HermesProyecto -NombreProyecto "TestProjectUAT"
```

### Verify
- [ ] Directory created at D:\Proyectos\TestProjectUAT
- [ ] Subdirectories: .vscode, src, pruebas, docs, scripts, data, logs
- [ ] Files: .gitignore, README.md, requirements.txt, CURRENT_STATE.md
- [ ] Virtual environment created (.venv)
- [ ] Return value is a pscustomobject with NombreProyecto

### Negative Test
```powershell
Crear-HermesProyecto -NombreProyecto ""
# Should fail with parameter validation error
```

## Test 4: Project Status

### Steps
```powershell
Get-HermesProyecto -ProjectPath "D:\Proyectos\TestProjectUAT"
```

### Verify
- [ ] Returns pscustomobject
- [ ] Properties: ProjectPath, Exists, HasGit, HasSrc, HasPruebas, HasDocs, HasVenv, HasReadme, HasGitignore, HasVSCode
- [ ] Exists = True
- [ ] HasSrc = True

### Negative Test
```powershell
Get-HermesProyecto -ProjectPath "D:\Proyectos\NonExistentProject"
# Should return $null with warning
```

## Test 5: List Projects

### Steps
```powershell
Get-HermesProyectos
```

### Verify
- [ ] Returns array of projects
- [ ] Each has Name, Path, HasGit, HasSrc properties
- [ ] TestProjectUAT appears in the list

## Test 6: Environment Management

### Steps
```powershell
New-HermesVenv -ProjectPath "D:\Proyectos\TestProjectUAT"
```

### Verify
- [ ] Returns $true on success
- [ ] .venv directory exists

```powershell
$activateCmd = Enter-HermesVenv -ProjectPath "D:\Proyectos\TestProjectUAT"
```

### Verify
- [ ] Returns activation command string
- [ ] Command contains "Activate.ps1"

```powershell
Remove-HermesVenv -ProjectPath "D:\Proyectos\TestProjectUAT"
```

### Verify
- [ ] Returns $true
- [ ] .venv directory removed

## Test 7: Git Operations

### Steps
```powershell
New-HermesCommit -ProjectPath "D:\Proyectos\TestProjectUAT" -Mensaje "UAT test commit"
```

### Verify
- [ ] Returns $true
- [ ] (If Git is available) Commit created

### Negative Test
```powershell
New-HermesCommit -ProjectPath "D:\Proyectos\NonExistent" -Mensaje "test"
# Should handle gracefully
```

## Test 8: Documentation Generation

### Steps
```powershell
New-HermesDocumentacion -ProjectPath "D:\Proyectos\TestProjectUAT" -ProjectName "TestProjectUAT"
```

### Verify
- [ ] Returns path to README.md
- [ ] README.md created/updated
- [ ] docs directory created

## Test 9: Workspace Management

### Steps
```powershell
New-HermesWorkspace -WorkspaceRoot "D:\Proyectos"
```

### Verify
- [ ] Returns $true
- [ ] Directory exists or confirmed

```powershell
Get-HermesWorkspace
```

### Verify
- [ ] Displays workspace paths
- [ ] D:\Proyectos appears

## Test 10: Python Verification

### Steps
```powershell
Test-HermesPython
```

### Verify
- [ ] Returns version string or $null
- [ ] If Python available: shows version starting with "Python"

## Test 11: Project Cleanup

### Steps
```powershell
Eliminar-HermesProyecto -ProjectPath "D:\Proyectos\TestProjectUAT"
```

### Verify
- [ ] Returns $true
- [ ] Directory removed

### Negative Test
```powershell
Eliminar-HermesProyecto -ProjectPath "D:\Proyectos\NonExistent"
# Should handle gracefully
```

## Test 12: Aliases

### Steps
```powershell
Get-Command -Module Hermes.Commands | Select-Object Name, @{Name='Alias'; Expression={$_.Parameters['Alias']}}
```

### Verify
- [ ] All 21 aliases work
- [ ] chp = Crear-HermesProyecto
- [ ] nhv = New-HermesVenv
- [ ] nhc = New-HermesCommit

## Acceptance Criteria

- [ ] All 21 commands available
- [ ] Module imports without errors
- [ ] Project creation/destruction works
- [ ] Environment management works
- [ ] Workspace management works
- [ ] Git operations work
- [ ] Documentation generation works
- [ ] Python verification works
- [ ] Error handling graceful
- [ ] Pipeline input supported
- [ ] No new PSScriptAnalyzer warnings introduced