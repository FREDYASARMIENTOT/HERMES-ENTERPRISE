<#
.SYNOPSIS
    Start-HermesProject - crea estructura local y ambiente para un nuevo proyecto Hermes.
.DESCRIPTION
    Soporta dos formas de invocación:
      - Sin parámetros: solicita el nombre por consola.
      - Con parámetro -NombreDeProyecto: usa el valor sin preguntar.
    Validaciones: el nombre debe cumplir ^[A-Za-z][A-Za-z0-9]*$
    Si la validación falla, NO se realiza ninguna operación y el script sale con code 1.
.NOTES
    Compatible PowerShell 5.1+ y 7+
#>

param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage='Nombre del proyecto.')]
    [string]$NombreDeProyecto
)

Set-StrictMode -Version Latest

function Write-Info { param($m) Write-Host $m -ForegroundColor Blue }
function Write-Warn { param($m) Write-Host $m -ForegroundColor Yellow }
function Write-Success { param($m) Write-Host $m -ForegroundColor Green }
function Write-ErrorAndExit {
    param($m, $code = 1)
    Write-Host $m -ForegroundColor Red
    exit $code
}

function Get-ProjectName {
    param([string]$CliNombre)
    if (-not [string]::IsNullOrWhiteSpace($CliNombre)) {
        Write-Info "Usando NombreDeProyecto pasado por parámetro: $CliNombre"
        return $CliNombre.Trim()
    }
    # Preguntar por consola
    Write-Info "Ingrese el nombre del proyecto:"
    $entrada = Read-Host
    if ($null -eq $entrada) { return '' }
    return $entrada.Trim()
}

function Test-ProjectName {
    param([string]$Nombre)
    # Regla: no vacío, no espacios, iniciar por letra, solo A-Z a-z 0-9
    if ([string]::IsNullOrWhiteSpace($Nombre)) {
        Write-Warn "ERROR El nombre del proyecto no cumple las reglas."
        Write-Host "- no puede estar vacío" -ForegroundColor Yellow
        return $false
    }
    if ($Nombre -match '\s') {
        Write-Warn "ERROR El nombre del proyecto no puede contener espacios."
        return $false
    }
    $pattern = '^[A-Za-z][A-Za-z0-9]*$'
    if ($Nombre -notmatch $pattern) {
        Write-Warn "ERROR El nombre del proyecto no cumple las reglas. Debe:"
        Write-Host "- comenzar por una letra" -ForegroundColor Yellow
        Write-Host "- contener únicamente letras y números" -ForegroundColor Yellow
        Write-Host "- no tener espacios" -ForegroundColor Yellow
        Write-Host "- no contener caracteres especiales" -ForegroundColor Yellow
        return $false
    }
    return $true
}

function New-LocalProject {
    param([string]$Nombre, [string]$SandboxRoot = '.\\sandbox')
    $projectPath = Join-Path -Path $SandboxRoot -ChildPath $Nombre
    if (Test-Path $projectPath) {
        Write-Warn "La carpeta $projectPath ya existe. No se sobreescribirá."
    } else {
        Write-Info "Creando carpeta local: $projectPath"
        New-Item -Path $projectPath -ItemType Directory -Force | Out-Null
    }

    $structure = @('src','tests','docs','scripts')
    foreach ($d in $structure) {
        $p = Join-Path $projectPath $d
        if (-not (Test-Path $p)) {
            New-Item -Path $p -ItemType Directory -Force | Out-Null
        }
    }

    # Archivos iniciales (si no existen)
    $files = @{ 
        'README.md' = "# $Nombre`n`nProyecto generado por Hermes."
        'LICENSE' = "MIT License"
        '.gitignore' = @(".venv/","__pycache__/","*.pyc",".env",".vscode/") -join "`n"
        '.env.example' = "ENV_EXAMPLE=valor_de_ejemplo"
        'requirements.txt' = ""
    }

    foreach ($name in $files.Keys) {
        $f = Join-Path $projectPath $name
        if (-not (Test-Path $f)) {
            $content = $files[$name]
            Set-Content -Path $f -Value $content -NoNewline:$false -Force
        }
    }

    return $projectPath
}

function New-GitRepository {
    param([string]$Path, [string]$RepoName)
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warn "git no está disponible en PATH. Saltando inicialización git local."
        return $false
    }
    Push-Location $Path
    try {
        if (-not (Test-Path (Join-Path $Path '.git'))) {
            git init | Out-Null
            git add . | Out-Null
            git commit -m "chore: inicializar repo $RepoName" --author="Hermes <hermes@example.local>" | Out-Null
            Write-Success "Repositorio git inicializado en $Path"
        } else {
            Write-Warn "Repositorio git ya existe en $Path"
        }
        return $true
    } catch {
        Write-Warn "Error al inicializar git: $($_.Exception.Message)"
        return $false
    } finally {
        Pop-Location
    }
}

