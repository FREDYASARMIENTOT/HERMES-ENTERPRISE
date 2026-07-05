<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AzureFoundryProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Primer provider real de HERMES-ENTERPRISE. Conecta el Provider Framework con Azure AI Foundry
    mediante llamadas HTTP autenticadas. Soporta descubrimiento de deployments, health check y
    chat completion. No almacena credenciales en memoria; las lee de variables de entorno en el
    momento de uso.

Subfases:
    4.1 - Conexión, autenticación y descubrimiento de deployments.
    4.2 - Health check contra /openai/models.
    4.3 - Primer chat completion contra un deployment.

Modo Simulado:
    Si no se detectan credenciales reales, el provider opera en modo simulado devolviendo los
    deployments conocidos (ur-hermes-mini, ur-hermes-coder, ur-ep-gpt-5.5) sin salir de red.
    Esto permite validar la integración del framework sin depender de una suscripción activa.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioAzureFoundryProvider = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioAzureFoundryProvider "ProviderAdapter.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "ProviderCapabilityDescriptor.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "ProviderConfigurationManager.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "ProviderDescriptor.ps1")
. (Join-Path $RutaDirectorioAzureFoundryProvider "ProviderDiagnostics.ps1")

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

#region Helpers internos

function Get-HermesEnterpriseAzureFoundryProviderAzureAdToken {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    try {
        $Token = az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv 2>$null
        if (-not [string]::IsNullOrWhiteSpace($Token)) {
            return [pscustomobject][ordered]@{
                Token = $Token
                Tipo = "Bearer"
                Origen = "AzureAD"
                TieneCredenciales = $true
                Error = $null
            }
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            Token = $null
            Tipo = $null
            Origen = "AzureAD"
            TieneCredenciales = $false
            Error = $_.Exception.Message
        }
    }

    return [pscustomobject][ordered]@{
        Token = $null
        Tipo = $null
        Origen = "AzureAD"
        TieneCredenciales = $false
        Error = "Token de Azure AD vacío."
    }
}

function Get-HermesEnterpriseAzureFoundryProviderKeyVaultSecret {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreSecreto
    )

    try {
        return az keyvault secret show --vault-name kv-hermes-enterprise-ur --name $NombreSecreto --query value -o tsv 2>$null
    }
    catch {
        return $null
    }
}

function Get-HermesEnterpriseAzureFoundryProviderKeyVaultCredential {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $Endpoint = Get-HermesEnterpriseAzureFoundryProviderKeyVaultSecret -NombreSecreto "AzureOpenAI-Endpoint"
    $Deployment = Get-HermesEnterpriseAzureFoundryProviderKeyVaultSecret -NombreSecreto "AzureOpenAI-Deployment"
    $ApiKey = Get-HermesEnterpriseAzureFoundryProviderKeyVaultSecret -NombreSecreto "AzureOpenAI-ApiKey"

    return [pscustomobject][ordered]@{
        Endpoint = $Endpoint
        Deployment = $Deployment
        ApiKey = $ApiKey
        Tipo = "api-key"
        Origen = "AzureKeyVault"
        TieneCredenciales = (-not [string]::IsNullOrWhiteSpace($Endpoint)) -and (-not [string]::IsNullOrWhiteSpace($ApiKey))
        Error = if ((-not [string]::IsNullOrWhiteSpace($Endpoint)) -and (-not [string]::IsNullOrWhiteSpace($ApiKey))) { $null } else { "No se pudieron recuperar todos los secretos requeridos de Key Vault." }
    }
}

