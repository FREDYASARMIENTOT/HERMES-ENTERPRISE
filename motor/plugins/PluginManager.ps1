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
. (Join-Path $RutaDirectorioMotor "lifecycle\PluginFaultPolicy.ps1")
. (Join-Path $RutaDirectorioMotor "lifecycle\LifecycleManager.ps1")

function New-HermesEnterprisePluginManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$RutaRaizRepositorio,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$VersionKernelActual = "0.4.0",
        [Parameter(Mandatory = $false)][ValidateSet("Continue", "Disable", "Abort")][string]$AccionFallaPlugin = "Continue"
    )

    return [pscustomobject][ordered]@{
        RutaRaizRepositorio = $RutaRaizRepositorio
        RutaDirectorioPlugins = Join-Path $RutaRaizRepositorio "plugins"
        VersionKernelActual = $VersionKernelActual
        PoliticaFallaPlugin = New-HermesEnterprisePluginFaultPolicy -AccionPorDefecto $AccionFallaPlugin
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

        $ContextoPlugin = Invoke-HermesEnterprisePluginLifecycle -PluginDescubierto $PluginDescubierto -MantenerIniciado -PoliticaFallaPlugin $AdministradorPlugins.PoliticaFallaPlugin
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

function Get-HermesEnterprisePluginObservability {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$AdministradorPlugins)

    $PluginsObservados = New-Object System.Collections.Generic.List[object]
    foreach ($NombrePlugin in $AdministradorPlugins.PluginsCargados.Keys) {
        $ContextoPlugin = $AdministradorPlugins.PluginsCargados[$NombrePlugin]
        $PluginsObservados.Add([pscustomobject][ordered]@{
            NombrePlugin = $ContextoPlugin.NombrePlugin
            EstadoActual = $ContextoPlugin.EstadoActual
            EstadoSandbox = $ContextoPlugin.EstadoSandbox
            AccionFallaPlugin = $ContextoPlugin.AccionFallaPlugin
            PluginDeshabilitado = [bool]$ContextoPlugin.PluginDeshabilitado
            HoraInicio = $ContextoPlugin.HoraInicio
            HoraFin = $ContextoPlugin.HoraFin
            DuracionMilisegundos = $ContextoPlugin.DuracionMilisegundos
            ErroresSandbox = $ContextoPlugin.ErroresSandbox.Count
        }) | Out-Null
    }

    $Plugins = $PluginsObservados.ToArray()
    $PluginsFaulted = @($Plugins | Where-Object { $_.EstadoActual -eq "Faulted" })
    $PluginsDeshabilitados = @($Plugins | Where-Object { $_.PluginDeshabilitado })

    return [pscustomobject][ordered]@{
        TotalPluginsCargados = $Plugins.Count
        TotalPluginsFaulted = $PluginsFaulted.Count
        TotalPluginsDeshabilitados = $PluginsDeshabilitados.Count
        AccionFallaPlugin = $AdministradorPlugins.PoliticaFallaPlugin.AccionPorDefecto
        Plugins = $Plugins
    }
}

function Get-HermesEnterprisePluginFrameworkMaturityReport {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$AdministradorPlugins)

    $ObservabilidadPlugins = Get-HermesEnterprisePluginObservability -AdministradorPlugins $AdministradorPlugins
    $EsAptoParaProvidersReales = (
        $ObservabilidadPlugins.TotalPluginsCargados -ge 1 -and
        $ObservabilidadPlugins.TotalPluginsFaulted -eq 0 -and
        $ObservabilidadPlugins.TotalPluginsDeshabilitados -eq 0
    )

    return [pscustomobject][ordered]@{
        NombreComponente = "Enterprise Plugin Framework"
        EstadoMadurez = if ($EsAptoParaProvidersReales) { "AptoParaProveedoresReales" } else { "RequiereEstabilizacion" }
        VersionKernelActual = $AdministradorPlugins.VersionKernelActual
        TotalPluginsCargados = $ObservabilidadPlugins.TotalPluginsCargados
        TotalPluginsFaulted = $ObservabilidadPlugins.TotalPluginsFaulted
        TotalPluginsDeshabilitados = $ObservabilidadPlugins.TotalPluginsDeshabilitados
        AccionFallaPlugin = $ObservabilidadPlugins.AccionFallaPlugin
        Capacidades = [pscustomobject][ordered]@{
            Discovery = $true
            Manifest = $true
            SemVer = $true
            Lifecycle = $true
            SandboxV1 = $true
            FaultPolicy = $true
            Observability = $true
            ProviderRegistry = $true
        }
        LimitesIncluidos = [pscustomobject][ordered]@{
            ProvidersReales = $false
            AzureFoundry = $false
            MCP = $false
            IA = $false
            RecoveryAutomatico = $false
        }
        PruebasRecomendadas = @(
            "pruebas/unitarias/Test-PluginManager.ps1",
            "pruebas/unitarias/Test-PluginObservability.ps1",
            "pruebas/unitarias/Test-PluginFrameworkMaturity.ps1",
            "scripts/Test-HermesEnterprise.ps1"
        )
        ProximaFaseRecomendada = "IntegracionControladaDeProvidersReales"
    }
}
