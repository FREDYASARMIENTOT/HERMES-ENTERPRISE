<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : DependencyInjection.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Implementa un contenedor mínimo de dependencias para registrar y resolver servicios del Kernel.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseDependencyContainer {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        ServiciosRegistrados = @{}
    }
}

function Register-HermesEnterpriseService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContenedorDependencias,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreServicio,
        [Parameter(Mandatory = $true)][ValidateNotNull()]$InstanciaServicio
    )

    # El registro por clave hace idempotente la operación y permite reemplazar implementaciones futuras.
    $ContenedorDependencias.ServiciosRegistrados[$NombreServicio] = $InstanciaServicio
    return $InstanciaServicio
}

function Resolve-HermesEnterpriseService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContenedorDependencias,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreServicio
    )

    if (-not $ContenedorDependencias.ServiciosRegistrados.ContainsKey($NombreServicio)) {
        throw "No existe un servicio registrado con el nombre: $NombreServicio"
    }

    return $ContenedorDependencias.ServiciosRegistrados[$NombreServicio]
}