function Test-HermesEnterpriseAzureFoundryProviderCredential {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Endpoint,
        [Parameter(Mandatory = $false)][string]$ApiVersion = $SCRIPT:HermesEnterpriseAzureFoundryApiVersionPredeterminada
    )

    $Uri = Build-HermesEnterpriseAzureFoundryProviderRequestUri -Endpoint $Endpoint -Ruta "/openai/models" -ApiVersion $ApiVersion

    # 1. Intentar Azure AD.
    $TokenAzureAD = Get-HermesEnterpriseAzureFoundryProviderAzureAdToken
    if ($TokenAzureAD.TieneCredenciales) {
        $CredencialAd = [pscustomobject][ordered]@{
            Endpoint = $Endpoint
            ApiKey = $TokenAzureAD.Token
            Tipo = $TokenAzureAD.Tipo
            Origen = "$($TokenAzureAD.Origen) + AzureKeyVault"
            TieneCredenciales = $true
            Error = $null
        }
        try {
            Invoke-HermesEnterpriseAzureFoundryProviderRestMethod -Uri $Uri -Credencial $CredencialAd -Metodo "GET" | Out-Null
            return $CredencialAd
        }
        catch {
            # Azure AD no funciona para este recurso; continuar con API Key.
        }
    }

    # 2. Fallback a API Key.
    $ApiKey = Get-HermesEnterpriseAzureFoundryProviderKeyVaultSecret -NombreSecreto "AzureOpenAI-ApiKey"
    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        $ApiKey = $env:AZURE_FOUNDRY_API_KEY
    }
    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        $ApiKey = $env:AZURE_OPENAI_API_KEY
    }

    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        $CredencialKey = [pscustomobject][ordered]@{
            Endpoint = $Endpoint
            ApiKey = $ApiKey
            Tipo = "api-key"
            Origen = "AzureKeyVault + AzureKeyVault"
            TieneCredenciales = $true
            Error = $null
        }
        try {
            Invoke-HermesEnterpriseAzureFoundryProviderRestMethod -Uri $Uri -Credencial $CredencialKey -Metodo "GET" | Out-Null
            return $CredencialKey
        }
        catch {
            return [pscustomobject][ordered]@{
                Endpoint = $Endpoint
                ApiKey = $ApiKey
                Tipo = "api-key"
                Origen = "AzureKeyVault + AzureKeyVault"
                TieneCredenciales = $false
                Error = $_.Exception.Message
            }
        }
    }

    return [pscustomobject][ordered]@{
        Endpoint = $Endpoint
        ApiKey = $null
        Tipo = $null
        Origen = "Ninguno"
        TieneCredenciales = $false
        Error = "No se pudo autenticar con Azure AD ni con API Key."
    }
}

function Get-HermesEnterpriseAzureFoundryProviderEnvironmentCredential {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    # 1. Resolver endpoint: entorno primero, Key Vault como respaldo.
    $Endpoint = $env:AZURE_FOUNDRY_ENDPOINT
    if ([string]::IsNullOrWhiteSpace($Endpoint)) {
        $Endpoint = $env:AZURE_OPENAI_ENDPOINT
    }
    $OrigenEndpoint = "Environment"
    if ([string]::IsNullOrWhiteSpace($Endpoint)) {
        $Endpoint = Get-HermesEnterpriseAzureFoundryProviderKeyVaultSecret -NombreSecreto "AzureOpenAI-Endpoint"
        $OrigenEndpoint = "AzureKeyVault"
    }

    if ([string]::IsNullOrWhiteSpace($Endpoint)) {
        return [pscustomobject][ordered]@{
            Endpoint = $null
            ApiKey = $null
            Tipo = $null
            Origen = "Ninguno"
            TieneCredenciales = $false
            Error = "No se pudo resolver el endpoint desde variables de entorno ni Azure Key Vault."
        }
    }

    return Test-HermesEnterpriseAzureFoundryProviderCredential -Endpoint $Endpoint
}

function Test-HermesEnterpriseAzureFoundryProviderSimulationMode {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $Credencial = Get-HermesEnterpriseAzureFoundryProviderEnvironmentCredential
    return -not $Credencial.TieneCredenciales
}

function Build-HermesEnterpriseAzureFoundryProviderRequestUri {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Endpoint,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Ruta,
        [Parameter(Mandatory = $false)][string]$ApiVersion = $SCRIPT:HermesEnterpriseAzureFoundryApiVersionPredeterminada
    )

    $EndpointNormalizado = $Endpoint.TrimEnd('/')
    $Separador = if ($Ruta.Contains('?')) { '&' } else { '?' }
    return "$EndpointNormalizado$Ruta${Separador}api-version=$ApiVersion"
}

