<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Bootstrap.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Orquesta la carga ordenada de componentes del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

$RutaDirectorioBootstrap = Split-Path -Parent $PSCommandPath
$RutaDirectorioMotor = Split-Path -Parent $RutaDirectorioBootstrap

. (Join-Path $RutaDirectorioMotor "kernel\KernelContext.ps1")
. (Join-Path $RutaDirectorioMotor "logging\Logger.ps1")
. (Join-Path $RutaDirectorioMotor "eventos\EventBus.ps1")
. (Join-Path $RutaDirectorioMotor "configuracion\ConfigurationManager.ps1")
. (Join-Path $RutaDirectorioMotor "registro\ModuleRegistry.ps1")
. (Join-Path $RutaDirectorioMotor "dependencias\DependencyInjection.ps1")
. (Join-Path $RutaDirectorioMotor "dependencias\ServiceLocator.ps1")
. (Join-Path $RutaDirectorioMotor "runtime\Runtime.ps1")
. (Join-Path $RutaDirectorioMotor "plugins\PluginManager.ps1")
. (Join-Path $RutaDirectorioMotor "kernel\KernelHealth.ps1")
. (Join-Path $RutaDirectorioMotor "kernel\KernelMetrics.ps1")
. (Join-Path $RutaDirectorioMotor "kernel\Kernel.ps1")

function Start-HermesEnterpriseBootstrap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$RutaRaizRepositorio,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$NombreEntorno = "Desarrollo"
    )

    $ContextoKernel = New-HermesEnterpriseKernelContext -RutaRaizRepositorio $RutaRaizRepositorio -NombreEntorno $NombreEntorno
    $KernelEnterprise = New-HermesEnterpriseKernel -ContextoKernel $ContextoKernel
    return Start-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise
}
