<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Export-HermesEnterpriseSandboxReport.ps1
Propósito:
    Genera los reportes JSON de un Sandbox: instalación, validación, smoke test, aceptación,
    developer context y workspace.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RutaSandbox = "",

    [Parameter(Mandatory = $false)]
    [psobject]$DeveloperContext = $null,

    [Parameter(Mandatory = $false)]
    [psobject]$SmokeTestResult = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Export-HermesEnterpriseSandboxReport {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][string]$RutaSandbox,
        [Parameter(Mandatory = $false)][psobject]$DeveloperContext = $null,
        [Parameter(Mandatory = $false)][psobject]$SmokeTestResult = $null
    )

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($RutaSandbox)
    $RutaReports = Join-Path $RutaAbsoluta "Reports"
    if (-not (Test-Path $RutaReports)) { New-Item -ItemType Directory -Path $RutaReports -Force | Out-Null }

    $RutaMetadata = Join-Path $RutaAbsoluta "sandbox.json"
    $Metadata = if (Test-Path $RutaMetadata) { Get-Content -Path $RutaMetadata -Raw | ConvertFrom-Json } else { $null }

    $Ahora = (Get-Date).ToString("o")

    $InstallationReport = [pscustomobject][ordered]@{
        Fecha        = $Ahora
        Sandbox      = if ($Metadata) { $Metadata.Nombre } else { "" }
        Escenario    = if ($Metadata) { $Metadata.Escenario } else { "" }
        Ruta         = $RutaAbsoluta
        Estructura   = (Get-ChildItem -Path $RutaAbsoluta -Directory | Select-Object -ExpandProperty Name)
        Estado       = if ($Metadata) { $Metadata.Estado } else { "Unknown" }
    }

    $ValidationReport = [pscustomobject][ordered]@{
        Fecha        = $Ahora
        Sandbox      = if ($Metadata) { $Metadata.Nombre } else { "" }
        Validaciones = @(
            @{ Nombre = "sandbox.json"; Existe = (Test-Path $RutaMetadata); Estado = if (Test-Path $RutaMetadata) { "OK" } else { "FAIL" } }
            @{ Nombre = "Workspace"; Existe = (Test-Path (Join-Path $RutaAbsoluta "Workspace")); Estado = if (Test-Path (Join-Path $RutaAbsoluta "Workspace")) { "OK" } else { "FAIL" } }
            @{ Nombre = "Reports"; Existe = (Test-Path $RutaReports); Estado = if (Test-Path $RutaReports) { "OK" } else { "FAIL" } }
            @{ Nombre = "UserGuide.md"; Existe = (Test-Path (Join-Path $RutaAbsoluta "UserGuide.md")); Estado = if (Test-Path (Join-Path $RutaAbsoluta "UserGuide.md")) { "OK" } else { "FAIL" } }
            @{ Nombre = "SandboxInstructions.ps1"; Existe = (Test-Path (Join-Path $RutaAbsoluta "SandboxInstructions.ps1")); Estado = if (Test-Path (Join-Path $RutaAbsoluta "SandboxInstructions.ps1")) { "OK" } else { "FAIL" } }
        )
        EstadoGeneral = if ((Test-Path $RutaMetadata) -and (Test-Path (Join-Path $RutaAbsoluta "Workspace")) -and (Test-Path $RutaReports)) { "PASSED" } else { "FAILED" }
    }

    $AcceptanceReport = [pscustomobject][ordered]@{
        Fecha        = $Ahora
        Sandbox      = if ($Metadata) { $Metadata.Nombre } else { "" }
        Escenario    = if ($Metadata) { $Metadata.Escenario } else { "" }
        Descripcion  = if ($Metadata) { $Metadata.Descripcion } else { "" }
        Estado       = if ($Metadata) { $Metadata.Estado } else { "Unknown" }
        Resultado    = if ($Metadata) { $Metadata.Resultado } else { "" }
    }

    $InstallationReport | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $RutaReports "InstallationReport.json") -Encoding UTF8
    $ValidationReport | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $RutaReports "ValidationReport.json") -Encoding UTF8
    $AcceptanceReport | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $RutaReports "AcceptanceReport.json") -Encoding UTF8

    if ($null -ne $SmokeTestResult) {
        $SmokeTestResult | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $RutaReports "SmokeTestReport.json") -Encoding UTF8
    }

    if ($null -ne $DeveloperContext) {
        $DeveloperContext | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $RutaReports "DeveloperContext.json") -Encoding UTF8
    }

    $WorkspaceInfo = if (Test-Path (Join-Path $RutaAbsoluta "Workspace")) {
        Get-ChildItem -Path (Join-Path $RutaAbsoluta "Workspace") -Directory | Select-Object Name, FullName
    } else { @() }
    $WorkspaceInfo | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $RutaReports "Workspace.json") -Encoding UTF8

    return [pscustomobject][ordered]@{
        RutaReports = $RutaReports
        Reportes    = @("InstallationReport.json", "ValidationReport.json", "AcceptanceReport.json", "SmokeTestReport.json", "DeveloperContext.json", "Workspace.json")
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($RutaSandbox)) {
        throw "El parámetro -RutaSandbox es obligatorio al ejecutar el script directamente."
    }
    Export-HermesEnterpriseSandboxReport -RutaSandbox $RutaSandbox -DeveloperContext $DeveloperContext -SmokeTestResult $SmokeTestResult
}
