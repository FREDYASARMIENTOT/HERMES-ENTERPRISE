<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-SandboxWorkflow.ps1
Propósito:
    Valida el ciclo de vida completo del Development Workspace Sandbox: creación,
    numeración consecutiva, estructura, inicialización de escenarios, ejecución,
    generación de guías/reportes y eliminación aislada.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition {
    param([bool]$CondicionEvaluada, [string]$MensajeError)
    if (-not $CondicionEvaluada) { throw $MensajeError }
}

. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Initialize-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Invoke-HermesEnterpriseScenario.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Export-HermesEnterpriseSandboxReport.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandboxUserGuide.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandboxInstructions.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Remove-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Get-HermesEnterpriseSandbox.ps1")

$RutaRaizSandbox = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP "HermesSandboxTest_$(Get-Random)"))

function Limpiar-SandboxesDePrueba {
    if (Test-Path $RutaRaizSandbox) {
        Remove-Item -Path $RutaRaizSandbox -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Test-HermesEnterpriseSandboxEscenario {
    param([string]$Escenario)

    Write-Host "Probando escenario: $Escenario" -ForegroundColor Cyan

    $Sandbox = New-HermesEnterpriseSandbox -RutaRaizSandbox $RutaRaizSandbox -Escenario $Escenario -NombreProyecto "HermesProject"
    Assert-HermesEnterpriseCondition (Test-Path $Sandbox) "No se creó el Sandbox para $Escenario."
    Assert-HermesEnterpriseCondition ($Sandbox -like "*Test???-$Escenario") "El nombre del Sandbox no es autodescriptivo para $Escenario."

    foreach ($Carpeta in @("HermesEnterprise", "Workspace", "Reports", "Snapshots", "Logs", "Sessions", "Artifacts")) {
        $RutaCarpeta = Join-Path $Sandbox $Carpeta
        Assert-HermesEnterpriseCondition (Test-Path $RutaCarpeta) "No existe la carpeta $Carpeta en $Escenario"
    }

    $RutaMetadata = Join-Path $Sandbox "sandbox.json"
    Assert-HermesEnterpriseCondition (Test-Path $RutaMetadata) "No se creó sandbox.json en $Escenario"
    $Metadata = Get-Content -Path $RutaMetadata -Raw | ConvertFrom-Json
    Assert-HermesEnterpriseCondition ($Metadata.Escenario -eq $Escenario) "Escenario incorrecto en metadata."
    Assert-HermesEnterpriseCondition ($Metadata.Estado -eq "Created") "Estado inicial incorrecto en $Escenario."

    $Inicializacion = Initialize-HermesEnterpriseSandbox -RutaSandbox $Sandbox
    Assert-HermesEnterpriseCondition ($Inicializacion.Errores.Count -eq 0) "Errores en inicialización de $Escenario."

    $Metadata = Get-Content -Path $RutaMetadata -Raw | ConvertFrom-Json
    Assert-HermesEnterpriseCondition ($Metadata.Estado -eq "Initialized") "Estado no pasó a Initialized en $Escenario."

    $EscenarioResultado = Invoke-HermesEnterpriseScenario -RutaSandbox $Sandbox
    Assert-HermesEnterpriseCondition ($null -ne $EscenarioResultado.DeveloperContext) "No se generó DeveloperContext en $Escenario."

    $Reportes = Export-HermesEnterpriseSandboxReport -RutaSandbox $Sandbox -DeveloperContext $EscenarioResultado.DeveloperContext
    Assert-HermesEnterpriseCondition (Test-Path (Join-Path $Reportes.RutaReports "InstallationReport.json")) "No se generó InstallationReport.json"
    Assert-HermesEnterpriseCondition (Test-Path (Join-Path $Reportes.RutaReports "ValidationReport.json")) "No se generó ValidationReport.json"
    Assert-HermesEnterpriseCondition (Test-Path (Join-Path $Reportes.RutaReports "AcceptanceReport.json")) "No se generó AcceptanceReport.json"

    $UserGuide = New-HermesEnterpriseSandboxUserGuide -RutaSandbox $Sandbox
    Assert-HermesEnterpriseCondition (Test-Path $UserGuide) "No se generó UserGuide.md en $Escenario."
    $ContenidoGuia = Get-Content -Path $UserGuide -Raw
    Assert-HermesEnterpriseCondition ($ContenidoGuia -like "*HERMES Enterprise Sandbox*") "UserGuide.md no tiene título esperado."

    $Instructions = New-HermesEnterpriseSandboxInstructions -RutaSandbox $Sandbox
    Assert-HermesEnterpriseCondition (Test-Path $Instructions) "No se generó SandboxInstructions.ps1 en $Escenario."

    Remove-HermesEnterpriseSandbox -RutaSandbox $Sandbox
    Assert-HermesEnterpriseCondition (-not (Test-Path $Sandbox)) "No se eliminó el Sandbox de $Escenario."
}

try {
    Limpiar-SandboxesDePrueba

    Write-Host "[1/4] Validar numeración consecutiva..." -ForegroundColor Cyan
    $Sandbox1 = New-HermesEnterpriseSandbox -RutaRaizSandbox $RutaRaizSandbox -Escenario "EmptyFolder"
    $Sandbox2 = New-HermesEnterpriseSandbox -RutaRaizSandbox $RutaRaizSandbox -Escenario "EmptyFolder"
    Assert-HermesEnterpriseCondition ($Sandbox1 -like "*Test001*") "Primer Sandbox no es Test001."
    Assert-HermesEnterpriseCondition ($Sandbox2 -like "*Test002*") "Segundo Sandbox no es Test002."
    Remove-HermesEnterpriseSandbox -RutaSandbox $Sandbox1
    Remove-HermesEnterpriseSandbox -RutaSandbox $Sandbox2

    Write-Host "[2/4] Validar listado de Sandboxes..." -ForegroundColor Cyan
    $Lista = Get-HermesEnterpriseSandbox -RutaRaizSandbox $RutaRaizSandbox
    Assert-HermesEnterpriseCondition ($Lista.Count -eq 0) "Quedaron Sandboxes residuales."

    Write-Host "[3/4] Probar escenarios representativos..." -ForegroundColor Cyan
    Test-HermesEnterpriseSandboxEscenario -Escenario "EmptyFolder"
    Test-HermesEnterpriseSandboxEscenario -Escenario "ExistingProject"
    Test-HermesEnterpriseSandboxEscenario -Escenario "GitWithoutRemote"

    Write-Host "[4/4] Validar numeración después de eliminar..." -ForegroundColor Cyan
    $Sandbox3 = New-HermesEnterpriseSandbox -RutaRaizSandbox $RutaRaizSandbox -Escenario "EmptyFolder"
    Assert-HermesEnterpriseCondition ($Sandbox3 -like "*Test001*") "Numeración debería reiniciar desde Test001 tras eliminar anteriores."
    Remove-HermesEnterpriseSandbox -RutaSandbox $Sandbox3
}
finally {
    Limpiar-SandboxesDePrueba
}

Write-Host "Test-SandboxWorkflow completado correctamente." -ForegroundColor Green
