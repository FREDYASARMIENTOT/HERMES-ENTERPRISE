<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ServiceLocator.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Proporciona una fachada controlada para resolver servicios registrados en el contenedor de
    dependencias del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseServiceLocator {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$ContenedorDependencias)

    return [pscustomobject][ordered]@{
        ContenedorDependencias = $ContenedorDependencias
    }
}

function Get-HermesEnterpriseService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$LocalizadorServicios,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreServicio
    )

    return Resolve-HermesEnterpriseService -ContenedorDependencias $LocalizadorServicios.ContenedorDependencias -NombreServicio $NombreServicio
}
