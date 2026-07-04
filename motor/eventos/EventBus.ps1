<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EventBus.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Implementa un bus de eventos en memoria para comunicación desacoplada entre componentes del
    Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseEventBus {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Suscripciones = @{}
        EventosPublicados = New-Object System.Collections.Generic.List[object]
    }
}

function Subscribe-HermesEnterpriseEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$EventBusKernel,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreEvento,
        [Parameter(Mandatory = $true)][scriptblock]$AccionEvento
    )

    # Crear la lista de suscriptores solo una vez por nombre de evento.
    if (-not $EventBusKernel.Suscripciones.ContainsKey($NombreEvento)) {
        $EventBusKernel.Suscripciones[$NombreEvento] = New-Object System.Collections.Generic.List[scriptblock]
    }

    $EventBusKernel.Suscripciones[$NombreEvento].Add($AccionEvento)
}

function Publish-HermesEnterpriseEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$EventBusKernel,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreEvento,
        [Parameter(Mandatory = $false)][hashtable]$DatosEvento = @{}
    )

    $EventoPublicado = [pscustomobject][ordered]@{
        NombreEvento = $NombreEvento
        DatosEvento  = $DatosEvento
        FechaEvento  = (Get-Date).ToString("o")
    }

    $EventBusKernel.EventosPublicados.Add($EventoPublicado)

    # Entregar el evento únicamente a suscriptores registrados, sin acoplar productores y consumidores.
    if ($EventBusKernel.Suscripciones.ContainsKey($NombreEvento)) {
        foreach ($AccionEvento in $EventBusKernel.Suscripciones[$NombreEvento]) {
            & $AccionEvento $EventoPublicado
        }
    }

    return $EventoPublicado
}
