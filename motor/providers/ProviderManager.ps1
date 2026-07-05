<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderManager.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Administra registro, inicialización, estado y apagado de providers sin realizar llamadas HTTP.
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
