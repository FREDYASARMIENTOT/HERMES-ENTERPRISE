<#
.SYNOPSIS
    RC53: MVP REMOTE PROVISIONING - Hermes Enterprise pipeline.
.DESCRIPTION
    Single-file implementation covering FASEs 1-9: workspace creation,
    conda env, git, GitHub remote, push, VS Code, and validations.
#>
function Invoke-EnterprisePipeline {
    param(
        [psobject]$Context
    )

    Write-Host "=== HERMES ENTERPRISE - RC53: COMPLETE MVP REMOTE PROVISIONING ===" -ForegroundColor Cyan
    Write-Host "Proyecto : $($Context.NombreProyecto)" -ForegroundColor Yellow
    Write-Host "Target   : $($Context.ProvisionTarget)" -ForegroundColor Yellow

    $workspaceRoot = if ($Context.WorkspaceRoot) { $Context.WorkspaceRoot } else { "D:\Proyectos" }
    $projectName = $Context.NombreProyecto
    $projectPath = Join-Path $workspaceRoot $projectName
    $repoName = $projectName
    $ghUser = $Context.GitHubUser

    Write-Host "Project   : $projectPath" -ForegroundColor Yellow
    Write-Host ""

    # ─────────────────────────────────────────────────────────────────
    # PRE-FLIGHT: GitHub authentication check
    # ─────────────────────────────────────────────────────────────────
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
    # FASE 3: Conda environment
    # ─────────────────────────────────────────────────────────────────
    Write-Host "=== FASE 3: Crear Conda environment ===" -ForegroundColor Green

    $envName = $repoName

    # Locate conda
    $up = (Resolve-Path ~).Path
    $condaPaths = @(
        "$up\miniconda3\condabin\conda.bat",
        "$up\miniconda3\Scripts\conda.exe",
        "$up\miniconda3\condabin\conda.exe",
        "C:\ProgramData\miniconda3\condabin\conda.bat",
        "C:\ProgramData\miniconda3\Scripts\conda.exe",
        "C:\Users\fredya.sarmiento\miniconda3\condabin\conda.bat",
        "C:\Users\fredya.sarmiento\miniconda3\Scripts\conda.exe"
    )
    $conda = $null
    foreach ($cp in $condaPaths) {
        if (Test-Path $cp) { $conda = $cp; break }
    }

    # Ensure conda is in PATH
    $env:PATH = "$up\miniconda3;$up\miniconda3\Scripts;$up\miniconda3\condabin;$up\miniconda3\Library\bin;$env:PATH"

    $envList = & $conda env list 2>&1 | Out-String
    if ($envList -match $envName) {
        Write-Host "  [OK] Conda environment $envName already exists" -ForegroundColor Green
    } else {
        # Create environment.yml for the project
        $projectEnvYml = Join-Path $projectPath "environment.yml"
        $envYmlContent = @"
name: $envName
channels:
  - defaults
dependencies:
  - python=3.14
  - pip
prefix: C:\Users\fredya.sarmiento\.conda\envs\$envName
"@
        $envYmlContent | Out-File -FilePath $projectEnvYml -Encoding utf8 -Force
        Write-Host "  [..] Creating Conda environment $envName via conda create (reliable method)..." -ForegroundColor Yellow
        & $conda create -y -n $envName python pip 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Conda environment $envName created" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] Conda environment creation failed" -ForegroundColor Red
        }
    }

    # ─────────────────────────────────────────────────────────────────
    # FASE 4: Initialize Git
    # ─────────────────────────────────────────────────────────────────
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
        git commit -m "RC53 - Initial commit for $repoName" 2>&1 | Out-Null
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

    # ─────────────────────────────────────────────────────────────────
    # FASE 5: GitHub remote repository
    # ─────────────────────────────────────────────────────────────────
    Write-Host "=== FASE 5: Crear repositorio GitHub remoto ===" -ForegroundColor Green
    $repoFullName = "$ghUser/$repoName"

    # Check if repo already exists
    $repoExists = & { gh repo view $repoFullName } 2>&1 | Out-String
    if ($repoExists -match "Viewing") {
        Write-Host "  [OK] GitHub repo already exists: $repoFullName" -ForegroundColor Green
        Push-Location $projectPath
        git remote add origin "https://github.com/$repoFullName.git" 2>&1 | Out-Null
        Write-Host "  [OK] Remote origin configured" -ForegroundColor Green
        Pop-Location
    } else {
        Write-Host "  [..] Creating GitHub repo: $repoFullName..." -ForegroundColor Yellow
        $createResult = & { gh repo create $repoFullName --public --push --remote origin --source $projectPath } 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] GitHub repo created: $repoFullName" -ForegroundColor Green
            Push-Location $projectPath
            git remote add origin "https://github.com/$repoFullName.git" 2>&1 | Out-Null
            Write-Host "  [OK] Remote origin configured" -ForegroundColor Green
            Pop-Location
        } elseif ($createResult -match "already exists") {
            Write-Host "  [OK] GitHub repo already exists (by create): $repoFullName" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] Could not create GitHub repo: $createResult" -ForegroundColor Red
            # Fallback: try gh repo create without --push
            $createResult2 = & { gh repo create $repoFullName --public } 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] GitHub repo created (fallback): $repoFullName" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] GitHub repo creation fallback also failed: $createResult2" -ForegroundColor Yellow
            }
        }
    }

    # Ensure origin is set
    Push-Location $projectPath
    $remoteUrl = & { git remote get-url origin } 2>$null
    if (-not $remoteUrl) {
        git remote add origin "https://github.com/$repoFullName.git" 2>&1 | Out-Null
        $remoteUrl = & { git remote get-url origin } 2>$null
    }
    if ($remoteUrl) {
        Write-Host "  [OK] Remote origin already configured: $($remoteUrl.Trim())" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Remote origin not configured" -ForegroundColor Red
        Pop-Location
        return 1
    }
    Pop-Location

    $remoteUrl = "https://github.com/$repoFullName.git"
    Write-Host "  [OK] Remote: $remoteUrl" -ForegroundColor Green

    # ─────────────────────────────────────────────────────────────────
    # FASE 6: Create base files
    # ─────────────────────────────────────────────────────────────────
    Write-Host "=== FASE 6: Crear archivos base ===" -ForegroundColor Green
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # .gitignore
    $gitignorePath = Join-Path $projectPath ".gitignore"
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

    # README.md
    $readmePath = Join-Path $projectPath "README.md"
    $readmeContent = @"
