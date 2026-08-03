<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Hermes.Commands.psm1 (RC56)
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Modulo principal de comandos Hermes Enterprise RC56.
    Incluye 21 comandos publicos: proyectos (12), entornos (6), workspace (3) + utilidades.
    Todos los proveedores, pipelines e historicos se integran desde aqui.
====================================================================================================
#>

Set-StrictMode -Version Latest

# ─────────────────────────────────────────────────────────────────
# CONSTANTES
# ─────────────────────────────────────────────────────────────────
$script:HermesRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:HermesDb = Join-Path $script:HermesRoot 'hermes.db'
$script:ProjectFactoryModule = Join-Path $script:HermesRoot 'tools\ProjectFactoryV2.psm1'
$script:EnterprisePipelineModule = Join-Path $script:HermesRoot 'tools\Invoke-EnterprisePipeline.ps1'
$script:RC56PipelineFile = Join-Path $PSScriptRoot 'Pipeline\RC56-EnterprisePipeline.ps1'

# ─────────────────────────────────────────────────────────────────
# HELPERS INTERNOS
# ─────────────────────────────────────────────────────────────────

function _New-GuidH { return [guid]::NewGuid().ToString('N') }

function _Get-ConfigValue {
    param([string]$Key, [string]$Default = '')
    $v = & sqlite3.exe "`"$script:HermesDb`"" "SELECT Value FROM Configuration WHERE Key='$Key'" 2>$null
    if ([string]::IsNullOrEmpty($v)) { return $Default }
    return $v.Trim()
}

function _Get-DbLog {
    param([string]$Table, [string]$Id, [string]$Action, [string]$Result = 'Pending', [hashtable]$Extra = @{})
    $now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $cols = "Id,Operation,StartTime,Result"
    $vals = "'$Id','$Action','$now','$Result'"
    foreach ($k in $Extra.Keys) { $cols += ",$k"; $vals += ",'$($Extra[$k])'" }
    & sqlite3.exe "`"$script:HermesDb`"" "INSERT INTO $Table ($cols) VALUES ($vals)" 2>$null | Out-Null
}

function _Complete-DbLog {
    param([string]$Table, [string]$Id, [string]$Result = 'Success')
    $now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $sql = "UPDATE $Table SET EndTime='$now', Duration=ROUND((julianday('$now')-julianday(StartTime))*86400,2), Result='$Result' WHERE Id='$Id'"
    & sqlite3.exe "`"$script:HermesDb`"" $sql 2>$null | Out-Null
}

function _Write-ProjectHistory {
    param([string]$ProjectId, [string]$Operation, [string]$Workspace = '', [string]$Result = 'Pending')
    $id = _New-GuidH
    $user = $env:USERNAME
    $ws = $Workspace.Replace("'", "''")
    $now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $sql = "INSERT INTO ProjectHistory (Id,ProjectId,Operation,StartTime,Result,Workspace,User) VALUES ('$id','$ProjectId','$Operation','$now','$Result','$ws','$user')"
    & sqlite3.exe "`"$script:HermesDb`"" $sql 2>$null | Out-Null
    return $id
}

