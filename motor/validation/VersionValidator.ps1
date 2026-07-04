<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : VersionValidator.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida compatibilidad SemVer básica entre plugins y Kernel Enterprise.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Test-HermesEnterprisePluginKernelVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$VersionKernelActual,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$VersionKernelMinimaRequerida
    )

    $VersionActual = [version]$VersionKernelActual
    $VersionMinima = [version]$VersionKernelMinimaRequerida
    $EsCompatible = ($VersionActual -ge $VersionMinima)

    return [pscustomobject][ordered]@{
        EsCompatible = $EsCompatible
        VersionKernelActual = $VersionKernelActual
        VersionKernelMinimaRequerida = $VersionKernelMinimaRequerida
        Mensaje = if ($EsCompatible) { "Compatible" } else { "Plugin requiere Kernel $VersionKernelMinimaRequerida o superior." }
    }
}
