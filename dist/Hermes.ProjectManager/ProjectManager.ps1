<#
ProjectManager.ps1 — Comandos de gestión avanzada de proyectos Hermes
No exportada. Solo uso interno del módulo.
#>

function _New-ProjectFromFactory {
    param(
        [string]$ProjectPath,
        [string]$ProjectName,
        [string]$TipoEntorno = 'venv',
        [switch]$InicializarGit,
        [switch]$CrearRepositorioGitHub,
        [switch]$AbrirVSCode,
        [switch]$NoPush
    )
    # 1. Create folder structure
    _New-ProjectFolder -ProjectPath $ProjectPath -ProjectName $ProjectName
    # 2. Register in DB
    _Register-ProjectInDb -ProjectPath $ProjectPath -ProjectName $ProjectName -Provider $TipoEntorno
    # 3. Git init
    if ($InicializarGit) { _Initialize-GitRepo -ProjectPath $ProjectPath }
    # 4. Open in VSCode
    if ($AbrirVSCode) { _Open-ProjectInVSCode -ProjectPath $ProjectPath }
    # 5. GitHub repo
    if ($CrearRepositorioGitHub) {
        try {
            $ghScript = _Resolve-ScriptPath -Name 'GitHub'
            if ($ghScript) { & $ghScript -ProjectPath $ProjectPath -ProjectName $ProjectName -NoPush:$NoPush }
        } catch { Write-Warning "GitHub creation failed: $_" }
    }
    return $true
}

function _Copy-ProjectFolder {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )
    if (-not (Test-Path $SourcePath)) { throw "Source path does not exist: $SourcePath" }
    if (Test-Path $DestinationPath) { throw "Destination path already exists: $DestinationPath" }
    Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse -Force -ErrorAction Stop
    return $true
}

function _Backup-ProjectFolder {
    param(
        [string]$ProjectPath,
        [string]$BackupPath
    )
    if (-not (Test-Path $ProjectPath)) { throw "Project path does not exist: $ProjectPath" }
    $backupDir = Split-Path $BackupPath -Parent
    if (-not (Test-Path $backupDir)) { New-Item -Path $backupDir -ItemType Directory -Force | Out-Null }
    $exclude = @('.venv', 'node_modules', '__pycache__', '.git')
    Get-ChildItem -Path $ProjectPath -Exclude $exclude | Copy-Item -Destination $BackupPath -Recurse -Force -ErrorAction Stop
    return $true
}

function _Restore-ProjectFolder {
    param(
        [string]$BackupPath,
        [string]$RestorePath
    )
    if (-not (Test-Path $BackupPath)) { throw "Backup path does not exist: $BackupPath" }
    if (Test-Path $RestorePath) { throw "Restore path already exists: $RestorePath" }
    Copy-Item -Path "$BackupPath\*" -Destination $RestorePath -Recurse -Force -ErrorAction Stop
    _Set-ProjectMarker -ProjectPath $RestorePath -ProjectName (Split-Path $RestorePath -Leaf)
    return $true
}

function _Rename-Project {
    param(
        [string]$ProjectPath,
        [string]$NewName
    )
    $parent = Split-Path $ProjectPath -Parent
    $newPath = Join-Path $parent $NewName
    if (Test-Path $newPath) { throw "Target path already exists: $newPath" }
    Rename-Item -Path $ProjectPath -NewName $NewName -ErrorAction Stop
    _Set-ProjectMarker -ProjectPath $newPath -ProjectName $NewName
    _Update-ProjectInDb -ProjectPath $ProjectPath -Status 'Renamed'
    return $newPath
}

function _Export-ProjectManifest {
    param([string]$ProjectPath)
    $info = _Get-ProjectInfo -ProjectPath $ProjectPath
    if (-not $info) { return $null }
    $manifest = @{
        ProjectName = $info.Name
        ProjectPath = $info.Path
        CreatedAt   = $info.CreatedAt
        Status      = $info.Status
        Version     = $info.Version
        Provider    = $info.Provider
    }
    if (_Test-GitRepository -Path $ProjectPath) {
        Push-Location $ProjectPath
        $manifest.GitCommit = (& git rev-parse HEAD 2>$null).Trim()
        Pop-Location
    }
    return $manifest
}

function _Import-ProjectManifest {
    param(
        [string]$ManifestPath,
        [string]$TargetPath
    )
    if (-not (Test-Path $ManifestPath)) { throw "Manifest not found: $ManifestPath" }
    $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
    _New-ProjectFolder -ProjectPath $TargetPath -ProjectName $manifest.ProjectName
    _Register-ProjectInDb -ProjectPath $TargetPath -ProjectName $manifest.ProjectName
    return $true
}