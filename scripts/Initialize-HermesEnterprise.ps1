<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Initialize-HermesEnterprise.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Inicializa completamente el repositorio HERMES-ENTERPRISE siguiendo la arquitectura oficial
    Enterprise definida para la Fase 0.1 del proyecto.

Características:
    - Idempotente: puede ejecutarse varias veces sin sobrescribir contenido existente.
    - Seguro: no elimina archivos, no modifica secretos y no destruye información previa.
    - Documentado: cada bloque tiene comentarios descriptivos.
    - Gobernable: deja el repositorio listo para iniciar Ingeniería de Requisitos.
====================================================================================================
#>

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "        INICIALIZANDO HERMES ENTERPRISE" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------------------------
# Obtener la ruta absoluta de la raíz del repositorio desde el directorio actual.
# Esta decisión evita rutas codificadas y permite ejecutar el script desde cualquier clon.
# -----------------------------------------------------------------------------------------

$RutaRaizRepositorio = (Get-Location).Path

# -----------------------------------------------------------------------------------------
# Validar que Git esté disponible antes de intentar inicializar o configurar el repositorio.
# Si Git no existe, el script falla con un mensaje explícito y accionable.
# -----------------------------------------------------------------------------------------

if (-not (Get-Command -Name git -ErrorAction SilentlyContinue)) {
    throw "Git no está disponible en el PATH. Instale Git antes de inicializar HERMES-ENTERPRISE."
}

# -----------------------------------------------------------------------------------------
# Crear estructura Enterprise.
# Cada directorio se crea únicamente si no existe para preservar cualquier contenido previo.
# -----------------------------------------------------------------------------------------

$DirectoriosProyecto = @(
    ".github",
    ".github\ISSUE_TEMPLATE",
    ".vscode",
    "agentes",
    "arquitectura",
    "arquitectura\diagramas",
    "arquitectura\decisiones",
    "builders",
    "configuracion",
    "documentacion",
    "documentacion\requisitos",
    "documentacion\arquitectura",
    "documentacion\manuales",
    "herramientas",
    "memoria",
    "motor",
    "perfiles",
    "plantillas",
    "protocolos",
    "proveedores",
    "pruebas",
    "pruebas\unitarias",
    "pruebas\integracion",
    "scripts"
)

foreach ($Directorio in $DirectoriosProyecto) {
    # Construir la ruta completa de forma portable para evitar rutas codificadas.
    $RutaCompletaDirectorio = Join-Path -Path $RutaRaizRepositorio -ChildPath $Directorio

    # Crear el directorio solamente cuando no exista.
    if (-not (Test-Path -Path $RutaCompletaDirectorio)) {
        New-Item -ItemType Directory -Path $RutaCompletaDirectorio | Out-Null
        Write-Host "Creado : $Directorio" -ForegroundColor Green
    }
    else {
        Write-Host "Existe : $Directorio" -ForegroundColor DarkGray
    }
}

# -----------------------------------------------------------------------------------------
# Crear archivos .gitkeep dentro de cada directorio Enterprise.
# Git no versiona directorios vacíos; estos marcadores permiten conservar la estructura
# completa del producto desde el primer commit sin introducir contenido funcional prematuro.
# -----------------------------------------------------------------------------------------

foreach ($Directorio in $DirectoriosProyecto) {
    # Construir la ruta completa del archivo marcador dentro del directorio actual.
    $RutaArchivoMarcadorDirectorio = Join-Path -Path $RutaRaizRepositorio -ChildPath (Join-Path -Path $Directorio -ChildPath ".gitkeep")

    # Crear el marcador únicamente si no existe para mantener la ejecución idempotente.
    if (-not (Test-Path -Path $RutaArchivoMarcadorDirectorio)) {
        New-Item -ItemType File -Path $RutaArchivoMarcadorDirectorio | Out-Null
        Write-Host "Marcador: $Directorio\.gitkeep" -ForegroundColor Blue
    }
    else {
        Write-Host "Existe  : $Directorio\.gitkeep" -ForegroundColor DarkGray
    }
}

# -----------------------------------------------------------------------------------------
# Crear archivos principales si no existen.
# Los archivos se inicializan como placeholders controlados porque la Fase 0.2 generará
# el contenido documental extenso mediante un generador automático.
# -----------------------------------------------------------------------------------------

$ArchivosBase = @(
    "README.md",
    "LICENSE",
    "CHANGELOG.md",
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    ".gitignore",
    ".github\CODEOWNERS",
    "documentacion\PROJECT_CHARTER.md",
    "documentacion\VISION.md",
    "documentacion\MISSION.md",
    "documentacion\OBJECTIVES.md",
    "documentacion\PRINCIPLES.md",
    "documentacion\CODING_STANDARD.md",
    "documentacion\DIRECTORY_STANDARD.md",
    "documentacion\ARCHITECTURE_DECISIONS.md",
    "documentacion\SRS_HERMES_ENTERPRISE.md"
)

foreach ($Archivo in $ArchivosBase) {
    # Construir la ruta completa de archivo desde la raíz del repositorio.
    $RutaCompletaArchivo = Join-Path -Path $RutaRaizRepositorio -ChildPath $Archivo

    # Crear el archivo únicamente si no existe para no sobrescribir contenido manual o generado.
    if (-not (Test-Path -Path $RutaCompletaArchivo)) {
        New-Item -ItemType File -Path $RutaCompletaArchivo | Out-Null
        Write-Host "Archivo : $Archivo" -ForegroundColor Yellow
    }
    else {
        Write-Host "Existe  : $Archivo" -ForegroundColor DarkGray
    }
}

# -----------------------------------------------------------------------------------------
# Inicializar Git cuando el directorio actual todavía no sea un repositorio.
# Si ya existe .git, se conserva la configuración actual, incluyendo remotos existentes.
# -----------------------------------------------------------------------------------------

$RutaDirectorioGit = Join-Path -Path $RutaRaizRepositorio -ChildPath ".git"

if (-not (Test-Path -Path $RutaDirectorioGit)) {
    git init
}
else {
    Write-Host "Existe  : .git" -ForegroundColor DarkGray
}

# -----------------------------------------------------------------------------------------
# Configurar la rama principal como main.
# Este comando es idempotente para el objetivo de estandarización del repositorio.
# -----------------------------------------------------------------------------------------

git branch -M main

# -----------------------------------------------------------------------------------------
# Mostrar resumen final de ejecución.
# -----------------------------------------------------------------------------------------

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "Proyecto inicializado correctamente." -ForegroundColor Green
Write-Host "Repositorio : $RutaRaizRepositorio"
Write-Host "Rama        : main"
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
