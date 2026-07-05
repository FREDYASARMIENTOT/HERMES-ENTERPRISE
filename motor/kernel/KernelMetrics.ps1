<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : KernelMetrics.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Implementa métricas internas mínimas del Kernel Enterprise usando exclusivamente Logger
    Enterprise como mecanismo de almacenamiento inicial.

Características:
    - Cero dependencias externas.
    - No introduce proveedores de observabilidad externos.
    - Mantiene compatibilidad con el Logger JSONL existente.
    - Permite medir hora inicio, hora fin, duración, errores, advertencias, memoria y estado.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseKernelMetricsCollector {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        NombreComponente = "KernelMetrics"
        VersionComponente = "1.0.0"
        FechaCreacion = (Get-Date).ToString("o")
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

        [Parameter(Mandatory = $true)]
        [datetime]$HoraFin,

        [Parameter(Mandatory = $false)]
        [int]$CantidadErrores = 0,

        [Parameter(Mandatory = $false)]
        [int]$CantidadAdvertencias = 0,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Estado = "Operativo"
    )

    if ($null -eq $KernelEnterprise.Logger) {
        throw "No se puede registrar métrica porque el Kernel no tiene Logger Enterprise operativo."
    }

    $TiempoEjecucionMilisegundos = [Math]::Max(0, [int](New-TimeSpan -Start $HoraInicio -End $HoraFin).TotalMilliseconds)
    $UsoMemoriaBytes = [System.GC]::GetTotalMemory($false)

    $DatosMetricaKernel = [ordered]@{
        TipoRegistro = "MetricaKernel"
        NombreComponente = $NombreComponente
        NombreOperacion = $NombreOperacion
        HoraInicio = $HoraInicio.ToString("o")
        HoraFin = $HoraFin.ToString("o")
        TiempoEjecucionMilisegundos = $TiempoEjecucionMilisegundos
        CantidadErrores = $CantidadErrores
        CantidadAdvertencias = $CantidadAdvertencias
        UsoMemoriaBytes = $UsoMemoriaBytes
        Estado = $Estado
    }

    Write-HermesEnterpriseLogEvent `
        -LoggerKernel $KernelEnterprise.Logger `
        -Nivel "INFO" `
        -Mensaje "Métrica interna del Kernel Enterprise" `
        -DatosEvento $DatosMetricaKernel | Out-Null

    return [pscustomobject]$DatosMetricaKernel
}
