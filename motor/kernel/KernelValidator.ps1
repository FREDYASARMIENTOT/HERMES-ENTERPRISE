<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : KernelValidator.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Ejecuta validaciones estructurales mínimas sobre el Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function Test-HermesEnterpriseKernel {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$KernelEnterprise)

    $ErroresValidacionKernel = New-Object System.Collections.Generic.List[string]

    if ($KernelEnterprise.EstadoKernel -ne "Iniciado") { $ErroresValidacionKernel.Add("El Kernel no está iniciado.") }
    if ($null -eq $KernelEnterprise.Runtime) { $ErroresValidacionKernel.Add("Runtime no inicializado.") }
    if ($null -eq $KernelEnterprise.Logger) { $ErroresValidacionKernel.Add("Logger no inicializado.") }
    if ($null -eq $KernelEnterprise.EventBus) { $ErroresValidacionKernel.Add("EventBus no inicializado.") }
    if ($null -eq $KernelEnterprise.RegistroModulos) { $ErroresValidacionKernel.Add("ModuleRegistry no inicializado.") }
    if ($null -eq $KernelEnterprise.PluginManager) { $ErroresValidacionKernel.Add("PluginManager no inicializado.") }

    return [pscustomobject][ordered]@{
        EsValido = ($ErroresValidacionKernel.Count -eq 0)
        Errores = @($ErroresValidacionKernel)
    }
}
