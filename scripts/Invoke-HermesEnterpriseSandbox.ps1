<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Invoke-HermesEnterpriseSandbox.ps1
Propósito:
    Orquesta el flujo completo del Development Workspace Sandbox:
    crear → inicializar escenario → ejecutar escenario → probar → exportar reportes → generar guías.
    Si ocurre un error, registra, marca FAILED y detiene. No reintenta automáticamente.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RutaRaizSandbox = "D:\Sandbox",

    [Parameter(Mandatory = $false)]
    [ValidateSet("NoWorkspace", "EmptyFolder", "ExistingProject", "ProjectWithoutGit", "GitWithoutRemote", "GitHubRepository", "ResumeSession", "NewProject", "CloneProject", "MultipleSessions")]
    [string]$Escenario = "EmptyFolder",

    [Parameter(Mandatory = $false)]
    [string]$NombreProyecto = "HermesProject",

    [Parameter(Mandatory = $false)]
    [switch]$SkipSmokeTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScript = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScript

. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Initialize-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Invoke-HermesEnterpriseScenario.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Test-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Export-HermesEnterpriseSandboxReport.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandboxUserGuide.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandboxInstructions.ps1")

$HoraInicio = Get-Date

function Registrar-ErrorSandbox {
    param([string]$RutaSandbox, [string]$Mensaje)
    $RutaMetadata = Join-Path $RutaSandbox "sandbox.json"
    if (Test-Path $RutaMetadata) {
        $Metadata = Get-Content -Path $RutaMetadata -Raw | ConvertFrom-Json
        $Metadata.Estado = "FAILED"
        $Metadata.Resultado = $Mensaje
        $Metadata | ConvertTo-Json -Depth 5 | Set-Content -Path $RutaMetadata -Encoding UTF8
    }
}

try {
    Write-Host "[1/7] Crear Sandbox..." -ForegroundColor Cyan
    $RutaSandbox = New-HermesEnterpriseSandbox -RutaRaizSandbox $RutaRaizSandbox -Escenario $Escenario -NombreProyecto $NombreProyecto
    Write-Host "Sandbox creado: $RutaSandbox" -ForegroundColor Green

    Write-Host "[2/7] Inicializar escenario..." -ForegroundColor Cyan
    $Inicializacion = Initialize-HermesEnterpriseSandbox -RutaSandbox $RutaSandbox

    Write-Host "[3/7] Ejecutar escenario..." -ForegroundColor Cyan
    $EscenarioResultado = Invoke-HermesEnterpriseScenario -RutaSandbox $RutaSandbox
    $DeveloperContext = $EscenarioResultado.DeveloperContext

    $SmokeTestResult = $null
    if (-not $SkipSmokeTest.IsPresent) {
        Write-Host "[4/7] Ejecutar Smoke Test..." -ForegroundColor Cyan
        $SmokeTestResult = Test-HermesEnterpriseSandbox -RutaSandbox $RutaSandbox
    }
    else {
        Write-Host "[4/7] Smoke Test omitido por parámetro." -ForegroundColor Yellow
    }

    Write-Host "[5/7] Exportar reportes..." -ForegroundColor Cyan
    $Reportes = Export-HermesEnterpriseSandboxReport -RutaSandbox $RutaSandbox -DeveloperContext $DeveloperContext -SmokeTestResult $SmokeTestResult

    Write-Host "[6/7] Generar UserGuide.md..." -ForegroundColor Cyan
    $UserGuide = New-HermesEnterpriseSandboxUserGuide -RutaSandbox $RutaSandbox

    Write-Host "[7/7] Generar SandboxInstructions.ps1..." -ForegroundColor Cyan
    $Instructions = New-HermesEnterpriseSandboxInstructions -RutaSandbox $RutaSandbox

    $HoraFin = Get-Date
    $Duracion = $HoraFin - $HoraInicio

    $Metadata = Get-Content -Path (Join-Path $RutaSandbox "sandbox.json") -Raw | ConvertFrom-Json
    $Metadata.Estado = "Completed"
    $Metadata.Resultado = "SUCCESS"
    $Metadata | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $RutaSandbox "sandbox.json") -Encoding UTF8

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Sandbox completado correctamente." -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Ruta:        $RutaSandbox" -ForegroundColor White
    Write-Host "Escenario:   $Escenario" -ForegroundColor White
    Write-Host "Duración:    $($Duracion.ToString('hh\:mm\:ss'))" -ForegroundColor White
    Write-Host "UserGuide:   $UserGuide" -ForegroundColor White
    Write-Host "Instrucciones: $Instructions" -ForegroundColor White
    Write-Host "Reportes:    $($Reportes.RutaReports)" -ForegroundColor White
    Write-Host ""
    Write-Host "Para inspeccionar el Sandbox:" -ForegroundColor Yellow
    Write-Host "pwsh $Instructions" -ForegroundColor DarkGray
}
catch {
    $MensajeError = $_.Exception.Message
    Registrar-ErrorSandbox -RutaSandbox $RutaSandbox -Mensaje $MensajeError
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "Sandbox falló. No se reintentará automáticamente." -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "Ruta:  $RutaSandbox" -ForegroundColor White
    Write-Host "Error: $MensajeError" -ForegroundColor White
    Write-Host ""
    throw
}
