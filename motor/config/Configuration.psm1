<#
Proyecto : HERMES-ENTERPRISE
Archivo  : Configuration.psm1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Gestión de configuración del Kernel Enterprise.
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseConfigurationManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaArchivoConfiguracion
    )

    return [pscustomobject][ordered]@{
        RutaArchivo = $RutaArchivoConfiguracion
        ConfiguracionCargada = $false
    }
}

function Get-HermesEnterpriseConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$AdministradorConfiguracion
    )

    if (-not (Test-Path $AdministradorConfiguracion.RutaArchivo)) {
        throw "Archivo de configuración no encontrado: $($AdministradorConfiguracion.RutaArchivo)"
    }

    $configJson = Get-Content -Path $AdministradorConfiguracion.RutaArchivo -Raw -ErrorAction Stop
    $config = $configJson | ConvertFrom-Json

    $AdministradorConfiguracion.ConfiguracionCargada = $true
    return $config
}

function Get-HermesConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Config not found: $ConfigPath"
    }

    return Get-Content $ConfigPath -Raw | ConvertFrom-Json
}

Export-ModuleMember -Function New-HermesEnterpriseConfigurationManager, Get-HermesEnterpriseConfiguration, Get-HermesConfiguration
