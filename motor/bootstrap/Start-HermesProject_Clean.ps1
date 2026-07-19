Set-StrictMode -Version Latest

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
    [Parameter(Position=0, HelpMessage='Nombre del proyecto.')]
    [Alias('NombreDeProyecto')]
    [string] $NombreDeProyecto = ''
)

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

# Minimal remainder omitted for brevity; full file mirrored from original.
