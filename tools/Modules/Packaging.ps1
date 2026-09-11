function Crear-ZipDespliegue {
    <#
    .SYNOPSIS
        Crea un paquete ZIP para despliegue excluyendo .git, .github, .vscode, logs, __pycache__, *.pyc, temp.
    .PARAMETER SourceDir
        Directorio del proyecto a empaquetar.
    .PARAMETER OutputPath
        Ruta para el archivo ZIP.
    .PARAMETER ExcludePatterns
        Lista de patrones a excluir (por defecto: .git .github .vscode logs __pycache__ *.pyc temp).
    .OUTPUTS
        Hashtable con la información del ZIP.
    #>
    param(
        [Parameter(Mandatory)] [string] $SourceDir,
        [Parameter(Mandatory)] [string] $OutputPath,
        [string[]] $ExcludePatterns = @()
    )

    $horaInicio = Get-Date

    if (-not (Test-Path $SourceDir)) {
        throw "Directorio de origen no encontrado: $SourceDir"
    }

    $directorioSalida = Split-Path $OutputPath -Parent
    if (-not (Test-Path $directorioSalida)) {
        $null = New-Item -Path $directorioSalida -ItemType Directory -Force
    }

    if (Test-Path $OutputPath) {
        Remove-Item -Path $OutputPath -Force
    }

    if ($ExcludePatterns.Count -eq 0) {
        $ExcludePatterns = @(".git", ".github", ".vscode", "logs", "__pycache__", "*.pyc", "temp")
    }

    Write-Host "[Packaging] Creando ZIP: $OutputPath"

    $directorioOriginal = Get-Location
    Set-Location $SourceDir

    try {
        $null = Get-Command 7z -ErrorAction SilentlyContinue
        if ($?) {
            $argumentosExclusion = $ExcludePatterns | ForEach-Object { "-x!$_" }
            $null = & 7z a -tzip $OutputPath . -r @argumentosExclusion -bso0 -bsp0 2>&1
            Write-Host "[Packaging] ZIP creado con 7z"
        } else {
            throw "7z no disponible"
        }
    }
    catch {
        Write-Host "[Packaging] 7z no disponible, usando Compress-Archive" -ForegroundColor Yellow
        $elementos = Get-ChildItem -Path $SourceDir
        $parametrosCompresion = @{
            Path = $elementos.FullName
            DestinationPath = $OutputPath
            Force = $true
        }
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            $parametrosCompresion.CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
        }
        Compress-Archive @parametrosCompresion
    }
    finally {
        Set-Location $directorioOriginal
    }

    $infoArchivo = Get-Item $OutputPath
    $sha256 = (Get-FileHash -Path $OutputPath -Algorithm SHA256).Hash

    Write-Host "[Packaging] ZIP creado: $OutputPath"
    Write-Host "[Packaging] Tamaño: $([math]::Round($infoArchivo.Length / 1KB, 2)) KB"
    Write-Host "[Packaging] SHA256: $sha256"

    $tiempoTranscurrido = (Get-Date) - $horaInicio
    $duracion = [math]::Round($tiempoTranscurrido.TotalSeconds, 2)

    return @{
        ZipPath = $OutputPath
        SizeKB = [math]::Round($infoArchivo.Length / 1KB, 2)
        SHA256 = $sha256
        Duration = $duracion
        Status = "OK"
    }
}

function Validar-IntegridadZipDespliegue {
    <#
    .SYNOPSIS
        Valida la estructura e integridad del ZIP de despliegue.
        Verifica que contenga los archivos requeridos: main.py, requirements.txt, startup.sh, .gitignore.
    .PARAMETER ZipPath
        Ruta al archivo ZIP.
    .OUTPUTS
        Hashtable con los resultados de validación.
    #>
    param(
        [Parameter(Mandatory)] [string] $ZipPath
    )

    if (-not (Test-Path $ZipPath)) {
        throw "Archivo ZIP no encontrado: $ZipPath"
    }

    $infoArchivo = Get-Item $ZipPath
    $hash = Get-FileHash -Path $ZipPath -Algorithm SHA256

    $archivosRequeridos = @("main.py", "requirements.txt", "startup.sh", ".gitignore")
    $archivosEncontrados = @()

    try {
        $null = Get-Command 7z -ErrorAction SilentlyContinue
        if ($?) {
            $contenidoZip = & 7z l $ZipPath -ba 2>&1
            foreach ($archivo in $archivosRequeridos) {
                if ($contenidoZip -match [regex]::Escape($archivo)) {
                    $archivosEncontrados += $archivo
                }
            }
        } else {
            throw "7z no disponible"
        }
    }
    catch {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        $entradas = $zip.Entries.FullName
        $zip.Dispose()

        foreach ($archivo in $archivosRequeridos) {
            if ($entradas -contains $archivo) {
                $archivosEncontrados += $archivo
            }
        }
    }

    $faltantes = $archivosRequeridos | Where-Object { $_ -notin $archivosEncontrados }

    return @{
        ZipPath = $ZipPath
        SizeKB = [math]::Round($infoArchivo.Length / 1KB, 2)
        SHA256 = $hash.Hash
        RequiredFilesFound = $archivosEncontrados.Count
        RequiredFilesTotal = $archivosRequeridos.Count
        MissingFiles = $faltantes
        Valid = ($faltantes.Count -eq 0)
    }
}

Export-ModuleMember -Function Crear-ZipDespliegue, Validar-IntegridadZipDespliegue