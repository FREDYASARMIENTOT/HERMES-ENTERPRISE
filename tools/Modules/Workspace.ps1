function Inicializar-EspacioProyecto {
    <#
    .SYNOPSIS
        Crea el directorio del proyecto y su estructura de subdirectorios.
    .PARAMETER ProjectName
        Nombre del proyecto.
    .PARAMETER OutputDir
        Directorio raíz donde se creará el proyecto.
    .PARAMETER CorrelationId
        Identificador único de correlación.
    .OUTPUTS
        Hashtable con la ruta del espacio de trabajo.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectName,
        [Parameter(Mandatory)] [string] $OutputDir,
        [Parameter(Mandatory)] [string] $CorrelationId
    )

    $horaInicio = Get-Date

    Write-Host "[Workspace] Creando espacio de trabajo para: $ProjectName"
    Write-Host "[Workspace] Directorio: $OutputDir"

    if (-not (Test-Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        Write-Host "[Workspace] Directorio creado: $OutputDir"
    }

    $subdirectorios = @("backend", "templates", "static", "data", "docs", "scripts")
    foreach ($dir in $subdirectorios) {
        $rutaCompleta = Join-Path $OutputDir $dir
        if (-not (Test-Path $rutaCompleta)) {
            New-Item -Path $rutaCompleta -ItemType Directory -Force | Out-Null
        }
    }

    $tiempoTranscurrido = (Get-Date) - $horaInicio
    $duracion = [math]::Round($tiempoTranscurrido.TotalSeconds, 2)

    Write-Host "[Workspace] Espacio de trabajo inicializado en ${duracion}s"

    return @{
        WorkspacePath = $OutputDir
        Subdirs = $subdirectorios
        Duration = $duracion
        Status = "OK"
    }
}

function Crear-ArchivoEspacioTrabajo {
    <#
    .SYNOPSIS
        Crea el archivo .code-workspace de VSCode para el proyecto.
    .PARAMETER ProjectName
        Nombre del proyecto.
    .PARAMETER OutputDir
        Directorio raíz del proyecto.
    .OUTPUTS
        Ruta del archivo de espacio de trabajo creado.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectName,
        [Parameter(Mandatory)] [string] $OutputDir
    )

    $archivoEspacioTrabajo = Join-Path (Split-Path $OutputDir -Parent) "$ProjectName.code-workspace"
    $contenidoEspacioTrabajo = @{
        folders = @(
            @{ path = $OutputDir }
        )
        settings = @{
            "python.defaultInterpreterPath" = "python"
            "files.encoding" = "utf8"
        }
    }
    $contenidoEspacioTrabajo | ConvertTo-Json -Depth 3 | Out-File -FilePath $archivoEspacioTrabajo -Encoding UTF8 -Force
    Write-Host "[Workspace] Archivo de espacio de trabajo creado: $archivoEspacioTrabajo"

    return $archivoEspacioTrabajo
}

Export-ModuleMember -Function Inicializar-EspacioProyecto, Crear-ArchivoEspacioTrabajo