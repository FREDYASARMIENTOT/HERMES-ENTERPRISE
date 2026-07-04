<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ModuleRegistry.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Mantiene el registro de módulos cargables del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseModuleRegistry {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        ModulosRegistrados = @{}
    }
}

function Register-HermesEnterpriseModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$RegistroModulos,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreModulo,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$VersionModulo,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$RutaModulo,
        [Parameter(Mandatory = $false)][string[]]$CapacidadesModulo = @()
    )

    # Registrar por nombre hace la operación idempotente: ejecutar dos veces actualiza la misma entrada.
    $RegistroModulos.ModulosRegistrados[$NombreModulo] = [pscustomobject][ordered]@{
        NombreModulo = $NombreModulo
        VersionModulo = $VersionModulo
        RutaModulo = $RutaModulo
        CapacidadesModulo = $CapacidadesModulo
        EstadoModulo = "Registrado"
        FechaRegistro = (Get-Date).ToString("o")
    }

    return $RegistroModulos.ModulosRegistrados[$NombreModulo]
}

function Get-HermesEnterpriseRegisteredModules {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$RegistroModulos)

    return @($RegistroModulos.ModulosRegistrados.Values)
}
