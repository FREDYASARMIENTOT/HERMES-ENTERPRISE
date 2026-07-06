<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : New-HermesEnterpriseSandboxInstructions.ps1
Propósito:
    Genera SandboxInstructions.ps1 dentro de un Sandbox. Al ejecutarlo, muestra ayuda interactiva
    específica del escenario.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RutaSandbox = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-HermesEnterpriseSandboxInstructions {
    [CmdletBinding()][OutputType([string])]
    param([Parameter(Mandatory = $true)][string]$RutaSandbox)

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($RutaSandbox)
    $RutaMetadata = Join-Path $RutaAbsoluta "sandbox.json"

    if (-not (Test-Path $RutaMetadata)) {
        throw "No se encontró sandbox.json en $RutaAbsoluta"
    }

    $Metadata = Get-Content -Path $RutaMetadata -Raw | ConvertFrom-Json
    $RutaInstructions = Join-Path $RutaAbsoluta "SandboxInstructions.ps1"

    $Contenido = @"
<#
Instrucciones del Sandbox $($Metadata.Nombre)
Escenario: $($Metadata.Escenario)
Generado automáticamente por HERMES Enterprise.
#>
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "HERMES Enterprise Sandbox" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Escenario:  $($Metadata.Escenario)" -ForegroundColor Yellow
Write-Host "Nombre:     $($Metadata.Nombre)" -ForegroundColor Yellow
Write-Host "Ruta:       $RutaAbsoluta" -ForegroundColor Yellow
Write-Host "Estado:     $($Metadata.Estado)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Comandos disponibles:" -ForegroundColor Green
Write-Host ""
Write-Host "1. Iniciar Hermes" -ForegroundColor White
Write-Host "   pwsh .\scripts\Start-HermesEnterprise.ps1" -ForegroundColor DarkGray
Write-Host ""
Write-Host "2. Ejecutar pruebas" -ForegroundColor White
Write-Host "   pwsh .\scripts\Test-HermesEnterprise.ps1" -ForegroundColor DarkGray
Write-Host ""
Write-Host "3. Ver reportes" -ForegroundColor White
Write-Host "   explorer .\Reports" -ForegroundColor DarkGray
Write-Host ""
Write-Host "4. Abrir guía de usuario" -ForegroundColor White
Write-Host "   notepad .\UserGuide.md" -ForegroundColor DarkGray
Write-Host ""
Write-Host "5. Eliminar Sandbox" -ForegroundColor White
Write-Host "   pwsh .\scripts\Remove-HermesEnterpriseSandbox.ps1 -RutaSandbox `"$RutaAbsoluta`"" -ForegroundColor DarkGray
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
"@

    [System.IO.File]::WriteAllText($RutaInstructions, $Contenido, [System.Text.UTF8Encoding]::new($false))
    return $RutaInstructions
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($RutaSandbox)) {
        throw "El parámetro -RutaSandbox es obligatorio al ejecutar el script directamente."
    }
    New-HermesEnterpriseSandboxInstructions -RutaSandbox $RutaSandbox
}
