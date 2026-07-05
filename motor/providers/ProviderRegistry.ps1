<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderRegistry.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Registra providers enterprise sin cargar implementaciones reales ni transporte externo.
====================================================================================================
#>
Set-StrictMode -Version Latest

function New-HermesEnterpriseProviderRegistry {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{ ProveedoresRegistrados = @{} }
}

function Register-HermesEnterpriseProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$ProveedorRegistry,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProveedor,
        [Parameter(Mandatory = $true)][ValidateNotNull()]$Proveedor
    )

    $ProveedorRegistry.ProveedoresRegistrados[$NombreProveedor] = $Proveedor
    return $Proveedor
}

function Test-HermesEnterpriseProviderRegistered {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$ProveedorRegistry,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProveedor
    )

    return $ProveedorRegistry.ProveedoresRegistrados.ContainsKey($NombreProveedor)
}

function Get-HermesEnterpriseProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$ProveedorRegistry,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProveedor
    )

    if (Test-HermesEnterpriseProviderRegistered -ProveedorRegistry $ProveedorRegistry -NombreProveedor $NombreProveedor) {
        return $ProveedorRegistry.ProveedoresRegistrados[$NombreProveedor]
    }
    return $null
}

function Get-HermesEnterpriseRegisteredProviders {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$ProveedorRegistry)

    return @($ProveedorRegistry.ProveedoresRegistrados.Values)
}

function Unregister-HermesEnterpriseProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$ProveedorRegistry,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProveedor
    )

    return $ProveedorRegistry.ProveedoresRegistrados.Remove($NombreProveedor)
}
