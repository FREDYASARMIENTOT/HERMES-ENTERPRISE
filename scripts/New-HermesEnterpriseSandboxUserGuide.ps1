<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : New-HermesEnterpriseSandboxUserGuide.ps1
Proposito:
    Genera UserGuide.md dentro de un Sandbox. Es documentacion para el usuario que prueba el escenario,
    no para el desarrollador de HERMES.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RutaSandbox = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-HermesEnterpriseSandboxUserGuide {
    [CmdletBinding()][OutputType([string])]
    param([Parameter(Mandatory = $true)][string]$RutaSandbox)

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($RutaSandbox)
    $RutaMetadata = Join-Path $RutaAbsoluta "sandbox.json"

    if (-not (Test-Path $RutaMetadata)) {
        throw "No se encontro sandbox.json en $RutaAbsoluta"
    }

    $Metadata = Get-Content -Path $RutaMetadata -Raw | ConvertFrom-Json
    $RutaWorkspace = Join-Path $RutaAbsoluta "Workspace"
    $RutaReports = Join-Path $RutaAbsoluta "Reports"
    $RutaUserGuide = Join-Path $RutaAbsoluta "UserGuide.md"

    $Lineas = @(
        '# HERMES Enterprise Sandbox'
        ''
        '## Nombre'
        ''
        $Metadata.Nombre
        ''
        '## Ruta'
        ''
        $RutaAbsoluta
        ''
        '## Escenario'
        ''
        $Metadata.Escenario
        ''
        '## Descripcion'
        ''
        $Metadata.Descripcion
        ''
        '## Estado'
        ''
        $Metadata.Estado
        ''
        '---'
        ''
        '## Como abrir'
        ''
        'Abrir Visual Studio Code.'
        ''
        'Archivo -> Open Folder -> Seleccionar:'
        ''
        '```'
        $RutaWorkspace
        '```'
        ''
        '---'
        ''
        '## Como iniciar Hermes'
        ''
        'Abrir PowerShell en esta carpeta y ejecutar:'
        ''
        '```powershell'
        'pwsh .\scripts\Start-HermesEnterprise.ps1'
        '```'
        ''
        '---'
        ''
        '## Que deberia ocurrir'
        ''
        "Escenario: $($Metadata.Escenario)"
        ''
        "- Descripcion: $($Metadata.Descripcion)"
        "- Proyecto: $($Metadata.Proyecto)"
        "- Modelo: $($Metadata.Modelo)"
        "- Provider: $($Metadata.Provider)"
        ''
        '---'
        ''
        '## Reportes'
        ''
        'Los reportes se encuentran en:'
        ''
        '```'
        $RutaReports
        '```'
        ''
        '- AcceptanceReport.json'
        '- SmokeTestReport.json'
        '- DeveloperContext.json'
        '- Workspace.json'
        ''
        '---'
        ''
        '## Como eliminar'
        ''
        '```powershell'
        "pwsh .\\scripts\\Remove-HermesEnterpriseSandbox.ps1 -RutaSandbox `"$RutaAbsoluta`""
        '```'
        ''
        '---'
        ''
        '## Instrucciones rapidas'
        ''
        'Ejecutar:'
        ''
        '```powershell'
        'pwsh .\SandboxInstructions.ps1'
        '```'
    )

    $Contenido = $Lineas -join "`n"
    [System.IO.File]::WriteAllText($RutaUserGuide, $Contenido, [System.Text.UTF8Encoding]::new($false))

    return $RutaUserGuide
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($RutaSandbox)) {
        throw "El parametro -RutaSandbox es obligatorio al ejecutar el script directamente."
    }
    New-HermesEnterpriseSandboxUserGuide -RutaSandbox $RutaSandbox
}
