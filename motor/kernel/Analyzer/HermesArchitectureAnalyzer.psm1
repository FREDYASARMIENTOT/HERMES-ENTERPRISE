<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : HermesArchitectureAnalyzer.psm1
Autor    : Cline AI
Proposito: 
    Hermes Architecture Analyzer (HAA) - Modulo principal.
    
    Este analizador ejecuta automaticamente todas las reglas arquitectonicas:
    - Canonical Source Policy
    - Redirect Stub Policy
    - Provider Rule
    - Module Rule
    - Kernel Rule
    - UseCase Rule
    - Bootstrap Rule
    - Documentation Rule
    - PublicApi Rule
    - Telemetry Rule
    - Persistence Rule
    - Packaging Rule
    - Git Rule
    - Sqlite Rule
    - Pester Rule
    - Parser Rule
    
    Genera un Architecture Score y decide si Release Ready es verdadero o falso.
====================================================================================================
#>

# Requerir dependencias
using module '..\..\persistence\HermesPersistence.psm1'

# ──────────────────────────────────────────────────────────────────────────────
# REGION: CONSTANTES GLOBALES
# ──────────────────────────────────────────────────────────────────────────────
$script:RutaRaiz = Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')
$script:RutaMotor = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$script:UmbralScoreMinimo = 95.0

# Umbral por defecto para Quality Gate
$script:UmbralQualityGate = 95.0

# ──────────────────────────────────────────────────────────────────────────────
# REGION: FUNCIONES INTERNAS DE ANALISIS
# ──────────────────────────────────────────────────────────────────────────────

<#
.SINOPSIS
    Verifica que un archivo sea un Redirect Stub valido.
    Un Redirect Stub solo puede importar, delegar, exportar o documentar.
    Nunca puede contener logica de negocio, acceso a SQLite, Git, HTTP, etc.
#>
function Test-CumplimientoRedirectStub {
    param(
        [string]$RutaArchivo
    )
    $resultado = [pscustomobject]@{
        Archivo          = $RutaArchivo
        EsStub           = $false
        EsValido         = $false
        Violaciones      = @()
        Advertencias     = @()
    }

    if (-not (Test-Path $RutaArchivo)) {
        return $resultado
    }

    $contenido = Get-Content -Path $RutaArchivo -Raw -ErrorAction SilentlyContinue
    if (-not $contenido) {
        return $resultado
    }

    # Detectar si es un stub (tiene indicadores como "# Stub", "# Redirect", solo imports/exports)
    $lineas = $contenido -split "`n"
    $tieneIndicadorStub = $contenido -match '#\s*(Stub|Redirect|RedirectStub)'
    $tieneSoloImportsExports = $true
    $violaciones = @()
    $advertencias = @()

    # Patrones prohibidos en stubs
    $patronesProhibidos = @(
        'Invoke-Sqlite|Invoke-HermesSql|SELECT |INSERT |UPDATE |DELETE ',
        'git |git\.|Invoke-Git|Start-Process.*git',
        'Invoke-WebRequest|Invoke-RestMethod|HttpClient|System\.Net\.Http',
        'New-Object.*Sqlite|System\.Data\.SQLite|Microsoft\.Data\.Sqlite',
        'Add-Type.*SQLite',
        'Write-Log|Write-EventLog|Register-HermesTelemetry',
        'Start-Process.*npm|Start-Process.*pip|Start-Process.*dotnet',
        'New-Item.*Provider|Register-.*Provider|Add-.*Provider'
    )

    foreach ($linea in $lineas) {
        $lineaTrim = $linea.Trim()
        if ([string]::IsNullOrWhiteSpace($lineaTrim)) { continue }
        if ($lineaTrim.StartsWith('#')) { continue }
        if ($lineaTrim.StartsWith('<#')) { continue }
        if ($lineaTrim.StartsWith('#>')) { continue }

        # Verificar si solo contiene imports, exports, using, param
        if ($lineaTrim -match '^(Import-Module|Using\s+Module|Using\s+Namespace|Export-ModuleMember|\[CmdletBinding|param\()') {
            continue
        }

        # Verificar si es un comando prohibido
        foreach ($patron in $patronesProhibidos) {
            if ($lineaTrim -match $patron) {
                $violaciones += "Linea contiene operacion prohibida en stub: [$lineaTrim] coincide con patron [$patron]"
                $tieneSoloImportsExports = $false
            }
        }
    }

    $resultado.EsStub = $tieneIndicadorStub
    $resultado.EsValido = $tieneIndicadorStub -and $tieneSoloImportsExports
    $resultado.Violaciones = $violaciones
    $resultado.Advertencias = $advertencias

    return $resultado
}

<#
.SINOPSIS
    Verifica que un archivo sea el Canonical Source de su componente.
    El Canonical Source es el unico archivo que contiene logica de negocio.
