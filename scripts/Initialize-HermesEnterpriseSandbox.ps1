<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Initialize-HermesEnterpriseSandbox.ps1
Propósito:
    Prepara el escenario dentro de un Sandbox ya creado. No ejecuta HERMES Enterprise.
    Solo construye el entorno necesario para representar la situación del desarrollador.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RutaSandbox = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScript = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScript

. (Join-Path $RutaRaizRepositorio "motor\providers\ProjectManager.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\GitManager.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\VSCodeManager.ps1")
. (Join-Path $RutaRaizRepositorio "motor\session\SessionManager.ps1")

function Initialize-HermesEnterpriseSandbox {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][string]$RutaSandbox)

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($RutaSandbox)
    $RutaMetadata = Join-Path $RutaAbsoluta "sandbox.json"

    if (-not (Test-Path $RutaMetadata)) {
        throw "No se encontró sandbox.json en $RutaAbsoluta"
    }

    $Metadata = Get-Content -Path $RutaMetadata -Raw | ConvertFrom-Json
    $Escenario = $Metadata.Escenario
    $NombreProyecto = $Metadata.Proyecto
    $RutaWorkspace = Join-Path $RutaAbsoluta "Workspace"
    $RutaSessions = Join-Path $RutaAbsoluta "Sessions"

    $Resultado = [pscustomobject][ordered]@{
        Escenario   = $Escenario
        RutaSandbox = $RutaAbsoluta
        Acciones    = @()
        Errores     = @()
    }

    try {
        switch ($Escenario) {
            "EmptyFolder" {
                # Nada que preparar
                $Resultado.Acciones += "Carpeta vacía lista."
            }

            "ExistingProject" {
                $Proyecto = New-HermesEnterpriseProject -NombreProyecto $NombreProyecto -RutaBase $RutaWorkspace -LenguajePrincipal "PowerShell" -TipoProyecto "Sandbox"
                New-HermesEnterpriseVSCodeWorkspaceFile -Ruta $Proyecto.RutaLocal -NombreWorkspace $NombreProyecto | Out-Null
                $Resultado.Acciones += "Proyecto creado en $($Proyecto.RutaLocal)"
            }

            "ProjectWithoutGit" {
                $Proyecto = New-HermesEnterpriseProject -NombreProyecto $NombreProyecto -RutaBase $RutaWorkspace -LenguajePrincipal "PowerShell" -TipoProyecto "Sandbox"
                New-HermesEnterpriseVSCodeWorkspaceFile -Ruta $Proyecto.RutaLocal -NombreWorkspace $NombreProyecto | Out-Null
                $Resultado.Acciones += "Proyecto sin Git creado en $($Proyecto.RutaLocal)"
            }

            "GitWithoutRemote" {
                $Proyecto = New-HermesEnterpriseProject -NombreProyecto $NombreProyecto -RutaBase $RutaWorkspace -LenguajePrincipal "PowerShell" -TipoProyecto "Sandbox"
                Initialize-HermesEnterpriseGitRepository -Ruta $Proyecto.RutaLocal | Out-Null
                New-HermesEnterpriseVSCodeWorkspaceFile -Ruta $Proyecto.RutaLocal -NombreWorkspace $NombreProyecto | Out-Null
                $Resultado.Acciones += "Proyecto con Git local creado en $($Proyecto.RutaLocal)"
            }

            "GitHubRepository" {
                $Proyecto = New-HermesEnterpriseProject -NombreProyecto $NombreProyecto -RutaBase $RutaWorkspace -LenguajePrincipal "PowerShell" -TipoProyecto "Sandbox"
                Initialize-HermesEnterpriseGitRepository -Ruta $Proyecto.RutaLocal | Out-Null
                New-HermesEnterpriseVSCodeWorkspaceFile -Ruta $Proyecto.RutaLocal -NombreWorkspace $NombreProyecto | Out-Null
                $Resultado.Acciones += "Proyecto con Git y remoto MOCK preparado en $($Proyecto.RutaLocal)"
            }

            "NewProject" {
                # El proyecto se creará dinámicamente al iniciar Hermes
                $Resultado.Acciones += "Workspace listo para nuevo proyecto."
            }

            "ResumeSession" {
                if (-not (Test-Path $RutaSessions)) { New-Item -ItemType Directory -Path $RutaSessions -Force | Out-Null }
                $Sesion = New-HermesEnterpriseSessionFromContext -RutaRaizRepositorio $RutaAbsoluta -NombreProyecto $NombreProyecto -RutaWorkspace $RutaWorkspace
                $Resultado.Acciones += "Sesión previa creada: $($Sesion.IdentificadorSesion)"
            }

            "MultipleSessions" {
                if (-not (Test-Path $RutaSessions)) { New-Item -ItemType Directory -Path $RutaSessions -Force | Out-Null }
                for ($i = 1; $i -le 3; $i++) {
                    $Sesion = New-HermesEnterpriseSessionFromContext -RutaRaizRepositorio $RutaAbsoluta -NombreProyecto "$NombreProyecto-$i" -RutaWorkspace $RutaWorkspace
                    $Resultado.Acciones += "Sesión $i creada: $($Sesion.IdentificadorSesion)"
                }
            }

            "CloneProject" {
                $Resultado.Acciones += "Escenario CloneProject preparado ( MOCK; no se clona repositorio real)."
            }

            "NoWorkspace" {
                $Resultado.Acciones += "Sin workspace inicial."
            }

            default {
                throw "Escenario no soportado: $Escenario"
            }
        }

        $Metadata.Estado = "Initialized"
        $Metadata | ConvertTo-Json -Depth 5 | Set-Content -Path $RutaMetadata -Encoding UTF8
    }
    catch {
        $Metadata.Estado = "FAILED"
        $Metadata.Resultado = $_.Exception.Message
        $Metadata | ConvertTo-Json -Depth 5 | Set-Content -Path $RutaMetadata -Encoding UTF8
        $Resultado.Errores += $_.Exception.Message
        throw
    }

    return $Resultado
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($RutaSandbox)) {
        throw "El parámetro -RutaSandbox es obligatorio al ejecutar el script directamente."
    }
    Initialize-HermesEnterpriseSandbox -RutaSandbox $RutaSandbox
}
