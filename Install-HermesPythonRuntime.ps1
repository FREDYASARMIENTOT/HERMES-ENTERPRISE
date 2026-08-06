<#
.SYNOPSIS
    Instala el Runtime Python oficial de Hermes Enterprise.
.DESCRIPTION
    Crea el entorno virtual Python en D:\HermesRuntime\Environments\HermesEnterprise
    usando venv. Instala todas las dependencias desde requirements.txt.
    NO utiliza Conda. NO depende del Python global del sistema.
    Usa --only-binary :all: para garantizar instalación desde wheels binarios.
.NOTES
    Proyecto   : HERMES-ENTERPRISE (RC70-D)
    Version    : 2.1.0
    Autor      : Fredy Alejandro Sarmiento Torres
    Requisitos : Windows 10/11, Python 3.12+ instalado en el sistema
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "config/Hermes.Python.json",

    [Parameter(Mandatory = $false)]
    [string]$RequirementsFile = "requirements.txt",

    [Parameter(Mandatory = $false)]
    [string]$HermesWebRequirements = "Hermes.Web/requirements.txt",

    [Parameter(Mandatory = $false)]
    [switch]$SkipVenvCreation,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────────────────────────────
# FUNCIONES AUXILIARES
# ─────────────────────────────────────────────────────────────────────

function Write-Title {
    param([string]$Text)
    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Text)
    Write-Host "[*] $Text" -ForegroundColor Yellow
}

function Write-OK {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-ErrorExit {
    param([string]$Text)
    Write-Host "[X] $Text" -ForegroundColor Red
    exit 1
}

function Write-Warning {
    param([string]$Text)
    Write-Host "[!] $Text" -ForegroundColor Magenta
}

# ─────────────────────────────────────────────────────────────────────
# 1. VALIDAR CONFIGURACIÓN
# ─────────────────────────────────────────────────────────────────────

Write-Title "HERMES ENTERPRISE - INSTALACION DEL RUNTIME PYTHON (RC70-D)"

$configPath = Join-Path $PSScriptRoot $ConfigPath
if (-not (Test-Path $configPath)) {
    Write-ErrorExit "Configuracion no encontrada: $configPath"
}

Write-Step "Leyendo configuracion desde: $configPath"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

Write-OK "Version Python configurada: $($config.VersionPython)"
Write-OK "Ruta destino: $($config.RutaEntornoVirtual)"

$runtimePath = $config.RutaEntornoVirtual
$pythonExe = $config.RutaPython
$pipExe = $config.RutaPip

# ─────────────────────────────────────────────────────────────────────
# 2. VERIFICAR PYTHON INSTALADO EN EL SISTEMA (para crear el venv)
# ─────────────────────────────────────────────────────────────────────

Write-Title "VERIFICANDO PYTHON EN EL SISTEMA"

# Buscar python.exe en ubicaciones estándar de instalación oficial (solo bootstrap)
$pythonPaths = @(
    "$env:ProgramFiles\Python314\python.exe",
    "$env:ProgramFiles\Python313\python.exe",
    "$env:ProgramFiles\Python312\python.exe",
    "$env:ProgramFiles\Python311\python.exe",
    "${env:ProgramFiles(x86)}\Python314\python.exe",
    "${env:ProgramFiles(x86)}\Python313\python.exe",
    "${env:ProgramFiles(x86)}\Python312\python.exe",
    "${env:ProgramFiles(x86)}\Python311\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe"
)

$pythonSystem = $null
foreach ($p in $pythonPaths) {
    if (Test-Path $p) {
        $pythonSystem = $p
        break
    }
}

if (-not $pythonSystem) {
    # Último recurso: buscar en PATH (solo para bootstrap inicial)
    try {
        $cmd = Get-Command python -ErrorAction Stop
        $pythonSystem = $cmd.Source
        Write-Warning "Usando Python del PATH para bootstrap inicial: $pythonSystem"
        Write-Warning "Se recomienda instalar Python oficialmente en: C:\Program Files\Python314\"
    } catch {
        Write-ErrorExit @"
Python no encontrado en el sistema.
Para instalar el Runtime Hermes Enterprise necesita:

1. Descargar Python 3.12+ desde: https://www.python.org/downloads/
2. Instalar con "Add Python to PATH" MARCADO
3. Ejecutar este script nuevamente

O instalar Python manualmente en: C:\Program Files\Python312\
"@
    }
}

# Verificar versión de Python
try {
    $versionOutput = & $pythonSystem --version 2>&1
    Write-OK "Python detectado: $($versionOutput.Trim()) en: $pythonSystem"
} catch {
    Write-ErrorExit "No se pudo ejecutar Python en: $pythonSystem"
}

# ─────────────────────────────────────────────────────────────────────
# 3. CREAR EL ENTORNO VIRTUAL (venv)
# ─────────────────────────────────────────────────────────────────────

Write-Title "CREANDO ENTORNO VIRTUAL HERMES ENTERPRISE"

if (-not $SkipVenvCreation) {
    if (Test-Path $runtimePath) {
        if ($Force) {
            Write-Warning "El directorio ya existe: $runtimePath"
            Write-Warning "Forzando recreacion (parametro -Force)..."
            Remove-Item -Path $runtimePath -Recurse -Force
            Write-OK "Directorio eliminado."
        } else {
            Write-Warning "El directorio ya existe: $runtimePath"
            Write-Warning "Omitiendo creacion. Use -Force para recrear."
        }
    }

    if (-not (Test-Path $runtimePath)) {
        Write-Step "Creando directorio: $runtimePath"
        New-Item -Path $runtimePath -ItemType Directory -Force | Out-Null

        Write-Step "Ejecutando: $pythonSystem -m venv $runtimePath"
        try {
            & $pythonSystem -m venv $runtimePath 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-ErrorExit "Error al crear el entorno virtual. Codigo: $LASTEXITCODE"
            }
            Write-OK "Entorno virtual creado exitosamente."
        } catch {
            Write-ErrorExit "Fallo al crear el entorno virtual: $_"
        }
    }
} else {
    Write-Warning "Creacion de venv omitida (parametro -SkipVenvCreation)"
}

