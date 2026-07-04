<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : New-HermesEnterpriseDocumentation.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Orquesta el Motor Generador de Documentación Enterprise para construir documentos Markdown
    desde plantillas reutilizables, metadatos centralizados y especificaciones declarativas.

Alcance de Fase 0.2:
    - Crear infraestructura del motor documental.
    - Demostrar generación controlada de documentos base mínimos.
    - No generar todavía documentación extensa ni las 300 páginas definitivas.

Características:
    - Idempotente.
    - Sin dependencias externas.
    - Compatible con PowerShell 7.
    - Arquitectura modular basada en builders y plantillas.
====================================================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$VersionProyecto = "1.0.0",

    [Parameter(Mandatory = $false)]
    [switch]$SoloValidar
)

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------------------
# Resolver la raíz del repositorio desde la ubicación del script.
# Esta estrategia permite ejecutar el generador desde cualquier directorio de trabajo.
# -----------------------------------------------------------------------------------------

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScripts

# -----------------------------------------------------------------------------------------
# Importar el constructor documental central.
# El script falla explícitamente si el builder no existe, evitando ejecuciones parciales.
# -----------------------------------------------------------------------------------------

$RutaDocumentBuilder = Join-Path -Path $RutaRaizRepositorio -ChildPath "builders\DocumentBuilder.ps1"

if (-not (Test-Path -Path $RutaDocumentBuilder)) {
    throw "No se encontró el constructor documental requerido: $RutaDocumentBuilder"
}

. $RutaDocumentBuilder

# -----------------------------------------------------------------------------------------
# Declarar rutas requeridas por el motor documental.
# Todas las rutas son relativas al repositorio para evitar acoplamiento con una máquina.
# -----------------------------------------------------------------------------------------

$RutasRequeridasMotorDocumental = @(
    "documentacion",
    "plantillas",
    "builders",
    "scripts",
    "plantillas\DocumentoBase.md.tpl",
    "plantillas\IndiceDocumentacion.md.tpl",
    "builders\DocumentBuilder.ps1",
    "builders\MarkdownUtilities.ps1",
    "builders\DocumentMetadata.ps1"
)

foreach ($RutaRequeridaMotorDocumental in $RutasRequeridasMotorDocumental) {
    $RutaCompletaRequeridaMotorDocumental = Join-Path -Path $RutaRaizRepositorio -ChildPath $RutaRequeridaMotorDocumental

    if (-not (Test-Path -Path $RutaCompletaRequeridaMotorDocumental)) {
        throw "Falta un componente requerido del motor documental: $RutaRequeridaMotorDocumental"
    }
}

# -----------------------------------------------------------------------------------------
# Definir contenido reutilizable común para evitar duplicación textual entre documentos.
# En fases futuras estos valores podrán venir de configuración centralizada o manifestos.
# -----------------------------------------------------------------------------------------

$DescripcionBibliotecaDocumental = @"
La biblioteca documental de HERMES-ENTERPRISE será generada desde plantillas reutilizables,
metadatos centralizados y especificaciones declarativas. Esta fase crea únicamente la
infraestructura del generador; el contenido extenso se incorporará de forma controlada en fases
posteriores.
"@

$ReferenciasCruzadasBase = @"
- README principal: README.md
- Project Charter: documentacion/PROJECT_CHARTER.md
- Visión: documentacion/VISION.md
- SRS: documentacion/SRS_HERMES_ENTERPRISE.md
- Motor documental: builders/DocumentBuilder.ps1
"@

# -----------------------------------------------------------------------------------------
# Construir especificaciones declarativas de documentos mínimos.
# Cada documento se genera a partir de plantilla y tokens; no se duplica estructura Markdown.
# -----------------------------------------------------------------------------------------

$EspecificacionesDocumentos = @(
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-README" `
        -TituloDocumento "HERMES-ENTERPRISE" `
        -RutaRelativaSalida "README.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -RutaDocumentoSiguiente "documentacion/PROJECT_CHARTER.md" `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Presentar la plataforma empresarial de ingeniería para agentes inteligentes."
            AlcanceDocumento = "Este README es generado por el motor documental y será enriquecido progresivamente."
            ContenidoInicialDocumento = $DescripcionBibliotecaDocumental
            ReferenciasCruzadas = $ReferenciasCruzadasBase
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-INDEX" `
        -TituloDocumento "Índice de Documentación Enterprise" `
        -RutaRelativaSalida "documentacion\README.md" `
        -RutaRelativaPlantilla "plantillas\IndiceDocumentacion.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Biblioteca documental", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Servir como punto de entrada a la biblioteca técnica versionada del proyecto."
            ContenidoInicialDocumento = $DescripcionBibliotecaDocumental
            ReferenciasCruzadas = $ReferenciasCruzadasBase
        })
)

# -----------------------------------------------------------------------------------------
# Si se solicita solo validación, terminar después de verificar dependencias y especificaciones.
# -----------------------------------------------------------------------------------------

if ($SoloValidar.IsPresent) {
    Write-Host "Motor documental validado correctamente." -ForegroundColor Green
    Write-Host "Repositorio : $RutaRaizRepositorio"
    Write-Host "Documentos  : $($EspecificacionesDocumentos.Count)"
    return
}

# -----------------------------------------------------------------------------------------
# Ejecutar la generación de documentos mínimos.
# Cada documento se escribe de forma idempotente; archivos sin cambios no se reescriben.
# -----------------------------------------------------------------------------------------

$CantidadDocumentosActualizados = 0

foreach ($EspecificacionDocumento in $EspecificacionesDocumentos) {
    $DocumentoFueActualizado = Invoke-HermesEnterpriseDocumentBuild `
        -EspecificacionDocumento $EspecificacionDocumento `
        -RutaRaizRepositorio $RutaRaizRepositorio `
        -VersionProyecto $VersionProyecto

    if ($DocumentoFueActualizado) {
        $CantidadDocumentosActualizados++
    }
}

# -----------------------------------------------------------------------------------------
# Mostrar resumen final para uso local y automatización futura en CI.
# -----------------------------------------------------------------------------------------

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "Motor documental ejecutado correctamente." -ForegroundColor Green
Write-Host "Repositorio             : $RutaRaizRepositorio"
Write-Host "Documentos declarados   : $($EspecificacionesDocumentos.Count)"
Write-Host "Documentos actualizados : $CantidadDocumentosActualizados"
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