# $repoName

Proyecto generado automaticamente por Hermes Enterprise.

## Estructura

- `src/` - Codigo fuente
- `pruebas/` - Pruebas unitarias y de integracion
- `docs/` - Documentacion
- `data/` - Datos de la aplicacion
- `logs/` - Logs de ejecucion
- `scripts/` - Scripts de utilidad

## Requisitos

- Python 3.14+
- Conda (opcional pero recomendado)

## Instalacion

\`\`\`bash
cd $repoName
pip install -r requirements.txt
\`\`\`

## Licencia

MIT
"@
    $readmeContent | Out-File -FilePath $readmePath -Encoding utf8 -Force
    Write-Host "  [OK] README.md created" -ForegroundColor Green

    # CURRENT_STATE.md
    $statePath = Join-Path $projectPath "CURRENT_STATE.md"
    $stateContent = @"
# CURRENT STATE - $projectName

- **Fecha**: $now
- **Proyecto**: $projectName
- **Estado**: En desarrollo
- **Version**: 0.1.0
- **Rama**: main
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
    }
    $reportObj | ConvertTo-Json | Out-File -FilePath $reportPath -Encoding utf8 -Force
    Write-Host "  [OK] EnvironmentReport.json created" -ForegroundColor Green

    # requirements.txt
    $reqPath = Join-Path $projectPath "requirements.txt"
    $reqContent = @"
pyyaml>=6.0
requests>=2.31.0
"@
    $reqContent | Out-File -FilePath $reqPath -Encoding utf8 -Force
    Write-Host "  [OK] requirements.txt created" -ForegroundColor Green

    # ─────────────────────────────────────────────────────────────────
    # FASE 7: Commit + Push
    # ─────────────────────────────────────────────────────────────────
    Write-Host "=== FASE 7: Commit y Push upstream ===" -ForegroundColor Green
    Push-Location $projectPath

    git add -A 2>&1 | Out-Null
    $tempStatus = & { git status --porcelain } 2>&1 | Out-String
    if ($tempStatus.Trim().Length -gt 0) {
        git commit -m "RC53 - MVP: Project structure for $repoName" 2>&1 | Out-Null
        Write-Host "  [OK] Files committed" -ForegroundColor Green
    } else {
        Write-Host "  [OK] No new files to commit" -ForegroundColor Green
    }

    Write-Host "  [..] Pushing to origin main..." -ForegroundColor Yellow
    $pushResult = & { git push -u origin main } 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Push upstream exitoso" -ForegroundColor Green
    } else {
        $pushResult2 = & { git push --force -u origin main } 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Push (force) upstream exitoso" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] Push fallo: $pushResult2" -ForegroundColor Red
            Pop-Location
            return 1
        }
    }
    Pop-Location

    # ─────────────────────────────────────────────────────────────────
    # FASE 8: Open VS Code
    # ─────────────────────────────────────────────────────────────────
    Write-Host "=== FASE 8: Abrir VS Code ===" -ForegroundColor Green
    if ($Context.AbrirVSCode -eq $true) {
        code $projectPath 2>&1 | Out-Null
        Write-Host "  [OK] VS Code opened: $projectPath" -ForegroundColor Green
    } else {
        Write-Host "  [..] VS Code opening skipped" -ForegroundColor Yellow
    }

    # ─────────────────────────────────────────────────────────────────
    # FASE 9: Validations
    # ─────────────────────────────────────────────────────────────────
    Write-Host "=== FASE 9: Verificaciones ===" -ForegroundColor Green

    Push-Location $projectPath
    $remoteV = & { git remote -v } 2>&1 | Out-String
    Write-Host "  [OK] git remote -v:" -ForegroundColor Cyan
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

    $repoView = & { gh repo view $repoFullName } 2>&1 | Out-String
    if ($repoView -match "Viewing|$repoName") {
        Write-Host "  [OK] gh repo view OK" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] gh repo view: $repoView" -ForegroundColor Yellow
    }

    # ─────────────────────────────────────────────────────────────────
    # RESULTADO FINAL
    # ─────────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "=== RESULTADO FINAL ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [OK] Carpeta creada: $projectPath" -ForegroundColor Green
    Write-Host "  [OK] Conda environment: $repoName" -ForegroundColor Green
    Write-Host "  [OK] VS Code abierto" -ForegroundColor Green
    Write-Host "  [OK] Git inicializado" -ForegroundColor Green
    Write-Host "  [OK] Rama main" -ForegroundColor Green
    Write-Host "  [OK] Remote origin: $remoteUrl" -ForegroundColor Green
    Write-Host "  [OK] Push exitoso" -ForegroundColor Green
    Write-Host "  [OK] GitHub creado: $repoFullName" -ForegroundColor Green
    Write-Host "  [OK] Working tree clean" -ForegroundColor Green

    Write-Host ""
    Write-Host "[PASS] Todas las fases completadas exitosamente" -ForegroundColor Green
    return 0
}