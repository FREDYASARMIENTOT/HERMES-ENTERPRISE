<#
.SYNOPSIS
    Start-HermesProject - Entry point publico del motor de bootstrap
.DESCRIPTION
    Unico punto de invocacion externo. Responsable de:
      1. Capturar datos del usuario (parametros o wizard).
      2. Construir BootstrapRequest.
      3. Convertir Request -> BootstrapState.
      4. Delegar en BootstrapOrchestrator.
      5. Retornar resultado final al usuario.

    NO contiene logica de negocio.
    NO invoca managers directamente.
    NO lee/escribe archivos (excepto lo que haga el orquestador internamente).
.NOTES
    Proyecto: HERMES-ENTERPRISE
    Sprint  : 6
#>

Set-StrictMode -Version Latest

function Start-HermesProject {
    <#
    .SYNOPSIS
        Inicia un proyecto Hermes creando la estructura y el Context Package.
    .DESCRIPTION
        Entry point publico. Acepta modo parametros (automatizado) y modo wizard
        (interactivo). Delega la ejecucion real en BootstrapOrchestrator.
    .PARAMETER NombreProyecto
        Nombre del proyecto (3-64 caracteres, A-Za-z0-9_-).
    .PARAMETER RutaProyecto
        Ruta absoluta donde se creara el proyecto.
    .PARAMETER AbrirVSCode
        Abrir el workspace en VS Code al finalizar (default: true).
    .PARAMETER CrearBackend
        Crear estructura de backend Python.
    .PARAMETER CrearFrontend
        Crear estructura de frontend Node.
    .PARAMETER ProveedorGit
        Proveedor de git remoto: GitHub, GitLab, Bitbucket, None.
    .PARAMETER Force
        Modo automatizado: salta wizard interactivo, requiere parametros completos.
    .OUTPUTS
        PSCustomObject { Success, BootstrapReport, BootstrapState, ProximaAccion }
    .EXAMPLE
        Start-HermesProject -NombreProyecto 'MiProy' -RutaProyecto 'C:\Proy\MiProy'
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$NombreProyecto = '',

        [Parameter()]
        [string]$RutaProyecto = '',

        [Parameter()]
        [bool]$AbrirVSCode = $true,

        [Parameter()]
        [bool]$CrearBackend = $false,

        [Parameter()]
        [bool]$CrearFrontend = $false,

        [Parameter()]
        [ValidateSet('GitHub', 'GitLab', 'Bitbucket', 'None')]
        [string]$ProveedorGit = 'None',

        [Parameter()]
        [switch]$Force
    )

    # --- Paso 1: completar datos si faltan y no estamos en Force ---
    if ([string]::IsNullOrWhiteSpace($NombreProyecto) -or
        [string]::IsNullOrWhiteSpace($RutaProyecto)) {

        if ($Force) {
            throw "Start-HermesProject: NombreProyecto y RutaProyecto son obligatorios en modo -Force."
        }

        if (Get-Command 'Start-BootstrapWizard' -ErrorAction SilentlyContinue) {
            $datosWizard = Start-BootstrapWizard -Modo 'CapturaInicial'
            $NombreProyecto = $datosWizard.NombreProyecto
            $RutaProyecto   = $datosWizard.RutaProyecto
            $AbrirVSCode    = $datosWizard.AbrirVSCode
        } else {
            throw "Start-HermesProject: faltan datos obligatorios y no hay wizard disponible."
        }
    }

    try {
        # --- Paso 2: construir BootstrapRequest ---
        $request = New-BootstrapRequest `
            -NombreProyecto     $NombreProyecto `
            -RutaProyecto       $RutaProyecto `
            -CrearBackend       $CrearBackend `
            -CrearFrontend      $CrearFrontend `
            -ProveedorGit       $ProveedorGit `
            -AbrirVSCode        $AbrirVSCode

        # --- Paso 3: convertir a BootstrapState ---
        $state = New-BootstrapStateFromRequest -Request $request

        # --- Paso 4: delegar en el orquestador ---
        $resultado = Invoke-BootstrapOrchestrator -BootstrapRequest $request `
                                                 -BootstrapState  $state `
                                                 -Force:$Force

        # --- Paso 5: derivar ProximaAccion ---
        $proximaAccion = if ($resultado.Reporte.Success) {
            if ($AbrirVSCode) { "Workspace abierto en VSCode" }
            else              { "Context Package generado, continuar en IDE" }
        } else {
            "Revisar errores en BootstrapReport.Errores"
        }

        return [PSCustomObject]@{
            Success         = $resultado.Reporte.Success
            BootstrapReport = $resultado.Reporte
            BootstrapState  = $resultado.BootstrapState
            ProximaAccion   = $proximaAccion
        }
    }
    catch {
        return [PSCustomObject]@{
            Success         = $false
            BootstrapReport = $null
            BootstrapState  = $null
            ProximaAccion   = "Fallo durante bootstrap: $($_.Exception.Message)"
        }
    }
}