function Invoke-HermesEnterpriseAzureFoundryProviderRestMethod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Uri,
        [Parameter(Mandatory = $true)][psobject]$Credencial,
        [Parameter(Mandatory = $false)][ValidateSet("GET", "POST")][string]$Metodo = "GET",
        [Parameter(Mandatory = $false)][hashtable]$Cuerpo = @{}
    )

    $Headers = @{
        "Content-Type" = "application/json"
    }

    if ($Credencial.Tipo -eq "Bearer") {
        $Headers["Authorization"] = "Bearer $($Credencial.ApiKey)"
    }
    else {
        $Headers["api-key"] = $Credencial.ApiKey
    }

    $ParametrosInvoke = @{
        Uri = $Uri
        Method = $Metodo
        Headers = $Headers
        UseBasicParsing = $true
        ErrorAction = "Stop"
    }

    if ($Metodo -eq "POST" -and $Cuerpo.Count -gt 0) {
        $ParametrosInvoke["Body"] = ($Cuerpo | ConvertTo-Json -Depth 10 -Compress)
    }

    return Invoke-RestMethod @ParametrosInvoke
}

function Resolve-HermesEnterpriseAzureFoundryProviderHealthFromStatusCode {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][int]$CodigoEstadoHttp,
        [Parameter(Mandatory = $false)][string]$MensajeAdicional = ""
    )

    switch ($CodigoEstadoHttp) {
        200 {
            return [pscustomobject][ordered]@{
                Estado = "Healthy"
                Mensaje = "Provider Healthy."
                CodigoEstadoHttp = $CodigoEstadoHttp
            }
        }
        401 {
            return [pscustomobject][ordered]@{
                Estado = "InvalidKey"
                Mensaje = "Invalid Key."
                CodigoEstadoHttp = $CodigoEstadoHttp
            }
        }
        404 {
            return [pscustomobject][ordered]@{
                Estado = "DeploymentNotFound"
                Mensaje = "Deployment inexistente."
                CodigoEstadoHttp = $CodigoEstadoHttp
            }
        }
        default {
            return [pscustomobject][ordered]@{
                Estado = "Degraded"
                Mensaje = "Respuesta inesperada del endpoint. $MensajeAdicional"
                CodigoEstadoHttp = $CodigoEstadoHttp
            }
        }
    }
}

#endregion

#region Construcción del provider

