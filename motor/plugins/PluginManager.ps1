<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : PluginManager.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Gestión de plugins del Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterprisePluginManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaRaizRepositorio,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$VersionKernelActual
    )

    $RutaPlugins = Join-Path $RutaRaizRepositorio "plugins"

    return [pscustomobject][ordered]@{
        RutaPlugins        = $RutaPlugins
        VersionKernel      = $VersionKernelActual
        PluginsCargados    = @()
        EstadoPlugins      = "Inicializado"
    }
}

function Initialize-HermesEnterprisePlugins {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$AdministradorPlugins
    )

    $RutaPlugins = $AdministradorPlugins.RutaPlugins

    if (-not (Test-Path $RutaPlugins)) {
        New-Item -ItemType Directory -Path $RutaPlugins -Force | Out-Null
    }

    $ArchivosPlugin = Get-ChildItem -Path $RutaPlugins -Filter "*.ps1" -ErrorAction SilentlyContinue
    foreach ($archivo in $ArchivosPlugin) {
        try {
            . $archivo.FullName
            $AdministradorPlugins.PluginsCargados += @{
                Ruta    = $archivo.FullName
                Nombre  = $archivo.BaseName
                Estado  = "Cargado"
            }
        } catch {
            $AdministradorPlugins.PluginsCargados += @{
                Ruta    = $archivo.FullName
                Nombre  = $archivo.BaseName
                Estado  = "Error"
                Error   = $_.Exception.Message
            }
        }
    }

    $AdministradorPlugins.EstadoPlugins = "Inicializado"
    return $AdministradorPlugins.PluginsCargados
}