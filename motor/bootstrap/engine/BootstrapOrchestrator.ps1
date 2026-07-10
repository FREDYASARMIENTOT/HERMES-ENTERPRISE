<#
.SYNOPSIS
    BootstrapOrchestrator - Coordinador puro del flujo de bootstrap (V2)

.DESCRIPTION
    Consume contratos:
      - BootstrapRequest (Hermes.Bootstrap.Request)
      - BootstrapState  (Hermes.Bootstrap.BootstrapState)

    Coordina los pasos sin lógica de negocio:
      1. BootstrapState   (registra arranque)
      2. BootstrapWizard  (interacción usuario, opcional)
      3. EnvironmentManager (valida entorno)
      4. GitManager       (init o validación repo)
      5. ContextEngine    (Context Package)
      6. VSCodeManager    (abre workspace si aplica)
      7. New-BootstrapReport (resume ejecución)

    No contiene lógica de negocio. Solo coordina.

.NOTES
    Proyecto: HERMES-ENTERPRISE
    Sprint  : 5.3 - V2 (BootstrapRequest + BootstrapState)
    Tamaño  : ~310 líneas (coordinación pura)
#>

Set-StrictMode -Version Latest

# ─────────────────────────────────────────────────────────────────────────────
# EVENTOS (sin EventBus externo)
# ─────────────────────────────────────────────────────────────────────────────

function Publish-BootstrapEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Started', 'Step.Started', 'Step.Completed', 'Completed', 'Failed')]
        [string]$EventoTipo,

        [Parameter()]
        [hashtable]$Propiedades = @{}
    )

    $evento = @{
        EventType  = $EventoTipo
        Timestamp  = [DateTime]::UtcNow
        Properties = $Propiedades
    }

    if (Get-Command 'Write-HermesLog' -ErrorAction SilentlyContinue) {
        Write-HermesLog -Level 'Info' -Message "Bootstrap.Event: $EventoTipo" -Properties $Propiedades
    }

    return $evento
}

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

function Get-BootstrapContextPath {
    <#
    .SYNOPSIS
        Deriva la ruta del Context Package desde BootstrapRequest.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Request
    )

    return (Join-Path $Request.RutaProyecto '.hermes\context')
}

# ─────────────────────────────────────────────────────────────────────────────
# INVOCADORES DE PASOS (wrappers sobre módulos existentes)
# Todos reciben State + Request y retornan StepResult.
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-BootstrapStateStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject]$State,
        [Parameter(Mandatory)][PSCustomObject]$Request
    )

    $resultado = [PSCustomObject]@{
        Paso     = 'BootstrapState'
        Success  = $true
        Data     = $null
        Error    = $null
        Duracion = [TimeSpan]::Zero
    }

    try {
        # BootstrapState ya viene construido por New-BootstrapStateFromRequest.
        # Se asegura de que tenga la ruta del proyecto derivada del Request.
        if (-not $State.PSObject.Properties['RutaProyecto']) {
            $State | Add-Member -MemberType NoteProperty -Name 'RutaProyecto' -Value $Request.RutaProyecto -Force
        }

        $resultado.Data = $State
        return $resultado
    } catch {
        $resultado.Success = $false
        $resultado.Error   = $_.Exception.Message
        return $resultado
    }
}

function Invoke-BootstrapWizardStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject]$State,
        [Parameter(Mandatory)][PSCustomObject]$Request,
        [switch]$Force
    )

    $resultado = [PSCustomObject]@{
        Paso     = 'BootstrapWizard'
        Success  = $true
        Data     = $null
        Error    = $null
        Duracion = [TimeSpan]::Zero
    }

    try {
        # En modo automatizado se salta el wizard (Request ya contiene la decisión del usuario).
        if ($Force -or -not (Get-Command 'Start-BootstrapWizard' -ErrorAction SilentlyContinue)) {
            $resultado.Data = $State
            return $resultado
        }

        $resultado.Data = Start-BootstrapWizard -State $State -Request $Request
        return $resultado
    } catch {
        $resultado.Success = $false
        $resultado.Error   = $_.Exception.Message
        return $resultado
    }
}

function Invoke-EnvironmentManagerStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject]$State,
        [Parameter(Mandatory)][PSCustomObject]$Request
    )

    $resultado = [PSCustomObject]@{
        Paso     = 'EnvironmentManager'
        Success  = $true
        Data     = $null
        Error    = $null
        Duracion = [TimeSpan]::Zero
    }

    try {
        if (Get-Command 'Invoke-EnvironmentManager' -ErrorAction SilentlyContinue) {
            $resultado.Data = Invoke-EnvironmentManager -State $State -Request $Request
        } else {
            $resultado.Data = $State
        }
        return $resultado
    } catch {
        $resultado.Success = $false
        $resultado.Error   = $_.Exception.Message
        return $resultado
    }
}

