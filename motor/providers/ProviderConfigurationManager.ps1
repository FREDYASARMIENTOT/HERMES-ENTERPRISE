<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderConfigurationManager.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Administra esquemas y validación local de configuración para providers sin leer secretos,
    archivos externos, HTTP ni proveedores reales.
====================================================================================================
#>
Set-StrictMode -Version Latest

function New-HermesEnterpriseProviderConfigurationManager {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        EsquemasConfiguracionProvider = @{}
    }
}

function Register-HermesEnterpriseProviderConfigurationSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorConfiguracionProviders,
        [Parameter(Mandatory = $true)][psobject]$EsquemaConfiguracionProvider
    )

    $AdministradorConfiguracionProviders.EsquemasConfiguracionProvider[$EsquemaConfiguracionProvider.NombreProvider] = $EsquemaConfiguracionProvider
    return $EsquemaConfiguracionProvider
}

function Test-HermesEnterpriseProviderConfigurationSchemaRegistered {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorConfiguracionProviders,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider
    )

    return $AdministradorConfiguracionProviders.EsquemasConfiguracionProvider.ContainsKey($NombreProvider)
}

function Resolve-HermesEnterpriseProviderConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorConfiguracionProviders,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider,
        [Parameter(Mandatory = $false)][hashtable]$ConfiguracionSolicitada = @{}
    )

    if (-not (Test-HermesEnterpriseProviderConfigurationSchemaRegistered -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders -NombreProvider $NombreProvider)) {
        throw "No existe esquema de configuración para provider: $NombreProvider"
    }

    $EsquemaConfiguracionProvider = $AdministradorConfiguracionProviders.EsquemasConfiguracionProvider[$NombreProvider]
    $ConfiguracionResuelta = @{}

    foreach ($ClaveDefecto in $EsquemaConfiguracionProvider.ValoresPorDefecto.Keys) {
        $ConfiguracionResuelta[$ClaveDefecto] = $EsquemaConfiguracionProvider.ValoresPorDefecto[$ClaveDefecto]
    }

    foreach ($ClaveSolicitada in $ConfiguracionSolicitada.Keys) {
        if ($ClaveSolicitada -notmatch "(?i)(secret|token|password|apikey|api_key|credential)") {
            $ConfiguracionResuelta[$ClaveSolicitada] = $ConfiguracionSolicitada[$ClaveSolicitada]
        }
    }

    return [pscustomobject]$ConfiguracionResuelta
}

function Test-HermesEnterpriseProviderConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$AdministradorConfiguracionProviders,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider,
        [Parameter(Mandatory = $false)]$ConfiguracionSolicitada = @{}
    )

    if (-not (Test-HermesEnterpriseProviderConfigurationSchemaRegistered -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders -NombreProvider $NombreProvider)) {
        throw "No existe esquema de configuración para provider: $NombreProvider"
    }

    $EsquemaConfiguracionProvider = $AdministradorConfiguracionProviders.EsquemasConfiguracionProvider[$NombreProvider]
    $Errores = New-Object System.Collections.Generic.List[string]
    $ConfiguracionNormalizada = @{}

    foreach ($Propiedad in $ConfiguracionSolicitada.PSObject.Properties) {
        $ConfiguracionNormalizada[$Propiedad.Name] = $Propiedad.Value
    }

    if ($ConfiguracionSolicitada -is [hashtable]) {
        foreach ($Clave in $ConfiguracionSolicitada.Keys) {
            $ConfiguracionNormalizada[$Clave] = $ConfiguracionSolicitada[$Clave]
        }
    }

    foreach ($ClaveRequerida in $EsquemaConfiguracionProvider.ClavesRequeridas) {
        if (-not $ConfiguracionNormalizada.ContainsKey($ClaveRequerida)) {
            $Errores.Add("Falta clave requerida: $ClaveRequerida") | Out-Null
        }
    }

    foreach ($ClaveConfiguracion in $ConfiguracionNormalizada.Keys) {
        if ($ClaveConfiguracion -match "(?i)(secret|token|password|apikey|api_key|credential)") {
            $Errores.Add("Clave sensible no permitida: $ClaveConfiguracion") | Out-Null
            continue
        }

        if ($EsquemaConfiguracionProvider.ClavesPermitidas -notcontains $ClaveConfiguracion) {
            $Errores.Add("Clave no permitida: $ClaveConfiguracion") | Out-Null
        }
    }

    return [pscustomobject][ordered]@{
        EsValida = ($Errores.Count -eq 0)
        NombreProvider = $NombreProvider
        Errores = $Errores.ToArray()
    }
}

function Get-HermesEnterpriseProviderConfigurationManagerState {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$AdministradorConfiguracionProviders)

    return [pscustomobject][ordered]@{
        NombreComponente = "Provider Configuration Manager"
        TotalEsquemasRegistrados = $AdministradorConfiguracionProviders.EsquemasConfiguracionProvider.Count
        EsquemasRegistrados = @($AdministradorConfiguracionProviders.EsquemasConfiguracionProvider.Keys)
        LimitesIncluidos = [pscustomobject][ordered]@{
            CredencialesReales = $false
            ArchivosExternos = $false
            HTTP = $false
            ProvidersReales = $false
        }
    }
}
