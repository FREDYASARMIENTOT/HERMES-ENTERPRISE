<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AzureFoundryProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Orquestador del primer provider real de HERMES-ENTERPRISE. Coordina autenticación,
    health check, descubrimiento de deployments y chat delegando en módulos especializados.
    No contiene lógica de red, autenticación ni resolución de credenciales.

Subfases:
    4.1 - Conexión, autenticación y descubrimiento de deployments.
    4.2 - Health check contra /openai/models.
    4.3 - Primer chat completion contra un deployment.
    4.4 - Refactorización arquitectónica: orquestador con módulos especializados.

Módulos delegados:
    motor/security/CredentialResolver.ps1
    motor/security/AzureAdResolver.ps1
    motor/security/KeyVaultResolver.ps1
    motor/providers/AzureFoundryRest.ps1
    motor/providers/AzureFoundryHealth.ps1
    motor/providers/AzureFoundryDeployment.ps1
    motor/providers/AzureFoundryChat.ps1
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioAzureFoundryProvider = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioAzureFoundryProvider "ProviderAdapter.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "ProviderCapabilityDescriptor.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "ProviderConfigurationManager.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "ProviderDescriptor.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "ProviderDiagnostics.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "..\security\CredentialResolver.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "..\logging\Logger.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "AzureFoundryTelemetry.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "AzureFoundryRest.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "AzureFoundryHealth.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "AzureFoundryDeployment.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "AzureFoundryChat.ps1")

#region Constantes del provider

$SCRIPT:HermesEnterpriseAzureFoundryProviderNombre = "AzureFoundryProvider"
$SCRIPT:HermesEnterpriseAzureFoundryProviderVersion = "0.4.0"
$SCRIPT:HermesEnterpriseAzureFoundryApiVersionPredeterminada = "2024-10-21"
$SCRIPT:HermesEnterpriseAzureFoundryDeploymentsSimulados = @(
    [pscustomobject][ordered]@{
        Nombre = "ur-hermes-mini"
        Modelo = "gpt-4o-mini"
        Capacidades = @("Chat")
        MaxTokens = 16384
        Estado = "Healthy"
    }
    [pscustomobject][ordered]@{
        Nombre = "ur-hermes-coder"
        Modelo = "gpt-4o"
        Capacidades = @("Chat", "Code")
        MaxTokens = 32768
        Estado = "Healthy"
    }
    [pscustomobject][ordered]@{
        Nombre = "ur-ep-gpt-5.5"
        Modelo = "gpt-5.5"
        Capacidades = @("Chat", "Reasoning")
        MaxTokens = 128000
        Estado = "Healthy"
    }
)

#endregion

#region Helpers del orquestador

function Get-HermesEnterpriseAzureFoundryProviderApiVersion {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    $ApiVersion = $null
    if ($null -ne $ContextoProvider.UltimaConfiguracion) {
        $ApiVersion = $ContextoProvider.UltimaConfiguracion.ApiVersion
    }
    if ([string]::IsNullOrWhiteSpace($ApiVersion)) {
        $ApiVersion = $SCRIPT:HermesEnterpriseAzureFoundryApiVersionPredeterminada
    }
    return $ApiVersion
}

function Test-HermesEnterpriseAzureFoundryProviderSimulationMode {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return Test-HermesEnterpriseAzureFoundrySimulationMode
}

#endregion

#region Construcción del provider