# ─────────────────────────────────────────────────────────────────────
# 4. VERIFICAR EJECUTABLES DEL RUNTIME
# ─────────────────────────────────────────────────────────────────────

Write-Title "VERIFICANDO RUNTIME"

if (-not (Test-Path $pythonExe)) {
    Write-ErrorExit "Python no encontrado en el Runtime: $pythonExe"
}
Write-OK "Python Runtime: $pythonExe"

if (-not (Test-Path $pipExe)) {
    Write-ErrorExit "Pip no encontrado en el Runtime: $pipExe"
}
Write-OK "Pip Runtime: $pipExe"

# Verificar pyvenv.cfg
$pyvenvCfg = Join-Path $runtimePath "pyvenv.cfg"
if (-not (Test-Path $pyvenvCfg)) {
    Write-ErrorExit "pyvenv.cfg no encontrado en: $runtimePath. No es un entorno virtual valido."
}
Write-OK "pyvenv.cfg encontrado."

# Mostrar versión del Runtime
try {
    $rtVersion = & $pythonExe --version 2>&1
    Write-OK "Version Runtime: $($rtVersion.Trim())"
} catch {
    Write-Warning "No se pudo obtener la version del Runtime"
}

# ─────────────────────────────────────────────────────────────────────
# 5. ACTUALIZAR PIP
# ─────────────────────────────────────────────────────────────────────

Write-Title "ACTUALIZANDO PIP"

try {
    Write-Step "Actualizando pip..."
    & $pythonExe -m pip install --upgrade pip 2>&1
    if ($LASTEXITCODE -eq 0) {
        $pipVersion = & $pipExe --version 2>&1
        Write-OK "Pip actualizado: $($pipVersion.Trim())"
    } else {
        Write-Warning "Actualizacion de pip fallo (codigo: $LASTEXITCODE). Continuando..."
    }
} catch {
    Write-Warning "Error al actualizar pip: $_"
}

# ─────────────────────────────────────────────────────────────────────
# 6. INSTALAR DEPENDENCIAS (solo wheels binarios)
# ─────────────────────────────────────────────────────────────────────

Write-Title "INSTALANDO DEPENDENCIAS (SOLO WHEELS BINARIOS)"

# Instalar dependencias raíz si existen
$rootReqs = Join-Path $PSScriptRoot $RequirementsFile
if (Test-Path $rootReqs) {
    Write-Step "Instalando dependencias desde: $RequirementsFile"
    try {
        & $pythonExe -m pip install --only-binary :all: -r $rootReqs 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Dependencias raiz instaladas."
        } else {
            Write-Warning "Instalacion de dependencias raiz fallo (codigo: $LASTEXITCODE)"
        }
    } catch {
        Write-Warning "Error instalando dependencias raiz: $_"
    }
} else {
    Write-Warning "requirements.txt raiz no encontrado: $rootReqs"
}

# Instalar dependencias de Hermes.Web
$webReqs = Join-Path $PSScriptRoot $HermesWebRequirements
if (Test-Path $webReqs) {
    Write-Step "Instalando dependencias desde: $HermesWebRequirements"
    try {
        & $pythonExe -m pip install --only-binary :all: -r $webReqs 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Dependencias Hermes.Web instaladas."
        } else {
            Write-Warning "Instalacion de dependencias Hermes.Web fallo (codigo: $LASTEXITCODE)"
        }
    } catch {
        Write-Warning "Error instalando dependencias Hermes.Web: $_"
    }
} else {
    Write-Warning "requirements.txt de Hermes.Web no encontrado: $webReqs"
}

# ─────────────────────────────────────────────────────────────────────
# 7. VALIDAR DEPENDENCIAS CRÍTICAS
# ─────────────────────────────────────────────────────────────────────

