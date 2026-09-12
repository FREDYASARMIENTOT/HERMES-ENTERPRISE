<#
.SYNOPSIS
    RC85 - Prueba canonica de renderizado de plantilla Child
.DESCRIPTION
    Valida el contrato actual de la plantilla main.py usada por Factory
    para generar la landing page de cada proyecto Child.

    PRINCIPIO DE PORTABILIDAD:
    No depende de rutas absolutas. Calcula la raiz del repositorio
    a partir de $PSScriptRoot (dos niveles arriba de pruebas/canonicas/).
    Funciona en Windows local y en GitHub Actions Windows Runner.

    CONTEXTO:
    - Factory canonico: tools/Crear-HermesProyecto.ps1
    - Plantilla Child: tools/Templates/backend/main.py
#>

# Inicializacion portable
$RaizRepositorio = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$RutaPlantilla = Join-Path -Path $RaizRepositorio -ChildPath "tools/Templates/backend/main.py"
$RutaFactory = Join-Path -Path $RaizRepositorio -ChildPath "tools/Crear-HermesProyecto.ps1"

$ConteoExitos = 0
$ConteoFallos = 0

function Escribir-ResultadoPrueba {
    param([string]$NombrePrueba, [bool]$Resultado)
    if ($Resultado) {
        Write-Host "  [PASS] $NombrePrueba" -ForegroundColor Green
        $script:ConteoExitos++
    } else {
        Write-Host "  [FAIL] $NombrePrueba" -ForegroundColor Red
        $script:ConteoFallos++
    }
}

function Mostrar-EncabezadoPrueba {
    param([string]$Titulo)
    Write-Host "[Prueba] $Titulo" -ForegroundColor Yellow
}

# Verificacion pre-vuelo: archivos obligatorios
$ArchivosObligatorios = @{}
$ArchivosObligatorios["Plantilla main.py"] = $RutaPlantilla
$ArchivosObligatorios["Factory canonico"]  = $RutaFactory

$ArchivosFaltantes = @()
foreach ($par in $ArchivosObligatorios.GetEnumerator()) {
    if (-not (Test-Path -LiteralPath $par.Value -PathType Leaf)) {
        $ArchivosFaltantes += $par.Key
    }
}
if ($ArchivosFaltantes.Count -gt 0) {
    Write-Host "[FAIL] Archivos obligatorios no encontrados:" -ForegroundColor Red
    foreach ($nombre in $ArchivosFaltantes) {
        Write-Host "  - $nombre" -ForegroundColor Red
    }
    Write-Host "[FAIL] La prueba no puede continuar sin los archivos del contrato actual." -ForegroundColor Red
    Write-Host "[INFO] Raiz calculada: $RaizRepositorio" -ForegroundColor Yellow
    exit 1
}

# Cargar contenido de archivos
$ContenidoPlantilla = Get-Content -LiteralPath $RutaPlantilla -Raw -Encoding UTF8
$ContenidoFactory = Get-Content -LiteralPath $RutaFactory -Raw -Encoding UTF8

# ========== PRUEBA 1 - Funciones internas de la plantilla ==========
Mostrar-EncabezadoPrueba "Funciones de la plantilla"
Escribir-ResultadoPrueba "_resolve_meta" ($ContenidoPlantilla -match "def _resolve_meta")
Escribir-ResultadoPrueba "_build_pipeline" ($ContenidoPlantilla -match "def _build_pipeline")
Escribir-ResultadoPrueba "consultar_sqlite_param" ($ContenidoPlantilla -match "def consultar_sqlite_param")

# ========== PRUEBA 2 - Landing page ==========
Mostrar-EncabezadoPrueba "Landing page"
Escribir-ResultadoPrueba "response_class=HTMLResponse" ($ContenidoPlantilla -match "response_class=HTMLResponse")
Escribir-ResultadoPrueba "Pipeline definido (_PIPELINE_DEF)" ($ContenidoPlantilla -match "_PIPELINE_DEF")