function New-PythonEnvironment {
    param([string]$ProjectPath)
    $pythonCmd = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $pythonCmd) {
        Write-Warn "python no encontrado."
        return $null
    }

    $venvPath = Join-Path $ProjectPath '.venv'
    Write-Info "Creando venv: $venvPath"

    # Invocación directa y simple
    & $pythonCmd -m venv $venvPath 2>&1 | Out-String | Write-Verbose

    if ($LASTEXITCODE -ne 0) {
        throw "Fallo al crear venv. ExitCode: $LASTEXITCODE"
    }

    # Linealización del path de pip (sin if dentro de expresiones)
    $pipName = 'bin/pip'
    if ($IsWindows) { $pipName = 'Scripts\\pip.exe' }
    $pipExe = Join-Path $venvPath $pipName

    Write-Host "Verificando pip en: $pipExe"
    # 1. Definir la ruta del ejecutable python dentro del venv
    $venvPython = Join-Path $venvPath ($IsWindows ? 'Scripts\\python.exe' : 'bin/python')

    # 2. Actualizar pip usando el módulo -m (Obligatorio para evitar errores de autoprotección)
    if (Test-Path $venvPython) {
        Write-Info "Actualizando pip, setuptools, wheel..."
        & $venvPython -m pip install --upgrade pip setuptools wheel | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "pip actualizado correctamente."
        } else {
            Write-Warn "Advertencia: pip no pudo actualizarse (ExitCode: $LASTEXITCODE)."
        }
    } else {
        Write-Warn "python no encontrado en venv, omitiendo actualización de pip."
    }

    return $venvPath
}

function Install-Dependencies {
    param([string]$ProjectPath, [string[]]$Dependencies)
    if ($null -eq $Dependencies) { $Dependencies = @() }
    if ($Dependencies.Count -eq 0) {
        Write-Info "No se especificaron dependencias mínimas a instalar."
    }

    $venvPath = Join-Path $ProjectPath '.venv'
    $pipName = 'bin/pip'
    if ($IsWindows) { $pipName = 'Scripts\\pip.exe' }
    $pipExe = Join-Path $venvPath $pipName
    if (-not (Test-Path $pipExe)) {
        Write-Warn "pip no disponible; no se instalarán dependencias."
    } else {
        if ($Dependencies.Count -gt 0) {
            Write-Info "Instalando dependencias mínimas: $($Dependencies -join ', ')"
            & $pipExe install $Dependencies | Out-Null
        }
        # Generar requirements.txt
        $reqFile = Join-Path $ProjectPath 'requirements.txt'
        & $pipExe freeze > $reqFile
        Write-Success "requirements.txt generado en $reqFile"
    }
}

function Write-Summary {
    param(
        [string]$Nombre,
        [string]$ProjectPath,
        [string]$VenvPath,
        [bool]$GitInit
    )
    Write-Host "========" -ForegroundColor Cyan
    Write-Success "Proyecto: $Nombre"
    Write-Info "Ruta local: $ProjectPath"
    if ($VenvPath) { Write-Info "VirtualEnv: $VenvPath" } else { Write-Warn "VirtualEnv: NO CREADO" }
    if ($GitInit) { Write-Success "Git: Inicializado" } else { Write-Warn "Git: NO inicializado" }
    Write-Host "========" -ForegroundColor Cyan
}

function Start-HermesProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string] $NombreDeProyecto
    )

    try {
        $nombre = Get-ProjectName -CliNombre $NombreDeProyecto

        if (-not (Test-ProjectName -Nombre $nombre)) {
            $msg = @"
ERROR El nombre del proyecto no cumple las reglas. Debe:
- comenzar por una letra
- contener únicamente letras y números
- no tener espacios
- no contener caracteres especiales
NO se realizará ninguna operación.
"@
            Write-ErrorAndExit $msg 1
        }

        # Si llegó aquí, el nombre es válido: proceder con creación local y ambiente
        $sandboxRoot = Join-Path -Path (Get-Location) -ChildPath 'sandbox'
        $projectPath = New-LocalProject -Nombre $nombre -SandboxRoot $sandboxRoot

        $gitOk = New-GitRepository -Path $projectPath -RepoName $nombre

        $venv = New-PythonEnvironment -ProjectPath $projectPath

        # Instalar dependencias mínimas (vacío por defecto)
        Install-Dependencies -ProjectPath $projectPath -Dependencies @()

        # Nunca crear .env con secretos; .env.example ya escrito
        Write-Summary -Nombre $nombre -ProjectPath $projectPath -VenvPath $venv -GitInit $gitOk

        # Devolver objeto con resumen
        return [PSCustomObject]@{
            NombreProyecto = $nombre
            PathLocal = (Resolve-Path -Path $projectPath).Path
            VirtualEnv = $venv
            GitInitialized = $gitOk
        }

    } catch {
    $err = $_
    $report = @"
--- ERROR FORENSE ---
Mensaje: $($err.Exception.Message)
Línea:   $($err.InvocationInfo.ScriptLineNumber)
Stack:   $($err.ScriptStackTrace)
Info:    $($err.InvocationInfo | Format-List * -Force | Out-String)
"@
    $report | Out-File 'D:/HERMES-ENTERPRISE/.verification/final_error_dump.txt' -Encoding utf8NoBOM
    Write-Error "ERROR FORENSE: Ver final_error_dump.txt"
    throw $err
}
}

# Ejecutar la función principal si el script fue invocado directamente

function Get-NextProyectoTestName {
    param([string]$Prefix = 'ProyectoTest', [string]$SandboxRoot = '.\\sandbox')
    $existing = @()
    if (Test-Path $SandboxRoot) {
        $existing = Get-ChildItem -Path $SandboxRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
    }
    $pattern = "$Prefix([0-9]{3})$"
    $max = 0
    foreach ($n in $existing) {
        if ($n -match $pattern) {
            $num = [int]$matches[1]
            if ($num -gt $max) { $max = $num }
        }
    }
    $next = $max + 1
    return "$Prefix{0:d3}" -f $next
}

if ($PSCommandPath) {
    if ([string]::IsNullOrWhiteSpace($NombreDeProyecto)) {
        $NombreDeProyecto = Get-NextProyectoTestName -Prefix 'ProyectoTest' -SandboxRoot (Join-Path (Get-Location) 'sandbox')
    }
    Start-HermesProject -NombreDeProyecto $NombreDeProyecto
}
