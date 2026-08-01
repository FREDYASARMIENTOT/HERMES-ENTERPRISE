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
. (Join-Path $RutaDirectorioMotor "kernel\Core\EventBus.ps1")
. (Join-Path $RutaDirectorioMotor "kernel\Core\ComponentRegistry.ps1")
. (Join-Path $RutaDirectorioMotor "kernel\Core\ServiceContainer.ps1")
. (Join-Path $RutaDirectorioMotor "kernel\Core\KernelHost.ps1")
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
