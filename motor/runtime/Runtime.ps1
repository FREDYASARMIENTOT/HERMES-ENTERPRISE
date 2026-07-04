<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Runtime.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Controla el ciclo de vida básico del Runtime del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseRuntime {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$EventBusKernel)

    return [pscustomobject][ordered]@{
        EstadoRuntime = "Creado"
        EventBusKernel = $EventBusKernel
        FechaInicio = $null
        FechaDetencion = $null
    }
}

function Start-HermesEnterpriseRuntime {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$RuntimeKernel)

    # Iniciar el Runtime es idempotente: si ya está en ejecución, se conserva el estado.
    if ($RuntimeKernel.EstadoRuntime -ne "EnEjecucion") {
        $RuntimeKernel.EstadoRuntime = "EnEjecucion"
        $RuntimeKernel.FechaInicio = (Get-Date).ToString("o")
        Publish-HermesEnterpriseEvent -EventBusKernel $RuntimeKernel.EventBusKernel -NombreEvento "Runtime.Iniciado" -DatosEvento @{} | Out-Null
    }

    return $RuntimeKernel
}

function Stop-HermesEnterpriseRuntime {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$RuntimeKernel)

    if ($RuntimeKernel.EstadoRuntime -ne "Detenido") {
        $RuntimeKernel.EstadoRuntime = "Detenido"
        $RuntimeKernel.FechaDetencion = (Get-Date).ToString("o")
        Publish-HermesEnterpriseEvent -EventBusKernel $RuntimeKernel.EventBusKernel -NombreEvento "Runtime.Detenido" -DatosEvento @{} | Out-Null
    }

    return $RuntimeKernel
}
