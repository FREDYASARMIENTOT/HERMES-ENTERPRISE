<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : TelemetryContracts.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Contratos de telemetría para el Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseTelemetryEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TipoEvento,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreComponente,

        [Parameter(Mandatory = $false)]
        [hashtable]$DatosEvento = @{},

        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = ''
    )

    if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
        $CorrelationId = [guid]::NewGuid().ToString()
    }

    return [pscustomobject][ordered]@{
        Timestamp        = (Get-Date).ToString('o')
        TipoEvento       = $TipoEvento
        Componente       = $NombreComponente
        CorrelationId    = $CorrelationId
        Datos            = $DatosEvento
        VersionContrato  = '1.0.0'
    }
}

function New-HermesEnterpriseTelemetryMetric {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreMetrica,

        [Parameter(Mandatory = $true)]
        [double]$ValorMetrica,

        [Parameter(Mandatory = $false)]
        [hashtable]$Etiquetas = @{},

        [Parameter(Mandatory = $false)]
        [ValidateSet('Count', 'Gauge', 'Histogram', 'Summary')]
        [string]$TipoMetrica = 'Gauge',

        [Parameter(Mandatory = $false)]
        [string]$Unidad = 'count'
    )

    return [pscustomobject][ordered]@{
        Timestamp       = (Get-Date).ToString('o')
        Nombre          = $NombreMetrica
        Valor           = $ValorMetrica
        Tipo            = $TipoMetrica
        Unidad          = $Unidad
        Etiquetas       = $Etiquetas
        VersionContrato = '1.0.0'
    }
}

Export-ModuleMember -Function New-HermesEnterpriseTelemetryEvent, New-HermesEnterpriseTelemetryMetric