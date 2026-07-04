<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : PluginDiscovery.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Descubre plugins disponibles buscando manifiestos plugin.json bajo el directorio plugins.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Find-HermesEnterprisePlugins {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$RutaDirectorioPlugins)

    $PluginsDescubiertos = New-Object System.Collections.Generic.List[object]

    # Si no existe el directorio de plugins, no es error: simplemente no hay plugins instalados.
    if (-not (Test-Path -Path $RutaDirectorioPlugins)) {
        return @()
    }

    $ArchivosManifest = Get-ChildItem -Path $RutaDirectorioPlugins -Filter "plugin.json" -Recurse -File

    foreach ($ArchivoManifest in $ArchivosManifest) {
        $ManifestPlugin = Get-HermesEnterprisePluginManifest -RutaArchivoManifest $ArchivoManifest.FullName
        $RutaDirectorioPlugin = Split-Path -Parent $ArchivoManifest.FullName
        $RutaScriptPlugin = Join-Path -Path $RutaDirectorioPlugin -ChildPath $ManifestPlugin.ScriptPrincipal

        $PluginsDescubiertos.Add([pscustomobject][ordered]@{
            Manifest = $ManifestPlugin
            RutaDirectorioPlugin = $RutaDirectorioPlugin
            RutaArchivoManifest = $ArchivoManifest.FullName
            RutaScriptPlugin = $RutaScriptPlugin
            EstadoActual = "Discovered"
        })
    }

    return $PluginsDescubiertos.ToArray()
}
