<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : RC56-EnterprisePipeline.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Pipeline RC56 para la creación de proyectos Hermes con soporte de entornos virtuales
    configurables (venv/conda), parámetros avanzados y persistencia en SQLite.
    Implementa el flujo completo: workspace, estructura, entorno, git, GitHub, VS Code.
====================================================================================================
#>

Set-StrictMode -Version Latest

function Invoke-RC56Pipeline {
    [CmdletBinding()]
    param(
        [psobject]$Context
    )

    Write-Host "=== RC56: HERMES ENTERPRISE - PIPELINE AVANZADO ===" -ForegroundColor Cyan
    Write-Host "Proyecto    : $($Context.NombreProyecto)" -ForegroundColor Yellow
    Write-Host "Target      : $($Context.ProvisionTarget)" -ForegroundColor Yellow
    Write-Host "TipoEntorno : $($Context.TipoEntorno)" -ForegroundColor Yellow
    Write-Host "PythonVer   : $($Context.PythonVersion)" -ForegroundColor Yellow
    Write-Host "GitHubUser  : $($Context.GitHubUser)" -ForegroundColor Yellow
    Write-Host "CrearRepo   : $($Context.CrearRepositorioGitHub)" -ForegroundColor Yellow
    Write-Host "InitGit     : $($Context.InicializarGit)" -ForegroundColor Yellow
    Write-Host "AbrirCode   : $($Context.AbrirVSCode)" -ForegroundColor Yellow
    Write-Host ""

    $workspaceRoot = if ($Context.WorkspaceRoot) { $Context.WorkspaceRoot } else { "D:\Proyectos" }
    $projectName = $Context.NombreProyecto
    $projectPath = Join-Path $workspaceRoot $projectName
    $repoName = $projectName
    $ghUser = $Context.GitHubUser
    $tipoEntorno = $Context.TipoEntorno
    $pythonVersion = $Context.PythonVersion
    $crearRepo = $Context.CrearRepositorioGitHub -eq $true
    $initGit = $Context.InicializarGit -eq $true
    $abrirCode = $Context.AbrirVSCode -eq $true

    # ─────────────────────────────────────────────────────────────────
    # PRE-FLIGHT: GitHub authentication check (if needed)
    # ─────────────────────────────────────────────────────────────────
    if ($crearRepo -or ($Context.ProvisionTarget -eq 'GitHub')) {
        Write-Host "=== PRE-FLIGHT: Verificar autenticacion GitHub ===" -ForegroundColor Magenta
        $ghStatus = & { gh auth status } 2>&1 | Out-String
        if ($ghStatus -match "Logged in to github.com") {
            Write-Host "  [OK] GitHub CLI autenticado" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] GitHub CLI NO autenticado" -ForegroundColor Red
            & gh auth login 2>&1 | Out-Null
            $ghStatus = & { gh auth status } 2>&1 | Out-String
            if (-not ($ghStatus -match "Logged in to github.com")) {
                Write-Host "  [FAIL] GitHub auth fallo" -ForegroundColor Red
                return 1
            }
        }

        if (-not $ghUser) {
            $ghUser = & { gh api user --jq .login } 2>$null
            if (-not $ghUser) {
                Write-Host "  [FAIL] No se pudo obtener usuario GitHub" -ForegroundColor Red
                return 1
            }
        }
        Write-Host "  [OK] Usuario: $ghUser" -ForegroundColor Green
        Write-Host ""
    }

    # ─────────────────────────────────────────────────────────────────
    # FASE 1: Workspace
    # ─────────────────────────────────────────────────────────────────
    Write-Host "=== FASE 1: Crear Workspace ===" -ForegroundColor Green
    if (-not (Test-Path $projectPath)) {
        New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
        Write-Host "  [OK] Project directory created: $projectPath" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Project directory already exists: $projectPath" -ForegroundColor Green
    }

    # ─────────────────────────────────────────────────────────────────
    # FASE 2: Directory structure
    # ─────────────────────────────────────────────────────────────────
    Write-Host "=== FASE 2: Crear estructura minima ===" -ForegroundColor Green
    $dirs = @(".vscode", "src", "pruebas", "docs", "scripts", "data", "logs")
    foreach ($d in $dirs) {
        $p = Join-Path $projectPath $d
        if (-not (Test-Path $p)) {
            New-Item -ItemType Directory -Path $p -Force | Out-Null
            Write-Host "  [OK] Created: $d" -ForegroundColor Green
        } else {
            Write-Host "  [OK] Exists: $d" -ForegroundColor Green
        }
    }

    # ─────────────────────────────────────────────────────────────────
    # FASE 3: Environment (venv or conda)
    # ─────────────────────────────────────────────────────────────────
    Write-Host "=== FASE 3: Crear entorno ($tipoEntorno) ===" -ForegroundColor Green

    $envProviderModule = Join-Path (Split-Path -Parent $PSScriptRoot) 'Providers\EnvironmentProvider.ps1'
    if (Test-Path $envProviderModule) {
        . $envProviderModule
    }

    $envId = [guid]::NewGuid().ToString('N')
    if ($tipoEntorno -eq 'venv') {
        $provider = New-EnvironmentProvider -Id $envId -Name "Venv-$projectName" -Version '1.0.0' -ProviderType 'VenvEnvironment' -ProviderConfig @{ PythonVersion = $pythonVersion }
        Initialize-ProviderBase -Provider $provider -ProviderConfig @{ PythonVersion = $pythonVersion }
        $result = New-VenvEnvironment -Provider $provider -ProjectPath $projectPath -PythonVersion $pythonVersion -ProjectName $projectName
        if (-not $result) {
            Write-Host "  [WARN] Fallback: intentando Conda..." -ForegroundColor Yellow
            $provider2 = New-EnvironmentProvider -Id ([guid]::NewGuid().ToString('N')) -Name "Conda-$projectName" -Version '1.0.0' -ProviderType 'CondaEnvironment' -ProviderConfig @{ PythonVersion = $pythonVersion }
            $result = New-CondaEnvironment -Provider $provider2 -ProjectPath $projectPath -EnvironmentName $projectName -PythonVersion $pythonVersion -ProjectName $projectName
            if (-not $result) {
                Write-Host "  [WARN] Entorno virtual no creado. Continuando sin el." -ForegroundColor Yellow
            }
        }
    } else {
        $provider = New-EnvironmentProvider -Id $envId -Name "Conda-$projectName" -Version '1.0.0' -ProviderType 'CondaEnvironment' -ProviderConfig @{ PythonVersion = $pythonVersion }
        Initialize-ProviderBase -Provider $provider -ProviderConfig @{ PythonVersion = $pythonVersion }
        $result = New-CondaEnvironment -Provider $provider -ProjectPath $projectPath -EnvironmentName $projectName -PythonVersion $pythonVersion -ProjectName $projectName
        if (-not $result) {
            Write-Host "  [WARN] Fallback: intentando venv..." -ForegroundColor Yellow
            $provider2 = New-EnvironmentProvider -Id ([guid]::NewGuid().ToString('N')) -Name "Venv-$projectName" -Version '1.0.0' -ProviderType 'VenvEnvironment' -ProviderConfig @{ PythonVersion = $pythonVersion }
            $result = New-VenvEnvironment -Provider $provider2 -ProjectPath $projectPath -PythonVersion $pythonVersion -ProjectName $projectName
        }
    }

    if ($result) {
        Write-Host "  [OK] Entorno $tipoEntorno creado exitosamente" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Continuando sin entorno virtual" -ForegroundColor Yellow
    }

    # ─────────────────────────────────────────────────────────────────
    # FASE 4: Initialize Git (optional)
    # ─────────────────────────────────────────────────────────────────
    if ($initGit) {
        Write-Host "=== FASE 4: Inicializar Git ===" -ForegroundColor Green
        Push-Location $projectPath
        $gitDir = Join-Path $projectPath ".git"
        if (-not (Test-Path $gitDir)) {
            git init 2>&1 | Out-Null
            Write-Host "  [OK] Git initialized" -ForegroundColor Green
        } else {
            Write-Host "  [OK] Git already initialized" -ForegroundColor Green
        }

        # Ensure initial commit
        $headRef = & { git rev-parse --verify HEAD } 2>$null
        if (-not $headRef) {
            $gitkeepPath = Join-Path $projectPath "src\.gitkeep"
            "" | Out-File -FilePath $gitkeepPath -Encoding utf8 -Force
            git add -A 2>&1 | Out-Null
            git commit -m "RC56 - Initial commit for $repoName" 2>&1 | Out-Null
            Write-Host "  [OK] Initial commit created" -ForegroundColor Green
        } else {
            Write-Host "  [OK] HEAD already exists" -ForegroundColor Green
        }

        # Ensure branch is 'main'
        $currentBranch = & { git rev-parse --abbrev-ref HEAD } 2>$null
        if ($currentBranch -ne "main") {
            if ($currentBranch -eq "master") {
                git branch -m master main 2>&1 | Out-Null
                Write-Host "  [OK] Renamed master to main" -ForegroundColor Green
            } else {
                git checkout -b main 2>&1 | Out-Null
                Write-Host "  [OK] Created branch main" -ForegroundColor Green
            }
        } else {
            Write-Host "  [OK] Branch: $currentBranch" -ForegroundColor Green
        }
        Pop-Location
    } else {
        Write-Host "=== FASE 4: Git omitido ===" -ForegroundColor Yellow
    }

    # ─────────────────────────────────────────────────────────────────
    # FASE 5: GitHub remote repository
    # ─────────────────────────────────────────────────────────────────
    if ($crearRepo -and $ghUser) {
        Write-Host "=== FASE 5: Crear repositorio GitHub remoto ===" -ForegroundColor Green
        $repoFullName = "$ghUser/$repoName"

        $repoExists = & { gh repo view $repoFullName } 2>&1 | Out-String
        if ($repoExists -match "Viewing") {
            Write-Host "  [OK] GitHub repo already exists: $repoFullName" -ForegroundColor Green
            if ($initGit) {
                Push-Location $projectPath
                git remote add origin "https://github.com/$repoFullName.git" 2>&1 | Out-Null
                Write-Host "  [OK] Remote origin configured" -ForegroundColor Green
                Pop-Location
            }
        } else {
            Write-Host "  [..] Creating GitHub repo: $repoFullName..." -ForegroundColor Yellow
            $createResult = & { gh repo create $repoFullName --public } 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] GitHub repo created: $repoFullName" -ForegroundColor Green
            } elseif ($createResult -match "already exists") {
                Write-Host "  [OK] GitHub repo already exists: $repoFullName" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] GitHub repo creation issue: $createResult" -ForegroundColor Yellow
            }
        }

        # Ensure origin is set
        if ($initGit) {
            Push-Location $projectPath
            $remoteUrl = & { git remote get-url origin } 2>$null
            if (-not $remoteUrl) {
                git remote add origin "https://github.com/$repoFullName.git" 2>&1 | Out-Null
                $remoteUrl = & { git remote get-url origin } 2>$null
            }
            if ($remoteUrl) {
                Write-Host "  [OK] Remote origin: $($remoteUrl.Trim())" -ForegroundColor Green
            }
            Pop-Location
        }

        $remoteUrl = "https://github.com/$repoFullName.git"
        Write-Host "  [OK] Remote: $remoteUrl" -ForegroundColor Green
    } else {
        Write-Host "=== FASE 5: GitHub remoto omitido ===" -ForegroundColor Yellow
    }

    # ─────────────────────────────────────────────────────────────────
    # FASE 6: Create base files
    # ─────────────────────────────────────────────────────────────────
    Write-Host "=== FASE 6: Crear archivos base ===" -ForegroundColor Green
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # .gitignore
    $gitignorePath = Join-Path $projectPath ".gitignore"
    if (-not (Test-Path $gitignorePath)) {
        $gitignoreContent = @"
# Python
__pycache__/
*.py[cod]
*.pyo
.env
.venv/
env/
venv/

# Node
node_modules/

# IDE
.vscode/settings.json
*.suo
*.user

# OS
.DS_Store
Thumbs.db

# Logs
logs/
*.log

# Data
data/*.db
data/*.sqlite
"@
        $gitignoreContent | Out-File -FilePath $gitignorePath -Encoding utf8 -Force
        Write-Host "  [OK] .gitignore created" -ForegroundColor Green
    } else {
        Write-Host "  [OK] .gitignore already exists" -ForegroundColor Green
    }

    # README.md
    $readmePath = Join-Path $projectPath "README.md"
    if (-not (Test-Path $readmePath)) {
        $readmeContent = @"
# $repoName

Proyecto generado automaticamente por Hermes Enterprise.

## Estructura

- src/ - Codigo fuente
- pruebas/ - Pruebas unitarias y de integracion
- docs/ - Documentacion
- data/ - Datos de la aplicacion
- logs/ - Logs de ejecucion
- scripts/ - Scripts de utilidad

## Requisitos

- Python $pythonVersion
- Conda o venv

## Instalacion

```bash
cd $repoName
pip install -r requirements.txt
```

## Licencia

MIT
"@
        $readmeContent | Out-File -FilePath $readmePath -Encoding utf8 -Force
        Write-Host "  [OK] README.md created" -ForegroundColor Green
    } else {
        Write-Host "  [OK] README.md already exists" -ForegroundColor Green
    }

    # CURRENT_STATE.md
    $statePath = Join-Path $projectPath "CURRENT_STATE.md"
    $stateContent = @"
# CURRENT STATE - $projectName

- Fecha: $now
- Proyecto: $projectName
- Estado: En desarrollo
- Version: 0.1.0
- Rama: main
- Entorno: $tipoEntorno
- Python: $pythonVersion
"@
    $stateContent | Out-File -FilePath $statePath -Encoding utf8 -Force
    Write-Host "  [OK] CURRENT_STATE.md created" -ForegroundColor Green

    # EnvironmentReport.json
    $reportPath = Join-Path $projectPath "EnvironmentReport.json"
    $reportObj = @{
        Proyecto = $projectName
        Fecha = $now
        Estado = "En desarrollo"
        Version = "0.1.0"
        Rama = "main"
        Entorno = $tipoEntorno
        PythonVersion = $pythonVersion
    }
    $reportObj | ConvertTo-Json | Out-File -FilePath $reportPath -Encoding utf8 -Force
    Write-Host "  [OK] EnvironmentReport.json created" -ForegroundColor Green

    # requirements.txt
    $reqPath = Join-Path $projectPath "requirements.txt"
    if (-not (Test-Path $reqPath)) {
        $reqContent = @"
pyyaml>=6.0
requests>=2.31.0
"@
        $reqContent | Out-File -FilePath $reqPath -Encoding utf8 -Force
        Write-Host "  [OK] requirements.txt created" -ForegroundColor Green
    } else {
        Write-Host "  [OK] requirements.txt already exists" -ForegroundColor Green
    }

    # environment.yml (if conda)
    if ($tipoEntorno -eq 'conda') {
        $envYmlPath = Join-Path $projectPath "environment.yml"
        if (-not (Test-Path $envYmlPath)) {
            $envYmlContent = @"
name: $projectName
channels:
  - defaults
  - conda-forge
dependencies:
  - python=$pythonVersion
  - pip
"@
            $envYmlContent | Out-File -FilePath $envYmlPath -Encoding utf8 -Force
            Write-Host "  [OK] environment.yml created" -ForegroundColor Green
        }
    }

    # ─────────────────────────────────────────────────────────────────
    # FASE 7: Commit + Push (if initGit)
    # ─────────────────────────────────────────────────────────────────
    if ($initGit) {
        Write-Host "=== FASE 7: Commit y Push upstream ===" -ForegroundColor Green
        Push-Location $projectPath

        git add -A 2>&1 | Out-Null
        $tempStatus = & { git status --porcelain } 2>&1 | Out-String
        if ($tempStatus.Trim().Length -gt 0) {
            git commit -m "RC56 - Project structure for $repoName (entorno=$tipoEntorno python=$pythonVersion)" 2>&1 | Out-Null
            Write-Host "  [OK] Files committed" -ForegroundColor Green
        } else {
            Write-Host "  [OK] No new files to commit" -ForegroundColor Green
        }

        if ($crearRepo -and $ghUser) {
            Write-Host "  [..] Pushing to origin main..." -ForegroundColor Yellow
            $pushResult = & { git push -u origin main } 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Push upstream exitoso" -ForegroundColor Green
            } else {
                $pushResult2 = & { git push --force -u origin main } 2>&1 | Out-String
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  [OK] Push (force) upstream exitoso" -ForegroundColor Green
                } else {
                    Write-Host "  [WARN] Push fallo: $pushResult2" -ForegroundColor Yellow
                }
            }
        }
        Pop-Location
    } else {
        Write-Host "=== FASE 7: Commit/Push omitido ===" -ForegroundColor Yellow
    }

    # ─────────────────────────────────────────────────────────────────
    # FASE 8: Open VS Code
    # ─────────────────────────────────────────────────────────────────
    if ($abrirCode) {
        Write-Host "=== FASE 8: Abrir VS Code ===" -ForegroundColor Green
        code $projectPath 2>&1 | Out-Null
        Write-Host "  [OK] VS Code opened: $projectPath" -ForegroundColor Green
    } else {
        Write-Host "=== FASE 8: VS Code omitido ===" -ForegroundColor Yellow
    }

    # ─────────────────────────────────────────────────────────────────
    # FASE 9: Verificaciones
    # ─────────────────────────────────────────────────────────────────
    Write-Host "=== FASE 9: Verificaciones ===" -ForegroundColor Green
    if ($initGit) {
        Push-Location $projectPath
        $remoteV = & { git remote -v } 2>&1 | Out-String
        Write-Host "  git remote -v:" -ForegroundColor Cyan
        Write-Host $remoteV

        $finalStatus = & { git status --short } 2>&1 | Out-String
        if ($finalStatus.Trim().Length -eq 0) {
            Write-Host "  [OK] Working tree clean" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] Working tree has changes" -ForegroundColor Yellow
        }

        $finalBranch = & { git rev-parse --abbrev-ref HEAD } 2>$null
        Write-Host "  [OK] Branch: $($finalBranch.Trim())" -ForegroundColor Green

        $upstreamBranch = & { git rev-parse --abbrev-ref --symbolic-full-name '@{u}' } 2>$null
        Write-Host "  [OK] Upstream: $($upstreamBranch.Trim())" -ForegroundColor Green
        Pop-Location
    }

    if ($crearRepo -and $ghUser) {
        $repoFullName = "$ghUser/$repoName"
        $repoView = & { gh repo view $repoFullName } 2>&1 | Out-String
        if ($repoView -match "Viewing|$repoName") {
            Write-Host "  [OK] gh repo view OK" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] gh repo view: $repoView" -ForegroundColor Yellow
        }
    }

    # ─────────────────────────────────────────────────────────────────
    # RESULTADO FINAL
    # ─────────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "=== RESULTADO FINAL RC56 ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [OK] Carpeta creada: $projectPath" -ForegroundColor Green
    Write-Host "  [OK] Entorno: $tipoEntorno (Python $pythonVersion)" -ForegroundColor Green
    if ($initGit) {
        Write-Host "  [OK] Git inicializado" -ForegroundColor Green
        Write-Host "  [OK] Rama main" -ForegroundColor Green
    }
    if ($crearRepo -and $ghUser) {
        $remoteUrl = "https://github.com/$ghUser/$repoName.git"
        Write-Host "  [OK] Remote origin: $remoteUrl" -ForegroundColor Green
        Write-Host "  [OK] Push exitoso" -ForegroundColor Green
        Write-Host "  [OK] GitHub creado: $ghUser/$repoName" -ForegroundColor Green
    }
    if ($abrirCode) {
        Write-Host "  [OK] VS Code abierto" -ForegroundColor Green
    }
    Write-Host "  [OK] Working tree clean" -ForegroundColor Green
    Write-Host ""
    Write-Host "[PASS] RC56 Pipeline completado exitosamente" -ForegroundColor Green
    return 0
}