function _Complete-ProjectHistory {
    param([string]$HistoryId, [string]$Result = 'Success', [string]$GitHubRepo = '', [string]$GitCommit = '')
    $now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $extra = ''
    if ($GitHubRepo) { $extra += ",GitHubRepository='$GitHubRepo'" }
    if ($GitCommit) { $extra += ",GitCommit='$GitCommit'" }
    & sqlite3.exe "`"$script:HermesDb`"" "UPDATE ProjectHistory SET EndTime='$now', Duration=ROUND((julianday('$now')-julianday(StartTime))*86400,2), Result='$Result'$extra WHERE Id='$HistoryId'" 2>$null | Out-Null
}

function _Get-ScriptCommand {
    param([string]$Name)
    $p = Join-Path $script:HermesRoot "scripts\$Name.ps1"
    if (Test-Path $p) { return $p }
    $p2 = Join-Path $script:HermesRoot "tools\$Name.ps1"
    if (Test-Path $p2) { return $p2 }
    return $null
}

# ─────────────────────────────────────────────────────────────────
# FASE 1 - 21 COMANDOS PUBLICOS
# ─────────────────────────────────────────────────────────────────

<#
.SYNOPSIS
    Crea un proyecto Hermes con soporte completo de entorno virtual (venv/conda).
    Parametros: -TipoEntorno, -PythonVersion, -AbrirVSCode, -CrearRepositorioGitHub, -InicializarGit
#>
function Crear-HermesProyecto {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NombreProyecto,

        [Parameter(Mandatory = $false)]
        [ValidateSet('venv', 'conda')]
        [string]$TipoEntorno = $( _Get-ConfigValue -Key 'EnvironmentProvider' -Default 'venv' ),

        [Parameter(Mandatory = $false)]
        [string]$PythonVersion = $( _Get-ConfigValue -Key 'PythonDefaultVersion' -Default '3.14' ),

        [Parameter(Mandatory = $false)]
        [string]$WorkspaceRoot = 'D:\Proyectos',

        [Parameter(Mandatory = $false)]
        [string]$GitHubUser = 'FREDYASARMIENTOT',

        [Parameter(Mandatory = $false)]
        [switch]$CrearRepositorioGitHub = $true,

        [Parameter(Mandatory = $false)]
        [switch]$InicializarGit = $true,

        [Parameter(Mandatory = $false)]
        [switch]$AbrirVSCode = $true,

        [Parameter(Mandatory = $false)]
        [switch]$NoPush
    )

    $historyId = _Write-ProjectHistory -ProjectId $NombreProyecto -Operation "Crear-HermesProyecto" -Workspace $WorkspaceRoot

    try {
        Write-Host "=== Crear-HermesProyecto (RC56) ===" -ForegroundColor Cyan

        # Load RC56 pipeline if available
        if (Test-Path $script:RC56PipelineFile) {
            . $script:RC56PipelineFile

            $Context = [pscustomobject][ordered]@{
                NombreProyecto          = $NombreProyecto
                ProvisionTarget         = if ($CrearRepositorioGitHub -or $GitHubUser) { 'GitHub' } else { 'Local' }
                TipoEntorno             = $TipoEntorno
                PythonVersion           = $PythonVersion
                GitHubUser              = $GitHubUser
                CrearRepositorioGitHub  = $CrearRepositorioGitHub.IsPresent
                InicializarGit          = $InicializarGit.IsPresent
                AbrirVSCode             = $AbrirVSCode.IsPresent
                WorkspaceRoot           = $WorkspaceRoot
                NoPush                  = $NoPush.IsPresent
            }

            $result = Invoke-RC56Pipeline -Context $Context
            if ($result -eq 0) {
                _Complete-ProjectHistory -HistoryId $historyId -Result 'Success'
                Write-Host "[PASS] Proyecto $NombreProyecto creado exitosamente" -ForegroundColor Green
                return $Context
            } else {
                _Complete-ProjectHistory -HistoryId $historyId -Result 'Failed'
                Write-Host "[FAIL] Error en pipeline RC56" -ForegroundColor Red
                return $null
            }
        }

        # Fallback al pipeline antiguo
        Write-Host "  [..] Usando pipeline clasico..." -ForegroundColor Yellow
        $installed = Install-ProjectFromFactory -NombreProyecto $NombreProyecto -WorkspaceRoot $WorkspaceRoot -GitHubUser $GitHubUser -TipoEntorno $TipoEntorno -PythonVersion $PythonVersion -InicializarGit:$InicializarGit -CrearRepositorioGitHub:$CrearRepositorioGitHub -AbrirVSCode:$AbrirVSCode
        if ($installed) {
            _Complete-ProjectHistory -HistoryId $historyId -Result 'Success'
            return $installed
        }
        _Complete-ProjectHistory -HistoryId $historyId -Result 'Failed'
        return $null
    } catch {
        _Complete-ProjectHistory -HistoryId $historyId -Result ('Failed: ' + $_.Exception.Message)
        Write-Host "[FAIL] Error: $_" -ForegroundColor Red
        return $null
    }
}

<#
.SYNOPSIS
    Inicia un proyecto Hermes existente.
#>
function Start-HermesProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )

    if (-not $ProjectPath) {
        $installed = Install-ProjectFromFactory -NombreProyecto "ProyectoPrueba003" -WorkspaceRoot "D:\Proyectos" -TipoEntorno 'conda' -PythonVersion '3.14' -GitHubUser 'FREDYASARMIENTOT'
        if ($installed) { return $installed }
        return $null
    }

    if (-not (Test-Path $ProjectPath)) {
        Write-Host "[FAIL] Project path not found: $ProjectPath" -ForegroundColor Red
        return $null
    }

    Write-Host "=== Start-HermesProject: $ProjectPath ===" -ForegroundColor Cyan
    $dirs = @(".vscode", "src", "pruebas", "docs", "scripts", "data", "logs")
    foreach ($d in $dirs) {
        $p = Join-Path $ProjectPath $d
        if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
    }

    $requiredFiles = @(".gitignore", "README.md", "requirements.txt", "CURRENT_STATE.md")
    foreach ($f in $requiredFiles) {
        $fp = Join-Path $ProjectPath $f
        if (-not (Test-Path $fp)) { "" | Out-File -FilePath $fp -Encoding utf8 -Force }
    }

    return [pscustomobject][ordered]@{ ProjectPath = $ProjectPath; Status = 'Started' }
}

<#
.SYNOPSIS
    Abre un proyecto Hermes en VS Code.
#>
function Abrir-HermesProyecto {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    if (-not (Test-Path $ProjectPath)) {
        Write-Host "[FAIL] Ruta no existe: $ProjectPath" -ForegroundColor Red
        return $false
    }

    code $ProjectPath
    Write-Host "[OK] VS Code abierto: $ProjectPath" -ForegroundColor Green
    return $true
}

<#
.SYNOPSIS
    Publica el proyecto a GitHub.
#>
function Publicar-HermesProyecto {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$GitHubUser,

        [Parameter(Mandatory = $true)]
        [string]$RepoName
    )

    $historyId = _Write-ProjectHistory -ProjectId $RepoName -Operation "Publicar-HermesProyecto" -Workspace $ProjectPath

    Push-Location $ProjectPath
    try {
        $repoFull = "$GitHubUser/$RepoName"
        $remoteUrl = "https://github.com/$repoFull.git"
        git remote remove origin 2>$null | Out-Null
        git remote add origin $remoteUrl 2>&1 | Out-Null
        Write-Host "[OK] Remote origin: $remoteUrl" -ForegroundColor Green

        $ghStatus = & { gh repo view $repoFull } 2>&1 | Out-String
        if ($ghStatus -notmatch "Viewing") {
            & { gh repo create $repoFull --public } 2>&1 | Out-Null
            Write-Host "[OK] GitHub repo created: $repoFull" -ForegroundColor Green
        }

        git push -u origin main 2>&1 | Out-Null
        Write-Host "[OK] Push upstream exitoso" -ForegroundColor Green

        _Complete-ProjectHistory -HistoryId $historyId -Result 'Success' -GitHubRepo $repoFull
        return $true
    } catch {
        _Complete-ProjectHistory -HistoryId $historyId -Result "Failed: $_"
        Write-Host "[FAIL] Error: $_" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

<#
.SYNOPSIS
    Cierra un proyecto Hermes eliminando archivos temporales.
#>
function Cerrar-HermesProyecto {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    Remove-Item -Path (Join-Path $ProjectPath 'logs\*') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path (Join-Path $ProjectPath '.venv') -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Proyecto cerrado: $ProjectPath" -ForegroundColor Green
    return $true
}

<#
.SYNOPSIS
    Elimina un proyecto Hermes completamente.
#>
function Eliminar-HermesProyecto {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    if (Test-Path $ProjectPath) {
        Remove-Item -Path $ProjectPath -Recurse -Force
        Write-Host "[OK] Proyecto eliminado: $ProjectPath" -ForegroundColor Green
    }
    return $true
}

<#
.SYNOPSIS
    Obtiene el estado de un proyecto.
#>
function Get-HermesProyecto {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    if (-not (Test-Path $ProjectPath)) {
        Write-Host "[INFO] Proyecto no existe: $ProjectPath" -ForegroundColor Yellow
        return $null
    }

    $state = [pscustomobject][ordered]@{
        ProjectPath     = $ProjectPath
        Exists          = $true
        HasGit          = Test-Path (Join-Path $ProjectPath '.git')
        HasSrc          = Test-Path (Join-Path $ProjectPath 'src')
        HasPruebas      = Test-Path (Join-Path $ProjectPath 'pruebas')
        HasDocs         = Test-Path (Join-Path $ProjectPath 'docs')
        HasVenv         = Test-Path (Join-Path $ProjectPath '.venv')
        HasReadme       = Test-Path (Join-Path $ProjectPath 'README.md')
        HasGitignore    = Test-Path (Join-Path $ProjectPath '.gitignore')
        HasVSCode       = Test-Path (Join-Path $ProjectPath '.vscode')
    }

    $state | Format-List
    return $state
}

<#
.SYNOPSIS
    Lista todos los proyectos en el workspace.
#>
function Get-HermesProyectos {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$WorkspaceRoot = 'D:\Proyectos'
    )

    if (-not (Test-Path $WorkspaceRoot)) {
        Write-Host "[INFO] Workspace no existe: $WorkspaceRoot" -ForegroundColor Yellow
        return
    }

    $projects = Get-ChildItem -Path $WorkspaceRoot -Directory | ForEach-Object {
        $p = $_.FullName
        [pscustomobject][ordered]@{
            Name    = $_.Name
            Path    = $p
            HasGit  = Test-Path (Join-Path $p '.git')
            HasSrc  = Test-Path (Join-Path $p 'src')
        }
    }
    $projects | Format-Table -AutoSize
    return $projects
}

<#
.SYNOPSIS
    Comprueba disponibilidad de Python y versión.
#>
function Test-HermesPython {
    $pv = & python --version 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] $($pv.Trim())" -ForegroundColor Green
        return $pv.Trim()
    }
    Write-Host "[FAIL] Python no disponible" -ForegroundColor Red
    return $null
}

<#
.SYNOPSIS
    Genera documentación base del proyecto.
#>
function New-HermesDocumentacion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = 'HermesProject'
    )

    $docsDir = Join-Path $ProjectPath 'docs'
    if (-not (Test-Path $docsDir)) { New-Item -ItemType Directory -Path $docsDir -Force | Out-Null }

    $readmePath = Join-Path $ProjectPath 'README.md'
    $readmeContent = @"
# $ProjectName

Proyecto Hermes Enterprise generado automaticamente.

## Estructura
- src/ - Codigo fuente
- pruebas/ - Pruebas
- docs/ - Documentacion
- scripts/ - Scripts
- data/ - Datos

## Instalacion
\`\`\`bash
pip install -r requirements.txt
\`\`\`
"@
    $readmeContent | Out-File -FilePath $readmePath -Encoding utf8 -Force

    Write-Host "[OK] Documentacion generada" -ForegroundColor Green
    return $readmePath
}

<#
.SYNOPSIS
    Realiza un commit en el proyecto.
#>
function New-HermesCommit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [string]$Mensaje = 'Hermes Enterprise commit'
    )

    Push-Location $ProjectPath
    try {
        git add -A 2>&1 | Out-Null
        $status = & { git status --porcelain } 2>&1 | Out-String
        if ($status.Trim().Length -gt 0) {
            git commit -m $Mensaje 2>&1 | Out-Null
            Write-Host "[OK] Commit: $Mensaje" -ForegroundColor Green
            return $true
        }
        Write-Host "[OK] No changes to commit" -ForegroundColor Green
        return $true
    } finally {
        Pop-Location
    }
}

# ─────────────────────────────────────────────────────────────────
# COMANDOS DE ENTORNO (6)
# ─────────────────────────────────────────────────────────────────

<#
.SYNOPSIS
    Crea un entorno virtual (venv) en el proyecto.
#>
function New-HermesVenv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [string]$PythonVersion = '3.14',

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = ''
    )

    $envMod = Join-Path $PSScriptRoot 'Providers\EnvironmentProvider.ps1'
    if (Test-Path $envMod) { . $envMod }

    $envId = _New-GuidH
    $provider = New-EnvironmentProvider -Id $envId -Name "Venv-$ProjectName" -Version '1.0.0' -ProviderType 'VenvEnvironment' -ProviderConfig @{ PythonVersion = $PythonVersion }
    return New-VenvEnvironment -Provider $provider -ProjectPath $ProjectPath -PythonVersion $PythonVersion -ProjectName $ProjectName
}

<#
.SYNOPSIS
    Activa el entorno venv (retorna comando de activación).
#>
function Enter-HermesVenv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $activateScript = Join-Path $ProjectPath '.venv\Scripts\Activate.ps1'
    if (Test-Path $activateScript) {
        Write-Host "[OK] Activar: & '$activateScript'" -ForegroundColor Green
        return "& '$activateScript'"
    }
    Write-Host "[WARN] No se encontro .venv\Scripts\Activate.ps1" -ForegroundColor Yellow
    return $null
}

<#
.SYNOPSIS
    Elimina el entorno venv.
#>
function Remove-HermesVenv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = ''
    )

    $envMod = Join-Path $PSScriptRoot 'Providers\EnvironmentProvider.ps1'
    if (Test-Path $envMod) { . $envMod }

    $envId = _New-GuidH
    $provider = New-EnvironmentProvider -Id $envId -Name "Venv-$ProjectName" -Version '1.0.0' -ProviderType 'VenvEnvironment'
    return Remove-VenvEnvironment -Provider $provider -ProjectPath $ProjectPath -ProjectName $ProjectName
}

<#
.SYNOPSIS
    Crea un entorno Conda.
#>
function New-HermesConda {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$EnvironmentName,

        [Parameter(Mandatory = $false)]
        [string]$PythonVersion = '3.14',

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = ''
    )

    $envMod = Join-Path $PSScriptRoot 'Providers\EnvironmentProvider.ps1'
    if (Test-Path $envMod) { . $envMod }

    $envId = _New-GuidH
    $provider = New-EnvironmentProvider -Id $envId -Name "Conda-$ProjectName" -Version '1.0.0' -ProviderType 'CondaEnvironment' -ProviderConfig @{ PythonVersion = $PythonVersion }
    return New-CondaEnvironment -Provider $provider -ProjectPath $ProjectPath -EnvironmentName $EnvironmentName -PythonVersion $PythonVersion -ProjectName $ProjectName
}

<#
.SYNOPSIS
    Activa un entorno Conda (retorna comando).
#>
function Enter-HermesConda {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentName
    )

    Write-Host "[OK] Activar conda: conda activate $EnvironmentName" -ForegroundColor Green
    return "conda activate $EnvironmentName"
}

<#
.SYNOPSIS
    Elimina un entorno Conda.
#>
function Remove-HermesConda {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentName,

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = ''
    )

    $envMod = Join-Path $PSScriptRoot 'Providers\EnvironmentProvider.ps1'
    if (Test-Path $envMod) { . $envMod }

    $envId = _New-GuidH
    $provider = New-EnvironmentProvider -Id $envId -Name "Conda-$ProjectName" -Version '1.0.0' -ProviderType 'CondaEnvironment'
    return Remove-CondaEnvironment -Provider $provider -EnvironmentName $EnvironmentName -ProjectName $ProjectName
}

# ─────────────────────────────────────────────────────────────────
# COMANDOS DE WORKSPACE (3)
# ─────────────────────────────────────────────────────────────────

<#
.SYNOPSIS
    Crea un nuevo workspace (directorio de proyectos).
#>
function New-HermesWorkspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceRoot
    )

    if (-not (Test-Path $WorkspaceRoot)) {
        New-Item -ItemType Directory -Path $WorkspaceRoot -Force | Out-Null
        Write-Host "[OK] Workspace creado: $WorkspaceRoot" -ForegroundColor Green
    } else {
        Write-Host "[OK] Workspace ya existe: $WorkspaceRoot" -ForegroundColor Green
    }

    $id = _New-GuidH
    $now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    & sqlite3.exe "`"$script:HermesDb`"" "INSERT INTO WorkspaceHistory (Id,WorkspacePath,Action,Result,StartTime) VALUES ('$id','$WorkspaceRoot','Create','Success','$now')" 2>$null | Out-Null
    return $true
}

