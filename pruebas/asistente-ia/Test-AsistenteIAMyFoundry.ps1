<#
.SYNOPSIS
    Prueba LOCAL del Asistente IA de configuracion de proyectos Child
    contra Microsoft Foundry (Azure AI Foundry).

.DESCRIPTION
    Ejecuta, SIN desplegar nada, la validacion completa de la nueva
    funcionalidad de configuracion de IA al crear proyectos hijos:

        1. Contrato del asistente y catalogo de proveedores
        2. Conversacion del chatbot (4 turnos)
        3. Validacion REAL de la credencial (chat completions)
        4. Creacion de la solicitud Child + auditoria server-side
        5. Caso negativo (modelo inexistente)

    PRINCIPIO DE PORTABILIDAD:
    No depende de rutas absolutas. Calcula la raiz del repositorio a
    partir de $PSScriptRoot (dos niveles arriba de pruebas/asistente-ia/).

.PARAMETER UrlBase
    URL base del endpoint. Ejemplo Microsoft Foundry:
    https://<recurso>.services.ai.azure.com/models

.PARAMETER ApiKey
    API key del recurso. NUNCA se imprime: solo se muestra enmascarada.

.PARAMETER Modelo
    Nombre del deployment/modelo. Por defecto: Proyecto-ia-ur

.PARAMETER Proveedor
    Id del proveedor del catalogo. Por defecto: msfoundry

.EXAMPLE
    .\Test-AsistenteIAMyFoundry.ps1 `
        -UrlBase "https://mi-recurso.services.ai.azure.com/models" `
        -ApiKey  "<api-key>" `
        -Modelo  "Proyecto-ia-ur"

.EXAMPLE
    # Usando variables de entorno
    $env:HERMES_IA_URL_BASE = "https://mi-recurso.services.ai.azure.com/models"
    $env:HERMES_IA_API_KEY  = "<api-key>"
    .\Test-AsistenteIAMyFoundry.ps1

.NOTES
    Autor : Hermes Enterprise
    Uso   : Prueba previa a produccion de la funcionalidad Asistente IA.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string]$UrlBase = "",
    [Parameter(Mandatory = $false)][string]$ApiKey = "",
    [Parameter(Mandatory = $false)][string]$Modelo = "",
    [Parameter(Mandatory = $false)][string]$Proveedor = "",
    [Parameter(Mandatory = $false)][string]$PythonExe = "python"
)

$ErrorActionPreference = "Stop"

# Inicializacion portable
$RaizRepositorio = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$RutaDriver = Join-Path -Path $PSScriptRoot -ChildPath "Probar-AsistenteIA.py"

function Escribir-Encabezado {
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host " Hermes Enterprise - Prueba LOCAL del Asistente IA (Microsoft Foundry)" -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host " Repositorio : $RaizRepositorio"
    Write-Host " Driver      : $RutaDriver"
    Write-Host " Python      : $PythonExe"
    Write-Host " Modelo      : $(if ($Modelo) { $Modelo } else { '<pendiente>' })"
    Write-Host " Proveedor   : $(if ($Proveedor) { $Proveedor } else { 'msfoundry' })"
    Write-Host "======================================================================" -ForegroundColor Cyan
}

# Verificacion pre-vuelo
if (-not (Test-Path -Path $RutaDriver)) {
    Write-Host "[FAIL] No se encontro el driver: $RutaDriver" -ForegroundColor Red
    exit 1
}

Escribir-Encabezado

# Resolucion de la configuracion: parametro > variable de entorno
if (-not $UrlBase) { $UrlBase = $env:HERMES_IA_URL_BASE }
if (-not $ApiKey) { $ApiKey = $env:HERMES_IA_API_KEY }
if (-not $Modelo) { $Modelo = $env:HERMES_IA_MODELO }
if (-not $Proveedor) { $Proveedor = $env:HERMES_IA_PROVEEDOR }
if (-not $Modelo) { $Modelo = "Proyecto-ia-ur" }
if (-not $Proveedor) { $Proveedor = "msfoundry" }

if (-not $UrlBase -or -not $ApiKey) {
    Write-Host ""
    Write-Host "[ERROR] Falta la configuracion del proveedor." -ForegroundColor Red
    Write-Host "        Indique -UrlBase y -ApiKey, o defina las variables:" -ForegroundColor Yellow
    Write-Host "          `$env:HERMES_IA_URL_BASE = `"https://<recurso>.services.ai.azure.com/models`"" -ForegroundColor Yellow
    Write-Host "          `$env:HERMES_IA_API_KEY  = `"<api-key>`"" -ForegroundColor Yellow
    Write-Host "          `$env:HERMES_IA_MODELO   = `"Proyecto-ia-ur`"   (opcional)" -ForegroundColor Yellow
    Write-Host "          `$env:HERMES_IA_PROVEEDOR= `"msfoundry`"        (opcional)" -ForegroundColor Yellow
    Write-Host ""
    exit 2
}

# El driver se ejecuta desde la raiz del repositorio para que resuelva
# correctamente el paquete Hermes.Web.
Push-Location -Path $RaizRepositorio
try {
    & $PythonExe $RutaDriver --url-base $UrlBase --api-key $ApiKey --modelo $Modelo --proveedor $Proveedor
    $CodigoSalida = $LASTEXITCODE
}
finally {
    Pop-Location
}

Write-Host ""
if ($CodigoSalida -eq 0) {
    Write-Host "[PASS] Prueba local del Asistente IA completada sin fallos." -ForegroundColor Green
} elseif ($CodigoSalida -eq 2) {
    Write-Host "[BLOQUEADO] Prueba local no ejecutada: falta configuracion." -ForegroundColor Yellow
} else {
    Write-Host "[FAIL] Prueba local del Asistente IA con fallos (codigo $CodigoSalida)." -ForegroundColor Red
}

exit $CodigoSalida