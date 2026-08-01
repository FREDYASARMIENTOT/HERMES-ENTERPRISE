<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ModuleRegistry.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Registro central de módulos del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseModuleRegistry {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Modulos = @()
    }
}

function Register-HermesEnterpriseModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$RegistroModulos,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreModulo,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$VersionModulo,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaModulo,

        [Parameter(Mandatory = $false)]
        [string[]]$CapacidadesModulo = @()
    )

    $EntradaModulo = [pscustomobject][ordered]@{
        Nombre       = $NombreModulo
        Version      = $VersionModulo
        Ruta         = $RutaModulo
        Capacidades  = $CapacidadesModulo
        FechaRegistro = (Get-Date).ToString("o")
    }

    $listaModulos = [System.Collections.ArrayList]@($RegistroModulos.Modulos)
    $listaModulos.Add($EntradaModulo) | Out-Null

    $RegistroModulos.Modulos = $listaModulos.ToArray()

    return $EntradaModulo
}

function Get-HermesEnterpriseModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$RegistroModulos,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreModulo
    )

    foreach ($m in $RegistroModulos.Modulos) {
        if ($m.Nombre -eq $NombreModulo) {
            return $m
        }
    }
    return $null
}