#>
function Test-CumplimientoCanonical {
    param(
        [string]$RutaArchivo
    )
    $resultado = [pscustomobject]@{
        Archivo          = $RutaArchivo
        EsCanonical      = $false
        EsValido         = $false
        Violaciones      = @()
        Advertencias     = @()
    }

    if (-not (Test-Path $RutaArchivo)) {
        return $resultado
    }

    $nombre = Split-Path $RutaArchivo -Leaf
    $contenido = Get-Content -Path $RutaArchivo -Raw -ErrorAction SilentlyContinue
    if (-not $contenido) {
        return $resultado
    }

    # Un archivo canonico debe:
    # 1. Estar en la ubicacion canonica (no en Module/ ni functions/ duplicado)
    $rutaRelativa = $RutaArchivo.Substring($script:RutaRaiz.Length + 1)
    $tieneUbicacionCanonica = $true

    # Si esta en ubicacion duplicada, no es canonical
    $ubicacionesNoCanonicas = @(
        'motor\kernel\Module\\',
        'motor\bootstrap\functions\\',
        'motor\bootstrap\engine\\',
        'tools\\.*\.psm1$',
        'motor\kernel\\Providers\\'
    )
    foreach ($patron in $ubicacionesNoCanonicas) {
        if ($rutaRelativa -match $patron) {
            $resultado.Violaciones += "Ubicacion no canonica: [$rutaRelativa] coincide con patron [$patron]"
            $tieneUbicacionCanonica = $false
        }
    }

    $resultado.EsCanonical = $tieneUbicacionCanonica
    $resultado.EsValido = $tieneUbicacionCanonica
    return $resultado
}

<#
.SINOPSIS
    Verifica que los providers esten correctamente registrados.