function Invoke-GitManagerStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject]$State,
        [Parameter(Mandatory)][PSCustomObject]$Request
    )

    $resultado = [PSCustomObject]@{
        Paso     = 'GitManager'
        Success  = $true
        Data     = $null
        Error    = $null
        Duracion = [TimeSpan]::Zero
    }

    try {
        $rutaProyecto = $Request.RutaProyecto
        $esNuevoRepo  = ($Request.AccionRepositorio -eq 'Nuevo') -or [bool]$Request.CrearNuevoRepositorio

        if (Get-Command 'Initialize-GitRepository' -ErrorAction SilentlyContinue) {
            if ($esNuevoRepo) {
                $resultado.Data = Initialize-GitRepository -Path $rutaProyecto
            } else {
                $resultado.Data = Validate-GitRepository -Path $rutaProyecto
            }
        } else {
            $resultado.Data = [PSCustomObject]@{ GitInicializado = $true; Ruta = $rutaProyecto }
        }
        return $resultado
    } catch {
        $resultado.Success = $false
        $resultado.Error   = $_.Exception.Message
        return $resultado
    }
}

function Invoke-ContextEngineStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject]$State,
        [Parameter(Mandatory)][PSCustomObject]$Request
    )

    $resultado = [PSCustomObject]@{
        Paso     = 'ContextEngine'
        Success  = $true
        Data     = $null
        Error    = $null
        Duracion = [TimeSpan]::Zero
    }

    try {
        $rutaContexto = Get-BootstrapContextPath -Request $Request

        if (Get-Command 'Invoke-ContextEngine' -ErrorAction SilentlyContinue) {
            $resultado.Data = Invoke-ContextEngine -ContextPath $rutaContexto
        } else {
            $resultado.Data = @()
        }
        return $resultado
    } catch {
        $resultado.Success = $false
        $resultado.Error   = $_.Exception.Message
        return $resultado
    }
}

