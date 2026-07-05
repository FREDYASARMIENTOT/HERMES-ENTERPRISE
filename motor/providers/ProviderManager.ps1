<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderManager.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Administra registro, validación local, health, inicialización, estado y apagado de providers
    sin realizar llamadas HTTP ni integrar proveedores reales.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioProviderManager = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioProviderManager "ProviderRegistry.ps1")

function New-HermesEnterpriseProviderManager {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        ProviderRegistry = New-HermesEnterpriseProviderRegistry
        ProvidersInicializados = @{}
    }
}

function Register-HermesEnterpriseManagedProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorProviders,
        [Parameter(Mandatory = $true)][psobject]$ContextoProvider
    )

    Register-HermesEnterpriseProvider `
        -ProveedorRegistry $AdministradorProviders.ProviderRegistry `
        -NombreProveedor $ContextoProvider.NombreProvider `
        -Proveedor $ContextoProvider | Out-Null

    return $ContextoProvider
}

function Initialize-HermesEnterpriseProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorProviders,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider
    )

    $ContextoProvider = Get-HermesEnterpriseProvider -ProveedorRegistry $AdministradorProviders.ProviderRegistry -NombreProveedor $NombreProvider
    if ($null -eq $ContextoProvider) { throw "Provider no registrado: $NombreProvider" }

    $ResultadoValidacion = Test-HermesEnterpriseManagedProviderConfiguration -AdministradorProviders $AdministradorProviders -NombreProvider $NombreProvider
    if (-not $ResultadoValidacion.EsValida) {
        $ContextoProvider.Estado = "ConfigurationInvalid"
        $ContextoProvider.Health.Estado = "Unhealthy"
        $ContextoProvider.Health.UltimaVerificacion = (Get-Date).ToString("o")
        $ContextoProvider.Health.Mensaje = $ResultadoValidacion.Errores -join "; "
        throw "Configuracion invalida para provider ${NombreProvider}: $($ResultadoValidacion.Errores -join '; ')"
    }

    $NombreFuncionInicializacion = "Initialize-$NombreProvider"
    if (-not (Get-Command -Name $NombreFuncionInicializacion -ErrorAction SilentlyContinue)) {
        throw "No existe la función requerida del provider: $NombreFuncionInicializacion"
    }

    $ContextoInicializado = & $NombreFuncionInicializacion -ContextoProvider $ContextoProvider
    $AdministradorProviders.ProvidersInicializados[$NombreProvider] = $ContextoInicializado
    return $ContextoInicializado
}

function Stop-HermesEnterpriseProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorProviders,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider
    )

    $ContextoProvider = Get-HermesEnterpriseProvider -ProveedorRegistry $AdministradorProviders.ProviderRegistry -NombreProveedor $NombreProvider
    if ($null -eq $ContextoProvider) { throw "Provider no registrado: $NombreProvider" }

    $NombreFuncionDesconexion = "Disconnect-$NombreProvider"
    if (-not (Get-Command -Name $NombreFuncionDesconexion -ErrorAction SilentlyContinue)) {
        throw "No existe la función requerida del provider: $NombreFuncionDesconexion"
    }

    $ContextoDetenido = & $NombreFuncionDesconexion -ContextoProvider $ContextoProvider
    $AdministradorProviders.ProvidersInicializados.Remove($NombreProvider) | Out-Null
    return $ContextoDetenido
}

function Get-HermesEnterpriseProviderState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorProviders,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider
    )

    $ContextoProvider = Get-HermesEnterpriseProvider -ProveedorRegistry $AdministradorProviders.ProviderRegistry -NombreProveedor $NombreProvider
    if ($null -eq $ContextoProvider) { return $null }
    return $ContextoProvider.Estado
}

function Test-HermesEnterpriseManagedProviderConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorProviders,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider
    )

    $ContextoProvider = Get-HermesEnterpriseProvider -ProveedorRegistry $AdministradorProviders.ProviderRegistry -NombreProveedor $NombreProvider
    if ($null -eq $ContextoProvider) { throw "Provider no registrado: $NombreProvider" }

    $NombreFuncionValidacion = "ValidateConfiguration-$NombreProvider"
    if (-not (Get-Command -Name $NombreFuncionValidacion -ErrorAction SilentlyContinue)) {
        throw "No existe la función requerida del provider: $NombreFuncionValidacion"
    }

    $ResultadoValidacion = & $NombreFuncionValidacion -ContextoProvider $ContextoProvider
    if ($ResultadoValidacion.EsValida) {
        $ContextoProvider.Health.Estado = "Healthy"
        $ContextoProvider.Health.Mensaje = "Configuracion validada localmente."
    }
    else {
        $ContextoProvider.Estado = "ConfigurationInvalid"
        $ContextoProvider.Health.Estado = "Unhealthy"
        $ContextoProvider.Health.Mensaje = $ResultadoValidacion.Errores -join "; "
    }

    $ContextoProvider.Health.UltimaVerificacion = (Get-Date).ToString("o")
    return $ResultadoValidacion
}

function Get-HermesEnterpriseProviderHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorProviders,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider
    )

    $ContextoProvider = Get-HermesEnterpriseProvider -ProveedorRegistry $AdministradorProviders.ProviderRegistry -NombreProveedor $NombreProvider
    if ($null -eq $ContextoProvider) { return $null }
    return $ContextoProvider.Health
}

function Get-HermesEnterpriseProviderObservability {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$AdministradorProviders)

    $ProvidersObservados = New-Object System.Collections.Generic.List[object]
    foreach ($NombreProvider in $AdministradorProviders.ProviderRegistry.ProveedoresRegistrados.Keys) {
        $ContextoProvider = $AdministradorProviders.ProviderRegistry.ProveedoresRegistrados[$NombreProvider]
        $ProvidersObservados.Add([pscustomobject][ordered]@{
            NombreProvider = $ContextoProvider.NombreProvider
            VersionProvider = $ContextoProvider.VersionProvider
            Estado = $ContextoProvider.Estado
            HealthEstado = $ContextoProvider.Health.Estado
            HealthMensaje = $ContextoProvider.Health.Mensaje
            UltimaVerificacionHealth = $ContextoProvider.Health.UltimaVerificacion
            CapacidadesProvider = $ContextoProvider.CapacidadesProvider
            EstaInicializado = $AdministradorProviders.ProvidersInicializados.ContainsKey($NombreProvider)
        }) | Out-Null
    }

    $Providers = $ProvidersObservados.ToArray()
    $ProvidersUnhealthy = @($Providers | Where-Object { $_.HealthEstado -eq "Unhealthy" })
    $ProvidersConfigurationInvalid = @($Providers | Where-Object { $_.Estado -eq "ConfigurationInvalid" })

    return [pscustomobject][ordered]@{
        NombreComponente = "Enterprise Provider Framework"
        TotalProvidersRegistrados = $Providers.Count
        TotalProvidersInicializados = $AdministradorProviders.ProvidersInicializados.Count
        TotalProvidersUnhealthy = $ProvidersUnhealthy.Count
        TotalProvidersConfigurationInvalid = $ProvidersConfigurationInvalid.Count
        Providers = $Providers
        LimitesIncluidos = [pscustomobject][ordered]@{
            ProvidersReales = $false
            AzureFoundry = $false
            HTTP = $false
            IA = $false
            CredencialesReales = $false
        }
    }
}

function Get-HermesEnterpriseProviderFrameworkMaturityReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorProviders,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$VersionFramework = "0.3.3"
    )

    $ObservabilidadProviders = Get-HermesEnterpriseProviderObservability -AdministradorProviders $AdministradorProviders
    $InfraestructuraBaseCertificada = (
        $ObservabilidadProviders.TotalProvidersRegistrados -ge 1 -and
        $ObservabilidadProviders.TotalProvidersUnhealthy -eq 0 -and
        $ObservabilidadProviders.TotalProvidersConfigurationInvalid -eq 0
    )

    return [pscustomobject][ordered]@{
        NombreComponente = "Enterprise Provider Framework"
        EstadoMadurez = if ($InfraestructuraBaseCertificada) { "InfraestructuraBaseCertificada" } else { "RequiereEstabilizacion" }
        VersionFramework = $VersionFramework
        TotalProvidersRegistrados = $ObservabilidadProviders.TotalProvidersRegistrados
        TotalProvidersInicializados = $ObservabilidadProviders.TotalProvidersInicializados
        TotalProvidersUnhealthy = $ObservabilidadProviders.TotalProvidersUnhealthy
        TotalProvidersConfigurationInvalid = $ObservabilidadProviders.TotalProvidersConfigurationInvalid
        Capacidades = [pscustomobject][ordered]@{
            ProviderContract = $true
            ProviderContext = $true
            ProviderRegistry = $true
            ProviderManager = $true
            ConfigurationValidation = $true
            Health = $true
            Observability = $true
        }
        LimitesIncluidos = $ObservabilidadProviders.LimitesIncluidos
        PruebasRecomendadas = @(
            "pruebas/unitarias/Test-ProviderFramework.ps1",
            "pruebas/unitarias/Test-ProviderManagerValidation.ps1",
            "pruebas/unitarias/Test-ProviderObservability.ps1",
            "pruebas/unitarias/Test-ProviderFrameworkMaturity.ps1",
            "scripts/Test-HermesEnterprise.ps1"
        )
        ProximaFaseRecomendada = "AdapterScaffoldingSinProvidersReales"
    }
}
