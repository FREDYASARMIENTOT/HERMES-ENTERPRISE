# Installation Guide

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| PowerShell | 5.0+ | PowerShell 7.x recommended |
| Python | 3.8+ | Required for virtual environments |
| Git | 2.30+ | Required for version control |
| GitHub CLI | 2.0+ | Required for GitHub integration |
| VS Code | Latest | Recommended IDE |
| SQLite | 3.x | Required for persistence layer |

## Installation Steps

### 1. Clone the Repository

```powershell
git clone https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE.git
cd HERMES-ENTERPRISE
```

### 2. Import the Hermes.Commands Module

```powershell
Import-Module .\motor\kernel\Hermes.Commands.psd1 -Force
```

### 3. Verify Installation

```powershell
Get-Command -Module Hermes.Commands
```

Expected output: 21 exported commands.

### 4. Verify Dependencies

```powershell
# Check Python
python --version

# Check Git
git --version

# Check GitHub CLI
gh --version

# Check SQLite
sqlite3 --version
```

### 5. (Optional) Configure Defaults

Set default configuration values:

```powershell
# Set default environment type (venv or conda)
# Automatically read from hermes.db configuration table
```

## Troubleshooting Installation

| Problem | Solution |
|---------|----------|
| Module not found | Ensure you're in the HERMES-ENTERPRISE root directory |
| Python not found | Install Python 3.8+ from python.org |
| Git not found | Install Git from git-scm.com |
| GitHub CLI not found | Install GitHub CLI from cli.github.com |

## Next Steps

After installation, see the [Quick Start Guide](QuickStart.md) to create your first project.