function Invoke-VSCodeManagerStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject]$State,
        [Parameter(Mandatory)][PSCustomObject]$Request
    )

    $resultado = [PSCustomObject]@{
        Paso     = 'VSCodeManager'
        Success  = $true
        Data     = $null
        Error    = $null
        Duracion = [TimeSpan]::Zero
    }

    try {
        $rutaProyecto = $Request.RutaProyecto
        $abrir        = [bool]$Request.AbrirVSCode

        if ($abrir -and (Get-Command 'Open-VSCodeWorkspace' -ErrorAction SilentlyContinue)) {
            $resultado.Data = Open-VSCodeWorkspace -Path $rutaProyecto
        } else {
            $resultado.Data = [PSCustomObject]@{ WorkspaceAbierto = $false; Ruta = $rutaProyecto }
        }
        return $resultado
    } catch {
        $resultado.Success = $false
        $resultado.Error   = $_.Exception.Message
        return $resultado
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# REPORTE
# ─────────────────────────────────────────────────────────────────────────────

function New-BootstrapReport {
    [CmdletBinding()]
    param(
        [System.Collections.ArrayList]$ResultadosPasos,
        [TimeSpan]$DuracionTotal,
        [System.Collections.ArrayList]$Errores
    )

    $listaErrores = @()
    if ($null -ne $Errores -and $Errores.Count -gt 0) {
        $listaErrores = $Errores.ToArray()
    }

    $pasosExitosos = @($ResultadosPasos | Where-Object { $_.Success }).Count
    $pasosFallidos = @($ResultadosPasos | Where-Object { -not $_.Success }).Count

    return [PSCustomObject]@{
        Success       = ($listaErrores.Count -eq 0)
        PasosExitosos = $pasosExitosos
        PasosFallidos = $pasosFallidos
        DuracionTotal = $DuracionTotal
        Errores       = $listaErrores
        Pasos         = $ResultadosPasos
        GeneradoEn    = [DateTime]::UtcNow
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# ORQUESTADOR PRINCIPAL
# Entrada: BootstrapRequest + BootstrapState
# Salida : BootstrapReport + BootstrapState actualizado
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-BootstrapOrchestrator {
    <#
    .SYNOPSIS
        Coordina el flujo completo de bootstrap consumiendo:
        - BootstrapRequest (Hermes.Bootstrap.Request)
        - BootstrapState  (Hermes.Bootstrap.BootstrapState)

    .DESCRIPTION
        Ejecuta los 6 pasos del motor de bootstrap en orden estricto,
        publicando eventos en cada fase. No contiene lógica de negocio:
        solo delega en los managers existentes pasando los contratos.

    .PARAMETER BootstrapRequest
        Objeto BootstrapRequest previamente validado (tipo: Hermes.Bootstrap.Request).

    .PARAMETER BootstrapState
        BootstrapState inicial construido por New-BootstrapStateFromRequest
        (tipo: Hermes.Bootstrap.BootstrapState).

    .PARAMETER Force
        Modo automatizado: salta confirmaciones y wizard interactivo.

    .OUTPUTS
        PSCustomObject con Reporte (BootstrapReport) y BootstrapState actualizado.

    .EXAMPLE
        $request = New-BootstrapRequest -NombreProyecto 'Demo' -RutaProyecto 'C:\Proyectos\Demo' -AbrirVSCode $false
        $state   = New-BootstrapStateFromRequest -Request $request
        $report  = Invoke-BootstrapOrchestrator -BootstrapRequest $request -BootstrapState $state
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [ValidateScript({
            if ($_.PSObject.TypeNames[0] -ne 'Hermes.Bootstrap.Request') {
                throw "El parámetro BootstrapRequest debe ser del tipo 'Hermes.Bootstrap.Request'"
            }
            return $true
        })]
        [PSCustomObject]$BootstrapRequest,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [ValidateScript({
            if ($_.PSObject.TypeNames[0] -ne 'Hermes.Bootstrap.BootstrapState') {
                throw "El parámetro BootstrapState debe ser del tipo 'Hermes.Bootstrap.BootstrapState'"
            }
            return $true
        })]
        [PSCustomObject]$BootstrapState,

        [Parameter()]
        [switch]$Force
    )

    $inicioTotal   = [DateTime]::UtcNow
    $resultados    = [System.Collections.ArrayList]::new()
    $errores       = [System.Collections.ArrayList]::new()
    $estadoActual  = $BootstrapState

    Publish-BootstrapEvent -EventoTipo 'Started' -Propiedades @{
        RutaProyecto   = $BootstrapRequest.RutaProyecto
        NombreProyecto = $BootstrapRequest.NombreProyecto
    } | Out-Null

    try {
        # Paso 1: BootstrapState
        Publish-BootstrapEvent -EventoTipo 'Step.Started' -Propiedades @{ Paso = 'BootstrapState' } | Out-Null
        $inicioPaso = [DateTime]::UtcNow
        $paso1      = Invoke-BootstrapStateStep -State $estadoActual -Request $BootstrapRequest
        $paso1.Duracion = [DateTime]::UtcNow - $inicioPaso
        $null = $resultados.Add($paso1)

        if ($paso1.Success) {
            $estadoActual = $paso1.Data
            Publish-BootstrapEvent -EventoTipo 'Step.Completed' -Propiedades @{ Paso = 'BootstrapState'; Duracion = $paso1.Duracion } | Out-Null
        } else {
            $null = $errores.Add("BootstrapState falló: $($paso1.Error)")
            Publish-BootstrapEvent -EventoTipo 'Failed' -Propiedades @{ Paso = 'BootstrapState'; Error = $paso1.Error } | Out-Null
        }

        # Paso 2: BootstrapWizard
        Publish-BootstrapEvent -EventoTipo 'Step.Started' -Propiedades @{ Paso = 'BootstrapWizard' } | Out-Null
        $inicioPaso = [DateTime]::UtcNow
        $paso2      = Invoke-BootstrapWizardStep -State $estadoActual -Request $BootstrapRequest -Force:$Force
        $paso2.Duracion = [DateTime]::UtcNow - $inicioPaso
        $null = $resultados.Add($paso2)

        if ($paso2.Success) {
            $estadoActual = $paso2.Data
            Publish-BootstrapEvent -EventoTipo 'Step.Completed' -Propiedades @{ Paso = 'BootstrapWizard'; Duracion = $paso2.Duracion } | Out-Null
        } elseif ($paso2.Data -and $paso2.Data.Cancelled) {
            $null = $errores.Add("Usuario canceló el bootstrap")
            Publish-BootstrapEvent -EventoTipo 'Failed' -Propiedades @{ Paso = 'BootstrapWizard'; Error = 'UsuarioCancelo' } | Out-Null
        } else {
            $null = $errores.Add("BootstrapWizard falló: $($paso2.Error)")
            Publish-BootstrapEvent -EventoTipo 'Failed' -Propiedades @{ Paso = 'BootstrapWizard'; Error = $paso2.Error } | Out-Null
        }

        # Paso 3: EnvironmentManager
        Publish-BootstrapEvent -EventoTipo 'Step.Started' -Propiedades @{ Paso = 'EnvironmentManager' } | Out-Null
        $inicioPaso = [DateTime]::UtcNow
        $paso3      = Invoke-EnvironmentManagerStep -State $estadoActual -Request $BootstrapRequest
        $paso3.Duracion = [DateTime]::UtcNow - $inicioPaso
        $null = $resultados.Add($paso3)

        if ($paso3.Success) {
            $estadoActual = $paso3.Data
            Publish-BootstrapEvent -EventoTipo 'Step.Completed' -Propiedades @{ Paso = 'EnvironmentManager'; Duracion = $paso3.Duracion } | Out-Null
        } else {
            $null = $errores.Add("EnvironmentManager falló: $($paso3.Error)")
            Publish-BootstrapEvent -EventoTipo 'Failed' -Propiedades @{ Paso = 'EnvironmentManager'; Error = $paso3.Error } | Out-Null
        }

        # Paso 4: GitManager
        Publish-BootstrapEvent -EventoTipo 'Step.Started' -Propiedades @{ Paso = 'GitManager' } | Out-Null
        $inicioPaso = [DateTime]::UtcNow
        $paso4      = Invoke-GitManagerStep -State $estadoActual -Request $BootstrapRequest
        $paso4.Duracion = [DateTime]::UtcNow - $inicioPaso
        $null = $resultados.Add($paso4)

        if ($paso4.Success) {
            Publish-BootstrapEvent -EventoTipo 'Step.Completed' -Propiedades @{ Paso = 'GitManager'; Duracion = $paso4.Duracion } | Out-Null
        } else {
            $null = $errores.Add("GitManager falló: $($paso4.Error)")
            Publish-BootstrapEvent -EventoTipo 'Failed' -Propiedades @{ Paso = 'GitManager'; Error = $paso4.Error } | Out-Null
        }

        # Paso 5: ContextEngine
        Publish-BootstrapEvent -EventoTipo 'Step.Started' -Propiedades @{ Paso = 'ContextEngine' } | Out-Null
        $inicioPaso = [DateTime]::UtcNow
        $paso5      = Invoke-ContextEngineStep -State $estadoActual -Request $BootstrapRequest
        $paso5.Duracion = [DateTime]::UtcNow - $inicioPaso
        $null = $resultados.Add($paso5)

        if ($paso5.Success) {
            Publish-BootstrapEvent -EventoTipo 'Step.Completed' -Propiedades @{ Paso = 'ContextEngine'; Duracion = $paso5.Duracion } | Out-Null
        } else {
            $null = $errores.Add("ContextEngine falló: $($paso5.Error)")
            Publish-BootstrapEvent -EventoTipo 'Failed' -Propiedades @{ Paso = 'ContextEngine'; Error = $paso5.Error } | Out-Null
        }

        # Paso 6: VSCodeManager
        Publish-BootstrapEvent -EventoTipo 'Step.Started' -Propiedades @{ Paso = 'VSCodeManager' } | Out-Null
        $inicioPaso = [DateTime]::UtcNow
        $paso6      = Invoke-VSCodeManagerStep -State $estadoActual -Request $BootstrapRequest
        $paso6.Duracion = [DateTime]::UtcNow - $inicioPaso
        $null = $resultados.Add($paso6)

        if ($paso6.Success) {
            Publish-BootstrapEvent -EventoTipo 'Step.Completed' -Propiedades @{ Paso = 'VSCodeManager'; Duracion = $paso6.Duracion } | Out-Null
        } else {
            $null = $errores.Add("VSCodeManager falló: $($paso6.Error)")
            Publish-BootstrapEvent -EventoTipo 'Failed' -Propiedades @{ Paso = 'VSCodeManager'; Error = $paso6.Error } | Out-Null
        }
    } catch {
        $null = $errores.Add("Error crítico en orquestador: $($_.Exception.Message)")
    }

    # Construir reporte
    $duracionTotal = [DateTime]::UtcNow - $inicioTotal
    $reporte       = New-BootstrapReport -ResultadosPasos $resultados -DuracionTotal $duracionTotal -Errores $errores

    # Actualizar estado final del motor
    $estadoActual | Add-Member -MemberType NoteProperty -Name 'EstadoFinal'   -Value $(if ($reporte.Success) { 'Completado' } else { 'Fallido' }) -Force
    $estadoActual | Add-Member -MemberType NoteProperty -Name 'FinishedAt'    -Value ([DateTime]::UtcNow.ToString('o')) -Force
    $estadoActual | Add-Member -MemberType NoteProperty -Name 'ReporteErrores'-Value $reporte.Errores -Force

    if ($reporte.Success) {
        Publish-BootstrapEvent -EventoTipo 'Completed' -Propiedades @{ Duracion = $duracionTotal; Pasos = $reporte.PasosExitosos } | Out-Null
    } else {
        Publish-BootstrapEvent -EventoTipo 'Failed' -Propiedades @{ Duracion = $duracionTotal; Errores = $reporte.Errores.Count } | Out-Null
    }

    return [PSCustomObject]@{
        Reporte        = $reporte
        BootstrapState = $estadoActual
    }
}
