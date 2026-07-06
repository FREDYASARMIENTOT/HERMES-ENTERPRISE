<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : New-HermesEnterpriseSandbox.ps1
Propósito:
    Crea un Development Workspace Sandbox aislado bajo D:\Sandbox (o ruta configurada).
    Genera nombres consecutivos autodescriptivos (Test001-ExistingProject) y la estructura
    interna completa de carpetas, metadatos, guía de usuario e instrucciones.
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
    [string]$Modelo = "ur-hermes-mini",

    [Parameter(Mandatory = $false)]
    [string]$Proveedor = "AzureFoundryProvider"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HermesEnterpriseNextSandboxNumber {
    [CmdletBinding()][OutputType([int])]
    param([Parameter(Mandatory = $true)][string]$RutaRaizSandbox)
    if (-not (Test-Path $RutaRaizSandbox)) { return 1 }
    $Directorios = Get-ChildItem -Path $RutaRaizSandbox -Directory -Filter "Test*" -ErrorAction SilentlyContinue
    $Maximo = 0
    foreach ($Directorio in $Directorios) {
        if ($Directorio.Name -match "^Test(\d{3})") {
            $Numero = [int]$Matches[1]
            if ($Numero -gt $Maximo) { $Maximo = $Numero }
        }
    }
    return $Maximo + 1
}

function New-HermesEnterpriseSandbox {
    [CmdletBinding()][OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][string]$RutaRaizSandbox,
        [Parameter(Mandatory = $true)][string]$Escenario,
        [Parameter(Mandatory = $false)][string]$NombreProyecto = "HermesProject",
        [Parameter(Mandatory = $false)][string]$Modelo = "ur-hermes-mini",
        [Parameter(Mandatory = $false)][string]$Proveedor = "AzureFoundryProvider"
    )

    $RutaRaizAbsoluta = [System.IO.Path]::GetFullPath($RutaRaizSandbox)
    if (-not (Test-Path $RutaRaizAbsoluta)) {
        New-Item -ItemType Directory -Path $RutaRaizAbsoluta -Force | Out-Null
    }

    $Numero = Get-HermesEnterpriseNextSandboxNumber -RutaRaizSandbox $RutaRaizAbsoluta
    $NombreSandbox = "Test{0:D3}-{1}" -f $Numero, $Escenario
    $RutaSandbox = Join-Path $RutaRaizAbsoluta $NombreSandbox

    if (Test-Path $RutaSandbox) {
        throw "El Sandbox $NombreSandbox ya existe. No se permite sobrescribir."
    }

    $Estructura = @(
        "HermesEnterprise"
        "Workspace"
        "Reports"
        "Snapshots"
        "Logs"
        "Sessions"
        "Artifacts"
    )

    foreach ($Carpeta in $Estructura) {
        New-Item -ItemType Directory -Path (Join-Path $RutaSandbox $Carpeta) -Force | Out-Null
    }

    $Metadata = [pscustomobject][ordered]@{
        Numero        = $Numero
        Nombre        = $NombreSandbox
        Escenario     = $Escenario
        Descripcion   = (Get-HermesEnterpriseSandboxScenarioDescription -Escenario $Escenario)
        Fecha         = (Get-Date).ToString("o")
        Version       = "0.9.1"
        Usuario       = $env:USERNAME
        Estado        = "Created"
        Proyecto      = $NombreProyecto
        Repositorio   = ""
        Modelo        = $Modelo
        Provider      = $Proveedor
        Resultado     = "Pending"
    }

    $RutaMetadata = Join-Path $RutaSandbox "sandbox.json"
    $Metadata | ConvertTo-Json -Depth 5 | Set-Content -Path $RutaMetadata -Encoding UTF8

    return $RutaSandbox
}

function Get-HermesEnterpriseSandboxScenarioDescription {
    [CmdletBinding()][OutputType([string])]
    param([Parameter(Mandatory = $true)][string]$Escenario)
    $Mapa = @{
        "NoWorkspace"       = "VS Code sin carpeta abierta"
        "EmptyFolder"       = "Carpeta vacía"
        "ExistingProject"   = "Proyecto existente"
        "ProjectWithoutGit" = "Proyecto sin Git"
        "GitWithoutRemote"  = "Git sin remoto"
        "GitHubRepository"  = "Git con remoto"
        "ResumeSession"     = "Reabrir sesión"
        "NewProject"        = "Crear proyecto nuevo"
        "CloneProject"      = "Clonar proyecto"
        "MultipleSessions"  = "Cambiar entre sesiones"
    }
    return $Mapa[$Escenario]
}

if ($MyInvocation.InvocationName -ne '.') {
    New-HermesEnterpriseSandbox -RutaRaizSandbox $RutaRaizSandbox -Escenario $Escenario -NombreProyecto $NombreProyecto -Modelo $Modelo -Proveedor $Proveedor
}