#>
function Test-ReglaProviders {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Providers'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $rutaProviders = Join-Path $script:RutaMotor 'kernel\Providers'
    $rutaModuleProviders = Join-Path $script:RutaMotor 'kernel\Module\Hermes.Commands\Providers'

    $violaciones = @()
    $detalle = @()

    # Verificar que cada provider en Module/ tenga canonical en Providers/
    if (Test-Path $rutaModuleProviders) {
        $moduleProviders = Get-ChildItem -Path $rutaModuleProviders -Filter '*.ps1'
        foreach ($mp in $moduleProviders) {
            $canonicalPath = Join-Path $rutaProviders $mp.Name
            if (Test-Path $canonicalPath) {
                $detalle += "Provider [$($mp.Name)] tiene canonical en Providers/ y stub en Module/Providers/"
            } else {
                $violaciones += "Provider [$($mp.Name)] en Module/Providers/ no tiene canonical en Providers/"
            }
        }
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 10))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica que el Kernel este correctamente estructurado.
#>
function Test-ReglaKernel {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Kernel'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $rutaKernel = $script:RutaMotor
    $componentesRequeridos = @(
        'kernel\Hermes.Commands.psm1',
        'kernel\Hermes.Commands.psd1',
        'kernel\Providers\ProviderBase.ps1',
        'kernel\Engine\DiscoveryEngine.ps1',
        'kernel\Pipeline',
        'kernel\Lifecycle',
        'kernel\Contracts',
        'kernel\Capabilities\CapabilityRegistry.ps1'
    )

    $violaciones = @()
    $detalle = @()

    foreach ($componente in $componentesRequeridos) {
        $rutaComponente = Join-Path $script:RutaMotor $componente
        if (Test-Path $rutaComponente) {
            $detalle += "Componente Kernel presente: [$componente]"
        } else {
            $violaciones += "Componente Kernel faltante: [$componente]"
        }
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 15))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica que los Use Cases esten correctamente consolidados.
#>
function Test-ReglaUseCases {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'UseCases'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $rutaUseCases = Join-Path $script:RutaMotor 'usecases'
    $violaciones = @()
    $detalle = @()

    if (Test-Path $rutaUseCases) {
        $archivosUseCase = Get-ChildItem -Path $rutaUseCases -Recurse -Filter '*.ps1'
        $detalle += "Archivos UseCase encontrados: $($archivosUseCase.Count)"
        foreach ($uc in $archivosUseCase) {
            $detalle += "  - $($uc.Name)"
        }
    } else {
        $violaciones += "Directorio de UseCases no encontrado: [$rutaUseCases]"
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = 50.0
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica la estructura de Bootstrap.
#>
function Test-ReglaBootstrap {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Bootstrap'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $rutaBootstrap = Join-Path $script:RutaMotor 'bootstrap'
    $violaciones = @()
    $detalle = @()

    $componentesEsperados = @(
        'Start-HermesProject.ps1',
        'Git.ps1',
        'GitHub.ps1',
        'Python.ps1',
        'Validation.ps1',
        'Reporting.ps1',
        'Templates.ps1'
    )

    if (Test-Path $rutaBootstrap) {
        foreach ($comp in $componentesEsperados) {
            $rutaComp = Join-Path $rutaBootstrap $comp
            if (Test-Path $rutaComp) {
                $detalle += "Componente Bootstrap presente: [$comp]"
            } else {
                $violaciones += "Componente Bootstrap faltante: [$comp]"
            }
        }
    } else {
        $violaciones += "Directorio Bootstrap no encontrado: [$rutaBootstrap]"
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 10))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica la documentacion del proyecto.
#>
function Test-ReglaDocumentacion {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Documentacion'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $documentosRequeridos = @(
        'README.md',
        'CURRENT_STATE.md',
        'CHANGELOG.md',
        'LICENSE',
        'docs\ArchitectureOverview.md',
        'docs\QuickStart.md',
        'docs\UserManual.md',
        'docs\Installation.md',
        'docs\Examples.md',
        'docs\FAQ.md'
    )

    $violaciones = @()
    $detalle = @()

    foreach ($doc in $documentosRequeridos) {
        $rutaDoc = Join-Path $script:RutaRaiz $doc
        if (Test-Path $rutaDoc) {
            $detalle += "Documento presente: [$doc]"
        } else {
            $violaciones += "Documento faltante: [$doc]"
        }
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 8))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica la estructura de la API Publica.
#>
function Test-ReglaApiPublica {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'ApiPublica'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $rutaPublicApi = Join-Path $script:RutaMotor 'kernel\Module\Hermes.Commands\Public'
    $violaciones = @()
    $detalle = @()

    if (Test-Path $rutaPublicApi) {
        $archivosPublicos = Get-ChildItem -Path $rutaPublicApi -Filter '*.ps1'
        $detalle += "Comandos publicos encontrados: $($archivosPublicos.Count)"
        foreach ($ap in $archivosPublicos) {
            $detalle += "  - $($ap.BaseName)"
        }
    } else {
        $violaciones += "Directorio de API Publica no encontrado: [$rutaPublicApi]"
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = 50.0
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica la estructura de persistencia.
#>
function Test-ReglaPersistencia {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Persistencia'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $rutaPersistencia = Join-Path $script:RutaMotor 'persistence'
    $violaciones = @()
    $detalle = @()

    $componentesPersistencia = @(
        'HermesPersistence.psm1',
        'SQLite',
        'Schema',
        'Migrations',
        'Repositories',
        'Interfaces'
    )

    if (Test-Path $rutaPersistencia) {
        foreach ($comp in $componentesPersistencia) {
            $rutaComp = Join-Path $rutaPersistencia $comp
            if (Test-Path $rutaComp) {
                $detalle += "Componente de persistencia presente: [$comp]"
            } else {
                $violaciones += "Componente de persistencia faltante: [$comp]"
            }
        }
    } else {
        $violaciones += "Directorio de persistencia no encontrado: [$rutaPersistencia]"
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 10))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica la estructura de empaquetado.
#>
function Test-ReglaEmpaquetado {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Empaquetado'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $violaciones = @()
    $detalle = @()

    $archivosEmpaquetado = @(
        'motor\kernel\Module\Hermes.Commands\Hermes.Commands.psd1',
        'motor\kernel\Module\Hermes.Commands\Hermes.Commands.psm1',
        'motor\kernel\Module\Hermes.Commands\en-US',
        'motor\kernel\Module\Hermes.Commands\es-ES',
        'motor\kernel\Module\Hermes.Commands\Install'
    )

    foreach ($archivo in $archivosEmpaquetado) {
        $rutaArchivo = Join-Path $script:RutaRaiz $archivo
        if (Test-Path $rutaArchivo) {
            $detalle += "Archivo de empaquetado presente: [$archivo]"
        } else {
            $violaciones += "Archivo de empaquetado faltante: [$archivo]"
        }
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 15))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica las reglas de SQLite.
#>
function Test-ReglaSqlite {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'SQLite'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $violaciones = @()
    $detalle = @()

    $libreriasSqlite = @(
        'lib\System.Data.SQLite',
        'lib\Microsoft.Data.Sqlite',
        'lib\HermesSQLiteProvider'
    )

    foreach ($lib in $libreriasSqlite) {
        $rutaLib = Join-Path $script:RutaRaiz $lib
        if (Test-Path $rutaLib) {
            $detalle += "Libreria SQLite presente: [$lib]"
        } else {
            $violaciones += "Libreria SQLite faltante: [$lib]"
        }
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 20))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica las reglas de Git.
#>
function Test-ReglaGit {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Git'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $violaciones = @()
    $detalle = @()

    # Verificar que .gitignore existe
    $rutaGitignore = Join-Path $script:RutaRaiz '.gitignore'
    if (Test-Path $rutaGitignore) {
        $detalle += "Archivo .gitignore presente"
    } else {
        $violaciones += "Archivo .gitignore faltante"
    }

    # Verificar que el repositorio git esta inicializado
    $rutaGit = Join-Path $script:RutaRaiz '.git'
    if (Test-Path $rutaGit) {
        $detalle += "Repositorio Git inicializado"
    } else {
        $violaciones += "Repositorio Git no inicializado"
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 25))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica las reglas de Pester.
#>
function Test-ReglaPester {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Pester'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $violaciones = @()
    $detalle = @()

    $rutaPruebas = Join-Path $script:RutaRaiz 'pruebas'
    if (Test-Path $rutaPruebas) {
        $archivosPrueba = Get-ChildItem -Path $rutaPruebas -Recurse -Filter '*.Tests.ps1'
        $detalle += "Archivos de prueba Pester encontrados: $($archivosPrueba.Count)"
        foreach ($tp in $archivosPrueba) {
            $detalle += "  - $($tp.Name)"
        }
        if ($archivosPrueba.Count -eq 0) {
            $violaciones += "No se encontraron archivos de prueba Pester (*.Tests.ps1)"
        }
    } else {
        $violaciones += "Directorio de pruebas no encontrado: [$rutaPruebas]"
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 20))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica las reglas del Parser de PowerShell.
#>
function Test-ReglaParser {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Parser'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $violaciones = @()
    $detalle = @()

    $archivosPowerShell = Get-ChildItem -Path $script:RutaMotor -Recurse -Include '*.ps1', '*.psm1', '*.psd1'
    $erroresParser = 0

    foreach ($archivo in $archivosPowerShell) {
        try {
            $tokens = $null
            $errores = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($archivo.FullName, [ref]$tokens, [ref]$errores)
            if ($errores.Count -gt 0) {
                $erroresParser += $errores.Count
                $violaciones += "Error de parser en [$($archivo.Name)]: $($errores[0].Message)"
            }
        }
        catch {
            $erroresParser++
            $violaciones += "Error al parsear [$($archivo.Name)]: $($_.Exception.Message)"
        }
    }

    $detalle += "Archivos PowerShell analizados: $($archivosPowerShell.Count)"
    $detalle += "Errores de parser encontrados: $erroresParser"

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($erroresParser -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($erroresParser * 5))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica las reglas de PSScriptAnalyzer.
#>
function Test-ReglaScriptAnalyzer {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'PSScriptAnalyzer'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $violaciones = @()
    $detalle = @()

    $comandoAvailable = Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue
    if (-not $comandoAvailable) {
        $resultado.Estado = 'WARN'
        $resultado.Puntaje = 50.0
        $detalle += 'PSScriptAnalyzer no disponible. Instalar con: Install-Module PSScriptAnalyzer -Force'
        return $resultado
    }

    $archivosPowerShell = Get-ChildItem -Path $script:RutaMotor -Recurse -Include '*.ps1', '*.psm1'
    $erroresSA = 0
    $totalAdvertencias = 0

    foreach ($archivo in $archivosPowerShell) {
        try {
            $resultadoSA = Invoke-ScriptAnalyzer -Path $archivo.FullName -ExcludeRule @('PSUseShouldProcessForChangeState', 'PSAvoidUsingWriteHost', 'PSAvoidUsingConvertToJson') 2>&1
            $errores = $resultadoSA | Where-Object { $_.Severity -eq 'Error' }
            $advertencias = $resultadoSA | Where-Object { $_.Severity -eq 'Warning' }
            $erroresSA += $errores.Count
            $totalAdvertencias += $advertencias.Count
            if ($errores.Count -gt 0) {
                $violaciones += "Errores en [$($archivo.Name)]: $($errores.Count) errores"
            }
        }
        catch {
            $violaciones += "Error al analizar [$($archivo.Name)]: $($_.Exception.Message)"
        }
    }

    $detalle += "Archivos analizados con PSScriptAnalyzer: $($archivosPowerShell.Count)"
    $detalle += "Errores: $erroresSA, Advertencias: $totalAdvertencias"

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($erroresSA -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($erroresSA * 10))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica las reglas de telemetria.
#>
function Test-ReglaTelemetria {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Telemetria'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $violaciones = @()
    $detalle = @()

    $rutaObservabilidad = Join-Path $script:RutaMotor 'observability'
    if (Test-Path $rutaObservabilidad) {
        $archivosObservabilidad = Get-ChildItem -Path $rutaObservabilidad -Filter '*.ps1'
        $detalle += "Archivos de observabilidad/telemetria: $($archivosObservabilidad.Count)"
        foreach ($ao in $archivosObservabilidad) {
            $detalle += "  - $($ao.Name)"
        }
    } else {
        $violaciones += "Directorio de observabilidad no encontrado: [$rutaObservabilidad]"
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = 50.0
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica las reglas de modulos.
#>
function Test-ReglaModulos {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Modulos'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $violaciones = @()
    $detalle = @()

    $modulosEsperados = @(
        'motor\kernel\Hermes.Commands.psd1',
        'motor\kernel\Hermes.Commands.psm1',
        'motor\persistence\HermesPersistence.psm1',
        'motor\config\Configuration.psm1'
    )

    foreach ($mod in $modulosEsperados) {
        $rutaMod = Join-Path $script:RutaRaiz $mod
        if (Test-Path $rutaMod) {
            $detalle += "Modulo presente: [$mod]"
        } else {
            $violaciones += "Modulo faltante: [$mod]"
        }
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 15))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica las reglas de empaquetado para release.
#>
function Test-ReglaPackaging {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Packaging'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $violaciones = @()
    $detalle = @()

    $archivosRelease = @(
        'README.md',
        'LICENSE',
        'CHANGELOG.md',
        'PSScriptAnalyzerSettings.psd1',
        'Hermes.config.json'
    )

    foreach ($archivo in $archivosRelease) {
        $rutaArchivo = Join-Path $script:RutaRaiz $archivo
        if (Test-Path $rutaArchivo) {
            $detalle += "Archivo de release presente: [$archivo]"
        } else {
            $violaciones += "Archivo de release faltante: [$archivo]"
        }
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 10))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica las reglas de Canonical Source Policy.
#>
function Test-ReglaCanonical {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Canonical'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $violaciones = @()
    $detalle = @()

    # Lista de archivos que deberian ser canonicos (no duplicados)
    $archivosCanonicosEsperados = @(
        'motor\bootstrap\Start-HermesProject.ps1',
        'motor\bootstrap\Git.ps1',
        'motor\bootstrap\GitHub.ps1',
        'motor\bootstrap\Python.ps1',
        'motor\bootstrap\Validation.ps1',
        'motor\bootstrap\Reporting.ps1',
        'motor\bootstrap\Templates.ps1',
        'motor\kernel\Hermes.Commands.psd1',
        'motor\kernel\Hermes.Commands.psm1',
        'motor\kernel\Capabilities\CapabilityRegistry.ps1',
        'motor\kernel\Engine\DiscoveryEngine.ps1',
        'motor\kernel\Providers\ProviderBase.ps1',
        'motor\kernel\Providers\CapabilityProvider.ps1',
        'motor\kernel\Providers\EnvironmentProvider.ps1',
        'motor\kernel\Providers\GitHubProvider.ps1',
        'motor\kernel\Providers\WorkspaceProvider.ps1',
        'motor\kernel\KernelHealth.ps1',
        'motor\kernel\KernelMetrics.ps1'
    )

    foreach ($canonical in $archivosCanonicosEsperados) {
        $rutaCanonical = Join-Path $script:RutaRaiz $canonical
        if (Test-Path $rutaCanonical) {
            $detalle += "Canonical presente: [$canonical]"
        } else {
            $violaciones += "Canonical faltante: [$canonical]"
        }
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 10))
    }

    return $resultado
}

<#
.SINOPSIS
    Verifica las reglas de Redirect Stubs.
#>
function Test-ReglaRedirect {
    param()
    $resultado = [pscustomobject]@{
        NombreRegla      = 'Redirect'
        Estado           = 'PASS'
        Puntaje          = 100.0
        Violaciones      = @()
        Detalle          = @()
    }

    $violaciones = @()
    $detalle = @()

    # Ubicaciones donde deberian estar los Redirect Stubs
    $ubicacionesStub = @(
        Join-Path $script:RutaMotor 'bootstrap\functions',
        Join-Path $script:RutaMotor 'kernel\Module\Hermes.Commands\Providers'
    )

    foreach ($ubicacion in $ubicacionesStub) {
        if (Test-Path $ubicacion) {
            $archivos = Get-ChildItem -Path $ubicacion -Filter '*.ps1'
            foreach ($archivo in $archivos) {
                $resultadoStub = Test-CumplimientoRedirectStub -RutaArchivo $archivo.FullName
                if ($resultadoStub.EsStub -and -not $resultadoStub.EsValido) {
                    $violaciones += "Stub invalido: [$($archivo.Name)] - $($resultadoStub.Violaciones -join '; ')"
                } elseif ($resultadoStub.EsStub -and $resultadoStub.EsValido) {
                    $detalle += "Stub valido: [$($archivo.Name)]"
                }
            }
        }
    }

    $resultado.Violaciones = $violaciones
    $resultado.Detalle = $detalle
    if ($violaciones.Count -gt 0) {
        $resultado.Estado = 'FAIL'
        $resultado.Puntaje = [math]::Max(0, 100 - ($violaciones.Count * 10))
    }

    return $resultado
}

# ──────────────────────────────────────────────────────────────────────────────
# REGION: FUNCIONES PRINCIPALES
# ──────────────────────────────────────────────────────────────────────────────

<#
.SINOPSIS
    Ejecuta el Hermes Architecture Analyzer completo.
    Evalua todas las reglas arquitectonicas y genera un reporte detallado.
.DESCRIPCION
    El analizador ejecuta cada regla secuencialmente, calcula el puntaje
    individual y global, y determina si el proyecto esta listo para release.
.PARAMETRO UmbralScore
    Umbral minimo de puntaje arquitectonico para considerar el proyecto valido.
.PARAMETRO RutaBase
    Ruta base del proyecto. Por defecto detecta automaticamente.
.PARAMETRO PersistirEnSqlite
    Si es verdadero, persiste los resultados en SQLite.
#>
function Invoke-HermesArchitectureAnalyzer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [double]$UmbralScore = $script:UmbralQualityGate,

        [Parameter(Mandatory = $false)]
        [string]$RutaBase = $script:RutaRaiz,

        [Parameter(Mandatory = $false)]
        [switch]$PersistirEnSqlite
    )

    Write-Host "`n#==============================================================================" -ForegroundColor DarkCyan
    Write-Host "# HERMES ARCHITECTURE ANALYZER (HAA)" -ForegroundColor DarkCyan
    Write-Host "# Evaluacion Arquitectonica Automatica" -ForegroundColor DarkCyan
    Write-Host "# Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkCyan
    Write-Host "#==============================================================================" -ForegroundColor DarkCyan

    $fechaInicio = Get-Date
    $resultadosReglas = @{}
    $violacionesGlobales = @()
    $advertenciasGlobales = @()

    # ── Ejecutar todas las reglas secuencialmente ──────────────────────────
    # Nota: Se usan nombres de función como strings y Get-Command para evitar
    # problemas de ámbito (scope) al invocar desde scriptblocks dentro del módulo.
    $reglas = @(
        @{ Nombre = 'Parser';           Funcion = 'Test-ReglaParser' }
        @{ Nombre = 'PSScriptAnalyzer'; Funcion = 'Test-ReglaScriptAnalyzer' }
        @{ Nombre = 'Canonical';        Funcion = 'Test-ReglaCanonical' }
        @{ Nombre = 'Redirect';         Funcion = 'Test-ReglaRedirect' }
        @{ Nombre = 'Providers';        Funcion = 'Test-ReglaProviders' }
        @{ Nombre = 'Kernel';           Funcion = 'Test-ReglaKernel' }
        @{ Nombre = 'Modulos';          Funcion = 'Test-ReglaModulos' }
        @{ Nombre = 'Bootstrap';        Funcion = 'Test-ReglaBootstrap' }
        @{ Nombre = 'UseCases';         Funcion = 'Test-ReglaUseCases' }
        @{ Nombre = 'ApiPublica';       Funcion = 'Test-ReglaApiPublica' }
        @{ Nombre = 'Persistencia';     Funcion = 'Test-ReglaPersistencia' }
        @{ Nombre = 'Documentacion';    Funcion = 'Test-ReglaDocumentacion' }
        @{ Nombre = 'Telemetria';       Funcion = 'Test-ReglaTelemetria' }
        @{ Nombre = 'Empaquetado';      Funcion = 'Test-ReglaEmpaquetado' }
        @{ Nombre = 'SQLite';           Funcion = 'Test-ReglaSqlite' }
        @{ Nombre = 'Git';              Funcion = 'Test-ReglaGit' }
        @{ Nombre = 'Pester';           Funcion = 'Test-ReglaPester' }
        @{ Nombre = 'Packaging';        Funcion = 'Test-ReglaPackaging' }
    )

    foreach ($regla in $reglas) {
        $nombreRegla = $regla.Nombre
        Write-Host "  Evaluando regla: $nombreRegla..." -NoNewline -ForegroundColor Gray
        try {
            $resultado = & (Get-Command -Name $regla.Funcion -Module 'HermesArchitectureAnalyzer' -ErrorAction Stop)
            $resultadosReglas[$nombreRegla] = $resultado
            $estadoColor = if ($resultado.Estado -eq 'PASS') { 'Green' } elseif ($resultado.Estado -eq 'WARN') { 'Yellow' } else { 'Red' }
            Write-Host " $($resultado.Estado) ($($resultado.Puntaje)/100)" -ForegroundColor $estadoColor
            if ($resultado.Violaciones.Count -gt 0) {
                $violacionesGlobales += $resultado.Violaciones
                foreach ($v in $resultado.Violaciones) {
                    Write-Host "    VIOLACION: $v" -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host " ERROR" -ForegroundColor Red
            $violacionesGlobales += "Excepcion en regla [$nombreRegla]: $($_.Exception.Message)"
            $resultadosReglas[$nombreRegla] = [pscustomobject]@{
                NombreRegla = $nombreRegla; Estado = 'ERROR'; Puntaje = 0.0
                Violaciones = @("Excepcion: $($_.Exception.Message)"); Detalle = @()
            }
        }
    }

    # ── Calcular puntaje global ───────────────────────────────────────────
    $puntajes = $resultadosReglas.Values | ForEach-Object { $_.Puntaje }
    $totalReglas = $puntajes.Count
    $puntajeAcumulado = ($puntajes | Measure-Object -Sum).Sum
    $puntajeGlobal = if ($totalReglas -gt 0) { [math]::Round($puntajeAcumulado / $totalReglas, 2) } else { 0.0 }
    $releaseReady = $puntajeGlobal -ge $UmbralScore -and ($violacionesGlobales.Count -eq 0)

    $fechaFin = Get-Date
    $duracion = [math]::Round(($fechaFin - $fechaInicio).TotalSeconds, 2)

    # ── Construir resultado final ─────────────────────────────────────────
    $resultadoFinal = [pscustomobject]@{
        FechaEvaluacion         = $fechaInicio.ToString('yyyy-MM-dd HH:mm:ss')
        DuracionSegundos        = $duracion
        RutaBase                = $RutaBase
        UmbralScore             = $UmbralScore
        PuntajeGlobal           = $puntajeGlobal
        TotalReglas             = $totalReglas
        ReglasAprobadas         = ($resultadosReglas.Values | Where-Object { $_.Estado -eq 'PASS' }).Count
        ReglasAdvertencia       = ($resultadosReglas.Values | Where-Object { $_.Estado -eq 'WARN' }).Count
        ReglasFallidas          = ($resultadosReglas.Values | Where-Object { $_.Estado -eq 'FAIL' -or $_.Estado -eq 'ERROR' }).Count
        TotalViolaciones        = $violacionesGlobales.Count
        ReleaseReady            = $releaseReady
        ResultadosPorRegla      = $resultadosReglas
        Violaciones             = $violacionesGlobales
        Advertencias            = $advertenciasGlobales
    }

    # ── Mostrar resumen ───────────────────────────────────────────────────
    Write-Host "`n#==============================================================================" -ForegroundColor DarkCyan
    Write-Host "# RESULTADOS DEL ANALISIS ARQUITECTONICO" -ForegroundColor DarkCyan
    Write-Host "#==============================================================================" -ForegroundColor DarkCyan
    Write-Host ""

    foreach ($kvp in $resultadosReglas.GetEnumerator()) {
        $r = $kvp.Value
        $colorEstado = if ($r.Estado -eq 'PASS') { 'Green' } elseif ($r.Estado -eq 'WARN') { 'Yellow' } else { 'Red' }
        Write-Host ("  {0,-25} {1,6}  ({2,6:F2})" -f $r.NombreRegla, $r.Estado, $r.Puntaje) -ForegroundColor $colorEstado
    }

    Write-Host ""
    Write-Host ("  {0,-25} {1,6}  ({2,6:F2})" -f 'PUNTAJE GLOBAL', $(if ($releaseReady) { 'PASS' } else { 'FAIL' }), $puntajeGlobal) -ForegroundColor $(if ($releaseReady) { 'Green' } else { 'Red' })
    Write-Host ("  {0,-25} {1,6}" -f 'Release Ready', $(if ($releaseReady) { 'YES' } else { 'NO' })) -ForegroundColor $(if ($releaseReady) { 'Green' } else { 'Red' })
    Write-Host ("  {0,-25} {1,6}" -f 'Violaciones', $violacionesGlobales.Count) -ForegroundColor $(if ($violacionesGlobales.Count -eq 0) { 'Green' } else { 'Red' })
    Write-Host ("  Duracion: {0}s" -f $duracion) -ForegroundColor Gray

    # ── Persistir en SQLite si se solicito ─────────────────────────────────
    if ($PersistirEnSqlite) {
        try {
            $rutaDb = Join-Path $script:RutaRaiz 'data\hermes_consolidated.db'
            $mgr = Initialize-HermesPersistence -DatabasePath $rutaDb -ErrorAction Stop
            $sqlCrearTabla = @"
CREATE TABLE IF NOT EXISTS ArchitectureScore (
    Id TEXT PRIMARY KEY,
    FechaEvaluacion TEXT NOT NULL,
    PuntajeGlobal REAL NOT NULL,
    TotalReglas INTEGER NOT NULL,
    ReglasAprobadas INTEGER NOT NULL,
    ReglasFallidas INTEGER NOT NULL,
    TotalViolaciones INTEGER NOT NULL,
    ReleaseReady INTEGER NOT NULL,
    Duracion REAL NOT NULL,
    CommitHash TEXT DEFAULT '',
    BranchName TEXT DEFAULT '',
    Usuario TEXT DEFAULT ''
)
"@
            $null = Invoke-HermesSql -Manager $mgr -Sql $sqlCrearTabla -Mode NonQuery

            $idEvaluacion = "haa-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $sqlInsertar = @"
INSERT INTO ArchitectureScore (Id, FechaEvaluacion, PuntajeGlobal, TotalReglas, ReglasAprobadas, ReglasFallidas, TotalViolaciones, ReleaseReady, Duracion)
VALUES (@id, @fecha, @puntaje, @total, @aprobadas, @fallidas, @violaciones, @release, @duracion)
"@
            $null = Invoke-HermesSql -Manager $mgr -Sql $sqlInsertar -Parameters @{
                '@id'         = $idEvaluacion
                '@fecha'      = $fechaInicio.ToString('yyyy-MM-dd HH:mm:ss')
                '@puntaje'    = $puntajeGlobal
                '@total'      = $totalReglas
                '@aprobadas'  = $resultadoFinal.ReglasAprobadas
                '@fallidas'   = $resultadoFinal.ReglasFallidas
                '@violaciones' = $violacionesGlobales.Count
                '@release'    = if ($releaseReady) { 1 } else { 0 }
                '@duracion'   = $duracion
            }
            Disconnect-HermesDatabase -Manager $mgr
            Write-Host "  Resultados persistidos en SQLite (ID: $idEvaluacion)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Error al persistir en SQLite: $_"
        }
    }

    return $resultadoFinal
}

<#
.SINOPSIS
    Prueba si la arquitectura del proyecto cumple con los requisitos minimos.
.DESCRIPCION
    Ejecuta el analizador completo y retorna verdadero solo si el puntaje
    es igual o superior al umbral definido.
.PARAMETRO UmbralScore
    Umbral minimo de puntaje. Por defecto 95.0.
#>
function Test-HermesArchitecture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [double]$UmbralScore = $script:UmbralQualityGate
    )

    $resultado = Invoke-HermesArchitectureAnalyzer -UmbralScore $UmbralScore
    return $resultado.ReleaseReady
}

<#
.SINOPSIS
    Obtiene el reporte arquitectonico mas reciente.
.DESCRIPCION
    Recupera el ultimo reporte de arquitectura desde SQLite o ejecuta uno nuevo.
.PARAMETRO DesdeSqlite
    Si es verdadero, intenta recuperar el ultimo reporte desde SQLite.
#>
function Get-HermesArchitectureReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$DesdeSqlite
    )

    if ($DesdeSqlite) {
        try {
            $rutaDb = Join-Path $script:RutaRaiz 'data\hermes_consolidated.db'
            $mgr = Initialize-HermesPersistence -DatabasePath $rutaDb -ErrorAction Stop
            $resultado = Invoke-HermesSql -Manager $mgr -Sql @"
SELECT * FROM ArchitectureScore ORDER BY FechaEvaluacion DESC LIMIT 1
"@ -Mode Query
            Disconnect-HermesDatabase -Manager $mgr
            if ($resultado -and $resultado.Rows.Count -gt 0) {
                return $resultado.Rows[0]
            }
        }
        catch {
            Write-Warning "Error al recuperar desde SQLite: $_"
        }
    }

    # Si no hay datos en SQLite, ejecutar analisis completo
    return Invoke-HermesArchitectureAnalyzer
}

<#
.SINOPSIS
    Exporta el reporte arquitectonico a un archivo Markdown.
.DESCRIPCION
    Genera un reporte detallado en formato Markdown con todos los resultados.
.PARAMETRO RutaSalida
    Ruta donde se guardara el archivo Markdown.
#>
function Export-HermesArchitectureReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RutaSalida = (Join-Path $script:RutaRaiz 'reports\HermesArchitectureReport.md')
    )

    $resultado = Invoke-HermesArchitectureAnalyzer

    $directorioSalida = Split-Path $RutaSalida -Parent
    if (-not (Test-Path $directorioSalida)) {
        New-Item -ItemType Directory -Path $directorioSalida -Force | Out-Null
    }

    $contenidoReporte = @"
