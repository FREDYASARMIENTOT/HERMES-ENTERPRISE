<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : DocumentMetadata.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Define funciones reutilizables para construir metadatos documentales consistentes en todo el
    ecosistema de documentación Enterprise.

Características:
    - Compatible con PowerShell 7.
    - Sin dependencias externas.
    - Idempotente.
    - Diseñado para ser utilizado por DocumentBuilder.ps1.
====================================================================================================
#>

Set-StrictMode -Version Latest

# -------------------------------------------------------------------------------------------------
# Crear un objeto de metadatos estándar para cualquier documento de HERMES-ENTERPRISE.
# Esta función centraliza versión, autor, licencia, repositorio y arquitectura base para evitar
# duplicación de texto entre plantillas y documentos generados.
# -------------------------------------------------------------------------------------------------
function New-HermesEnterpriseDocumentMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreDocumento,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$VersionProyecto = "1.0.0",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$AutorPrincipal = "Fredy Alejandro Sarmiento Torres",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$LicenciaProyecto = "MIT",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositorioOficial = "https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ArquitecturaBase = "Hermes Agent + Azure AI Foundry + MCP + A2A"
    )

    # Usar un diccionario ordenado garantiza que la salida Markdown sea estable entre ejecuciones.
    $MetadatosDocumento = [ordered]@{
        NombreDocumento     = $NombreDocumento
        Proyecto            = "HERMES-ENTERPRISE"
        Version             = $VersionProyecto
        AutorPrincipal      = $AutorPrincipal
        Licencia            = $LicenciaProyecto
        RepositorioOficial  = $RepositorioOficial
        ArquitecturaBase    = $ArquitecturaBase
        FechaGeneracion     = (Get-Date).ToString("yyyy-MM-dd")
        GeneradoPor         = "New-HermesEnterpriseDocumentation.ps1"
    }

    return $MetadatosDocumento
}

# -------------------------------------------------------------------------------------------------
# Convertir los metadatos estándar en una tabla Markdown reutilizable.
# Esta función permite que todos los documentos compartan encabezados homogéneos.
# -------------------------------------------------------------------------------------------------
function ConvertTo-HermesEnterpriseMetadataMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary]$MetadatosDocumento
    )

    $LineasMarkdownMetadatos = New-Object System.Collections.Generic.List[string]

    $LineasMarkdownMetadatos.Add("| Campo | Valor |")
    $LineasMarkdownMetadatos.Add("|---|---|")

    foreach ($NombreCampoMetadato in $MetadatosDocumento.Keys) {
        $ValorCampoMetadato = [string]$MetadatosDocumento[$NombreCampoMetadato]
        $LineasMarkdownMetadatos.Add("| $NombreCampoMetadato | $ValorCampoMetadato |")
    }

    return ($LineasMarkdownMetadatos -join [Environment]::NewLine)
}


