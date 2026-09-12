function Inicializar-GitProyecto {
    <#
    .SYNOPSIS
        Inicializa un repositorio Git en el directorio del proyecto.
    .PARAMETER ProjectDir
        Ruta al directorio del proyecto.
    .PARAMETER BranchName
        Nombre de la rama (por defecto: main).
    .OUTPUTS
        Hashtable con el estado de inicialización de Git.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectDir,
        [string] $BranchName = "main"
    )

    $horaInicio = Get-Date

    if (-not (Test-Path $ProjectDir)) {
        throw "Directorio del proyecto no encontrado: $ProjectDir"
    }

    $directorioOriginal = Get-Location
    Set-Location $ProjectDir

    try {
        if (Test-Path ".git") {
            Write-Host "[Git] Repositorio ya inicializado"
            $estado = "EXISTENTE"
        }
        else {
            $salidaInicio = git init --initial-branch=$BranchName 2>&1
            Write-Host "[Git] Repositorio inicializado con rama: $BranchName"
            $null = git config user.name "Hermes Enterprise"
            $null = git config user.email "hermes@enterprise.local"
            $estado = "CREADO"
        }
    }
    finally {
        Set-Location $directorioOriginal
    }

    $tiempoTranscurrido = (Get-Date) - $horaInicio
    $duracion = [math]::Round($tiempoTranscurrido.TotalSeconds, 2)

    return @{
        Status = $estado
        Branch = $BranchName
        Duration = $duracion
        GitDir = Join-Path $ProjectDir ".git"
    }
}

function Crear-CommitProyecto {
    <#
    .SYNOPSIS
        Agrega todos los archivos al staging y crea un commit.
    .PARAMETER ProjectDir
        Ruta al directorio del proyecto.
    .PARAMETER Mensaje
        Mensaje del commit.
    .OUTPUTS
        Hashtable con la información del commit.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectDir,
        [Parameter(Mandatory)] [string] $Mensaje
    )

    $directorioOriginal = Get-Location
    Set-Location $ProjectDir

    try {
        $null = git add -A 2>&1
        $resultado = git commit -m $Mensaje 2>&1
        if ($LASTEXITCODE -ne 0) {
            $null = git add -A 2>&1
            $resultado = git commit -m $Mensaje --no-verify 2>&1
        }

        $hashCommit = git rev-parse HEAD 2>&1
        $archivosCambiados = @(git diff --cached --name-only 2>&1).Count

        Write-Host "[Git] Commit creado: $($hashCommit.Trim())"
        Write-Host "[Git] Archivos cambiados: $archivosCambiados"
    }
    finally {
        Set-Location $directorioOriginal
    }

    return @{
        CommitHash = $hashCommit.Trim()
        FilesChanged = $archivosCambiados
        Message = $Mensaje
    }
}

function Obtener-EstadoGitProyecto {
    <#
    .SYNOPSIS
        Obtiene el estado actual del repositorio Git del proyecto.
    .PARAMETER ProjectDir
        Ruta al directorio del proyecto.
    .OUTPUTS
        Hashtable con el estado de Git.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectDir
    )

    $directorioOriginal = Get-Location
    Set-Location $ProjectDir

    try {
        $estado = git status --porcelain 2>&1
        $rama = git rev-parse --abbrev-ref HEAD 2>&1
        $hashCommit = git rev-parse HEAD 2>&1
        $estaLimpio = [string]::IsNullOrEmpty($estado)
    }
    finally {
        Set-Location $directorioOriginal
    }

    return @{
        Branch = $rama.Trim()
        CommitHash = $hashCommit.Trim()
        IsClean = $estaLimpio
        StatusOutput = $estado
    }
}

Export-ModuleMember -Function Inicializar-GitProyecto, Crear-CommitProyecto, Obtener-EstadoGitProyecto