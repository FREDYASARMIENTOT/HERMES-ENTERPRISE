<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : MockProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Provider ficticio end-to-end que reutiliza infraestructura local del Provider Framework sin red,
    HTTP, SDKs, IA, credenciales reales ni providers externos.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioMockProvider = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioMockProvider "ProviderAdapter.ps1")
. (Join-Path $RutaDirectorioMockProvider "ProviderCapabilityDescriptor.ps1")
. (Join-Path $RutaDirectorioMockProvider "ProviderConfigurationManager.ps1")
. (Join-Path $RutaDirectorioMockProvider "ProviderDescriptor.ps1")
. (Join-Path $RutaDirectorioMockProvider "ProviderDiagnostics.ps1")

function New-HermesEnterpriseMockProvider {
    [CmdletBinding()]
    param()

    $AdministradorConfiguracion = New-HermesEnterpriseProviderConfigurationManager
    Register-HermesEnterpriseProviderConfigurationSchema `
        -AdministradorConfiguracionProviders $AdministradorConfiguracion `
        -EsquemaConfiguracionProvider ([pscustomobject][ordered]@{
            NombreProvider = "MockProvider"
            VersionEsquema = "0.1.0"
            ClavesRequeridas = @("Modelo", "Region")
            ClavesPermitidas = @("Modelo", "Region", "TimeoutSegundos", "Modo")
            ValoresPorDefecto = @{ TimeoutSegundos = 30; Modo = "Local" }
        }) | Out-Null

    return [pscustomobject][ordered]@{
        NombreProvider = "MockProvider"
        VersionProvider = "0.1.0"
        Autor = "HERMES-ENTERPRISE"
        Adapter = New-HermesEnterpriseProviderAdapter -NombreProvider "MockProvider" -VersionProvider "0.1.0" -Autor "HERMES-ENTERPRISE"
        ConfigurationManager = $AdministradorConfiguracion
        Capabilities = New-HermesEnterpriseProviderCapabilityDescriptor `
            -NombreProvider "MockProvider" `
            -VersionProvider "0.1.0" `
            -CapacidadesSoportadas @("Chat") `
            -CapacidadesExperimentales @() `
            -MetadatosCapacidades @{ ToolCalling = $false; Vision = $false; Embeddings = $false; Streaming = $false; Speech = $false }
        Health = [pscustomobject][ordered]@{ Estado = "Unknown"; Mensaje = "Health no evaluado."; UltimaVerificacion = $null }
        HoraInicioInicializacion = $null
        HoraFinInicializacion = $null
        UltimaConfiguracion = $null
    }
}

function Validate-HermesEnterpriseMockProviderConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$MockProvider,
        [Parameter(Mandatory = $true)][hashtable]$ConfiguracionProvider
    )

    $MockProvider.UltimaConfiguracion = Resolve-HermesEnterpriseProviderConfiguration `
        -AdministradorConfiguracionProviders $MockProvider.ConfigurationManager `
        -NombreProvider $MockProvider.NombreProvider `
        -ConfiguracionSolicitada $ConfiguracionProvider

    $Resultado = Test-HermesEnterpriseProviderConfiguration `
        -AdministradorConfiguracionProviders $MockProvider.ConfigurationManager `
        -NombreProvider $MockProvider.NombreProvider `
        -ConfiguracionSolicitada $MockProvider.UltimaConfiguracion

    if ($Resultado.EsValida) {
        if ($MockProvider.Adapter.EstadoActual -eq "Created") {
            Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $MockProvider.Adapter -NuevoEstado "Configured" | Out-Null
        }
        if ($MockProvider.Adapter.EstadoActual -eq "Configured") {
            Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $MockProvider.Adapter -NuevoEstado "Validated" | Out-Null
        }
    }

    return $Resultado
}

function Initialize-HermesEnterpriseMockProvider {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$MockProvider)

    $MockProvider.HoraInicioInicializacion = Get-Date
    Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $MockProvider.Adapter -NuevoEstado "Initialized" | Out-Null
    $MockProvider.HoraFinInicializacion = Get-Date
    return $MockProvider
}

function Connect-HermesEnterpriseMockProvider {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$MockProvider)

    Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $MockProvider.Adapter -NuevoEstado "Ready" | Out-Null
    return $MockProvider
}

function Disconnect-HermesEnterpriseMockProvider {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$MockProvider)

    Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $MockProvider.Adapter -NuevoEstado "Disposed" | Out-Null
    $MockProvider.Health.Estado = "Disposed"
    $MockProvider.Health.Mensaje = "MockProvider dispuesto localmente."
    $MockProvider.Health.UltimaVerificacion = (Get-Date).ToString("o")
    return $MockProvider
}

function Get-HermesEnterpriseMockProviderHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$MockProvider,
        [Parameter(Mandatory = $false)][ValidateSet("Healthy", "Degraded", "Faulted")][string]$EstadoSolicitado = "Healthy"
    )

    if ($EstadoSolicitado -ne $MockProvider.Adapter.EstadoActual) {
        Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $MockProvider.Adapter -NuevoEstado $EstadoSolicitado | Out-Null
    }

    $MockProvider.Health.Estado = $EstadoSolicitado
    $MockProvider.Health.Mensaje = "MockProvider reporta estado $EstadoSolicitado en memoria local."
    $MockProvider.Health.UltimaVerificacion = (Get-Date).ToString("o")
    return $MockProvider.Health
}

function Get-HermesEnterpriseMockProviderCapabilities {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$MockProvider)
    return $MockProvider.Capabilities
}

function Get-HermesEnterpriseMockProviderDiagnostics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$MockProvider,
        [Parameter(Mandatory = $true)][hashtable]$ConfiguracionProvider
    )

    return Invoke-HermesEnterpriseProviderDiagnostics `
        -NombreProvider $MockProvider.NombreProvider `
        -AdministradorConfiguracionProviders $MockProvider.ConfigurationManager `
        -ConfiguracionProvider $ConfiguracionProvider `
        -DescriptorCapacidadesProvider $MockProvider.Capabilities `
        -CapacidadesRequeridas @("Chat") `
        -HealthProvider $MockProvider.Health
}

function Get-HermesEnterpriseMockProviderObservability {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$MockProvider)

    $DuracionInicializacion = if ($MockProvider.HoraInicioInicializacion -and $MockProvider.HoraFinInicializacion) {
        [int]($MockProvider.HoraFinInicializacion - $MockProvider.HoraInicioInicializacion).TotalMilliseconds
    } else { 0 }

    return [pscustomobject][ordered]@{
        EstadoInicial = if ($MockProvider.Adapter.HistorialEstados.Count -gt 0) { $MockProvider.Adapter.HistorialEstados[0] } else { "Created" }
        EstadoFinal = $MockProvider.Adapter.EstadoActual
        CantidadTransiciones = $MockProvider.Adapter.HistorialEstados.Count
        DuracionInicializacionMilisegundos = $DuracionInicializacion
    }
}

function Get-HermesEnterpriseMockProviderDescriptor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$MockProvider,
        [Parameter(Mandatory = $true)][hashtable]$ConfiguracionProvider
    )

    $Diagnostics = Get-HermesEnterpriseMockProviderDiagnostics -MockProvider $MockProvider -ConfiguracionProvider $ConfiguracionProvider
    return New-HermesEnterpriseProviderDescriptor `
        -Metadata ([pscustomobject][ordered]@{ Nombre = $MockProvider.NombreProvider; Version = $MockProvider.VersionProvider; Autor = $MockProvider.Autor }) `
        -Configuration (Get-HermesEnterpriseProviderConfigurationManagerState -AdministradorConfiguracionProviders $MockProvider.ConfigurationManager) `
        -Capabilities $MockProvider.Capabilities `
        -Diagnostics $Diagnostics `
        -Health $MockProvider.Health `
        -Observability (Get-HermesEnterpriseMockProviderObservability -MockProvider $MockProvider) `
        -Maturity ([pscustomobject][ordered]@{ EstadoMadurez = "MockProviderEndToEndCertificado" }) `
        -RuntimeState ([pscustomobject][ordered]@{ Estado = $MockProvider.Adapter.EstadoActual; EstaInicializado = ($MockProvider.Adapter.HistorialEstados -contains "Initialized") })
}

function Get-HermesEnterpriseMockProviderSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$MockProvider,
        [Parameter(Mandatory = $true)][hashtable]$ConfiguracionProvider
    )

    $Descriptor = Get-HermesEnterpriseMockProviderDescriptor -MockProvider $MockProvider -ConfiguracionProvider $ConfiguracionProvider
    $ResultadoDescriptor = Test-HermesEnterpriseProviderDescriptor -ProviderDescriptor $Descriptor
    return [pscustomobject][ordered]@{
        NombreProvider = $MockProvider.NombreProvider
        EstadoActual = $MockProvider.Adapter.EstadoActual
        DescriptorValido = $ResultadoDescriptor.EsValido
        DiagnosticsListoLocalmente = $Descriptor.Diagnostics.EsListoLocalmente
        CantidadTransiciones = $Descriptor.Observability.CantidadTransiciones
        LimitesIncluidos = [pscustomobject][ordered]@{ HTTP = $false; AzureFoundry = $false; SDKExterno = $false; ProviderReal = $false; CredencialesReales = $false; IA = $false }
    }
}