Write-Title "VALIDANDO DEPENDENCIAS CRITICAS"

$dependenciasCriticas = @(
    @{Modulo = "fastapi";         Descripcion = "FastAPI - Framework Web"},
    @{Modulo = "uvicorn";         Descripcion = "Uvicorn - Servidor ASGI"},
    @{Modulo = "jinja2";          Descripcion = "Jinja2 - Motor de Plantillas"},
    @{Modulo = "pydantic";        Descripcion = "Pydantic - Validacion de Datos"},
    @{Modulo = "httpx";           Descripcion = "HTTPX - Cliente HTTP"},
    @{Modulo = "sqlite3";         Descripcion = "SQLite3 - Base de Datos (built-in)"},
    @{Modulo = "gunicorn";        Descripcion = "Gunicorn - Servidor WSGI (Azure)"},
    @{Modulo = "azure.identity";  Descripcion = "Azure Identity - Autenticacion Azure"},
    @{Modulo = "starlette";       Descripcion = "Starlette - ASGI Framework subyacente"}
)

$fallos = 0
foreach ($dep in $dependenciasCriticas) {
    try {
        $output = & $pythonExe -c "import $($dep.Modulo); print('OK')" 2>&1
        if ($output.Trim() -eq "OK") {
            Write-OK "$($dep.Descripcion) ($($dep.Modulo))"
        } else {
            Write-Warning "$($dep.Descripcion) ($($dep.Modulo)): $output"
            $fallos++
        }
    } catch {
        Write-Warning "$($dep.Descripcion) ($($dep.Modulo)): NO DISPONIBLE - $_"
        $fallos++
    }
}

# ─────────────────────────────────────────────────────────────────────
# 8. GENERAR REPORTE
# ─────────────────────────────────────────────────────────────────────

Write-Title "REPORTE DE INSTALACION"

function _Get-CommandOutput {
    param([string]$FilePath, [string]$Arguments)
    $result = & $FilePath $Arguments 2>&1
    if ($result -is [System.Management.Automation.ErrorRecord]) {
        return "ERROR"
    }
    return ($result | Out-String).Trim()
}

$report = [PSCustomObject][ordered]@{
    FechaInstalacion          = [datetime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
    RuntimePath               = $runtimePath
    PythonExe                 = $pythonExe
    PipExe                    = $pipExe
    PythonVersion             = _Get-CommandOutput -FilePath $pythonExe -Arguments "--version"
    PipVersion                = _Get-CommandOutput -FilePath $pipExe -Arguments "--version"
    ConfigFile                = $configPath
    DependenciasInstaladas    = $true
    FastapiDisponible         = _Get-CommandOutput -FilePath $pythonExe -Arguments '-c "import fastapi; print(fastapi.__version__)"'
    UvicornDisponible         = _Get-CommandOutput -FilePath $pythonExe -Arguments '-c "import uvicorn; print(''OK'')"'
    Jinja2Disponible          = _Get-CommandOutput -FilePath $pythonExe -Arguments '-c "import jinja2; print(jinja2.__version__)"'
    SQLite3Disponible         = _Get-CommandOutput -FilePath $pythonExe -Arguments '-c "import sqlite3; print(sqlite3.sqlite_version)"'
    GunicornDisponible        = _Get-CommandOutput -FilePath $pythonExe -Arguments '-c "import gunicorn; print(''OK'')"'
    AzureIdentityDisponible   = _Get-CommandOutput -FilePath $pythonExe -Arguments '-c "import azure.identity; print(''OK'')"'
    DependenciasFallaron      = ($fallos -gt 0)
    TotalFallos               = $fallos
}

$reportPath = Join-Path $PSScriptRoot "reports/HermesPythonRuntime-Report.json"
$reportDir = Split-Path $reportPath -Parent
if (-not (Test-Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

$report | ConvertTo-Json -Depth 3 | Set-Content $reportPath -Encoding UTF8
Write-OK "Reporte generado: $reportPath"

# ─────────────────────────────────────────────────────────────────────
# 9. RESUMEN FINAL
# ─────────────────────────────────────────────────────────────────────

Write-Title "INSTALACION COMPLETADA"

Write-Host ""
Write-Host "Runtime Python : $runtimePath" -ForegroundColor White
Write-Host "Python         : $pythonExe" -ForegroundColor White
Write-Host "Pip            : $pipExe" -ForegroundColor White
Write-Host "Reporte        : $reportPath" -ForegroundColor White
Write-Host ""

if ($fallos -gt 0) {
    Write-Warning "$fallos dependencias criticas no estan disponibles."
    Write-Warning "Revise el reporte para mas detalles."
    exit 1
} else {
    Write-OK "Hermes Enterprise Python Runtime instalado correctamente."
    Write-OK "Listo para usar Hermes.Web y las herramientas del ecosistema."
    exit 0
}