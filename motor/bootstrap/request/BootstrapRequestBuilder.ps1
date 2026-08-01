<#
.SYNOPSIS
    Construye un BootstrapRequest a partir de entrada del usuario

.DESCRIPTION
    BootstrapRequestBuilder interactÃºa con el usuario para recopilar
    toda la informaciÃ³n necesaria para crear un proyecto Hermes.

    Este componente es responsable ÃšNICAMENTE de:
    - Preguntar al usuario (vÃ­a Read-Host)
    - Validar respuestas
    - Construir un BootstrapRequest vÃ¡lido

    NO es responsable de:
    - Crear archivos o carpetas
    - Ejecutar comandos git
    - Manipular BootstrapState
    - Invocar el orquestador

    Flujo:
        Usuario â†’ Builder â†’ BootstrapRequest â†’ Converter â†’ BootstrapState

.NOTES
    Autor: Hermes Agent
    Fecha: 2026-07-10
    VersiÃ³n: 1.0.0

    Principios:
    - SeparaciÃ³n de preocupaciones: SOLO captura datos
    - Valida cada respuesta antes de continuar
    - Proporciona valores por defecto razonables
    - No asume nada sobre el sistema del usuario
#>

function Invoke-BootstrapRequestBuilder {
    <#
    .SYNOPSIS
        InteractÃºa con el usuario para construir un BootstrapRequest

    .DESCRIPTION
        GuÃ­a al usuario a travÃ©s de una serie de preguntas para
        recopilar toda la informaciÃ³n necesaria para crear un proyecto
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

    Write-Output "`nâ•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan
    Write-Output "â•‘     HERMES ENTERPRISE - ConfiguraciÃ³n de Nuevo Proyecto     â•‘" -ForegroundColor Cyan
    Write-Output "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan
    Write-Output ""

    # â”€â”€ 1. Nombre del proyecto â”€â”€
    if ([string]::IsNullOrWhiteSpace($NombreProyecto)) {
        $NombreProyecto = Invoke-PromptNombreProyecto
    } else {
        Write-Output "  âœ“ Nombre del proyecto: $NombreProyecto" -ForegroundColor Green
    }

    # â”€â”€ 2. Rutas â”€â”€
    $RutaProyecto = Invoke-PromptRutaProyecto -NombreProyecto $NombreProyecto
    $RutaDefaultEnvironment = Join-Path $RutaProyecto ".venv"
    $RutaEnvironment = Invoke-PromptRutaEnvironment -RutaDefault $RutaDefaultEnvironment

    # â”€â”€ 3. Estructura del proyecto â”€â”€
    $CrearFrontend = Invoke-PromptBoolean -Mensaje "Â¿Crear estructura de frontend (frontend/)?" -Default $false
    $CrearBackend = Invoke-PromptBoolean -Mensaje "Â¿Crear estructura de backend (backend/)?" -Default $false

    # â”€â”€ 4. Runtimes â”€â”€
    $RuntimeNode = ""
    if ($CrearFrontend) {
        $RuntimeNode = Invoke-PromptString -Mensaje "  VersiÃ³n de Node.js" -Default "20.11.0"
    }

    $RuntimePython = ""
    if ($CrearBackend) {
        $RuntimePython = Invoke-PromptString -Mensaje "  VersiÃ³n de Python" -Default "3.11"
    }

    # â”€â”€ 5. Repositorio Git â”€â”€
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

    # â”€â”€ 6. ConfiguraciÃ³n adicional â”€â”€
    $CrearGitIgnore = Invoke-PromptBoolean -Mensaje "Crear archivo .gitignore?" -Default $true
    $CrearEnv = Invoke-PromptBoolean -Mensaje "Crear entorno virtual Python (.venv)?" -Default $false
    $AbrirVSCode = Invoke-PromptBoolean -Mensaje "Abrir VS Code al finalizar?" -Default $true

    # â”€â”€ 7. DescripciÃ³n â”€â”€
    $DescripcionProyecto = Invoke-PromptString -Mensaje "DescripciÃ³n del proyecto (opcional)" -Default ""

    # â”€â”€ 8. Construir DTO â”€â”€
    $request = New-BootstrapRequest @PSBoundParameters

    Write-Output "`n  âœ“ BootstrapRequest creado exitosamente" -ForegroundColor Green
    Write-Output ""

    return $request
}

function Invoke-PromptNombreProyecto {
    <#
    .SYNOPSIS
        Solicita el nombre del proyecto con validaciÃ³n
    #>

    [CmdletBinding()]
    param()

    while ($true) {
        $nombre = Read-Host "  Nombre del proyecto"

        if ([string]::IsNullOrWhiteSpace($nombre)) {
            Write-Output "    âœ— El nombre no puede estar vacÃ­o" -ForegroundColor Red
            continue
        }

        if ($nombre.Length -lt 3 -or $nombre.Length -gt 64) {
            Write-Output "    âœ— Debe tener entre 3 y 64 caracteres (ingresado: $($nombre.Length))" -ForegroundColor Red
            continue
        }

        if ($nombre -notmatch '^[a-zA-Z0-9_-]+$') {
            Write-Output "    âœ— Solo se permiten letras, nÃºmeros, guiones bajos (_) y guiones (-)" -ForegroundColor Red
            Write-Output "      Ejemplos vÃ¡lidos: MiProyecto, proyecto-demo, proyecto_2026" -ForegroundColor Gray
            continue
        }

        return $nombre
    }
}

function Invoke-PromptRutaProyecto {
    <#
    .SYNOPSIS
        Solicita la ruta donde se crearÃ¡ el proyecto
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
            Write-Output "    âœ— Debe especificar una ruta" -ForegroundColor Red
            continue
        }

        if (-not (Test-Path $ruta)) {
            Write-Output "    âœ— La ruta no existe" -ForegroundColor Red
            continue
        }

        $gitDir = Join-Path $ruta ".git"
        if (-not (Test-Path (Join-Path $gitDir "HEAD"))) {
            Write-Output "    âœ— La ruta no contiene un repositorio Git vÃ¡lido" -ForegroundColor Red
            continue
        }

        return $ruta
    }
}

function Invoke-PromptBoolean {
    <#
    .SYNOPSIS
        Solicita una respuesta sÃ­/no
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
        Solicita la acciÃ³n sobre el repositorio Git
    #>

    [CmdletBinding()]
    param()

    Write-Output "`n  â”€â”€ ConfiguraciÃ³n de repositorio Git â”€â”€" -ForegroundColor Cyan
    Write-Output "  1) Crear nuevo repositorio y conectar con remoto" -ForegroundColor White
    Write-Output "  2) Clonar repositorio existente" -ForegroundColor White
    Write-Output "  3) Conectar con repositorio local existente" -ForegroundColor White
    Write-Output "  4) Ninguno (proyecto sin Git)" -ForegroundColor White

    while ($true) {
        $opcion = Read-Host "  Seleccione una opciÃ³n (1-4, default: 4)"

        if ([string]::IsNullOrWhiteSpace($opcion)) {
            return "Ninguno"
        }

        switch ($opcion) {
            "1" { return "Nuevo" }
            "2" { return "Clonar" }
            "3" { return "Conectar" }
            "4" { return "Ninguno" }
            default {
                Write-Output "    âœ— OpciÃ³n invÃ¡lida" -ForegroundColor Red
                continue
            }
        }
    }
}