# Hermes Architecture Report
## Reporte Arquitectonico Automatico

**Fecha de Evaluacion:** $($resultado.FechaEvaluacion)
**Duracion:** $($resultado.DuracionSegundos) segundos
**Ruta Base:** $($resultado.RutaBase)

---

## Resumen Global

| Metrica | Valor |
|---------|-------|
| Puntaje Global | $($resultado.PuntajeGlobal)/100 |
| Umbral Requerido | $($resultado.UmbralScore) |
| Reglas Evaluadas | $($resultado.TotalReglas) |
| Reglas Aprobadas | $($resultado.ReglasAprobadas) |
| Reglas con Advertencia | $($resultado.ReglasAdvertencia) |
| Reglas Fallidas | $($resultado.ReglasFallidas) |
| Violaciones Totales | $($resultado.TotalViolaciones) |
| **Release Ready** | **$(if ($resultado.ReleaseReady) { 'SI' } else { 'NO' })** |

---

## Resultados por Regla

| Regla | Estado | Puntaje |
|-------|--------|---------|
"@

    foreach ($kvp in $resultado.ResultadosPorRegla.GetEnumerator()) {
        $r = $kvp.Value
        $contenidoReporte += "`n| $($r.NombreRegla) | $($r.Estado) | $($r.Puntaje)/100 |"
    }

    $contenidoReporte += @"

