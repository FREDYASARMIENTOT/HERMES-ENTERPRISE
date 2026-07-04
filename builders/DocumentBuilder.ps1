<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : DocumentBuilder.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Implementa el constructor central de documentos Markdown para HERMES-ENTERPRISE.

Características:
    - Construye documentos desde plantillas reutilizables.
    - Inyecta metadatos, tabla de contenido, navegación y referencias cruzadas.
    - No contiene contenido documental definitivo extenso.
    - Permite regenerar documentos de forma idempotente.
====================================================================================================
#>

Set-StrictMode -Version Latest

$RutaDirectorioConstructorDocumental = Split-Path -Parent $PSCommandPath
. (Join-Path -Path $RutaDirectorioConstructorDocumental -ChildPath "DocumentMetadata.ps1")
. (Join-Path -Path $RutaDirectorioConstructorDocumental -ChildPath "MarkdownUtilities.ps1")

# -------------------------------------------------------------------------------------------------
# Crear una especificación de documento Enterprise.
# La especificación separa datos de construcción, ruta de salida y navegación del proceso de render.
# -------------------------------------------------------------------------------------------------
function New-HermesEnterpriseDocumentSpecification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IdentificadorDocumento,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TituloDocumento,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaRelativaSalida,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaRelativaPlantilla,

        [Parameter(Mandatory = $false)]
        [string[]]$NombresSeccionesDocumento = @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas"),

        [Parameter(Mandatory = $false)]
        [string]$RutaDocumentoAnterior,

        [Parameter(Mandatory = $false)]
        [string]$RutaDocumentoSiguiente,

        [Parameter(Mandatory = $false)]
        [hashtable]$ValoresAdicionalesPlantilla = @{}
    )

    $EspecificacionDocumento = [ordered]@{
        IdentificadorDocumento        = $IdentificadorDocumento
        TituloDocumento               = $TituloDocumento
        RutaRelativaSalida            = $RutaRelativaSalida
        RutaRelativaPlantilla         = $RutaRelativaPlantilla
        NombresSeccionesDocumento     = $NombresSeccionesDocumento
        RutaDocumentoAnterior         = $RutaDocumentoAnterior
        RutaDocumentoSiguiente        = $RutaDocumentoSiguiente
        ValoresAdicionalesPlantilla   = $ValoresAdicionalesPlantilla
    }

    return $EspecificacionDocumento
}

# -------------------------------------------------------------------------------------------------
# Construir el contenido Markdown completo de un documento a partir de una plantilla y metadatos.
# Esta función es pura respecto al contenido: recibe datos y devuelve texto Markdown renderizado.
# -------------------------------------------------------------------------------------------------
function New-HermesEnterpriseDocumentContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$EspecificacionDocumento,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ContenidoPlantillaMarkdown,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$VersionProyecto = "1.0.0"
    )

    $MetadatosDocumento = New-HermesEnterpriseDocumentMetadata `
        -NombreDocumento $EspecificacionDocumento.TituloDocumento `
        -VersionProyecto $VersionProyecto

    $MarkdownMetadatosDocumento = ConvertTo-HermesEnterpriseMetadataMarkdown -MetadatosDocumento $MetadatosDocumento
    $MarkdownTablaContenido = New-HermesEnterpriseMarkdownTableOfContents -NombresSeccionesDocumento $EspecificacionDocumento.NombresSeccionesDocumento
    $MarkdownNavegacion = New-HermesEnterpriseMarkdownNavigation `
        -RutaDocumentoAnterior $EspecificacionDocumento.RutaDocumentoAnterior `
        -RutaDocumentoSiguiente $EspecificacionDocumento.RutaDocumentoSiguiente

    $ValoresTokensPlantilla = @{
        TituloDocumento       = $EspecificacionDocumento.TituloDocumento
        IdentificadorDocumento = $EspecificacionDocumento.IdentificadorDocumento
        Metadatos             = $MarkdownMetadatosDocumento
        TablaContenido        = $MarkdownTablaContenido
        Navegacion            = $MarkdownNavegacion
    }

    foreach ($NombreValorAdicional in $EspecificacionDocumento.ValoresAdicionalesPlantilla.Keys) {
        $ValoresTokensPlantilla[$NombreValorAdicional] = $EspecificacionDocumento.ValoresAdicionalesPlantilla[$NombreValorAdicional]
    }

    $ContenidoDocumentoGenerado = Resolve-HermesEnterpriseMarkdownTemplateTokens `
        -ContenidoPlantillaMarkdown $ContenidoPlantillaMarkdown `
        -ValoresTokensPlantilla $ValoresTokensPlantilla

    return $ContenidoDocumentoGenerado
}

