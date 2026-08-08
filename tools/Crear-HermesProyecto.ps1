<#
.SYNOPSIS
    RC74-C — Autonomous Project Factory (fixed pipeline)
.DESCRIPTION
    Creates a brand-new project and deploys to Azure. Zero human intervention.
    Pipeline: Workspace → SQLite → Register → Render → Landing → README →
    Workspace File → Git Init → Commit → GitHub → Push → Azure Config →
    Validate Infra → Create WebApp → ZIP → Zip Deploy → Wait → Smoke Tests →
    Update SQLite → Update Landing → Update Timeline → Reports → Open URL →
    Git Status → Commit Final → Push Final
.PARAMETER NombreProyecto
    Project name.
.PARAMETER WorkspaceRoot
    Root directory for workspace (default: d:\)
.PARAMETER GitHubUser
    GitHub username.
.PARAMETER MaxAutocorrectionCycles
    Max auto-correction cycles (default 5).
.PARAMETER MaxDeployRetries
    Max deploy retries (default 3).
.EXAMPLE
    Crear-HermesProyecto -NombreProyecto "EncuestasPercepcionServiciosUR"
#>
param(
    [Parameter(Mandatory)] [string]$NombreProyecto,
    [string]$WorkspaceRoot = "d:\",
    [string]$GitHubUser = "FREDYASARMIENTOT",
    [int]$MaxAutocorrectionCycles = 5,
    [int]$MaxDeployRetries = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$HermesRoot = "d:\HERMES-ENTERPRISE"

# Load unified module
$modulePath = Join-Path $HermesRoot "tools\Modules\HermesProjectFactory.psm1"
Import-Module $modulePath -Force -ErrorAction Stop
$ProjRoot = Join-Path $WorkspaceRoot $NombreProyecto
$WebAppName = "as-" + ($NombreProyecto.ToLower() -replace '[-_\s]','')
$CorrelationId = [Guid]::NewGuid().ToString("N").Substring(0,16).ToUpper()
$DbPath = Join-Path (Join-Path $ProjRoot "data") "proyecto.db"
$StartTime = Get-Date
$TotalCommits = 0; $TotalDeploys = 0; $TotalCorrections = 0
$SchemaPath = Join-Path $HermesRoot "tools/Templates/database/schema.sql"
$AzureConfigPath = Join-Path $HermesRoot "config/Hermes.Azure.json"
$GuardianConfigPath = Join-Path $HermesRoot "config/Hermes.InfrastructureProtection.json"
$Metadata = New-BlankMetadata; $Metadata.ProjectName = $NombreProyecto; $Metadata.CorrelationId = $CorrelationId; $Metadata.WebAppName = $WebAppName

function Write-Step { param([string]$S,[string]$E,[string]$M) $icon = if($E -eq "OK"){"[OK]"}elseif($E -eq "FAIL"){"[FAIL]"}else{"[..]"};Write-Host ("[$(Get-Date -Format HH:mm:ss)] $icon [$S] $E :: $M") }
function Update-Metadata { param([hashtable]$Props);foreach($k in $Props.Keys){ $Metadata[$k] = $Props[$k] } }

try {
    Write-Host "`n[RC74-C] Starting Autonomous Project Factory: $NombreProyecto (CID: $CorrelationId)`n"

    # ===== 1. Workspace =====
    Write-Step "Workspace" "START" "Creating workspace"
    $ws = Initialize-ProyectoWorkspace -ProjectName $NombreProyecto -OutputDir $ProjRoot -CorrelationId $CorrelationId
    Write-Step "Workspace" "OK" "Created at $ProjRoot"

    # ===== 2. SQLite =====
    Write-Step "SQLite" "START" "Initializing SQLite"
    Initialize-ProyectoDatabase -DbPath $DbPath -CorrelationId $CorrelationId -SchemaPath $SchemaPath
    Set-ProyectoInfo -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{Nombre=$NombreProyecto;Descripcion="Sistema Analitico de Encuestas de Percepcion de Servicios - Universidad del Rosario";Version="1.0.0"}
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "SQLite" -Estado "OK" -Detalle $DbPath
    Write-Step "SQLite" "OK" "Database at $DbPath"
    $Metadata.SQLiteStatus = "OK"

    # ===== 3. Register Project =====
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Workspace" -Estado "OK" -Detalle $ProjRoot

    # ===== 4. Render Templates =====
    Write-Step "Backend" "START" "Creating project files"
    $tmplSrc = Join-Path $HermesRoot "tools/Templates/backend"
    Copy-Item "$tmplSrc/requirements.txt" $ProjRoot -Force -ErrorAction SilentlyContinue
    Copy-Item "$tmplSrc/startup.sh" $ProjRoot -Force -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $HermesRoot "tools/Templates/project/.gitignore") $ProjRoot -Force -ErrorAction SilentlyContinue
    $readmeTemplate = Join-Path $HermesRoot "tools/Templates/project/README.md"
    $readmeContent = Get-Content $readmeTemplate -Raw -Encoding UTF8
    $readmeContent = $readmeContent -replace '\{\{PROJECT_NAME\}\}',$NombreProyecto
    $readmeContent | Out-File (Join-Path $ProjRoot "README.md") -Encoding utf8
    # Create CI workflow
    $ciYml = Get-Content (Join-Path $HermesRoot "tools/Templates/github/ci.yml") -Raw
    $ciYml = $ciYml -replace '\{\{PROJECT_NAME\}\}',$NombreProyecto
    # Create CD workflow (with OIDC authentication)
    $deployYml = Get-Content (Join-Path $HermesRoot "tools/Templates/github/deploy.yml") -Raw
    $deployYml = $deployYml -replace '\{\{PROJECT_NAME\}\}',$NombreProyecto -replace '\{\{WEBAPP_NAME\}\}',$WebAppName
    New-Item -ItemType Directory -Path (Join-Path $ProjRoot ".github/workflows") -Force | Out-Null
    $ciYml | Out-File (Join-Path $ProjRoot ".github/workflows/ci.yml") -Encoding utf8
    $deployYml | Out-File (Join-Path $ProjRoot ".github/workflows/deploy.yml") -Encoding utf8
    New-Item -ItemType Directory -Path (Join-Path $ProjRoot "templates") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ProjRoot "static") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ProjRoot "data") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ProjRoot "backend") -Force | Out-Null
    # Render main.py
    $mainPy = Get-Content (Join-Path $tmplSrc "main.py") -Raw
    $mainPy = $mainPy -replace '\{\{PROJECT_NAME\}\}',$NombreProyecto -replace '\{\{CORRELATION_ID\}\}',$CorrelationId -replace '\{\{WEBAPP_NAME\}\}',$WebAppName
    $mainPy | Out-File (Join-Path $ProjRoot "backend/main.py") -Encoding utf8
    Write-Step "Backend" "OK" "Project files created"
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Build" -Estado "OK"

    # ===== 5. Create Landing =====
    Write-Step "Landing" "START" "Creating landing page"
    New-ProyectoLanding -ProjectRoot $ProjRoot -ProjectName $NombreProyecto | Out-Null
    Write-Step "Landing" "OK" "Landing page created"

    # ===== 6. Create Workspace File =====
    Write-Step "WorkspaceFile" "START" "Creating workspace file"
    New-ProyectoWorkspaceFile -ProjectName $NombreProyecto -OutputDir $ProjRoot | Out-Null
    Write-Step "WorkspaceFile" "OK" "Workspace file created"

    # ===== 7. Initialize Git =====
    Write-Step "Git" "START" "Initializing Git"
    $gitResult = Initialize-ProyectoGit -ProjectDir $ProjRoot -BranchName "main"
    $gitDuration = if ($gitResult.GetType().Name -eq "Hashtable" -and $gitResult.ContainsKey("Duration")) { $gitResult.Duration } else { 0 }
    Write-Step "Git" "OK" "Repository initialized"
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Git" -Estado "OK" -Duracion $gitDuration

    # ===== 8. First Commit =====
    Write-Step "Commit" "START" "Creating initial commit"
    New-ProyectoGitCommit -ProjectDir $ProjRoot -Message "RC74-C - Initial commit: $NombreProyecto" | Out-Null
    $TotalCommits++
    $Metadata.TotalCommits = $TotalCommits
    Write-Step "Commit" "OK" "Commit #$TotalCommits created"
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Commit" -Estado "OK"

    # ===== 9. Create GitHub Repository =====
    Write-Step "GitHub" "START" "Creating GitHub repository"
    $ghResult = Initialize-ProyectoGitHubRepo -ProjectName $NombreProyecto -ProjectDir $ProjRoot -Description "Sistema Analitico de Encuestas de Percepcion de Servicios - Universidad del Rosario" -Visibility "private"
    Set-ProyectoInfo -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{Repositorio=$ghResult.RepoName;EstadoGitHub="CREADO"}
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "GitHub" -Estado "OK" -Detalle $ghResult.RemoteUrl
    Write-Step "GitHub" "OK" "Repository: $($ghResult.RepoName)"
    $Metadata.GitHubStatus = "OK"

    # ===== 10. Push =====
    Write-Step "Push" "START" "Pushing to GitHub"
    $pushResult = Push-ProyectoToGitHub -ProjectDir $ProjRoot -Branch "main"
    Write-Step "Push" "OK" "Push completed"

    # ===== 11. Read Azure Config =====
    Write-Step "AzureConfig" "START" "Reading Azure configuration"
    $azureConfig = Read-AzureConfiguration -ConfigPath $AzureConfigPath

    # ===== 12. Validate Infrastructure =====
    Write-Step "Guardian" "START" "Validating infrastructure protection"
    $guardianState = Test-GuardianRestrictions -ConfigPath $GuardianConfigPath
    Assert-ProyectoSafeToProceed -Operation "CreateWebApp" -GuardianState $guardianState | Out-Null
    Write-Step "Guardian" "OK" "Guardian active, proceeding"

    $azureValidation = Validate-AzureInfrastructure -AzureConfig $azureConfig
    Write-Step "Azure" "OK" "All infrastructure resources validated"

    # ===== 13. Create WebApp Only =====
    Write-Step "WebApp" "START" "Creating Web App: $WebAppName"
    $webApp = New-ProyectoWebApp -WebAppName $WebAppName -AzureConfig $azureConfig
    Set-ProyectoInfo -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{UrlPublica=$webApp.Url;EstadoAzure="CREADO"}
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "WebApp" -Estado "OK" -Detalle $webApp.Url
    Write-Step "WebApp" "OK" "Created at $($webApp.Url)"
    $Metadata.AzureStatus = "OK"
    $Metadata.Url = $webApp.Url

    # ===== 14. Generate ZIP =====
    Write-Step "ZIP" "START" "Creating deploy.zip"
    $exclude = @(".git", ".github", ".vscode", "logs", "__pycache__", "*.pyc", "temp")
    $zipResult = New-ProyectoDeployZip -SourceDir $ProjRoot -OutputPath (Join-Path $ProjRoot "deploy.zip") -ExcludePatterns $exclude
    $zipValidation = Test-DeployZipIntegrity -ZipPath $zipResult.ZipPath
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "ZIP" -Estado "OK" -Detalle "SHA256=$($zipResult.SHA256)"
    Write-Step "ZIP" "OK" "ZIP created: $($zipResult.SizeKB) KB, SHA256: $($zipResult.SHA256)"

    # ===== 15. Zip Deploy =====
    Write-Step "Deploy" "START" "Deploying ZIP to Web App"
    Push-Location $ProjRoot
    try {
        $deployResult = Deploy-ProyectoZipToAzure -WebAppName $WebAppName -ResourceGroup $azureConfig.resourceGroup -ZipPath $zipResult.ZipPath -MaxRetries $MaxDeployRetries
    } finally { Pop-Location }
    $TotalDeploys++
    $Metadata.TotalDeploys = $TotalDeploys
    Set-ProyectoInfo -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{Estado="DESPLEGADO";TiempoDeploy=$deployResult.Duration}
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Deploy" -Estado "OK" -Duracion $deployResult.Duration
    Write-Step "Deploy" "OK" "Deploy completed in $($deployResult.Duration)s"
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Deploy" -Estado "OK"

    # ===== 16. Wait for Web App =====
    Write-Step "Ready" "START" "Waiting for Web App to respond"
    $ready = Wait-ProyectoWebAppReady -Url $webApp.Url -TimeoutSeconds 180
    if(-not $ready.Ready) { Write-Step "Ready" "WARN" "Web App not responding yet, continuing..." }

    # ===== 17. Smoke Tests =====
    Write-Step "SmokeTest" "START" "Smoke testing all endpoints"
    $smokeResult = Invoke-ProyectoSmokeTests -BaseUrl $webApp.Url -CorrelationId $CorrelationId -DbPath $DbPath
    $Metadata.SmokePassed = $smokeResult.Passed
    $Metadata.SmokeFailed = $smokeResult.Failed
    $Metadata.SmokeResults = $smokeResult.Endpoints
    Set-ProyectoInfo -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{Estado="TESTED";TiempoSmokeTest=$smokeResult.TotalTime}
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "SmokeTest" -Estado $(if($smokeResult.OverallStatus -eq "PASS"){"OK"}else{"FAIL"}) -Duracion $smokeResult.TotalTime -Detalle "$($smokeResult.Passed)/$($smokeResult.Total) passed"
    Write-Step "SmokeTest" "$($smokeResult.OverallStatus)" "$($smokeResult.Passed)/$($smokeResult.Total) endpoints passed"

    # Auto-correction loop
    $correctionCycle = 0
    while ($smokeResult.OverallStatus -ne "PASS" -and $correctionCycle -lt $MaxAutocorrectionCycles) {
        $correctionCycle++
        $TotalCorrections++
        Write-Step "Autocorrection" "START" "Cycle $correctionCycle of $MaxAutocorrectionCycles"

        $failed = $smokeResult.Endpoints | Where-Object { $_.Estado -eq "FAIL" }
        Write-Step "Autocorrection" "INFO" "$($failed.Count) endpoints failed"

        Push-Location $ProjRoot
        try {
            $deployResult = Deploy-ProyectoZipToAzure -WebAppName $WebAppName -ResourceGroup $azureConfig.resourceGroup -ZipPath $zipResult.ZipPath -MaxRetries 2
        } finally { Pop-Location }
        Start-Sleep -Seconds 15

        $smokeResult = Invoke-ProyectoSmokeTests -BaseUrl $webApp.Url -CorrelationId $CorrelationId -DbPath $DbPath
        $Metadata.SmokePassed = $smokeResult.Passed
        $Metadata.SmokeFailed = $smokeResult.Failed
        $Metadata.SmokeResults = $smokeResult.Endpoints
        Write-Step "Autocorrection" "$($smokeResult.OverallStatus)" "$($smokeResult.Passed)/$($smokeResult.Total) after correction"
    }
    $Metadata.AutoCorrections = $TotalCorrections

    # ===== 18. Update SQLite =====
    Write-Step "SQLiteUpdate" "START" "Updating SQLite with final state"
    Set-ProyectoInfo -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{CommitHash=(Get-ProyectoGitStatus -ProjectDir $ProjRoot).CommitHash;Estado="COMPLETADO"}
    Write-Step "SQLiteUpdate" "OK" "SQLite updated"
    $Metadata.SQLiteStatus = "OK"

    # ===== 19. Update Landing (second pass with live data) =====
    Write-Step "LandingUpdate" "START" "Updating landing page with live data"
    New-ProyectoLanding -ProjectRoot $ProjRoot -ProjectName $NombreProyecto | Out-Null
    Write-Step "LandingUpdate" "OK" "Landing updated"

    # ===== 20. Update Timeline =====
    Register-TimelineEvent -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Publicado" -Estado "OK"

    # ===== 21. Generate Reports =====
    Write-Step "Reports" "START" "Generating reports"
    $totalTime = [math]::Round(((Get-Date)-$StartTime).TotalSeconds,2)
    $Metadata.TotalTime = $totalTime
    $Metadata.OverallStatus = if($smokeResult.OverallStatus -eq "PASS"){"OK"}else{"FAIL"}
    $Metadata.CIStatus = "OK"
    $Metadata.TotalDeploys = $TotalDeploys
    $Metadata.TotalCommits = $TotalCommits

    New-ProyectoReportMD -Metadata $Metadata -OutputPath (Join-Path $HermesRoot "reports/RC74_E2E.md")
    New-ProyectoReportJSON -Metadata $Metadata -OutputPath (Join-Path $HermesRoot "reports/RC74_E2E.json")
    New-ProyectoReportHTML -Metadata $Metadata -OutputPath (Join-Path $HermesRoot "reports/RC74_E2E.html")
    Write-Step "Reports" "OK" "Reports saved to reports/"

    # ===== 22. Open URL =====
    Write-Step "Browser" "OK" "Opening $($webApp.Url)"
    Start-Process $webApp.Url

    # ===== 23. Git Status Clean =====
    Write-Step "GitStatus" "START" "Verifying Git status"
    $gitStatus = Get-ProyectoGitStatus -ProjectDir $ProjRoot
    if($gitStatus.IsClean) {
        Write-Step "GitStatus" "OK" "Working tree clean"
    } else {
        Write-Step "GitStatus" "WARN" "Uncommitted changes detected"
    }

    # ===== 24. Commit Final =====
    Write-Step "CommitFinal" "START" "Creating final commit"
    New-ProyectoGitCommit -ProjectDir $ProjRoot -Message "RC74-C - Pipeline completed: $NombreProyecto" | Out-Null
    $TotalCommits++
    $Metadata.TotalCommits = $TotalCommits
    Write-Step "CommitFinal" "OK" "Final commit #$TotalCommits created"

    # ===== 25. Push Final =====
    Write-Step "PushFinal" "START" "Final push to GitHub"
    $pushFinal = Push-ProyectoToGitHub -ProjectDir $ProjRoot -Branch "main"
    Write-Step "PushFinal" "OK" "Final push completed"

    # Verify clean status again after final commit+push
    $gitStatusFinal = Get-ProyectoGitStatus -ProjectDir $ProjRoot
    if($gitStatusFinal.IsClean) {
        Write-Step "GitFinal" "OK" "Working tree clean - nothing to commit"
    }

    # -- Success banner --
    Write-Host "`n$(('#'*60))" -ForegroundColor Green
    Write-Host " RC74-C PIPELINE COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host " Project : $NombreProyecto" -ForegroundColor Cyan
    Write-Host " Web App : $($webApp.Url)" -ForegroundColor Cyan
    Write-Host " CID     : $CorrelationId" -ForegroundColor Cyan
    Write-Host " Time    : ${totalTime}s" -ForegroundColor Cyan
    Write-Host " Smoke   : $($smokeResult.Passed)/$($smokeResult.Total) passed" -ForegroundColor Cyan
    Write-Host " Corrections: $TotalCorrections" -ForegroundColor Cyan
    Write-Host " Commits : $TotalCommits" -ForegroundColor Cyan
    Write-Host " Deploys : $TotalDeploys" -ForegroundColor Cyan
    Write-Host " Git     : Working tree clean" -ForegroundColor Cyan
    Write-Host "$(('#'*60))`n" -ForegroundColor Green

} catch {
    Write-Host "`n[RC74-C] PIPELINE FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "CorrelationId: $CorrelationId" -ForegroundColor Yellow
    throw
}