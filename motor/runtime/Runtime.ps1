<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Runtime.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Runtime del Kernel Enterprise — ciclo de vida y ejecución de componentes.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$EventBusKernel
    )

    return [pscustomobject][ordered]@{
        EventBus        = $EventBusKernel
        EstadoRuntime   = "Creado"
        Componentes     = @()
        HoraInicio      = $null
    }
}

function Start-HermesEnterpriseRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$RuntimeKernel
    )

    if ($RuntimeKernel.EstadoRuntime -eq "Iniciado") {
        return $RuntimeKernel
    }

    $RuntimeKernel.HoraInicio = Get-Date
    $RuntimeKernel.EstadoRuntime = "Iniciado"

    return $RuntimeKernel
}

function Stop-HermesEnterpriseRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$RuntimeKernel
    )

    if ($RuntimeKernel.EstadoRuntime -ne "Detenido") {
        $RuntimeKernel.EstadoRuntime = "Detenido"
    }

    return $RuntimeKernel
}

function Register-HermesEnterpriseRuntimeComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$RuntimeKernel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreComponente,

        [Parameter(Mandatory = $false)]
        [hashtable]$ConfiguracionComponente = @{}
    )

    $EntradaComponente = [pscustomobject][ordered]@{
        Nombre       = $NombreComponente
        Configuracion = $ConfiguracionComponente
        FechaRegistro = (Get-Date).ToString("o")
    }

    $listaComponentes = [System.Collections.ArrayList]@($RuntimeKernel.Componentes)
    $listaComponentes.Add($EntradaComponente) | Out-Null
    $RuntimeKernel.Componentes = $listaComponentes.ToArray()

    return $EntradaComponente
}

function New-HermesEnterpriseKernelHealthMonitor {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Estado        = "Saludable"
        UltimaVerificacion = $null
        Errores       = @()
    }
}

function New-HermesEnterpriseKernelMetricsCollector {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Metricas = @{}
        ContadorOperaciones = 0
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

        [Parameter(Mandatory = $true)]
        [int]$CantidadErrores,

        [Parameter(Mandatory = $true)]
        [int]$CantidadAdvertencias,

        [Parameter(Mandatory = $true)]
        [string]$Estado
    )

    $Duracion = ($HoraFin - $HoraInicio).TotalMilliseconds

    $Metrica = [pscustomobject][ordered]@{
        Componente      = $NombreComponente
        Operacion       = $NombreOperacion
        DuracionMs      = [math]::Round($Duracion, 2)
        HoraInicio      = $HoraInicio.ToString("o")
        HoraFin         = $HoraFin.ToString("o")
        Errores         = $CantidadErrores
        Advertencias    = $CantidadAdvertencias
        Estado          = $Estado
    }

    if ($null -ne $KernelEnterprise.Error) {
        $KernelEnterprise = $null
    }

    # Devolver métrica por si se necesita registrar externamente
    return $Metrica
}