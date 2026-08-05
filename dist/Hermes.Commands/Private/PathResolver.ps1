<#
PathResolver.ps1 — Resolución de rutas del sistema Hermes
No exportadas. Solo uso interno.
#>

function _Resolve-ScriptPath {
    param([string]$Name)
    $root = _Get-HermesRoot
    # Search in scripts/ and tools/
    $paths = @(
        Join-Path $root "scripts\$Name.ps1",
        Join-Path $root "tools\$Name.ps1",
        Join-Path $root "motor\bootstrap\functions\$Name.ps1"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return (Resolve-Path $p).Path }
    }
    return $null
}

function _Resolve-ToolModule {
    param([string]$Name)
    $root = _Get-HermesRoot
    $paths = @(
        Join-Path $root "tools\$Name.psm1",
        Join-Path $root "tools\$Name.ps1"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return (Resolve-Path $p).Path }
    }
    return $null
}

function _Find-ProjectConfig {
    param([string]$ProjectPath)
    $files = @(
        Join-Path $ProjectPath 'Hermes.config.json',
        Join-Path $ProjectPath '.hermes',
        Join-Path $ProjectPath 'environment.yml'
    )
    foreach ($f in $files) {
        if (Test-Path $f) { return $f }
    }
    return $null
}

function _Get-ProjectMarker {
    param([string]$ProjectPath)
    $p = Join-Path $ProjectPath '.hermes'
    if (Test-Path $p) { return (Get-Content $p -Raw -ErrorAction SilentlyContinue).Trim() }
    return $null
}

function _Set-ProjectMarker {
    param([string]$ProjectPath, [string]$ProjectName)
    $p = Join-Path $ProjectPath '.hermes'
    $ProjectName | Out-File -FilePath $p -Encoding utf8 -Force
}

function _Remove-ProjectMarker {
    param([string]$ProjectPath)
    $p = Join-Path $ProjectPath '.hermes'
    if (Test-Path $p) { Remove-Item -Path $p -Force -ErrorAction SilentlyContinue }
}

function _Resolve-VenvPath {
    param([string]$ProjectPath)
    $v = Join-Path $ProjectPath '.venv'
    if (Test-Path (Join-Path $v 'Scripts\Activate.ps1')) { return $v }
    return $null
}

function _Resolve-CondaPath {
    $up = (Resolve-Path ~).Path
    $condaPaths = @(
        "$up\miniconda3\condabin\conda.bat",
        "$up\miniconda3\Scripts\conda.exe",
        "C:\ProgramData\miniconda3\condabin\conda.bat",
        "C:\Users\fredya.sarmiento\miniconda3\condabin\conda.bat"
    )
    foreach ($cp in $condaPaths) {
        if (Test-Path $cp) { return $cp }
    }
    try {
        $whereResult = where.exe conda 2>$null
        if ($whereResult) { return $whereResult[0].Trim() }
    } catch {
        Write-Verbose "Conda not found via where.exe: $_"
    }
    return $null
}

function _Is-HermesProject {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    $marker = Join-Path $Path '.hermes'
    return (Test-Path $marker)
}