# ========== PRUEBA 3 - Nodos del pipeline ==========
Mostrar-EncabezadoPrueba "Nodos del pipeline"
$NodosEsperados = @("factory","child-repo","ci","control-plane","oidc","asp-iaur","web-app","zip-deploy","readiness","functional-tests","evidence","online")
foreach ($nodo in $NodosEsperados) {
    Escribir-ResultadoPrueba "Nodo $nodo" ($ContenidoPlantilla -match [regex]::Escape("`"$nodo`""))
}

# ========== PRUEBA 4 - Variables de entorno (fallback) ==========
Mostrar-EncabezadoPrueba "Variables de entorno (fallback)"
$VariablesEntorno = @("HERMES_PROJECT_NAME","HERMES_REGION","HERMES_DEPLOYMENT_ID","HERMES_CORRELATION_ID","HERMES_WEBAPP_NAME")
foreach ($var in $VariablesEntorno) {
    Escribir-ResultadoPrueba "Variable $var" ($ContenidoPlantilla -match $var)
}

# ========== PRUEBA 5 - SQL parametrizado (seguridad) ==========
Mostrar-EncabezadoPrueba "SQL parametrizado (seguridad)"
Escribir-ResultadoPrueba "WHERE CorrelationId = ?" ($ContenidoPlantilla -match [regex]::Escape("WHERE CorrelationId = ?"))
Escribir-ResultadoPrueba "execute(query, params)" ($ContenidoPlantilla -match [regex]::Escape("c.execute(query, params)"))

# ========== PRUEBA 6 - Secciones de la UI ==========
Mostrar-EncabezadoPrueba "Secciones de la UI"
Escribir-ResultadoPrueba "IDENTIDAD DEL PROYECTO" ($ContenidoPlantilla -match "IDENTIDAD DEL PROYECTO")
Escribir-ResultadoPrueba "INFRAESTRUCTURA" ($ContenidoPlantilla -match ">INFRAESTRUCTURA<")
Escribir-ResultadoPrueba "TRAZABILIDAD DE DESPLIEGUE" ($ContenidoPlantilla -match "TRAZABILIDAD DE DESPLIEGUE")
Escribir-ResultadoPrueba "DETALLE DE IMPLEMENTACION" ($ContenidoPlantilla -match "DETALLE DE IMPLEMENTACI")
Escribir-ResultadoPrueba "ACCESOS" ($ContenidoPlantilla -match ">ACCESOS<")
Escribir-ResultadoPrueba "PRUEBAS FUNCIONALES" ($ContenidoPlantilla -match "PRUEBAS FUNCIONALES")
Escribir-ResultadoPrueba "Redoc" ($ContenidoPlantilla -match "redoc")
Escribir-ResultadoPrueba "Footer (Hermes Enterprise 2026)" ($ContenidoPlantilla -match "Hermes Enterprise" -and $ContenidoPlantilla -match "2026")

# ========== PRUEBA 7 - Indicadores visuales del Plan ==========
Mostrar-EncabezadoPrueba "Indicadores visuales del Plan"
Escribir-ResultadoPrueba "Badge REUTILIZADO" ($ContenidoPlantilla -match "REUTILIZADO")
Escribir-ResultadoPrueba "Plan Creado: NO" ($ContenidoPlantilla -match "Plan Creado.*NO")
Escribir-ResultadoPrueba "Plan Reutilizado: SI" ($ContenidoPlantilla -match [regex]::Escape("Plan Reutilizado"))
Escribir-ResultadoPrueba "Badge OIDC" ($ContenidoPlantilla -match "OIDC")

# ========== PRUEBA 8 - Sin duplicados en secciones criticas ==========
Mostrar-EncabezadoPrueba "Sin duplicados"
$CantidadAccesos = ([regex]::Matches($ContenidoPlantilla, ">ACCESOS<")).Count
Escribir-ResultadoPrueba "ACCESOS aparece exactamente una vez" ($CantidadAccesos -eq 1)

# ========== PRUEBA 9 - Placeholders de Factory (variables internas) ==========
Mostrar-EncabezadoPrueba "Placeholders de Factory (variables internas)"
Escribir-ResultadoPrueba "Variable _REGION con placeholder {{REGION}}" ($ContenidoPlantilla -match [regex]::Escape('_REGION = "{{REGION}}"'))
Escribir-ResultadoPrueba "Variable _DEPLOYMENT_ID con placeholder {{DEPLOYMENT_ID}}" ($ContenidoPlantilla -match [regex]::Escape('_DEPLOYMENT_ID = "{{DEPLOYMENT_ID}}"'))

# ========== PRUEBA 10 - Detalle de implementacion ==========
Mostrar-EncabezadoPrueba "Detalle de implementacion"
Escribir-ResultadoPrueba "Menciona Crear-HermesProyecto" ($ContenidoPlantilla -match "Crear-HermesProyecto")
Escribir-ResultadoPrueba "Menciona deploy-child.yml" ($ContenidoPlantilla -match "deploy-child.yml")
Escribir-ResultadoPrueba "Menciona ZIP Deploy" ($ContenidoPlantilla -match "ZIP Deploy")
Escribir-ResultadoPrueba "Menciona deployment-report.json" ($ContenidoPlantilla -match "deployment-report.json")

# ========== PRUEBA 11 - Factory canonico ==========
Mostrar-EncabezadoPrueba "Factory canonico (Crear-HermesProyecto.ps1)"
Escribir-ResultadoPrueba "Usa .Replace() (no -replace)" ($ContenidoFactory -match [regex]::Escape('.Replace('))
Escribir-ResultadoPrueba "Reemplaza REGION mediante .Replace()" ($ContenidoFactory -match "REGION" -and $ContenidoFactory -match "Replace")
Escribir-ResultadoPrueba "Reemplaza DEPLOYMENT_ID mediante .Replace()" ($ContenidoFactory -match "DEPLOYMENT_ID" -and $ContenidoFactory -match "Replace")
Escribir-ResultadoPrueba "Validacion de ubicacion (ContainsKey)" ($ContenidoFactory -match "ContainsKey")

# ========== RESULTADO FINAL ==========
Write-Host "================================" -ForegroundColor Cyan
Write-Host "RESULTADO" -ForegroundColor Cyan
Write-Host "TOTAL : $($ConteoExitos + $ConteoFallos)" -ForegroundColor Cyan
Write-Host "PASS  : $ConteoExitos" -ForegroundColor Green
Write-Host "FAIL  : $ConteoFallos" -ForegroundColor $(if ($ConteoFallos -eq 0) { 'Green' } else { 'Red' })
if ($ConteoFallos -eq 0) {
    Write-Host "RESULT: ALL PASSED" -ForegroundColor Green
} else {
    Write-Host "RESULT: $ConteoExitos/$($ConteoExitos + $ConteoFallos)" -ForegroundColor Red
}
Write-Host "================================" -ForegroundColor Cyan

if ($ConteoFallos -gt 0) {
    exit 1
}

# Contrato explícito de salida: 0 cuando todas las pruebas pasan
exit 0