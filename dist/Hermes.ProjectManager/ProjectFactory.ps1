<#
ProjectFactory.ps1 — Gestión de proyectos Hermes
No exportada. Solo uso interno del módulo.
#>

function _New-ProjectFolder {
    param(
        [string]$ProjectPath,
        [string]$ProjectName
    )
    if (-not (Test-Path $ProjectPath)) {
        New-Item -Path $ProjectPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    # Create .hermes marker
    _Set-ProjectMarker -ProjectPath $ProjectPath -ProjectName $ProjectName
    # Create basic project structure
    $dirs = @('docs', 'src', 'tests', 'scripts')
    foreach ($d in $dirs) {
        $p = Join-Path $ProjectPath $d
        if (-not (Test-Path $p)) { New-Item -Path $p -ItemType Directory -Force | Out-Null }
    }
    # Create .gitignore
    $gitignore = Join-Path $ProjectPath '.gitignore'
    if (-not (Test-Path $gitignore)) {
        @"
# Python
__pycache__/
*.py[cod]
*.egg-info/
.venv/
env/
venv/

# Node
node_modules/

# IDE
.vscode/
.idea/
*.swp

# OS
Thumbs.db
.DS_Store

# Hermes
*.log
*.db
"@ | Out-File -FilePath $gitignore -Encoding utf8 -Force
    }
    return $true
}

function _Remove-ProjectFolder {
    param([string]$ProjectPath)
    if (Test-Path $ProjectPath) {
        Remove-Item -Path $ProjectPath -Recurse -Force -ErrorAction Stop
        return $true
    }
    return $false
}

function _Get-ProjectInfo {
    param([string]$ProjectPath)
    if (-not (Test-Path $ProjectPath)) { return $null }
    $name = _Get-ProjectMarker -ProjectPath $ProjectPath
    $dbInfo = _Get-ProjectFromDb -ProjectPath $ProjectPath
    if ($dbInfo) {
        $dbInfo.Name = $name
        return $dbInfo
    }
    return [pscustomobject]@{
        Id       = ''
        Name     = ($name -or (Split-Path $ProjectPath -Leaf))
        Path     = $ProjectPath
        Status   = 'Unknown'
        Version  = ''
        Provider = ''
    }
}

function _Open-ProjectInVSCode {
    param([string]$ProjectPath)
    try {
        & code $ProjectPath 2>$null
        return $true
    } catch { return $false }
}

function _Initialize-GitRepo {
    param([string]$ProjectPath)
    try {
        Push-Location $ProjectPath
        & git init 2>$null | Out-Null
        & git add -A 2>$null | Out-Null
        & git commit -m "Initial commit via Hermes Enterprise" 2>$null | Out-Null
        Pop-Location
        return $true
    } catch {
        Pop-Location
        return $false
    }
}

function _Create-EnvYml {
    param(
        [string]$ProjectPath,
        [string]$EnvironmentName,
        [string]$PythonVersion = '3.14'
    )
    $envYml = Join-Path $ProjectPath 'environment.yml'
    if (-not (Test-Path $envYml)) {
        @"
name: $EnvironmentName
channels:
  - defaults
  - conda-forge
dependencies:
  - python=$PythonVersion
  - pip
prefix: $((Resolve-Path ~).Path)\.conda\envs\$EnvironmentName
"@ | Out-File -FilePath $envYml -Encoding utf8 -Force
    }
}

function _Create-RequirementsTxt {
    param([string]$ProjectPath)
    $req = Join-Path $ProjectPath 'requirements.txt'
    if (-not (Test-Path $req)) {
        "# Python dependencies" | Out-File -FilePath $req -Encoding utf8 -Force
    }
}