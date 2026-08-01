<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : DependencyInjection.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Contenedor de dependencias del Kernel Enterprise.
    Unifica registro y resolución de servicios sin ServiceLocator.
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

<#
.SYNOPSIS
    Verifica si un servicio está registrado en el contenedor.
#>
function Test-HermesEnterpriseServiceRegistered {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$ContenedorDependencias,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreServicio
    )

    return $ContenedorDependencias.Servicios.ContainsKey($NombreServicio)
}

<#
.SYNOPSIS
    Obtiene la lista de nombres de servicios registrados.
#>
function Get-HermesEnterpriseRegisteredServices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$ContenedorDependencias
    )

    return $ContenedorDependencias.Servicios.Keys
}

# =============================================================================
# NOTA: New-HermesEnterpriseServiceLocator ha sido eliminado.
# Se reemplaza por el uso directo del DependencyContainer (ContenedorDependencias)
# vía Register-HermesEnterpriseService / Resolve-HermesEnterpriseService.
# =============================================================================

Export-ModuleMember -Function New-HermesEnterpriseDependencyContainer, Register-HermesEnterpriseService, Resolve-HermesEnterpriseService, Test-HermesEnterpriseServiceRegistered, Get-HermesEnterpriseRegisteredServices