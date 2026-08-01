<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EventBus.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Bus de eventos interno para comunicación desacoplada entre subsistemas.
====================================================================================================
#>

Set-StrictMode -Version Latest

# Aliases de compatibilidad
Set-Alias -Name New-EventBus -Value New-HermesEnterpriseEventBus -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name Publish-EventBusEvent -Value Publish-HermesEnterpriseEvent -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name Subscribe-EventBusEvent -Value Subscribe-HermesEnterpriseEvent -Scope Global -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Crea una nueva instancia del bus de eventos del sistema.
#>
function New-HermesEnterpriseEventBus {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Suscriptores      = @{}
        EventosPublicados = 0
        PipelineEvents    = @{
            'usecase.completed' = [System.Collections.ArrayList]@()
            'usecase.failed'    = [System.Collections.ArrayList]@()
            'usecase.pending'   = [System.Collections.ArrayList]@()
            'usecase.executing' = [System.Collections.ArrayList]@()
        }
    }
}

<#
.SYNOPSIS
    Publica un evento en el bus de eventos.
.DESCRIPTION
    Crea un objeto de evento con metadatos y notifica a todos los suscriptores registrados.
    Soporta eventos de pipeline Use Case (usecase.*) para integración con el nuevo
    PipelineOrchestrator.
.PARAMETER EventBusKernel
    Instancia del bus de eventos.
.PARAMETER NombreEvento
    Nombre del evento (ej: "usecase.completed", "engine.started", "provider.connected").
.PARAMETER DatosEvento
    Hashtable con datos asociados al evento.
.PARAMETER OrigenEvento
    Origen del evento (Runtime, Engine, Provider, Pipeline).
#>
function Publish-HermesEnterpriseEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$EventBusKernel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreEvento,

        [Parameter(Mandatory = $false)]
        [hashtable]$DatosEvento = @{},

        [Parameter(Mandatory = $false)]
        [string]$OrigenEvento = ""
    )

    $Evento = [pscustomobject][ordered]@{
        Id            = [guid]::NewGuid().ToString()
        Nombre        = $NombreEvento
        Datos         = $DatosEvento
        Origen        = $OrigenEvento
        Timestamp     = (Get-Date).ToString("o")
    }

    $EventBusKernel.EventosPublicados++

    # Notificar suscriptores genéricos
    if ($EventBusKernel.Suscriptores.ContainsKey($NombreEvento)) {
        foreach ($manejador in $EventBusKernel.Suscriptores[$NombreEvento]) {
            try {
                & $manejador $Evento
            } catch {
                Write-Error "[EventBus] Error al ejecutar suscriptor para $NombreEvento : $($_.Exception.Message)"
            }
        }
    }

    # Registrar en seguimiento de pipeline si es evento de usecase
    if ($EventBusKernel.PipelineEvents.ContainsKey($NombreEvento)) {
        $null = $EventBusKernel.PipelineEvents[$NombreEvento].Add($Evento)
    }
    elseif ($NombreEvento -like 'usecase.*') {
        # Almacenar eventos de usecase no categorizados
        if (-not $EventBusKernel.PipelineEvents.ContainsKey($NombreEvento)) {
            $EventBusKernel.PipelineEvents[$NombreEvento] = [System.Collections.ArrayList]@()
        }
        $null = $EventBusKernel.PipelineEvents[$NombreEvento].Add($Evento)
    }

    return $Evento
}

<#
.SYNOPSIS
    Registra un suscriptor para un evento específico.
.PARAMETER EventBusKernel
    Instancia del bus de eventos.
.PARAMETER NombreEvento
    Nombre del evento al cual suscribirse.
.PARAMETER Manejador
    ScriptBlock que manejará el evento.
#>
function Subscribe-HermesEnterpriseEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$EventBusKernel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreEvento,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_ -is [scriptblock] })]
        [object]$Manejador
    )

    if (-not $EventBusKernel.Suscriptores.ContainsKey($NombreEvento)) {
        $EventBusKernel.Suscriptores[$NombreEvento] = [System.Collections.ArrayList]@()
    }

    $EventBusKernel.Suscriptores[$NombreEvento].Add($Manejador) | Out-Null
    return $true
}

<#
.SYNOPSIS
    Obtiene los eventos de pipeline almacenados en el bus.
.PARAMETER EventBusKernel
    Instancia del bus de eventos.
.PARAMETER UseCaseStatus
    Filtro opcional por estado del Use Case (completed, failed, pending, executing).
#>
function Get-PipelineEvents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$EventBusKernel,

        [Parameter(Mandatory = $false)]
        [ValidateSet('completed', 'failed', 'pending', 'executing')]
        [string]$UseCaseStatus = ''
    )

    if (-not [string]::IsNullOrEmpty($UseCaseStatus)) {
        $eventName = "usecase.$UseCaseStatus"
        if ($EventBusKernel.PipelineEvents.ContainsKey($eventName)) {
            return $EventBusKernel.PipelineEvents[$eventName]
        }
        return @()
    }

    # Si no hay filtro, devolver todos los eventos de pipeline
    $allEvents = [System.Collections.ArrayList]@()
    foreach ($eventList in $EventBusKernel.PipelineEvents.Values) {
        foreach ($evt in $eventList) {
            $null = $allEvents.Add($evt)
        }
    }
    return $allEvents
}

Export-ModuleMember -Function New-HermesEnterpriseEventBus, Publish-HermesEnterpriseEvent, Subscribe-HermesEnterpriseEvent, Get-PipelineEvents
