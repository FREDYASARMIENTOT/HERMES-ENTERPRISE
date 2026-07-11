<#
.SYNOPSIS
    Punto de entrada publico del motor Hermes Enterprise.
.DESCRIPTION
    Start-HermesProject es el unico componente responsable de capturar
    informacion del usuario para construir un ProjectArchitecture y
    despues un BootstrapRequest.
    RESPONSABILIDADES:
    - Mostrar asistente interactivo.
    - Solicitar datos minimos (nombre, descripcion, tipo, frontend,
      backend, lenguaje, frameworks).
    - Validar respuestas basicas.
    - Construir ProjectArchitecture (contrato puro).
    - Invocar New-BootstrapRequestFromProjectArchitecture.
    NO es responsable de:
    - Crear carpetas ni archivos.
    - Invocar BootstrapState ni BootstrapOrchestrator.
    - Consultar Azure, GitHub, Docker ni ningun proveedor.
    - Ejecutar plugins ni capacidades.
.NOTES
    Sprint 5.6 | HERMES-ENTERPRISE | 2026-07-10 | v1.0.0
#>

Set-StrictMode -Version Latest

function Start-HermesProject {
    <#
    .SYNOPSIS
        Asistente interactivo para iniciar un proyecto Hermes.
    .DESCRIPTION
        Recopila informacion minima del usuario, construye un
        ProjectArchitecture y produce un BootstrapRequest via
        New-BootstrapRequestFromProjectArchitecture.
    .PARAMETER NombreProyecto
        3-64 chars alfanumericos, guion o guion bajo.
    .PARAMETER DescripcionProyecto
        Descripcion libre del proyecto.
    .PARAMETER TipoProyecto
        API | Web | FullStack | IA | Automatizacion | Otro.
    .PARAMETER LenguajePrincipal
        Lenguaje principal (PowerShell, CSharp, Python, TypeScript, etc.)
    .PARAMETER FrameworkFrontend
        Framework de frontend (solo si RequiereFrontend es true).
    .PARAMETER FrameworkBackend
        Framework de backend  (solo si RequiereBackend es true).
    .PARAMETER RequiereFrontend
        Indica si el proyecto requiere estructura FrontEnd.
    .PARAMETER RequiereBackend
        Indica si el proyecto requiere estructura BackEnd.
    .PARAMETER NonInteractive
        Modo automatizado: salta el wizard.
    .OUTPUTS
        PSCustomObject { ProyectoArquitectura; SolicitudBootstrap }
    .EXAMPLE
        Start-HermesProject
    .EXAMPLE
        Start-HermesProject -NombreProyecto 'MiApp' -DescripcionProyecto 'Demo' `
            -TipoProyecto 'API' -LenguajePrincipal 'PowerShell' `
            -RequiereBackend $true -FrameworkBackend 'PSFramework' -NonInteractive
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()][string] $NombreProyecto       = '',
        [Parameter()][string] $DescripcionProyecto  = '',
        [Parameter()][ValidateSet('API','Web','FullStack','IA','Automatizacion','Otro','')]
                     [string] $TipoProyecto          = '',
        [Parameter()][string] $LenguajePrincipal    = '',
        [Parameter()][string] $FrameworkFrontend    = '',
        [Parameter()][string] $FrameworkBackend     = '',
        [Parameter()][bool]   $RequiereFrontend     = $false,
        [Parameter()][bool]   $RequiereBackend      = $false,
        [Parameter()][switch] $NonInteractive
    )

    $tiposValidos = @('API','Web','FullStack','IA','Automatizacion','Otro')

    # ── Captura interactiva si faltan datos criticos ────────────────
    if (-not $NonInteractive -and
        ([string]::IsNullOrWhiteSpace($NombreProyecto) -or
         [string]::IsNullOrWhiteSpace($TipoProyecto)   -or
         [string]::IsNullOrWhiteSpace($LenguajePrincipal))) {

        Write-Host "=== Hermes Enterprise - Nuevo Proyecto ===" -ForegroundColor Cyan

        if ([string]::IsNullOrWhiteSpace($NombreProyecto)) {
            $NombreProyecto = Read-Host 'Nombre del proyecto (3-64 chars)'
        }
        if ([string]::IsNullOrWhiteSpace($DescripcionProyecto)) {
            $DescripcionProyecto = Read-Host 'Descripcion del proyecto'
        }
        if ([string]::IsNullOrWhiteSpace($TipoProyecto)) {
            Write-Host "Tipo de solucion:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $tiposValidos.Count; $i++) {
                Write-Host "  $($i+1)) $($tiposValidos[$i])"
            }
            do {
                $respuesta = Read-Host 'Selecciona (1-6)'
                if ($respuesta -match '^[1-6]$') {
                    $TipoProyecto = $tiposValidos[[int]$respuesta - 1]
                }
            } while (-not $TipoProyecto)
        }

        $RequiereFrontend = Convertir-RespuestaSN (Read-Host 'Requiere FrontEnd? (S/N)')
        $RequiereBackend  = Convertir-RespuestaSN (Read-Host 'Requiere BackEnd?  (S/N)')

        if ([string]::IsNullOrWhiteSpace($LenguajePrincipal)) {
            $LenguajePrincipal = Read-Host 'Lenguaje principal'
        }
        if ($RequiereFrontend) {
            $FrameworkFrontend = Read-Host 'Framework FrontEnd'
        }
        if ($RequiereBackend) {
            $FrameworkBackend = Read-Host 'Framework BackEnd'
        }
    }

    # ── Validaciones obligatorias ────────────────────────────────────
    Validar-NombreProyecto -Nombre $NombreProyecto
    Validar-TipoProyecto   -Tipo $TipoProyecto -TiposValidos $tiposValidos
    Validar-Lenguaje       -Lenguaje $LenguajePrincipal

    if ($RequiereFrontend -and [string]::IsNullOrWhiteSpace($FrameworkFrontend)) {
        throw 'RequiereFrontend es true pero no se indico FrameworkFrontend.'
    }
    if ($RequiereBackend -and [string]::IsNullOrWhiteSpace($FrameworkBackend)) {
        throw 'RequiereBackend es true pero no se indico FrameworkBackend.'
    }

    # ── ProjectArchitecture (contrato puro, sin IO) ──────────────────
    $proyectoArquitectura = [PSCustomObject]@{
        PSTypeName               = 'Hermes.Project.Architecture'
        NombreProyecto           = $NombreProyecto.Trim()
        Descripcion              = $DescripcionProyecto.Trim()
        TipoProyecto             = $TipoProyecto
        LenguajePrincipal        = $LenguajePrincipal.Trim()
        FrameworkFrontend        = $FrameworkFrontend.Trim()
        FrameworkBackend         = $FrameworkBackend.Trim()
        RequiereFrontend         = $RequiereFrontend
        RequiereBackend          = $RequiereBackend
        RequiereAzure            = $false
        RequiereGitHub           = $false
        CapacidadesSeleccionadas = @()
    }

    # ── BootstrapRequest (se detiene aqui) ────────────────────────────
    $solicitudBootstrap = New-BootstrapRequestFromProjectArchitecture `
        -ProjectArchitecture $proyectoArquitectura

    Write-Host "ProjectArchitecture construido: $($proyectoArquitectura.NombreProyecto)" -ForegroundColor Green
    Write-Host 'BootstrapRequest listo. Siguiente fase: BootstrapState + Orchestrator (fuera de scope).' -ForegroundColor Gray

    return [PSCustomObject]@{
        PSTypeName           = 'Hermes.Project.ResultadoEntrada'
        ProyectoArquitectura = $proyectoArquitectura
        SolicitudBootstrap   = $solicitudBootstrap
    }
}

# ── Helpers privados ──────────────────────────────────────────────────

function Convertir-RespuestaSN {
    param([string]$Valor)
    if ([string]::IsNullOrWhiteSpace($Valor)) { return $false }
    $v = $Valor.Trim().ToLower()
    return ($v -eq 's' -or $v -eq 'si' -or $v -eq 'y' -or
            $v -eq 'yes' -or $v -eq 'true' -or $v -eq '1')
}

function Validar-NombreProyecto {
    param([string]$Nombre)
    if ([string]::IsNullOrWhiteSpace($Nombre)) {
        throw 'NombreProyecto es obligatorio.'
    }
    $n = $Nombre.Trim()
    if ($n.Length -lt 3 -or $n.Length -gt 64) {
        throw ('NombreProyecto debe tener 3-64 caracteres (actual: ' + $n.Length + ').')
    }
    if ($n -notmatch '^[A-Za-z0-9_-]+$') {
        throw 'NombreProyecto solo acepta letras, numeros, guion y guion bajo.'
    }
}

function Validar-TipoProyecto {
    param([string]$Tipo, [string[]]$TiposValidos)
    if ([string]::IsNullOrWhiteSpace($Tipo)) {
        throw 'TipoProyecto es obligatorio.'
    }
    if ($Tipo -notin $TiposValidos) {
        $permitidos = $TiposValidos -join ', '
        throw ('TipoProyecto invalido: ' + $Tipo + '. Permitidos: ' + $permitidos)
    }
}

function Validar-Lenguaje {
    param([string]$Lenguaje)
    if ([string]::IsNullOrWhiteSpace($Lenguaje)) {
        throw 'LenguajePrincipal es obligatorio.'
    }
}
