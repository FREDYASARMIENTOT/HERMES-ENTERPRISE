<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : PluginManager.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Coordina descubrimiento, validación, orden de carga, ciclo de vida y registro de proveedores
    para plugins desacoplados de HERMES-ENTERPRISE.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioPluginManager = Split-Path -Parent $PSCommandPath
$RutaDirectorioMotor = Split-Path -Parent $RutaDirectorioPluginManager
. (Join-Path $RutaDirectorioMotor "manifest\ManifestLoader.ps1")
. (Join-Path $RutaDirectorioMotor "discovery\PluginDiscovery.ps1")
. (Join-Path $RutaDirectorioMotor "dependencygraph\DependencyResolver.ps1")
. (Join-Path $RutaDirectorioMotor "validation\VersionValidator.ps1")
. (Join-Path $RutaDirectorioMotor "contracts\PluginContracts.ps1")
. (Join-Path $RutaDirectorioMotor "providers\ProviderRegistry.ps1")
. (Join-Path $RutaDirectorioMotor "plugins\PluginLoader.ps1")
. (Join-Path $RutaDirectorioMotor "lifecycle\LifecycleManager.ps1")

function New-HermesEnterprisePluginManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$RutaRaizRepositorio,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$VersionKernelActual = "0.4.0"
    )

    return [pscustomobject][ordered]@{
        RutaRaizRepositorio = $RutaRaizRepositorio
        RutaDirectorioPlugins = Join-Path $RutaRaizRepositorio "plugins"
        VersionKernelActual = $VersionKernelActual
        PluginsCargados = @{}
        ProveedorRegistry = New-HermesEnterpriseProviderRegistry
    }
}

function Initialize-HermesEnterprisePlugins {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$AdministradorPlugins)

    $PluginsDescubiertos = Find-HermesEnterprisePlugins -RutaDirectorioPlugins $AdministradorPlugins.RutaDirectorioPlugins
    $PluginsOrdenados = Resolve-HermesEnterprisePluginLoadOrder -PluginsDescubiertos $PluginsDescubiertos

    foreach ($PluginDescubierto in $PluginsOrdenados) {
        $ResultadoVersion = Test-HermesEnterprisePluginKernelVersion -VersionKernelActual $AdministradorPlugins.VersionKernelActual -VersionKernelMinimaRequerida $PluginDescubierto.Manifest.KernelMinimo
        if (-not $ResultadoVersion.EsCompatible) { throw $ResultadoVersion.Mensaje }

        Import-HermesEnterprisePluginScript -RutaScriptPlugin $PluginDescubierto.RutaScriptPlugin | Out-Null
        $ResultadoContrato = Test-HermesEnterprisePluginContract -NombrePlugin $PluginDescubierto.Manifest.Nombre
        if (-not $ResultadoContrato.EsValido) { throw "Plugin $($PluginDescubierto.Manifest.Nombre) no cumple contrato: $($ResultadoContrato.FuncionesFaltantes -join ', ')" }

        $ContextoPlugin = Invoke-HermesEnterprisePluginLifecycle -PluginDescubierto $PluginDescubierto -MantenerIniciado
        $AdministradorPlugins.PluginsCargados[$PluginDescubierto.Manifest.Nombre] = $ContextoPlugin

        foreach ($NombreProveedor in $ContextoPlugin.ProveedoresRegistrados.Keys) {
            Register-HermesEnterpriseProvider -ProveedorRegistry $AdministradorPlugins.ProveedorRegistry -NombreProveedor $NombreProveedor -Proveedor $ContextoPlugin.ProveedoresRegistrados[$NombreProveedor] | Out-Null
        }
    }

    return $AdministradorPlugins
}

function Get-HermesEnterprisePlugin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorPlugins,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombrePlugin
    )

    if ($AdministradorPlugins.PluginsCargados.ContainsKey($NombrePlugin)) {
        return $AdministradorPlugins.PluginsCargados[$NombrePlugin]
    }
    return $null
}
