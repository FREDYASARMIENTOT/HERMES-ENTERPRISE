<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ConfigurationManager.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Administra configuración centralizada del Kernel Enterprise en formato JSON.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseConfigurationManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaArchivoConfiguracion
    )

    $RutaDirectorioConfiguracion = Split-Path -Parent $RutaArchivoConfiguracion
    if (-not (Test-Path $RutaDirectorioConfiguracion)) {
        New-Item -ItemType Directory -Path $RutaDirectorioConfiguracion | Out-Null
    }

    if (-not (Test-Path $RutaArchivoConfiguracion)) {
        $ConfiguracionInicial = [ordered]@{
            Proyecto = "HERMES-ENTERPRISE"
            Kernel = [ordered]@{
                Version = "0.3.0"
                Entorno = "Desarrollo"
                ModulosAutoCarga = @()
            }
        }
        $ConfiguracionInicial | ConvertTo-Json -Depth 10 | Set-Content -Path $RutaArchivoConfiguracion -Encoding UTF8
    }

    return [pscustomobject][ordered]@{
        RutaArchivoConfiguracion = $RutaArchivoConfiguracion
    }
}

function Get-HermesEnterpriseConfiguration {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$AdministradorConfiguracion)

    return Get-Content -Path $AdministradorConfiguracion.RutaArchivoConfiguracion -Raw | ConvertFrom-Json
}