function New-HermesEnterpriseAzureFoundryProvider {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

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

#region Operaciones del provider

function Get-AzureFoundryProviderHealth {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    return $ContextoProvider.Health
}

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

function Get-HermesEnterpriseAzureFoundryDeploymentsFromManagementApi {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param()

    try {
        $Respuesta = az rest `
            --method get `
            --url "https://management.azure.com/subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/resourceGroups/RG-Datamining-IA-UR/providers/Microsoft.CognitiveServices/accounts/Modelo-IA-UR/deployments?api-version=2023-05-01" `
            --query 'value[]' -o json 2>$null | ConvertFrom-Json

        $DeploymentsMapeados = New-Object System.Collections.Generic.List[object]
        foreach ($Item in $Respuesta) {
            $DeploymentsMapeados.Add([pscustomobject][ordered]@{
                Nombre = $Item.name
                Modelo = if ($Item.properties.model.name) { $Item.properties.model.name } else { $Item.properties.model }
                Capacidades = @("Chat")
                MaxTokens = 0
                Estado = if ($Item.properties.provisioningState -eq "Succeeded") { "Healthy" } else { $Item.properties.provisioningState }
            }) | Out-Null
        }
        return $DeploymentsMapeados.ToArray()
    }
    catch {
        return @()
    }
}

function Get-AzureFoundryDeployments {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    $ModoSimulado = Test-HermesEnterpriseAzureFoundryProviderSimulationMode
    if ($ModoSimulado) {
        return $SCRIPT:HermesEnterpriseAzureFoundryDeploymentsSimulados
    }

    $Credencial = Get-HermesEnterpriseAzureFoundryProviderEnvironmentCredential
    if (-not $Credencial.TieneCredenciales) {
        return Get-HermesEnterpriseAzureFoundryDeploymentsFromManagementApi
    }

    $Uri = Build-HermesEnterpriseAzureFoundryProviderRequestUri -Endpoint $Credencial.Endpoint -Ruta "/openai/models" -ApiVersion (Get-HermesEnterpriseAzureFoundryProviderApiVersion -ContextoProvider $ContextoProvider)

    try {
        $Respuesta = Invoke-HermesEnterpriseAzureFoundryProviderRestMethod -Uri $Uri -Credencial $Credencial -Metodo "GET"
        $DeploymentsMapeados = New-Object System.Collections.Generic.List[object]

        foreach ($Modelo in $Respuesta.data) {
            $DeploymentsMapeados.Add([pscustomobject][ordered]@{
                Nombre = $Modelo.id
                Modelo = $Modelo.id
                Capacidades = @("Chat")
                MaxTokens = if ($Modelo.PSObject.Properties.Match("max_tokens")) { $Modelo.max_tokens } else { 0 }
                Estado = "Healthy"
            }) | Out-Null
        }

        return $DeploymentsMapeados.ToArray()
    }
    catch {
        $DeploymentsDesdeManagementApi = Get-HermesEnterpriseAzureFoundryDeploymentsFromManagementApi
        if ($DeploymentsDesdeManagementApi.Count -gt 0) {
            return $DeploymentsDesdeManagementApi
        }
        throw "No se pudieron obtener deployments desde el endpoint de datos ni desde Azure Management API. Error: $($_.Exception.Message)"
    }
}

function Get-AzureFoundryDeploymentDescription {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContextoProvider,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreDeployment
    )

    $Deployments = Get-AzureFoundryDeployments -ContextoProvider $ContextoProvider
    $Deployment = $Deployments | Where-Object { $_.Nombre -eq $NombreDeployment } | Select-Object -First 1

    if ($null -eq $Deployment) {
        return [pscustomobject][ordered]@{
            Encontrado = $false
            Nombre = $NombreDeployment
            Modelo = $null
            Capacidades = @()
            MaxTokens = 0
            Endpoint = $null
            Estado = "DeploymentNotFound"
        }
    }

    $Endpoint = $null
    if (-not (Test-HermesEnterpriseAzureFoundryProviderSimulationMode)) {
        $Credencial = Get-HermesEnterpriseAzureFoundryProviderEnvironmentCredential
        $Endpoint = "$($Credencial.Endpoint.TrimEnd('/'))/openai/deployments/$NombreDeployment"
    }

    return [pscustomobject][ordered]@{
        Encontrado = $true
        Nombre = $Deployment.Nombre
        Modelo = $Deployment.Modelo
        Capacidades = $Deployment.Capacidades
        MaxTokens = $Deployment.MaxTokens
        Endpoint = $Endpoint
        Estado = $Deployment.Estado
    }
}

function Invoke-AzureFoundryHealth {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$ContextoProvider)

    $ModoSimulado = Test-HermesEnterpriseAzureFoundryProviderSimulationMode
    if ($ModoSimulado) {
        $ContextoProvider.Health = [pscustomobject][ordered]@{
            Estado = "Healthy"
            Mensaje = "Provider Healthy (modo simulado)."
            UltimaVerificacion = (Get-Date).ToString("o")
        }
        return $ContextoProvider.Health
    }

    $Credencial = Get-HermesEnterpriseAzureFoundryProviderEnvironmentCredential
    $Uri = Build-HermesEnterpriseAzureFoundryProviderRequestUri -Endpoint $Credencial.Endpoint -Ruta "/openai/models" -ApiVersion (Get-HermesEnterpriseAzureFoundryProviderApiVersion -ContextoProvider $ContextoProvider)

    try {
        Invoke-HermesEnterpriseAzureFoundryProviderRestMethod -Uri $Uri -Credencial $Credencial -Metodo "GET" | Out-Null
        $ContextoProvider.Health = [pscustomobject][ordered]@{
            Estado = "Healthy"
            Mensaje = "Provider Healthy."
            UltimaVerificacion = (Get-Date).ToString("o")
            CodigoEstadoHttp = 200
        }
    }
    catch {
        $CodigoEstado = 0
        if ($_.Exception.Response) {
            $CodigoEstado = [int]$_.Exception.Response.StatusCode
        }
        elseif ($_.Exception -match "\((\d{3})\)") {
            $CodigoEstado = [int]$Matches[1]
        }

        # Fallback: si el endpoint de datos rechaza la autenticación, verificar con Management API.
        if ($CodigoEstado -in @(401, 403)) {
            $DeploymentsDesdeManagementApi = Get-HermesEnterpriseAzureFoundryDeploymentsFromManagementApi
            if ($DeploymentsDesdeManagementApi.Count -gt 0) {
                $ContextoProvider.Health = [pscustomobject][ordered]@{
                    Estado = "Healthy"
                    Mensaje = "Provider Healthy (autenticación vía Azure Management API; endpoint de datos requiere RBAC adicional)."
                    UltimaVerificacion = (Get-Date).ToString("o")
                    CodigoEstadoHttp = $CodigoEstado
                }
            }
            else {
                $Health = Resolve-HermesEnterpriseAzureFoundryProviderHealthFromStatusCode -CodigoEstadoHttp $CodigoEstado -MensajeAdicional $_.Exception.Message
                $ContextoProvider.Health = [pscustomobject][ordered]@{
                    Estado = $Health.Estado
                    Mensaje = $Health.Mensaje
                    UltimaVerificacion = (Get-Date).ToString("o")
                    CodigoEstadoHttp = $Health.CodigoEstadoHttp
                }
            }
        }
        else {
            $Health = Resolve-HermesEnterpriseAzureFoundryProviderHealthFromStatusCode -CodigoEstadoHttp $CodigoEstado -MensajeAdicional $_.Exception.Message
            $ContextoProvider.Health = [pscustomobject][ordered]@{
                Estado = $Health.Estado
                Mensaje = $Health.Mensaje
                UltimaVerificacion = (Get-Date).ToString("o")
                CodigoEstadoHttp = $Health.CodigoEstadoHttp
            }
        }
    }

    if ($ContextoProvider.Adapter.EstadoActual -eq "Ready" -and $ContextoProvider.Health.Estado -ne "Healthy") {
        Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Degraded" | Out-Null
    }
    elseif ($ContextoProvider.Adapter.EstadoActual -eq "Ready" -and $ContextoProvider.Health.Estado -eq "Healthy") {
        Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Healthy" | Out-Null
    }

    return $ContextoProvider.Health
}

function Invoke-AzureFoundryChat {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContextoProvider,
        [Parameter(Mandatory = $false)][string]$Mensaje = "Hola",
        [Parameter(Mandatory = $false)][string]$Deployment = ""
    )

    if ([string]::IsNullOrWhiteSpace($Deployment)) {
        $Deployment = $ContextoProvider.UltimaConfiguracion.DeploymentDefault
    }

    $ModoSimulado = Test-HermesEnterpriseAzureFoundryProviderSimulationMode
    if ($ModoSimulado) {
        return [pscustomobject][ordered]@{
            Deployment = $Deployment
            MensajeEntrada = $Mensaje
            Respuesta = $Mensaje
            Modelo = "simulado"
            TokensEntrada = 0
            TokensSalida = 0
            Modo = "Simulado"
        }
    }

    $Credencial = Get-HermesEnterpriseAzureFoundryProviderEnvironmentCredential
    $Ruta = "/openai/deployments/$Deployment/chat/completions"
    $Uri = Build-HermesEnterpriseAzureFoundryProviderRequestUri -Endpoint $Credencial.Endpoint -Ruta $Ruta -ApiVersion (Get-HermesEnterpriseAzureFoundryProviderApiVersion -ContextoProvider $ContextoProvider)

    $Cuerpo = @{
        messages = @(
            @{ role = "user"; content = $Mensaje }
        )
        max_completion_tokens = 50
    }

    $Respuesta = Invoke-HermesEnterpriseAzureFoundryProviderRestMethod -Uri $Uri -Credencial $Credencial -Metodo "POST" -Cuerpo $Cuerpo

    return [pscustomobject][ordered]@{
        Deployment = $Deployment
        MensajeEntrada = $Mensaje
        Respuesta = $Respuesta.choices[0].message.content
        Modelo = $Respuesta.model
        TokensEntrada = $Respuesta.usage.prompt_tokens
        TokensSalida = $Respuesta.usage.completion_tokens
        Modo = "Real"
    }
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