# -------------------------------------------------------------------------------------------------
# Escribir un documento generado en disco de forma idempotente.
# Si el contenido actual es idéntico, no reescribe el archivo para evitar cambios innecesarios.
# -------------------------------------------------------------------------------------------------
function Write-HermesEnterpriseGeneratedDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaArchivoSalida,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string]$ContenidoDocumentoGenerado
    )

    $RutaDirectorioSalida = Split-Path -Parent $RutaArchivoSalida

    # Normalizar el contenido generado con salto de línea final único.
    # PowerShell agrega salto de línea al escribir con Set-Content; normalizar antes de comparar
    # evita que el motor reescriba documentos idénticos en cada ejecución.
    if (-not $ContenidoDocumentoGenerado.EndsWith([Environment]::NewLine)) {
        $ContenidoDocumentoGenerado = $ContenidoDocumentoGenerado + [Environment]::NewLine
    }

    if (-not (Test-Path -Path $RutaDirectorioSalida)) {
        New-Item -ItemType Directory -Path $RutaDirectorioSalida | Out-Null
    }

    if (Test-Path -Path $RutaArchivoSalida) {
        # Leer con API .NET preserva el contenido exacto y evita normalizaciones de Get-Content.
        $ContenidoActualDocumento = [System.IO.File]::ReadAllText($RutaArchivoSalida)

        if ($ContenidoActualDocumento -eq $ContenidoDocumentoGenerado) {
            Write-Host "Sin cambios: $RutaArchivoSalida" -ForegroundColor DarkGray
            return $false
        }
    }

    # Escribir con API .NET evita que Set-Content agregue saltos de línea adicionales.
    # UTF8Encoding(false) evita BOM y mantiene archivos Markdown limpios para GitHub.
    $CodificacionUtf8SinMarcaOrdenBytes = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($RutaArchivoSalida, $ContenidoDocumentoGenerado, $CodificacionUtf8SinMarcaOrdenBytes)
    Write-Host "Generado  : $RutaArchivoSalida" -ForegroundColor Green
    return $true
}

# -------------------------------------------------------------------------------------------------
# Construir un documento completo desde su especificación, resolviendo rutas de plantilla y salida.
# Esta es la función principal usada por scripts orquestadores.
# -------------------------------------------------------------------------------------------------
function Invoke-HermesEnterpriseDocumentBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$EspecificacionDocumento,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaRaizRepositorio,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$VersionProyecto = "1.0.0"
    )

    $RutaCompletaPlantilla = Join-Path -Path $RutaRaizRepositorio -ChildPath $EspecificacionDocumento.RutaRelativaPlantilla
    $RutaCompletaSalida = Join-Path -Path $RutaRaizRepositorio -ChildPath $EspecificacionDocumento.RutaRelativaSalida

    if (-not (Test-Path -Path $RutaCompletaPlantilla)) {
        throw "No existe la plantilla requerida: $RutaCompletaPlantilla"
    }

    $ContenidoPlantillaMarkdown = Get-Content -Path $RutaCompletaPlantilla -Raw
    $ContenidoDocumentoGenerado = New-HermesEnterpriseDocumentContent `
        -EspecificacionDocumento $EspecificacionDocumento `
        -ContenidoPlantillaMarkdown $ContenidoPlantillaMarkdown `
        -VersionProyecto $VersionProyecto

    return Write-HermesEnterpriseGeneratedDocument `
        -RutaArchivoSalida $RutaCompletaSalida `
        -ContenidoDocumentoGenerado $ContenidoDocumentoGenerado
}


