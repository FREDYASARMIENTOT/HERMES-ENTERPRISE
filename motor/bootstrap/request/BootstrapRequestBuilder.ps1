<#
.SYNOPSIS
    Construye un BootstrapRequest a partir de entrada del usuario

.DESCRIPTION
    BootstrapRequestBuilder interactúa con el usuario para recopilar
    toda la información necesaria para crear un proyecto Hermes.

    Este componente es responsable ÚNICAMENTE de:
    - Preguntar al usuario (vía Read-Host)
    - Validar respuestas
    - Construir un BootstrapRequest válido

    NO es responsable de:
    - Crear archivos o carpetas
    - Ejecutar comandos git
    - Manipular BootstrapState
    - Invocar el orquestador

    Flujo:
        Usuario → Builder → BootstrapRequest → Converter → BootstrapState

.NOTES
    Autor: Hermes Agent
    Fecha: 2026-07-10
    Versión: 1.0.0

    Principios:
    - Separación de preocupaciones: SOLO captura datos
    - Valida cada respuesta antes de continuar
    - Proporciona valores por defecto razonables
    - No asume nada sobre el sistema del usuario
#>

function Invoke-BootstrapRequestBuilder {
    <#
    .SYNOPSIS
        Interactúa con el usuario para construir un BootstrapRequest

    .DESCRIPTION
        Guía al usuario a través de una serie de preguntas para
        recopilar toda la información necesaria para crear un proyecto
        Hermes. Valida cada respuesta y construye un DTO inmutable.

    .PARAMETER NombreProyecto
        Nombre del proyecto (si se proporciona, no pregunta)

    .PARAMETER NonInteractive
        Si se establece, usa valores por defecto sin preguntar

    .OUTPUTS
        PSCustomObject de tipo 'Hermes.Bootstrap.Request'
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$NombreProyecto = '',

        [Parameter()]
        [switch]$NonInteractive
    )

    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     HERMES ENTERPRISE - Configuración de Nuevo Proyecto     ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # ── 1. Nombre del proyecto ──
    if ([string]::IsNullOrWhiteSpace($NombreProyecto)) {
        $NombreProyecto = Invoke-PromptNombreProyecto
    } else {
        Write-Host "  ✓ Nombre del proyecto: $NombreProyecto" -ForegroundColor Green
    }

    # ── 2. Rutas ──
    $RutaProyecto = Invoke-PromptRutaProyecto -NombreProyecto $NombreProyecto
    $RutaDefaultEnvironment = Join-Path $RutaProyecto ".venv"
    $RutaEnvironment = Invoke-PromptRutaEnvironment -RutaDefault $RutaDefaultEnvironment

    # ── 3. Estructura del proyecto ──
    $CrearFrontend = Invoke-PromptBoolean -Mensaje "¿Crear estructura de frontend (frontend/)?" -Default $false
    $CrearBackend = Invoke-PromptBoolean -Mensaje "¿Crear estructura de backend (backend/)?" -Default $false

    # ── 4. Runtimes ──
    $RuntimeNode = ""
    if ($CrearFrontend) {
        $RuntimeNode = Invoke-PromptString -Mensaje "  Versión de Node.js" -Default "20.11.0"
    }

    $RuntimePython = ""
    if ($CrearBackend) {
        $RuntimePython = Invoke-PromptString -Mensaje "  Versión de Python" -Default "3.11"
    }

    # ── 5. Repositorio Git ──
    $AccionRepositorio = Invoke-PromptAccionRepositorio
    $ProveedorGit = "None"
    $URLRemoto = ""
    $CrearNuevoRepositorio = $false

    switch ($AccionRepositorio) {
        "Nuevo" {
            $ProveedorGit = Invoke-PromptString -Mensaje "  Proveedor Git remoto" -Default "GitHub"
            $URLRemoto = Invoke-PromptString -Mensaje "  URL del repositorio remoto" -Default ""
            $CrearNuevoRepositorio = $true
        }
        "Clonar" {
            $URLRemoto = Invoke-PromptString -Mensaje "  URL del repositorio a clonar" -Default ""
            if ([string]::IsNullOrWhiteSpace($URLRemoto)) {
                throw "Debe especificar una URL para clonar"
            }
        }
        "Conectar" {
            $RutaRepositorioLocal = Invoke-PromptRutaRepositorioLocal
        }
        "Ninguno" {
            # No hacer nada
        }
    }

    # ── 6. Configuración adicional ──
    $CrearGitIgnore = Invoke-PromptBoolean -Mensaje "Crear archivo .gitignore?" -Default $true
    $CrearEnv = Invoke-PromptBoolean -Mensaje "Crear entorno virtual Python (.venv)?" -Default $false
    $AbrirVSCode = Invoke-PromptBoolean -Mensaje "Abrir VS Code al finalizar?" -Default $true

    # ── 7. Descripción ──
    $DescripcionProyecto = Invoke-PromptString -Mensaje "Descripción del proyecto (opcional)" -Default ""

    # ── 8. Construir DTO ──
    $request = New-BootstrapRequest @PSBoundParameters

    Write-Host "`n  ✓ BootstrapRequest creado exitosamente" -ForegroundColor Green
    Write-Host ""

    return $request
}