<#
.SYNOPSIS
    Abre un workspace en VS Code.
#>
function Open-HermesWorkspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceRoot
    )

    if (-not (Test-Path $WorkspaceRoot)) {
        Write-Host "[FAIL] Workspace no existe: $WorkspaceRoot" -ForegroundColor Red
        return $false
    }

    code $WorkspaceRoot
    Write-Host "[OK] Workspace abierto: $WorkspaceRoot" -ForegroundColor Green
    return $true
}

<#
.SYNOPSIS
    Lista workspaces registrados.
#>
function Get-HermesWorkspace {
    $ws = & sqlite3.exe "`"$script:HermesDb`"" "SELECT DISTINCT WorkspacePath FROM WorkspaceHistory ORDER BY CreatedAt DESC" 2>$null
    if ($ws) {
        $ws -split "`n" | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }
    } else {
        Write-Host "[INFO] No hay workspaces registrados. Default: D:\Proyectos" -ForegroundColor Yellow
    }
}

# ─────────────────────────────────────────────────────────────────
# COMANDOS DE INSTALACIÓN (FACTORY - compatibilidad RC53)
# ─────────────────────────────────────────────────────────────────

function Install-ProjectFromFactory {
    [CmdletBinding()]
    param(
        [string]$NombreProyecto,
        [string]$WorkspaceRoot = 'D:\Proyectos',
        [string]$GitHubUser = 'FREDYASARMIENTOT',
        [string]$TipoEntorno = 'conda',
        [string]$PythonVersion = '3.14',
        [switch]$InicializarGit = $true,
        [switch]$CrearRepositorioGitHub = $true,
        [switch]$AbrirVSCode = $true
    )

    $historyId = _Write-ProjectHistory -ProjectId $NombreProyecto -Operation 'Crear-HermesProyecto' -Workspace $WorkspaceRoot
    $projectPath = Join-Path $WorkspaceRoot $NombreProyecto

    # 1. Workspace
    if (-not (Test-Path $projectPath)) { New-Item -ItemType Directory -Path $projectPath -Force | Out-Null }
    Write-Host "[OK] Carpeta: $projectPath" -ForegroundColor Green

    # 2. Load RC56 pipeline
    if (Test-Path $script:RC56PipelineFile) {
        . $script:RC56PipelineFile
        $Context = [pscustomobject][ordered]@{
            NombreProyecto          = $NombreProyecto
            ProvisionTarget         = if ($CrearRepositorioGitHub -or $GitHubUser) { 'GitHub' } else { 'Local' }
            TipoEntorno             = $TipoEntorno
            PythonVersion           = $PythonVersion
            GitHubUser              = $GitHubUser
            CrearRepositorioGitHub  = $CrearRepositorioGitHub.IsPresent
            InicializarGit          = $InicializarGit.IsPresent
            AbrirVSCode             = $AbrirVSCode.IsPresent
            WorkspaceRoot           = $WorkspaceRoot
        }
        $result = Invoke-RC56Pipeline -Context $Context
        if ($result -eq 0) {
            _Complete-ProjectHistory -HistoryId $historyId -Result 'Success'
            return $Context
        }
    }

    # 3. Minimal fallback
    $dirs = @(".vscode", "src", "pruebas", "docs", "scripts", "data", "logs")
    foreach ($d in $dirs) { $p = Join-Path $projectPath $d; if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null } }

    $files = @(".gitignore", "README.md", "requirements.txt", "CURRENT_STATE.md")
    foreach ($f in $files) { $fp = Join-Path $projectPath $f; if (-not (Test-Path $fp)) { "" | Out-File -FilePath $fp -Encoding utf8 -Force } }

    # 4. Conda/venv
    $envMod = Join-Path $PSScriptRoot 'Providers\EnvironmentProvider.ps1'
    if (Test-Path $envMod) {
        . $envMod
        $envId = _New-GuidH
        if ($TipoEntorno -eq 'conda') {
            $provider = New-EnvironmentProvider -Id $envId -Name "Conda-$NombreProyecto" -Version '1.0.0' -ProviderType 'CondaEnvironment' -ProviderConfig @{ PythonVersion = $PythonVersion }
            New-CondaEnvironment -Provider $provider -ProjectPath $projectPath -EnvironmentName $NombreProyecto -PythonVersion $PythonVersion -ProjectName $NombreProyecto | Out-Null
        } else {
            $provider = New-EnvironmentProvider -Id $envId -Name "Venv-$NombreProyecto" -Version '1.0.0' -ProviderType 'VenvEnvironment' -ProviderConfig @{ PythonVersion = $PythonVersion }
            New-VenvEnvironment -Provider $provider -ProjectPath $projectPath -PythonVersion $PythonVersion -ProjectName $NombreProyecto | Out-Null
        }
    }

    # 5. Git
    if ($InicializarGit) {
        Push-Location $projectPath
        if (-not (Test-Path (Join-Path $projectPath '.git'))) {
            git init 2>&1 | Out-Null
            $head = & { git rev-parse --verify HEAD } 2>$null
            if (-not $head) { git add -A 2>&1 | Out-Null; git commit -m "RC56 - Initial commit" 2>&1 | Out-Null }
            git checkout -b main 2>&1 | Out-Null
        }
        Pop-Location
    }

    # 6. GitHub
    if ($CrearRepositorioGitHub -and $GitHubUser) {
        $repoFull = "$GitHubUser/$NombreProyecto"
        $exists = & { gh repo view $repoFull } 2>&1 | Out-String
        if ($exists -notmatch "Viewing") { & { gh repo create $repoFull --public } 2>&1 | Out-Null }

        if ($InicializarGit) {
            Push-Location $projectPath
            $remoteUrl = "https://github.com/$repoFull.git"
            git remote remove origin 2>$null | Out-Null
            git remote add origin $remoteUrl 2>&1 | Out-Null
            git push -u origin main 2>&1 | Out-Null
            Pop-Location
        }
    }

    # 7. VS Code
    if ($AbrirVSCode) { code $projectPath }

    _Complete-ProjectHistory -HistoryId $historyId -Result 'Success'
    Write-Host "[PASS] Proyecto $NombreProyecto instalado (factory)" -ForegroundColor Green
    return [pscustomobject][ordered]@{ ProjectPath = $projectPath; Status = 'Installed' }
}

# ─────────────────────────────────────────────────────────────────
# EXPORT MODULE (desde .psd1, pero tambien aqui por seguridad)
# ─────────────────────────────────────────────────────────────────
Export-ModuleMember -Function @(
    'Crear-HermesProyecto',
    'Start-HermesProject',
    'Abrir-HermesProyecto',
    'Publicar-HermesProyecto',
    'Cerrar-HermesProyecto',
    'Eliminar-HermesProyecto',
    'Get-HermesProyecto',
    'Get-HermesProyectos',
    'Test-HermesPython',
    'New-HermesDocumentacion',
    'New-HermesCommit',
    'New-HermesVenv',
    'Enter-HermesVenv',
    'Remove-HermesVenv',
    'New-HermesConda',
    'Enter-HermesConda',
    'Remove-HermesConda',
    'New-HermesWorkspace',
    'Open-HermesWorkspace',
    'Get-HermesWorkspace',
    'Install-ProjectFromFactory'
)

Write-Host "[Hermes.Commands] RC56 Module loaded. 21 commands exported." -ForegroundColor Cyan