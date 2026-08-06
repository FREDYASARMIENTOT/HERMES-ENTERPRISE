# Installation Guide (RC70-D)

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| PowerShell | 5.0+ | PowerShell 7.x recommended |
| Git | 2.30+ | Required for version control |
| GitHub CLI | 2.0+ | Required for GitHub integration |
| VS Code | Latest | Recommended IDE |

> **Note:** Python is NOT required as a global installation. The Hermes Python Runtime manages its own Python interpreter (venv-based) at `D:\HermesRuntime\Environments\HermesEnterprise\`.

## Installation Steps

### 1. Clone the Repository

```powershell
git clone https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE.git
cd HERMES-ENTERPRISE
```

### 2. Install the Hermes Python Runtime

```powershell
.\Install-HermesPythonRuntime.ps1
```

This script:
- Creates `D:\HermesRuntime\Environments\HermesEnterprise\`
- Creates a Python venv with the latest available Python 3.x
- Updates pip to latest version
- Installs all dependencies from `requirements.txt`
- Validates Python, pip, FastAPI, Uvicorn, Jinja2, and SQLite
- Generates a validation report

### 3. Verify the Runtime

```powershell
.\tools\VerifyEnvironment.ps1
```

Expected output: All runtime checks pass.

### 4. Import the Hermes.Commands Module

```powershell
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force
```

### 5. Verify Installation

```powershell
Get-Command -Module Hermes.Commands
```

Expected output: 21+ exported commands.

### 6. (Optional) Run the Bootstrap Wizard

```powershell
.\motor\bootstrap\engine\BootstrapWizard.ps1
```

The Bootstrap Wizard validates:
- ✓ Hermes.Python.json exists
- ✓ python.exe exists in Runtime
- ✓ pip.exe exists in Runtime
- ✓ The virtual environment exists
- ✓ pyvenv.cfg exists
- ✓ requirements.txt exists

## Troubleshooting Installation

| Problem | Solution |
|---------|----------|
| Module not found | Ensure you're in the HERMES-ENTERPRISE root directory |
| Runtime not found | Run `Install-HermesPythonRuntime.ps1` first |
| Python Runtime error | Check `config/Hermes.Python.json` exists and paths are correct |
| Git not found | Install Git from git-scm.com |
| GitHub CLI not found | Install GitHub CLI from cli.github.com |

## Next Steps

After installation, see the [Quick Start Guide](QuickStart.md) to create your first project.

## Runtime Architecture

```
D:\HermesRuntime\
└── Environments\
    └── HermesEnterprise\          ← Único Runtime oficial
        ├── Scripts\               ← python.exe, pip.exe, etc.
        ├── Lib\                   ← Site-packages and standard library
        ├── Include\               ← C headers
        └── pyvenv.cfg             ← Venv configuration
```

All modules read `config/Hermes.Python.json` to locate the runtime. No PATH, no Conda, no global Python.