# Troubleshooting Guide

## Common Issues and Solutions

### Module Import Issues

**Problem**: `Import-Module` fails

**Solutions**:
```powershell
# Ensure you're in the correct directory
cd D:\HERMES-ENTERPRISE

# Use full path
Import-Module D:\HERMES-ENTERPRISE\motor\kernel\Hermes.Commands.psd1 -Force

# Check execution policy
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Python Not Found

**Problem**: `Test-HermesPython` returns null or "Python no disponible"

**Solutions**:
```powershell
# Check if Python is installed
python --version

# If not found, add Python to PATH
$env:Path = "C:\Python312;$env:Path"
# Or install from python.org

# Check Python launcher
py --version
```

### venv Creation Failure

**Problem**: `New-HermesVenv` returns false

**Solutions**:
```powershell
# Check Python is available
python -m venv --help

# Ensure the project path exists
Test-Path "D:\Proyectos\MiProyecto"

# Try creating venv manually
python -m venv D:\Proyectos\MiProyecto\.venv
```

### Conda Not Found

**Problem**: Conda environment creation fails

**Solutions**:
```powershell
# Find Conda
where.exe conda

# Common Conda paths:
# C:\Users\<user>\miniconda3\condabin\conda.bat
# C:\ProgramData\miniconda3\Scripts\conda.exe
```

### Git Not Found

**Problem**: Git operations fail

**Solutions**:
```powershell
# Install Git from git-scm.com
# Or verify existing installation
git --version

# Add Git to PATH if needed
$env:Path = "C:\Program Files\Git\cmd;$env:Path"
```

### GitHub CLI Issues

**Problem**: GitHub operations fail with "gh not found"

**Solutions**:
```powershell
# Install GitHub CLI from cli.github.com
# Verify installation
gh --version

# Authenticate
gh auth login

# Check authentication status
gh auth status
```

### Permissions Issues

**Problem**: "Access denied" or permission errors

**Solutions**:
```powershell
# Run PowerShell as Administrator
# Right-click PowerShell -> Run as Administrator

# Or set execution policy
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Workspace Directory Not Found

**Problem**: `Get-HermesProyectos` returns nothing

**Solutions**:
```powershell
# Create workspace directory
New-HermesWorkspace -WorkspaceRoot "D:\Proyectos"

# Or specify a custom workspace
Get-HermesProyectos -WorkspaceRoot "C:\Users\MiUser\Projects"
```

### Database Connection Issues

**Problem**: Operations requiring hermes.db fail

**Solutions**:
```powershell
# Verify hermes.db exists
Test-Path D:\HERMES-ENTERPRISE\hermes.db

# Check SQLite is available
sqlite3 --version

# Recreate database if corrupted
# (This happens automatically on first use)
```

### Commit Fails

**Problem**: `New-HermesCommit` fails

**Solutions**:
```powershell
# Configure Git user if not set
git config --global user.email "tu@email.com"
git config --global user.name "Tu Nombre"

# Check Git status
git -C "D:\Proyectos\MiProyecto" status
```

### VS Code Not Opening

**Problem**: `Abrir-HermesProyecto` doesn't open VS Code

**Solutions**:
```powershell
# Ensure VS Code is in PATH
code --version

# If not, add to PATH manually
$env:Path += ";C:\Program Files\Microsoft VS Code\bin"
```

## Error Messages Reference

| Error | Cause | Solution |
|-------|-------|----------|
| "Python no disponible" | Python not installed or not in PATH | Install Python 3.8+ |
| "Conda no encontrado" | Miniconda/Anaconda not installed | Install Miniconda |
| "Ruta no existe" | Specified directory doesn't exist | Create directory first |
| "gh not found" | GitHub CLI not installed | Install GitHub CLI |
| "git not found" | Git not installed | Install Git |
| "No changes to commit" | No uncommitted changes | Make changes first |
| "Remote origin already exists" | Remote already configured | Use `Publicar-HermesProyecto` instead |

## Getting Help

```powershell
# Command help
Get-Help <CommandName> -Full

# Module info
Get-Module Hermes.Commands | Format-List

# Online documentation
# https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE