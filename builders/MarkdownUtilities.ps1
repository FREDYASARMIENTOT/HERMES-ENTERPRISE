<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : MarkdownUtilities.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Proporciona utilidades Markdown reutilizables para el Motor Generador de Documentación
    Enterprise.

Características:
    - Sin dependencias externas.
    - Compatible con PowerShell 7.
    - Funciones pequeñas y reutilizables.
====================================================================================================
#>

Set-StrictMode -Version Latest

# -------------------------------------------------------------------------------------------------
# Convertir un título Markdown en un ancla compatible con la convención general de GitHub.
# Esta función es necesaria para construir tablas de contenido y navegación interna.
# -------------------------------------------------------------------------------------------------
function ConvertTo-HermesEnterpriseMarkdownAnchor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TituloMarkdown
    )

    # Normalizar a minúsculas y eliminar caracteres comunes que no forman parte del ancla.
    $AnclaNormalizada = $TituloMarkdown.ToLowerInvariant()
    $AnclaNormalizada = $AnclaNormalizada -replace '[áàäâ]', 'a'
    $AnclaNormalizada = $AnclaNormalizada -replace '[éèëê]', 'e'
    $AnclaNormalizada = $AnclaNormalizada -replace '[íìïî]', 'i'
    $AnclaNormalizada = $AnclaNormalizada -replace '[óòöô]', 'o'
    $AnclaNormalizada = $AnclaNormalizada -replace '[úùüû]', 'u'
    $AnclaNormalizada = $AnclaNormalizada -replace 'ñ', 'n'
    $AnclaNormalizada = $AnclaNormalizada -replace '[^a-z0-9\s-]', ''
    $AnclaNormalizada = $AnclaNormalizada.Trim() -replace '\s+', '-'
    $AnclaNormalizada = $AnclaNormalizada -replace '-+', '-'

    return $AnclaNormalizada
}

# -------------------------------------------------------------------------------------------------
# Construir una tabla de contenido Markdown a partir de una lista de secciones.
# Cada sección debe ser texto plano, sin el prefijo de numeral Markdown.
# -------------------------------------------------------------------------------------------------
function New-HermesEnterpriseMarkdownTableOfContents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]]$NombresSeccionesDocumento
    )

    $LineasTablaContenido = New-Object System.Collections.Generic.List[string]
    $LineasTablaContenido.Add("## Tabla de contenido")
    $LineasTablaContenido.Add("")

    foreach ($NombreSeccionDocumento in $NombresSeccionesDocumento) {
        $AnclaSeccionDocumento = ConvertTo-HermesEnterpriseMarkdownAnchor -TituloMarkdown $NombreSeccionDocumento
        $LineasTablaContenido.Add("- [$NombreSeccionDocumento](#$AnclaSeccionDocumento)")
    }

    return ($LineasTablaContenido -join [Environment]::NewLine)
}

# -------------------------------------------------------------------------------------------------
# Crear bloque de navegación estándar para enlazar documentos relacionados.
# La navegación se mantiene como datos para poder regenerarse de forma consistente.
# -------------------------------------------------------------------------------------------------
function New-HermesEnterpriseMarkdownNavigation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RutaDocumentoAnterior,

        [Parameter(Mandatory = $false)]
        [string]$RutaDocumentoSiguiente,

        [Parameter(Mandatory = $false)]
        [string]$RutaIndiceDocumentacion = "README.md"
    )

    $LineasNavegacion = New-Object System.Collections.Generic.List[string]
    $LineasNavegacion.Add("## Navegación")
    $LineasNavegacion.Add("")
    $LineasNavegacion.Add("- [Índice de documentación]($RutaIndiceDocumentacion)")

    if (-not [string]::IsNullOrWhiteSpace($RutaDocumentoAnterior)) {
        $LineasNavegacion.Add("- [Documento anterior]($RutaDocumentoAnterior)")
    }

    if (-not [string]::IsNullOrWhiteSpace($RutaDocumentoSiguiente)) {
        $LineasNavegacion.Add("- [Documento siguiente]($RutaDocumentoSiguiente)")
    }

    return ($LineasNavegacion -join [Environment]::NewLine)
}

# -------------------------------------------------------------------------------------------------
# Reemplazar tokens de plantilla en formato {{NombreToken}}.
# Esta función evita concatenación manual repetitiva y centraliza el mecanismo de plantillas.
# -------------------------------------------------------------------------------------------------
function Resolve-HermesEnterpriseMarkdownTemplateTokens {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string]$ContenidoPlantillaMarkdown,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$ValoresTokensPlantilla
    )

    $ContenidoMarkdownResuelto = $ContenidoPlantillaMarkdown

    foreach ($NombreTokenPlantilla in $ValoresTokensPlantilla.Keys) {
        $TokenPlantilla = "{{" + $NombreTokenPlantilla + "}}"
        $ValorTokenPlantilla = [string]$ValoresTokensPlantilla[$NombreTokenPlantilla]
        $ContenidoMarkdownResuelto = $ContenidoMarkdownResuelto.Replace($TokenPlantilla, $ValorTokenPlantilla)
    }

    return $ContenidoMarkdownResuelto
}


