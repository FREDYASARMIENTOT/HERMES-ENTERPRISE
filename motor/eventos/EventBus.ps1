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

function New-HermesEnterpriseEventBus {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Suscriptores = @{}
        EventosPublicados = 0
    }
}

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

    if ($EventBusKernel.Suscriptores.ContainsKey($NombreEvento)) {
        foreach ($manejador in $EventBusKernel.Suscriptores[$NombreEvento]) {
            try {
                & $manejador $Evento
            } catch {
                Write-Error "[EventBus] Error al ejecutar suscriptor para $NombreEvento : $($_.Exception.Message)"
            }
        }
    }

    return $Evento
}

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
}