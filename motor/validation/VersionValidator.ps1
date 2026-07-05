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

function Test-HermesEnterpriseSemanticVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$VersionSemantica,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$NombreCampo = "Version"
    )

    # HERMES-ENTERPRISE usa SemVer estricto de tres segmentos numéricos para plugins.
    # PowerShell [version] acepta formatos abreviados como 1.2; por eso primero se valida
    # explícitamente Major.Minor.Patch y luego se delega el parseo tipado a [version].
    if ($VersionSemantica -notmatch '^\d+\.\d+\.\d+$') {
        return [pscustomobject][ordered]@{
            EsValida = $false
            Campo = $NombreCampo
            VersionOriginal = $VersionSemantica
            VersionTipada = $null
            Major = $null
            Minor = $null
            Patch = $null
            Mensaje = "El campo $NombreCampo debe usar formato SemVer Major.Minor.Patch. Valor recibido: $VersionSemantica"
        }
    }

    try {
        $VersionTipada = [version]$VersionSemantica
    }
    catch {
        return [pscustomobject][ordered]@{
            EsValida = $false
            Campo = $NombreCampo
            VersionOriginal = $VersionSemantica
            VersionTipada = $null
            Major = $null
            Minor = $null
            Patch = $null
            Mensaje = "El campo $NombreCampo no pudo convertirse a [version]. Valor recibido: $VersionSemantica"
        }
    }

    return [pscustomobject][ordered]@{
        EsValida = $true
        Campo = $NombreCampo
        VersionOriginal = $VersionSemantica
        VersionTipada = $VersionTipada
        Major = $VersionTipada.Major
        Minor = $VersionTipada.Minor
        Patch = $VersionTipada.Build
        Mensaje = "Compatible con formato SemVer Major.Minor.Patch"
    }
}

function Test-HermesEnterprisePluginKernelVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$VersionKernelActual,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$VersionKernelMinimaRequerida
    )

    $ResultadoVersionActual = Test-HermesEnterpriseSemanticVersion -VersionSemantica $VersionKernelActual -NombreCampo "VersionKernelActual"
    $ResultadoVersionMinima = Test-HermesEnterpriseSemanticVersion -VersionSemantica $VersionKernelMinimaRequerida -NombreCampo "VersionKernelMinimaRequerida"

    if (-not $ResultadoVersionActual.EsValida) {
        return [pscustomobject][ordered]@{
            EsCompatible = $false
            VersionKernelActual = $VersionKernelActual
            VersionKernelMinimaRequerida = $VersionKernelMinimaRequerida
            Mensaje = $ResultadoVersionActual.Mensaje
        }
    }

    if (-not $ResultadoVersionMinima.EsValida) {
        return [pscustomobject][ordered]@{
            EsCompatible = $false
            VersionKernelActual = $VersionKernelActual
            VersionKernelMinimaRequerida = $VersionKernelMinimaRequerida
            Mensaje = $ResultadoVersionMinima.Mensaje
        }
    }

    $EsCompatible = ($ResultadoVersionActual.VersionTipada -ge $ResultadoVersionMinima.VersionTipada)

    return [pscustomobject][ordered]@{
        EsCompatible = $EsCompatible
        VersionKernelActual = $VersionKernelActual
        VersionKernelMinimaRequerida = $VersionKernelMinimaRequerida
        Mensaje = if ($EsCompatible) { "Compatible" } else { "Plugin requiere Kernel $VersionKernelMinimaRequerida o superior." }
    }
}