---

## Violaciones Detectadas

"@

    if ($resultado.Violaciones.Count -gt 0) {
        foreach ($v in $resultado.Violaciones) {
            $contenidoReporte += "`n- $v"
        }
    } else {
        $contenidoReporte += "`nNo se detectaron violaciones arquitectonicas."
    }

    $contenidoReporte += @"

---

## Detalle por Componente

### Parser
$($resultado.ResultadosPorRegla['Parser'].Detalle -join "`n")

### PSScriptAnalyzer
$($resultado.ResultadosPorRegla['PSScriptAnalyzer'].Detalle -join "`n")

### Canonical
$($resultado.ResultadosPorRegla['Canonical'].Detalle -join "`n")

### Redirect
$($resultado.ResultadosPorRegla['Redirect'].Detalle -join "`n")

### Providers
$($resultado.ResultadosPorRegla['Providers'].Detalle -join "`n")

### Kernel
$($resultado.ResultadosPorRegla['Kernel'].Detalle -join "`n")

### Bootstrap
$($resultado.ResultadosPorRegla['Bootstrap'].Detalle -join "`n")

### UseCases
$($resultado.ResultadosPorRegla['UseCases'].Detalle -join "`n")

### API Publica
$($resultado.ResultadosPorRegla['ApiPublica'].Detalle -join "`n")

