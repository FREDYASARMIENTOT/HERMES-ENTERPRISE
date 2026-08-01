<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : KernelMetrics.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Colector y registro de métricas operacionales del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseKernelMetricsCollector {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Metricas = [System.Collections.ArrayList]@()
        EventosRegistrados = 0
    }
}

function Write-HermesEnterpriseKernelMetric {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$KernelEnterprise,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreComponente,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreOperacion,

        [Parameter(Mandatory = $true)]
        [datetime]$HoraInicio,

        [Parameter(Mandatory = $false)]
        [datetime]$HoraFin,

        [Parameter(Mandatory = $false)]
        [int]$CantidadErrores = 0,

        [Parameter(Mandatory = $false)]
        [int]$CantidadAdvertencias = 0,

        [Parameter(Mandatory = $false)]
        [string]$Estado = 'OK'
    )
    $metric = [pscustomobject][ordered]@{
        Timestamp   = (Get-Date).ToString('o')
        Componente  = $NombreComponente
        Operacion   = $NombreOperacion
        HoraInicio  = $HoraInicio.ToString('o')
        HoraFin     = $HoraFin.ToString('o')
        DuracionMs  = [math]::Round(($HoraFin - $HoraInicio).TotalMilliseconds, 2)
        Errores     = $CantidadErrores
        Advertencias = $CantidadAdvertencias
        Estado      = $Estado
    }

    # Resolver el colector de métricas del contenedor de dependencias
    if ($null -ne $KernelEnterprise.ContenedorDependencias) {
        try {
            $metricsCollector = Resolve-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio 'KernelMetrics'
            $null = $metricsCollector.Metricas.Add($metric)
            $metricsCollector.EventosRegistrados++
        } catch {
            Write-Debug "KernelMetrics collector not registered yet: $_"
        }
    }

    return $metric
}

function Get-HermesEnterpriseKernelMetricsReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$ColectorMetricas
    )

    return [pscustomobject][ordered]@{
        TotalMetricas       = $ColectorMetricas.Metricas.Count
        EventosRegistrados  = $ColectorMetricas.EventosRegistrados
        UltimasMetricas     = $ColectorMetricas.Metricas | Select-Object -Last 20
    }
}

Export-ModuleMember -Function New-HermesEnterpriseKernelMetricsCollector, Write-HermesEnterpriseKernelMetric, Get-HermesEnterpriseKernelMetricsReport