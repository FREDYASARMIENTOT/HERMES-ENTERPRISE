<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-DocumentationEngine.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Ejecuta pruebas unitarias sin dependencias externas para validar el Motor Generador de
    Documentación Enterprise creado en la Fase 0.2.

Características:
    - Sin Pester para mantener cero dependencias externas en esta fase.
    - Compatible con PowerShell 7.
    - Falla con mensajes explícitos cuando una validación no se cumple.
====================================================================================================
#>

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------------------
# Resolver rutas principales desde la ubicación del archivo de prueba.
# -----------------------------------------------------------------------------------------

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaDirectorioPruebas = Split-Path -Parent $RutaDirectorioPruebasUnitarias
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioPruebas

# -----------------------------------------------------------------------------------------
# Definir una aserción mínima para no depender de frameworks externos.
# -----------------------------------------------------------------------------------------

function Assert-HermesEnterpriseCondition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$CondicionEvaluada,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$MensajeError
    )

    if (-not $CondicionEvaluada) {
        throw $MensajeError
    }
}

# -----------------------------------------------------------------------------------------
# Importar utilidades y builder para probar funciones públicas del motor documental.
# -----------------------------------------------------------------------------------------

. (Join-Path -Path $RutaRaizRepositorio -ChildPath "builders\MarkdownUtilities.ps1")
. (Join-Path -Path $RutaRaizRepositorio -ChildPath "builders\DocumentMetadata.ps1")
. (Join-Path -Path $RutaRaizRepositorio -ChildPath "builders\DocumentBuilder.ps1")

# -----------------------------------------------------------------------------------------
# Validar conversión de anclas Markdown.
# -----------------------------------------------------------------------------------------

$AnclaGenerada = ConvertTo-HermesEnterpriseMarkdownAnchor -TituloMarkdown "Arquitectura Empresarial"
Assert-HermesEnterpriseCondition `
    -CondicionEvaluada ($AnclaGenerada -eq "arquitectura-empresarial") `
    -MensajeError "La generación de anclas Markdown no produjo el valor esperado."

# -----------------------------------------------------------------------------------------
# Validar construcción de metadatos documentales.
# -----------------------------------------------------------------------------------------

$MetadatosPrueba = New-HermesEnterpriseDocumentMetadata -NombreDocumento "Documento de Prueba"
Assert-HermesEnterpriseCondition `
    -CondicionEvaluada ($MetadatosPrueba.Proyecto -eq "HERMES-ENTERPRISE") `
    -MensajeError "Los metadatos no incluyen el nombre correcto del proyecto."

# -----------------------------------------------------------------------------------------
# Validar reemplazo de tokens de plantilla.
# -----------------------------------------------------------------------------------------

$ContenidoResuelto = Resolve-HermesEnterpriseMarkdownTemplateTokens `
    -ContenidoPlantillaMarkdown "Proyecto: {{Proyecto}}" `
    -ValoresTokensPlantilla @{ Proyecto = "HERMES-ENTERPRISE" }

Assert-HermesEnterpriseCondition `
    -CondicionEvaluada ($ContenidoResuelto -eq "Proyecto: HERMES-ENTERPRISE") `
    -MensajeError "La resolución de tokens de plantilla falló."

# -----------------------------------------------------------------------------------------
# Validar generación de contenido documental a partir de una especificación mínima.
# -----------------------------------------------------------------------------------------

$EspecificacionDocumentoPrueba = New-HermesEnterpriseDocumentSpecification `
    -IdentificadorDocumento "DOC-TEST" `
    -TituloDocumento "Documento de Prueba" `
    -RutaRelativaSalida "documentacion\DocumentoPrueba.md" `
    -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
    -ValoresAdicionalesPlantilla @{
        PropositoDocumento = "Validar el motor documental."
        AlcanceDocumento = "Prueba unitaria local."
        ContenidoInicialDocumento = "Contenido controlado de prueba."
        ReferenciasCruzadas = "Sin referencias externas."
    }