function New-HermesEnterpriseAzureFoundryProvider {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)][psobject]$LoggerKernel = $null
    )

    $AdministradorConfiguracion = New-HermesEnterpriseProviderConfigurationManager
    Register-HermesEnterpriseProviderConfigurationSchema `
        -AdministradorConfiguracionProviders $AdministradorConfiguracion `
        -EsquemaConfiguracionProvider ([pscustomobject][ordered]@{
            NombreProvider = $SCRIPT:HermesEnterpriseAzureFoundryProviderNombre
            VersionEsquema = $SCRIPT:HermesEnterpriseAzureFoundryProviderVersion
            ClavesRequeridas = @("Endpoint", "ApiVersion")
            ClavesPermitidas = @("Endpoint", "ApiVersion", "DeploymentDefault", "TimeoutSegundos", "Modo")
            ValoresPorDefecto = @{
                ApiVersion = $SCRIPT:HermesEnterpriseAzureFoundryApiVersionPredeterminada
                TimeoutSegundos = 60
                Modo = "Auto"
                DeploymentDefault = "ur-hermes-mini"
            }
        }) | Out-Null

    $Adapter = New-HermesEnterpriseProviderAdapter `
        -NombreProvider $SCRIPT:HermesEnterpriseAzureFoundryProviderNombre `
        -VersionProvider $SCRIPT:HermesEnterpriseAzureFoundryProviderVersion

    $Adapter.LimitesIncluidos.AzureFoundry = $true
    $Adapter.LimitesIncluidos.HTTP = $true
    $Adapter.LimitesIncluidos.ProviderReal = $true
    $Adapter.LimitesIncluidos.CredencialesReales = $false
    $Adapter.LimitesIncluidos.IA = $true

    $LoggerEfectivo = $LoggerKernel
    if ($null -eq $LoggerEfectivo) {
        $RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
        $RutaLogProvider = Join-Path $RutaRaizRepositorio "logs\AzureFoundryProvider.log"
        $LoggerEfectivo = New-HermesEnterpriseLogger -RutaArchivoLog $RutaLogProvider -NombreComponente "AzureFoundryProvider"
    }

    return [pscustomobject][ordered]@{
        NombreProvider = $SCRIPT:HermesEnterpriseAzureFoundryProviderNombre
        VersionProvider = $SCRIPT:HermesEnterpriseAzureFoundryProviderVersion
        Autor = "HERMES-ENTERPRISE"
        Adapter = $Adapter
        ConfigurationManager = $AdministradorConfiguracion
        ConfiguracionProvider = @{}
        Capabilities = New-HermesEnterpriseProviderCapabilityDescriptor `
            -NombreProvider $SCRIPT:HermesEnterpriseAzureFoundryProviderNombre `
            -VersionProvider $SCRIPT:HermesEnterpriseAzureFoundryProviderVersion `
            -CapacidadesSoportadas @("Chat", "Health", "Deployments") `
            -CapacidadesExperimentales @() `
            -MetadatosCapacidades @{ ToolCalling = $false; Vision = $false; Embeddings = $false; Streaming = $false; Speech = $false }
        Health = [pscustomobject][ordered]@{ Estado = "Unknown"; Mensaje = "Health no evaluado."; UltimaVerificacion = $null }
        HoraInicioInicializacion = $null
        HoraFinInicializacion = $null
        UltimaConfiguracion = $null
        Logger = $LoggerEfectivo
    }
}

#endregion

#region Contrato del ProviderManager

function ValidateConfiguration-AzureFoundryProvider {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    $ConfiguracionSolicitada = $ContextoProvider.ConfiguracionProvider
    if ($null -eq $ConfiguracionSolicitada) { $ConfiguracionSolicitada = @{} }

    $ContextoProvider.UltimaConfiguracion = Resolve-HermesEnterpriseProviderConfiguration `
        -AdministradorConfiguracionProviders $ContextoProvider.ConfigurationManager `
        -NombreProvider $ContextoProvider.NombreProvider `
        -ConfiguracionSolicitada $ConfiguracionSolicitada

    $Resultado = Test-HermesEnterpriseProviderConfiguration `
        -AdministradorConfiguracionProviders $ContextoProvider.ConfigurationManager `
        -NombreProvider $ContextoProvider.NombreProvider `
        -ConfiguracionSolicitada $ContextoProvider.UltimaConfiguracion

    if ($Resultado.EsValida) {
        if ($ContextoProvider.Adapter.EstadoActual -eq "Created") {
            Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Configured" | Out-Null
        }
        if ($ContextoProvider.Adapter.EstadoActual -eq "Configured") {
            Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Validated" | Out-Null
        }
    }

    return $Resultado
}

function Initialize-AzureFoundryProvider {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    $ContextoProvider.HoraInicioInicializacion = Get-Date
    Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Initialized" | Out-Null
    $ContextoProvider.HoraFinInicializacion = Get-Date
    return $ContextoProvider
}

function Connect-AzureFoundryProvider {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContextoProvider,
        [Parameter(Mandatory = $false)][hashtable]$ConfiguracionProvider = @{}
    )

    if ($ConfiguracionProvider.Count -gt 0) {
        $ContextoProvider.ConfiguracionProvider = $ConfiguracionProvider
    }

    if ($ContextoProvider.ConfiguracionProvider.Count -eq 0) {
        $ContextoProvider.ConfiguracionProvider = @{
            Endpoint = $env:AZURE_FOUNDRY_ENDPOINT
            ApiVersion = $env:AZURE_FOUNDRY_API_VERSION
            DeploymentDefault = "ur-hermes-mini"
        }
        if ([string]::IsNullOrWhiteSpace($ContextoProvider.ConfiguracionProvider.ApiVersion)) {
            $ContextoProvider.ConfiguracionProvider.ApiVersion = $SCRIPT:HermesEnterpriseAzureFoundryApiVersionPredeterminada
        }
    }

    $ContextoProvider.UltimaConfiguracion = Resolve-HermesEnterpriseProviderConfiguration `
        -AdministradorConfiguracionProviders $ContextoProvider.ConfigurationManager `
        -NombreProvider $ContextoProvider.NombreProvider `
        -ConfiguracionSolicitada $ContextoProvider.ConfiguracionProvider

    if ($ContextoProvider.Adapter.EstadoActual -eq "Created" -or $ContextoProvider.Adapter.EstadoActual -eq "Configured") {
        ValidateConfiguration-AzureFoundryProvider -ContextoProvider $ContextoProvider | Out-Null
    }

    if ($ContextoProvider.Adapter.EstadoActual -eq "Validated") {
        Initialize-AzureFoundryProvider -ContextoProvider $ContextoProvider | Out-Null
    }

    $ModoSimulado = Test-HermesEnterpriseAzureFoundryProviderSimulationMode
    if ($ModoSimulado) {
        $ContextoProvider.Adapter.LimitesIncluidos.CredencialesReales = $false
        $ContextoProvider.Health = [pscustomobject][ordered]@{
            Estado = "Healthy"
            Mensaje = "Provider Healthy (modo simulado)."
            UltimaVerificacion = (Get-Date).ToString("o")
        }
    }
    else {
        $ContextoProvider.Adapter.LimitesIncluidos.CredencialesReales = $true
        $Health = Invoke-AzureFoundryHealth -ContextoProvider $ContextoProvider
        $ContextoProvider.Health = [pscustomobject][ordered]@{
            Estado = $Health.Estado
            Mensaje = $Health.Mensaje
            UltimaVerificacion = (Get-Date).ToString("o")
        }
    }

    if ($ContextoProvider.Health.Estado -eq "Healthy") {
        Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Ready" | Out-Null
    }
    else {
        Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Faulted" | Out-Null
    }

    return $ContextoProvider
}

