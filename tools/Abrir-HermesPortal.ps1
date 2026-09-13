<#
.SYNOPSIS
    Abre el Portal de Hermes Enterprise en el navegador predeterminado de Windows,
    previa validacion de salud del Portal.

.DESCRIPTION
    Este script verifica que el Portal este operativo (HTTP 200 en / y /health)
    antes de abrirlo en el navegador. No requiere secretos ni autenticacion.
    Disenado para ejecucion local desde VS Code / Cline.

    Uso:
        .\tools\Abrir-HermesPortal.ps1

    Sin parametros:
        Usa https://as-hermesportal.azurewebsites.net/ como URL predeterminada.

.PARAMETER Url
    URL base del Portal.

.PARAMETER NoBrowser
    Solo valida el estado sin abrir el navegador.

.EXAMPLE
    .\tools\Abrir-HermesPortal.ps1

.EXAMPLE
    .\tools\Abrir-HermesPortal.ps1 -NoBrowser

.NOTES
    Version: 1.0
    RC: 94.36
#>

param(
    [string]$Url = "https://as-hermesportal.azurewebsites.net",
    [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Icon, [string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Icon $Message"
}

function Test-PortalEndpoint {
    param([string]$Endpoint, [string]$Label)
    try {
        $response = Invoke-WebRequest -Uri $Endpoint -Method GET -UseBasicParsing -TimeoutSec 15
        if ($response.StatusCode -eq 200) {
            Write-Step "[OK]" "$Label - HTTP 200 OK"
            return $true
        } else {
            Write-Step "[!!]" "$Label - HTTP $($response.StatusCode) (esperado 200)"
            return $false
        }
    } catch {
        Write-Step "[EE]" "$Label - Error: $($_.Exception.Message)"
        return $false
    }
}

# === Encabezado ============================================
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Hermes Enterprise - Abrir Portal Web" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  URL: $Url" -ForegroundColor Gray
Write-Host ""

# === 1. Validar conectividad basica =======================
Write-Step "[..]" "Validando conectividad del Portal..."

$rootOk = Test-PortalEndpoint -Endpoint $Url -Label "GET /"
$healthOk = Test-PortalEndpoint -Endpoint "${Url}/health" -Label "GET /health"

Write-Host ""

# === 2. Resumen ===========================================
if ($rootOk -and $healthOk) {
    Write-Host "  [OK] Portal operativo - todos los endpoints responden 200" -ForegroundColor Green
} elseif ($rootOk) {
    Write-Host "  [!!] Portal responde pero /health fallo" -ForegroundColor Yellow
} else {
    Write-Host "  [EE] Portal NO responde" -ForegroundColor Red
    Write-Host "  Verificar: https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE/actions" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# === 3. Abrir navegador ===================================
if (-not $NoBrowser) {
    Write-Step "[..]" "Abriendo Portal en el navegador predeterminado..."
    try {
        Start-Process $Url
        Write-Step "[OK]" "Navegador abierto en: $Url"
    } catch {
        Write-Step "[!!]" "No se pudo abrir el navegador: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Listo." -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan