<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : DependencyInjection.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Contenedor de dependencias, ServiceLocator y registro de servicios.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseDependencyContainer {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Servicios = @{}
    }
}

function Register-HermesEnterpriseService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$ContenedorDependencias,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreServicio,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$InstanciaServicio
    )

    $ContenedorDependencias.Servicios[$NombreServicio] = $InstanciaServicio
}

function Resolve-HermesEnterpriseService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$ContenedorDependencias,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreServicio
    )

    if (-not $ContenedorDependencias.Servicios.ContainsKey($NombreServicio)) {
        throw "Servicio no registrado: $NombreServicio"
    }

    return $ContenedorDependencias.Servicios[$NombreServicio]
}

function New-HermesEnterpriseServiceLocator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$ContenedorDependencias
    )

    return [pscustomobject][ordered]@{
        Contenedor = $ContenedorDependencias
    }
}