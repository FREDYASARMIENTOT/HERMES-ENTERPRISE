<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ManifestLoader.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Carga manifiestos plugin.json para el Enterprise Plugin Framework.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Get-HermesEnterprisePluginManifest {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$RutaArchivoManifest)

    # Validar existencia explícitamente evita errores ambiguos de ConvertFrom-Json.
    if (-not (Test-Path -Path $RutaArchivoManifest)) {
        throw "No existe el manifiesto de plugin: $RutaArchivoManifest"
    }

    # Leer el JSON completo y convertirlo a objeto PowerShell para consumo del Kernel.
    $ContenidoManifest = Get-Content -Path $RutaArchivoManifest -Raw
    $ManifestPlugin = $ContenidoManifest | ConvertFrom-Json

    # Validar campos mínimos del contrato de manifiesto.
    foreach ($NombreCampoRequerido in @("Nombre", "Version", "Autor", "KernelMinimo", "ScriptPrincipal")) {
        if (-not $ManifestPlugin.PSObject.Properties.Name.Contains($NombreCampoRequerido)) {
            throw "El manifiesto $RutaArchivoManifest no contiene el campo requerido: $NombreCampoRequerido"
        }
    }

    return $ManifestPlugin
}