function Invoke-PromptNombreProyecto {
    <#
    .SYNOPSIS
        Solicita el nombre del proyecto con validación
    #>

    [CmdletBinding()]
    param()

    while ($true) {
        $nombre = Read-Host "  Nombre del proyecto"

        if ([string]::IsNullOrWhiteSpace($nombre)) {
            Write-Host "    ✗ El nombre no puede estar vacío" -ForegroundColor Red
            continue
        }

        if ($nombre.Length -lt 3 -or $nombre.Length -gt 64) {
            Write-Host "    ✗ Debe tener entre 3 y 64 caracteres (ingresado: $($nombre.Length))" -ForegroundColor Red
            continue
        }

        if ($nombre -notmatch '^[a-zA-Z0-9_-]+$') {
            Write-Host "    ✗ Solo se permiten letras, números, guiones bajos (_) y guiones (-)" -ForegroundColor Red
            Write-Host "      Ejemplos válidos: MiProyecto, proyecto-demo, proyecto_2026" -ForegroundColor Gray
            continue
        }

        return $nombre
    }
}

function Invoke-PromptRutaProyecto {
    <#
    .SYNOPSIS
        Solicita la ruta donde se creará el proyecto
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$NombreProyecto
    )

    $defaultRuta = Join-Path (Get-Item $env:USERPROFILE).FullName $NombreProyecto

    $ruta = Read-Host "  Ruta del proyecto (default: $defaultRuta)"

    if ([string]::IsNullOrWhiteSpace($ruta)) {
        return $defaultRuta
    }

    return $ruta
}

function Invoke-PromptRutaEnvironment {
    <#
    .SYNOPSIS
        Solicita la ruta del entorno virtual
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RutaDefault
    )

    $ruta = Read-Host "  Ruta del entorno virtual (default: $RutaDefault)"

    if ([string]::IsNullOrWhiteSpace($ruta)) {
        return $RutaDefault
    }

    return $ruta
}

function Invoke-PromptRutaRepositorioLocal {
    <#
    .SYNOPSIS
        Solicita la ruta de un repositorio local existente
    #>

    [CmdletBinding()]
    param()

    while ($true) {
        $ruta = Read-Host "  Ruta del repositorio local existente"

        if ([string]::IsNullOrWhiteSpace($ruta)) {
            Write-Host "    ✗ Debe especificar una ruta" -ForegroundColor Red
            continue
        }

        if (-not (Test-Path $ruta)) {
            Write-Host "    ✗ La ruta no existe" -ForegroundColor Red
            continue
        }

        $gitDir = Join-Path $ruta ".git"
        if (-not (Test-Path (Join-Path $gitDir "HEAD"))) {
            Write-Host "    ✗ La ruta no contiene un repositorio Git válido" -ForegroundColor Red
            continue
        }

        return $ruta
    }
}

function Invoke-PromptBoolean {
    <#
    .SYNOPSIS
        Solicita una respuesta sí/no
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Mensaje,

        [Parameter()]
        [bool]$Default = $false
    )

    $defaultStr = if ($Default) { "S/n" } else { "s/N" }
    $respuesta = Read-Host "  $Mensaje [$defaultStr]"

    if ([string]::IsNullOrWhiteSpace($respuesta)) {
        return $Default
    }

    $respuesta = $respuesta.Trim().ToLower()

    return ($respuesta -eq "s" -or $respuesta -eq "si" -or $respuesta -eq "y" -or $respuesta -eq "yes")
}

function Invoke-PromptString {
    <#
    .SYNOPSIS
        Solicita una cadena de texto
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Mensaje,

        [Parameter()]
        [string]$Default = ""
    )

    $defaultDisplay = if ($Default) { " (default: $Default)" } else { "" }
    $respuesta = Read-Host "  $Mensaje$defaultDisplay"

    if ([string]::IsNullOrWhiteSpace($respuesta)) {
        return $Default
    }

    return $respuesta.Trim()
}

function Invoke-PromptAccionRepositorio {
    <#
    .SYNOPSIS
        Solicita la acción sobre el repositorio Git
    #>

    [CmdletBinding()]
    param()

    Write-Host "`n  ── Configuración de repositorio Git ──" -ForegroundColor Cyan
    Write-Host "  1) Crear nuevo repositorio y conectar con remoto" -ForegroundColor White
    Write-Host "  2) Clonar repositorio existente" -ForegroundColor White
    Write-Host "  3) Conectar con repositorio local existente" -ForegroundColor White
    Write-Host "  4) Ninguno (proyecto sin Git)" -ForegroundColor White

    while ($true) {
        $opcion = Read-Host "  Seleccione una opción (1-4, default: 4)"

        if ([string]::IsNullOrWhiteSpace($opcion)) {
            return "Ninguno"
        }

        switch ($opcion) {
            "1" { return "Nuevo" }
            "2" { return "Clonar" }
            "3" { return "Conectar" }
            "4" { return "Ninguno" }
            default {
                Write-Host "    ✗ Opción inválida" -ForegroundColor Red
                continue
            }
        }
    }
}