$ContenidoPlantillaPrueba = Get-Content -Path (Join-Path -Path $RutaRaizRepositorio -ChildPath "plantillas\DocumentoBase.md.tpl") -Raw
$ContenidoDocumentoPrueba = New-HermesEnterpriseDocumentContent `
    -EspecificacionDocumento $EspecificacionDocumentoPrueba `
    -ContenidoPlantillaMarkdown $ContenidoPlantillaPrueba

Assert-HermesEnterpriseCondition `
    -CondicionEvaluada ($ContenidoDocumentoPrueba.Contains("# Documento de Prueba")) `
    -MensajeError "El builder no generó el título esperado."

Assert-HermesEnterpriseCondition `
    -CondicionEvaluada ($ContenidoDocumentoPrueba.Contains("## Tabla de contenido")) `
    -MensajeError "El builder no generó tabla de contenido."

# -----------------------------------------------------------------------------------------
# Validar que la plantilla especializada de Bootstrap puede renderizar una especificación
# ejecutable con las secciones Enterprise que convierten el documento en contrato de arranque.
# -----------------------------------------------------------------------------------------

$EspecificacionBootstrapPrueba = New-HermesEnterpriseDocumentSpecification `
    -IdentificadorDocumento "DOC-BOOTSTRAP-TEST" `
    -TituloDocumento "Bootstrap Enterprise" `
    -RutaRelativaSalida "documentacion\BOOTSTRAP.md" `
    -RutaRelativaPlantilla "plantillas\BootstrapEnterprise.md.tpl" `
    -NombresSeccionesDocumento @("Propósito", "Alcance", "Secuencia de inicialización", "Contratos de Bootstrap", "Estados del ciclo de arranque", "Eventos publicados", "Métricas y telemetría", "Recuperación ante fallos", "Contenido inicial", "Referencias cruzadas") `
    -ValoresAdicionalesPlantilla @{
        PropositoDocumento = "Validar Bootstrap como fase de nacimiento del sistema."
        AlcanceDocumento = "Prueba unitaria local."
        SecuenciaInicializacion = "Secuencia controlada."
        ContratosBootstrap = "Contrato controlado."
        EstadosCicloArranque = "READY."
        EventosPublicados = "Bootstrap.Completed."
        MetricasTelemetria = "bootstrap.total.duration."
        RecuperacionFallos = "Abort."
        ContenidoInicialDocumento = "Contenido controlado de Bootstrap."
        ReferenciasCruzadas = "Kernel."
    }

$ContenidoPlantillaBootstrapPrueba = Get-Content -Path (Join-Path -Path $RutaRaizRepositorio -ChildPath "plantillas\BootstrapEnterprise.md.tpl") -Raw
$ContenidoBootstrapPrueba = New-HermesEnterpriseDocumentContent `
    -EspecificacionDocumento $EspecificacionBootstrapPrueba `
    -ContenidoPlantillaMarkdown $ContenidoPlantillaBootstrapPrueba

Assert-HermesEnterpriseCondition `
    -CondicionEvaluada ($ContenidoBootstrapPrueba.Contains("## Contratos de Bootstrap")) `
    -MensajeError "La plantilla de Bootstrap no generó la sección de contratos."

Assert-HermesEnterpriseCondition `
    -CondicionEvaluada ($ContenidoBootstrapPrueba.Contains("## Métricas y telemetría")) `
    -MensajeError "La plantilla de Bootstrap no generó la sección de métricas y telemetría."

Assert-HermesEnterpriseCondition `
    -CondicionEvaluada ($ContenidoBootstrapPrueba.Contains("## Recuperación ante fallos")) `
    -MensajeError "La plantilla de Bootstrap no generó la sección de recuperación ante fallos."

Write-Host "Pruebas del motor documental completadas correctamente." -ForegroundColor Green
