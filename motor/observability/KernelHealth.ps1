<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : KernelHealth.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Monitor de salud del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseKernelHealthMonitor {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Chequeos = [System.Collections.ArrayList]@()
        EstadoSalud = 'Healthy'
        UltimaVerificacion = $null
        ErroresActivos = @()
    }
}

function Test-HermesEnterpriseKernelHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$MonitorSalud,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$KernelEnterprise
    )

    $resultados = [System.Collections.ArrayList]@()

    # Verificar subsistemas principales
    $subsistemas = @(
        @{ Nombre = 'ConfigurationManager'; Objeto = $KernelEnterprise.AdministradorConfiguracion },
        @{ Nombre = 'ModuleRegistry';      Objeto = $KernelEnterprise.RegistroModulos },
        @{ Nombre = 'Logger';              Objeto = $KernelEnterprise.Logger },
        @{ Nombre = 'EventBus';            Objeto = $KernelEnterprise.EventBus },
        @{ Nombre = 'Runtime';             Objeto = $KernelEnterprise.Runtime },
        @{ Nombre = 'PluginManager';       Objeto = $KernelEnterprise.PluginManager },
        @{ Nombre = 'DependencyContainer'; Objeto = $KernelEnterprise.ContenedorDependencias }
    )

    foreach ($sub in $subsistemas) {
        $estado = if ($null -ne $sub.Objeto) { 'Healthy' } else { 'Unhealthy' }
        $null = $resultados.Add([pscustomobject][ordered]@{
            Subsistema = $sub.Nombre
            Estado     = $estado
            CheckTime  = (Get-Date).ToString('o')
        })
    }

    $MonitorSalud.Chequeos = $resultados
    $MonitorSalud.UltimaVerificacion = Get-Date

    $unhealthyCount = ($resultados | Where-Object { $_.Estado -eq 'Unhealthy' }).Count
    $MonitorSalud.EstadoSalud = if ($unhealthyCount -gt 0) { 'Degraded' } else { 'Healthy' }
    $MonitorSalud.ErroresActivos = $KernelEnterprise.ErroresArranque

    return $MonitorSalud
}

Export-ModuleMember -Function New-HermesEnterpriseKernelHealthMonitor, Test-HermesEnterpriseKernelHealth