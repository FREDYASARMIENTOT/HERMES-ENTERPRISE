<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : SessionTelemetry.ps1
Propósito:
    Registra actividad y eventos en el historial de una sesión HERMES Enterprise.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Write-HermesEnterpriseSessionEvent {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$true)][psobject]$SessionDescriptor,
        [Parameter(Mandatory=$true)][string]$Operacion,
        [Parameter(Mandatory=$false)][string]$Mensaje = "",
        [Parameter(Mandatory=$false)][hashtable]$Metadatos = @{}
    )
    $Evento = [pscustomobject][ordered]@{
        Fecha = (Get-Date).ToString("o")
        Operacion = $Operacion
        Mensaje = $Mensaje
        Metadatos = $Metadatos
    }
    if ($null -eq $SessionDescriptor.Historial) { $SessionDescriptor.Historial = New-Object System.Collections.Generic.List[psobject] }
    $SessionDescriptor.Historial.Add($Evento)
    $SessionDescriptor.UltimaActividad = Get-Date
    return $Evento
}

function Get-HermesEnterpriseSessionTelemetrySummary {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][psobject]$SessionDescriptor)
    $Total = if ($null -eq $SessionDescriptor.Historial) { 0 } else { $SessionDescriptor.Historial.Count }
    return [pscustomobject][ordered]@{
        IdentificadorSesion = $SessionDescriptor.IdentificadorSesion
        TotalEventos = $Total
        UltimaActividad = $SessionDescriptor.UltimaActividad
        Operaciones = if ($Total -gt 0) { $SessionDescriptor.Historial | Group-Object -Property Operacion | Select-Object -Property Name, Count } else { @() }
    }
}