### Persistencia
$($resultado.ResultadosPorRegla['Persistencia'].Detalle -join "`n")

### Documentacion
$($resultado.ResultadosPorRegla['Documentacion'].Detalle -join "`n")

### Telemetria
$($resultado.ResultadosPorRegla['Telemetria'].Detalle -join "`n")

### Empaquetado
$($resultado.ResultadosPorRegla['Empaquetado'].Detalle -join "`n")

### SQLite
$($resultado.ResultadosPorRegla['SQLite'].Detalle -join "`n")

### Git
$($resultado.ResultadosPorRegla['Git'].Detalle -join "`n")

### Pester
$($resultado.ResultadosPorRegla['Pester'].Detalle -join "`n")

### Packaging
$($resultado.ResultadosPorRegla['Packaging'].Detalle -join "`n")

---

*Reporte generado automaticamente por Hermes Architecture Analyzer (HAA)*
*Fecha: $($resultado.FechaEvaluacion)*
"@

    $contenidoReporte | Set-Content -Path $RutaSalida -Encoding UTF8
    Write-Host "Reporte exportado a: $RutaSalida" -ForegroundColor Green

    return $RutaSalida
}

# ──────────────────────────────────────────────────────────────────────────────
# REGION: EXPORTACION DE FUNCIONES
# ──────────────────────────────────────────────────────────────────────────────

Export-ModuleMember -Function @(
    'Invoke-HermesArchitectureAnalyzer'
    'Test-HermesArchitecture'
    'Get-HermesArchitectureReport'
    'Export-HermesArchitectureReport'
)