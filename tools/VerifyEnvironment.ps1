<#
.SYNOPSIS
    Verifica el entorno de desarrollo de Hermes Enterprise.
.DESCRIPTION
    Valida que todas las herramientas necesarias estén disponibles.
    NO busca Python ni pip en PATH. Usa exclusivamente config/Hermes.Python.json.
    NO utiliza Conda, Miniconda ni Anaconda.
.NOTES
    Proyecto : HERMES-ENTERPRISE (RC70-D)
    Version  : 3.0.0
    Autor    : Fredy Alejandro Sarmiento Torres
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$PythonConfigPath = "config/Hermes.Python.json"
)

Set-StrictMode -Version Latest

$ok = $true
$errors = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host " VERIFICACION DE ENTORNO HERMES ENTERPRISE" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# ─────────────────────────────────────────────────────────────────────
# 1. VERIFICAR CONFIGURACIÓN PYTHON
# ─────────────────────────────────────────────────────────────────────
Write-Host "`n[*] Verificando config/Hermes.Python.json..." -ForegroundColor Yellow

$configPath = Join-Path $PSScriptRoot ".." $PythonConfigPath
$configPath = Resolve-Path $configPath -ErrorAction SilentlyContinue

if (-not $configPath) {
    $null = $errors.Add("config/Hermes.Python.json no encontrado.")
    $ok = $false
} else {
    Write-Host "[OK] config/Hermes.Python.json encontrado." -ForegroundColor Green

    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json

        # ── Validar campos requeridos ──
        $camposRequeridos = @('VersionPython', 'RutaEntornoVirtual', 'RutaPython', 'RutaPip', 'ArchivoRequirements')
        foreach ($campo in $camposRequeridos) {
            if (-not $config.$campo) {
                $null = $errors.Add("Campo '$campo' faltante o vacio en Hermes.Python.json.")
                $ok = $false
            }
        }

        Write-Host "  Python Version      : $($config.VersionPython)" -ForegroundColor White
        Write-Host "  Entorno Virtual     : $($config.RutaEntornoVirtual)" -ForegroundColor White
        Write-Host "  Ruta Python         : $($config.RutaPython)" -ForegroundColor White
        Write-Host "  Ruta Pip            : $($config.RutaPip)" -ForegroundColor White
        Write-Host "  Archivo Requirements: $($config.ArchivoRequirements)" -ForegroundColor White

        # ── Verificar python.exe ──
        if (Test-Path $config.RutaPython) {
            try {
                $pyVersion = & $config.RutaPython --version 2>&1
                Write-Host "[OK] Python: $($pyVersion.Trim())" -ForegroundColor Green
            } catch {
                $null = $errors.Add("Python no ejecutable en: $($config.RutaPython)")
                $ok = $false
            }
        } else {
            $null = $errors.Add("Python no encontrado en: $($config.RutaPython)")
            $ok = $false
        }

        # ── Verificar pip.exe ──
        if (Test-Path $config.RutaPip) {
            try {
                $pipVersion = & $config.RutaPip --version 2>&1
                Write-Host "[OK] Pip: $($pipVersion.Trim())" -ForegroundColor Green
            } catch {
                $null = $errors.Add("Pip no ejecutable en: $($config.RutaPip)")
                $ok = $false
            }
        } else {
            $null = $errors.Add("Pip no encontrado en: $($config.RutaPip)")
            $ok = $false
        }

        # ── Verificar pyvenv.cfg ──
        $pyvenvCfg = Join-Path $config.RutaEntornoVirtual "pyvenv.cfg"
        if (Test-Path $pyvenvCfg) {
            Write-Host "[OK] pyvenv.cfg encontrado." -ForegroundColor Green
        } else {
            $null = $warnings.Add("pyvenv.cfg no encontrado en el entorno virtual. Ejecute Install-HermesPythonRuntime.ps1")
        }

    } catch {
        $null = $errors.Add("Error al leer config/Hermes.Python.json: $_")
        $ok = $false
    }
}

# ─────────────────────────────────────────────────────────────────────
# 2. VERIFICAR HERRAMIENTAS DEL SISTEMA
# ─────────────────────────────────────────────────────────────────────
Write-Host "`n[*] Verificando herramientas del sistema..." -ForegroundColor Yellow

# Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Git instalado." -ForegroundColor Green
} else {
    $null = $errors.Add("Git no encontrado.")
    $ok = $false
}

# GitHub CLI
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "[OK] GitHub CLI instalado." -ForegroundColor Green
} else {
    $null = $warnings.Add("GitHub CLI (gh) no encontrado. Funcionalidad GitHub no disponible.")
}

# VSCode
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "[OK] VSCode instalado." -ForegroundColor Green
} else {
    $null = $warnings.Add("VSCode (code) no encontrado. Funcionalidad opcional.")
}

# Azure CLI
if (Get-Command az -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Azure CLI instalado." -ForegroundColor Green
} else {
    $null = $warnings.Add("Azure CLI (az) no encontrado. Funcionalidad Azure no disponible.")
}

# ─────────────────────────────────────────────────────────────────────
# 3. VERIFICAR DEPENDENCIAS PYTHON CRÍTICAS
# ─────────────────────────────────────────────────────────────────────
Write-Host "`n[*] Verificando dependencias Python..." -ForegroundColor Yellow

if ($config -and $ok) {
    $deps = @(
        @{Modulo = "fastapi";  Descripcion = "FastAPI"},
        @{Modulo = "uvicorn";  Descripcion = "Uvicorn"},
        @{Modulo = "jinja2";   Descripcion = "Jinja2"},
        @{Modulo = "pydantic"; Descripcion = "Pydantic"},
        @{Modulo = "httpx";    Descripcion = "HTTPX"},
        @{Modulo = "sqlite3";  Descripcion = "SQLite3"}
    )

    foreach ($dep in $deps) {
        try {
            $out = & $config.RutaPython -c "import $($dep.Modulo); print('OK')" 2>&1
            if ($out.Trim() -eq "OK") {
                Write-Host "[OK] $($dep.Descripcion) disponible." -ForegroundColor Green
            } else {
                $null = $warnings.Add("$($dep.Descripcion) no disponible.")
            }
        } catch {
            $null = $warnings.Add("$($dep.Descripcion) no disponible: $_")
        }
    }
}

# ─────────────────────────────────────────────────────────────────────
# 4. RESUMEN
# ─────────────────────────────────────────────────────────────────────
Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host " RESULTADO" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

if ($errors.Count -gt 0) {
    Write-Host "`n[X] ERRORES:" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "    - $err" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`n[!] ADVERTENCIAS:" -ForegroundColor Magenta
    foreach ($warn in $warnings) {
        Write-Host "    - $warn" -ForegroundColor Magenta
    }
}

if ($ok) {
    Write-Host "`n[OK] Entorno Hermes Enterprise verificado correctamente." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[X] El entorno no esta completo. Revise los errores." -ForegroundColor Red
    exit 1
}