function Disconnect-AzureFoundryProvider {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Disposed" | Out-Null
    $ContextoProvider.Health = [pscustomobject][ordered]@{
        Estado = "Disposed"
        Mensaje = "AzureFoundryProvider dispuesto."
        UltimaVerificacion = (Get-Date).ToString("o")
    }
    return $ContextoProvider
}

#endregion

#region Operaciones del provider (delegadas)

function Get-AzureFoundryProviderHealth {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    return $ContextoProvider.Health
}

function Get-AzureFoundryDeployments {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    return Get-AzureFoundryDeploymentList `
        -ContextoProvider $ContextoProvider `
        -DeploymentsSimulados $SCRIPT:HermesEnterpriseAzureFoundryDeploymentsSimulados `
        -ApiVersion (Get-HermesEnterpriseAzureFoundryProviderApiVersion -ContextoProvider $ContextoProvider)
}

function Get-AzureFoundryDeploymentDescription {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContextoProvider,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreDeployment
    )

    return Get-AzureFoundryDeploymentInfo `
        -ContextoProvider $ContextoProvider `
        -NombreDeployment $NombreDeployment `
        -DeploymentsSimulados $SCRIPT:HermesEnterpriseAzureFoundryDeploymentsSimulados `
        -ApiVersion (Get-HermesEnterpriseAzureFoundryProviderApiVersion -ContextoProvider $ContextoProvider)
}

function Invoke-AzureFoundryHealth {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    return Invoke-AzureFoundryHealthCheck `
        -ContextoProvider $ContextoProvider `
        -ApiVersion (Get-HermesEnterpriseAzureFoundryProviderApiVersion -ContextoProvider $ContextoProvider)
}

function Invoke-AzureFoundryChat {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContextoProvider,
        [Parameter(Mandatory = $false)][string]$Mensaje = "Hola",
        [Parameter(Mandatory = $false)][string]$Deployment = ""
    )

    return Invoke-AzureFoundryChatCompletion `
        -ContextoProvider $ContextoProvider `
        -Mensaje $Mensaje `
        -Deployment $Deployment `
        -ApiVersion (Get-HermesEnterpriseAzureFoundryProviderApiVersion -ContextoProvider $ContextoProvider)
}

#endregion

#region Descriptor, diagnostics y observability

function Get-AzureFoundryProviderDiagnostics {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    return Invoke-HermesEnterpriseProviderDiagnostics `
        -NombreProvider $ContextoProvider.NombreProvider `
        -AdministradorConfiguracionProviders $ContextoProvider.ConfigurationManager `
        -ConfiguracionProvider ($ContextoProvider.UltimaConfiguracion) `
        -DescriptorCapacidadesProvider $ContextoProvider.Capabilities `
        -CapacidadesRequeridas @("Chat", "Health", "Deployments") `
        -HealthProvider $ContextoProvider.Health
}

function Get-AzureFoundryProviderObservability {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    $DuracionInicializacion = if ($ContextoProvider.HoraInicioInicializacion -and $ContextoProvider.HoraFinInicializacion) {
        [int]($ContextoProvider.HoraFinInicializacion - $ContextoProvider.HoraInicioInicializacion).TotalMilliseconds
    } else { 0 }

    return [pscustomobject][ordered]@{
        EstadoInicial = if ($ContextoProvider.Adapter.HistorialEstados.Count -gt 0) { $ContextoProvider.Adapter.HistorialEstados[0] } else { "Created" }
        EstadoFinal = $ContextoProvider.Adapter.EstadoActual
        CantidadTransiciones = $ContextoProvider.Adapter.HistorialEstados.Count
        DuracionInicializacionMilisegundos = $DuracionInicializacion
        LimitesIncluidos = $ContextoProvider.Adapter.LimitesIncluidos
    }
}

function Get-AzureFoundryProviderDescriptor {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    $Diagnostics = Get-AzureFoundryProviderDiagnostics -ContextoProvider $ContextoProvider
    return New-HermesEnterpriseProviderDescriptor `
        -Metadata ([pscustomobject][ordered]@{ Nombre = $ContextoProvider.NombreProvider; Version = $ContextoProvider.VersionProvider; Autor = $ContextoProvider.Autor }) `
        -Configuration (Get-HermesEnterpriseProviderConfigurationManagerState -AdministradorConfiguracionProviders $ContextoProvider.ConfigurationManager) `
        -Capabilities $ContextoProvider.Capabilities `
        -Diagnostics $Diagnostics `
        -Health $ContextoProvider.Health `
        -Observability (Get-AzureFoundryProviderObservability -ContextoProvider $ContextoProvider) `
        -Maturity ([pscustomobject][ordered]@{ EstadoMadurez = "AzureFoundryProviderConectado" }) `
        -RuntimeState ([pscustomobject][ordered]@{ Estado = $ContextoProvider.Adapter.EstadoActual; EstaInicializado = ($ContextoProvider.Adapter.HistorialEstados -contains "Initialized") })
}

function Get-AzureFoundryProviderSummary {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    $Descriptor = Get-AzureFoundryProviderDescriptor -ContextoProvider $ContextoProvider
    $ResultadoDescriptor = Test-HermesEnterpriseProviderDescriptor -ProviderDescriptor $Descriptor
    $ModoSimulado = Test-HermesEnterpriseAzureFoundryProviderSimulationMode

    return [pscustomobject][ordered]@{
        NombreProvider = $ContextoProvider.NombreProvider
        EstadoActual = $ContextoProvider.Adapter.EstadoActual
        DescriptorValido = $ResultadoDescriptor.EsValido
        DiagnosticsListoLocalmente = $Descriptor.Diagnostics.EsListoLocalmente
        CantidadTransiciones = $Descriptor.Observability.CantidadTransiciones
        Modo = if ($ModoSimulado) { "Simulado" } else { "Real" }
        LimitesIncluidos = [pscustomobject][ordered]@{
            HTTP = $true
            AzureFoundry = $true
            SDKExterno = $false
            ProviderReal = $true
            CredencialesReales = (-not $ModoSimulado)
            IA = $true
        }
    }
}

#endregion
