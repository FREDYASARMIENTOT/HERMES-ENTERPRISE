<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AuditTrail.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Registro de auditoría del Kernel Enterprise — seguimiento de cambios y decisiones.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseAuditTrail {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Entradas   = [System.Collections.ArrayList]@()
        TotalEntradas = 0
    }
}

function Write-HermesEnterpriseAuditEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Auditoria,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Accion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Componente,

        [Parameter(Mandatory = $false)]
        [string]$Usuario = $env:USERNAME,

        [Parameter(Mandatory = $false)]
        [string]$Descripcion = '',

        [Parameter(Mandatory = $false)]
        [hashtable]$DetallesExtra = @{},

        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = ''
    )

    if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
        $CorrelationId = [guid]::NewGuid().ToString()
    }

    $entry = [pscustomobject][ordered]@{
        Timestamp     = (Get-Date).ToString('o')
        Accion        = $Accion
        Componente    = $Componente
        Usuario       = $Usuario
        Descripcion   = $Descripcion
        Detalles      = $DetallesExtra
        CorrelationId = $CorrelationId
    }

    $null = $Auditoria.Entradas.Add($entry)
    $Auditoria.TotalEntradas++

    return $entry
}

function Get-HermesEnterpriseAuditReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Auditoria,

        [Parameter(Mandatory = $false)]
        [string]$ComponenteFilter = '',

        [Parameter(Mandatory = $false)]
        [string]$AccionFilter = '',

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 100
    )

    $results = $Auditoria.Entradas

    if (-not [string]::IsNullOrWhiteSpace($ComponenteFilter)) {
        $results = $results | Where-Object { $_.Componente -eq $ComponenteFilter }
    }

    if (-not [string]::IsNullOrWhiteSpace($AccionFilter)) {
        $results = $results | Where-Object { $_.Accion -eq $AccionFilter }
    }

    $results = $results | Select-Object -Last $MaxResults

    return [pscustomobject][ordered]@{
        TotalEntradas  = $Auditoria.TotalEntradas
        FiltroAplicado = ($ComponenteFilter -ne '' -or $AccionFilter -ne '')
        Resultados     = $results
    }
}

Export-ModuleMember -Function New-HermesEnterpriseAuditTrail, Write-HermesEnterpriseAuditEntry, Get-HermesEnterpriseAuditReport