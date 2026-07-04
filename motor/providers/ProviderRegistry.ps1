<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderRegistry.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Registra proveedores aportados por plugins.
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
