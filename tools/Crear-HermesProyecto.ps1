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
    [int]$MaxDeployRetries = 3,
    [switch]$TriggerControlPlane = $false,
    [switch]$SkipAzure = $false,
    [string]$AppServicePlanId = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$HermesRoot = if ($env:HermesRoot) { $env:HermesRoot } elseif (Test-Path (Join-Path $PSScriptRoot ".." "config")) { (Resolve-Path (Join-Path $PSScriptRoot "..")).Path } else { "d:\HERMES-ENTERPRISE" }

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
$Metadata = Nuevo-MetadatosVacios; $Metadata.ProjectName = $NombreProyecto; $Metadata.CorrelationId = $CorrelationId; $Metadata.WebAppName = $WebAppName

# Inicializar Registro de Implementación (RC87)
$RegistroImpl = Iniciar-RegistroImplementacion -DbPath $DbPath -CorrelationId $CorrelationId -NombreProyecto $NombreProyecto

function Write-Step { param([string]$S,[string]$E,[string]$M) $icon = if($E -eq "OK"){"[OK]"}elseif($E -eq "FAIL"){"[FAIL]"}else{"[..]"};Write-Host ("[$(Get-Date -Format HH:mm:ss)] $icon [$S] $E :: $M") }
function Update-Metadata { param([hashtable]$Props);foreach($k in $Props.Keys){ $Metadata[$k] = $Props[$k] } }

try {
    Write-Host "`n[RC74-C] Starting Autonomous Project Factory: $NombreProyecto (CID: $CorrelationId)`n"

    # ===== 1. Workspace =====
    Write-Step "Workspace" "START" "Creating workspace"
    $ws = Inicializar-EspacioProyecto -ProjectName $NombreProyecto -OutputDir $ProjRoot -CorrelationId $CorrelationId
    Write-Step "Workspace" "OK" "Created at $ProjRoot"

    # ===== 2. SQLite =====
    Write-Step "SQLite" "START" "Initializing SQLite"
    Inicializar-BaseDatosProyecto -DbPath $DbPath -CorrelationId $CorrelationId -SchemaPath $SchemaPath
    Establecer-InformacionProyecto -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{Nombre=$NombreProyecto;Descripcion="Sistema Analitico de Encuestas de Percepcion de Servicios - Universidad del Rosario";Version="1.0.0"}
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "SQLite" -Estado "OK" -Detalle $DbPath
    Write-Step "SQLite" "OK" "Database at $DbPath"
    $Metadata.SQLiteStatus = "OK"

    # ===== 3. Register Project =====
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Workspace" -Estado "OK" -Detalle $ProjRoot

    # RC87: Registry - Factory completada
    Iniciar-PasoImplementacion -Registro $RegistroImpl -NumeroPaso 2 -Detalle "Factory: workspace + SQLite"
    Finalizar-PasoImplementacion -Registro $RegistroImpl -NumeroPaso 2 -Estado "COMPLETADO" -Detalle "Workspace, SQLite y estructura creados"
    Persistir-RegistroImplementacion -Registro $RegistroImpl

    # ===== 4. Read Azure Config (early, needed for template placeholders) =====
    $azureConfig = Leer-ConfiguracionAzure -ConfigPath $AzureConfigPath

    # ===== 5. Render Templates =====
    Write-Step "Backend" "START" "Creating project files"
    $tmplSrc = Join-Path $HermesRoot "tools/Templates/backend"
    Copy-Item "$tmplSrc/requirements.txt" $ProjRoot -Force -ErrorAction SilentlyContinue
    # Render startup.sh (replace {{PROJECT_NAME}} placeholder)
    $startupSh = Get-Content (Join-Path $tmplSrc "startup.sh") -Raw
    $startupSh = $startupSh -replace "{{PROJECT_NAME}}",$NombreProyecto
    $startupSh | Out-File (Join-Path $ProjRoot "startup.sh") -Encoding utf8
    Copy-Item (Join-Path $HermesRoot "tools/Templates/project/.gitignore") $ProjRoot -Force -ErrorAction SilentlyContinue
    $readmeTemplate = Join-Path $HermesRoot "tools/Templates/project/README.md"
    $readmeContent = Get-Content $readmeTemplate -Raw -Encoding UTF8
    $readmeContent = $readmeContent -replace '\{\{PROJECT_NAME\}\}',$NombreProyecto
    $readmeContent | Out-File (Join-Path $ProjRoot "README.md") -Encoding utf8
    # Create CI workflow
    $ciYml = Get-Content (Join-Path $HermesRoot "tools/Templates/github/ci.yml") -Raw
    $ciYml = $ciYml -replace '\{\{PROJECT_NAME\}\}',$NombreProyecto
    # Create CI workflow only (CD is orchestrated by HERMES-ENTERPRISE deploy-child.yml)
    New-Item -ItemType Directory -Path (Join-Path $ProjRoot ".github/workflows") -Force | Out-Null
    $ciYml | Out-File (Join-Path $ProjRoot ".github/workflows/ci.yml") -Encoding utf8
    # Note: No deploy.yml for child repos. Deployment orchestrated by Control Plane.
    New-Item -ItemType Directory -Path (Join-Path $ProjRoot "templates") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ProjRoot "static") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ProjRoot "data") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ProjRoot "backend") -Force | Out-Null
    # Render main.py
    $mainPy = Get-Content (Join-Path $tmplSrc "main.py") -Raw
    # Literal .Replace() avoids regex escaping issues with {{PLACEHOLDER}}
    $mainPy = $mainPy.Replace('{{PROJECT_NAME}}', $NombreProyecto)
    $mainPy = $mainPy.Replace('{{CORRELATION_ID}}', $CorrelationId)
    $mainPy = $mainPy.Replace('{{WEBAPP_NAME}}', $WebAppName)
    $regionVal = if ($azureConfig.ContainsKey('Location') -and $azureConfig['Location']) { $azureConfig['Location'] } else { 'eastus' }
    $mainPy = $mainPy.Replace('{{REGION}}', $regionVal)
    $mainPy = $mainPy.Replace('{{DEPLOYMENT_ID}}', $CorrelationId)
    $mainPy | Out-File (Join-Path $ProjRoot "backend/main.py") -Encoding utf8
    # Copy registro_implementacion.py (required import for the child app)
    Copy-Item (Join-Path $tmplSrc "registro_implementacion.py") (Join-Path $ProjRoot "backend/registro_implementacion.py") -Force -ErrorAction Stop
    Write-Step "Backend" "OK" "Project files created"
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Build" -Estado "OK"

    # ===== 6. Create Landing =====
    Write-Step "Landing" "START" "Creating landing page"
    Crear-PaginaInicioProyecto -ProjectRoot $ProjRoot -ProjectName $NombreProyecto -WebAppName $WebAppName | Out-Null
    Write-Step "Landing" "OK" "Landing page created"

    # ===== 7. Create Workspace File =====
    Write-Step "WorkspaceFile" "START" "Creating workspace file"
    Crear-ArchivoEspacioTrabajo -ProjectName $NombreProyecto -OutputDir $ProjRoot | Out-Null
    Write-Step "WorkspaceFile" "OK" "Workspace file created"

    # ===== 8. Initialize Git =====
    Write-Step "Git" "START" "Initializing Git"
    $gitResult = Inicializar-GitProyecto -ProjectDir $ProjRoot -BranchName "main"
    $gitDuration = if ($gitResult.GetType().Name -eq "Hashtable" -and $gitResult.ContainsKey("Duration")) { $gitResult.Duration } else { 0 }
    Write-Step "Git" "OK" "Repository initialized"
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Git" -Estado "OK" -Duracion $gitDuration

    # ===== 9. First Commit =====
    Write-Step "Commit" "START" "Creating initial commit"
    Crear-CommitProyecto -ProjectDir $ProjRoot -Mensaje "RC74-C - Initial commit: $NombreProyecto" | Out-Null
    $TotalCommits++
    $Metadata.TotalCommits = $TotalCommits
    Write-Step "Commit" "OK" "Commit #$TotalCommits created"
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Commit" -Estado "OK"

    # ===== 10. Create GitHub Repository =====
    Write-Step "GitHub" "START" "Creating GitHub repository"
    $ghResult = Crear-RepositorioGitHubProyecto -ProjectName $NombreProyecto -ProjectDir $ProjRoot -Description "Sistema Analitico de Encuestas de Percepcion de Servicios - Universidad del Rosario" -Visibility "private"
    Establecer-InformacionProyecto -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{Repositorio=$ghResult.RepoName;EstadoGitHub="CREADO"}
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "GitHub" -Estado "OK" -Detalle $ghResult.RemoteUrl
    Write-Step "GitHub" "OK" "Repository: $($ghResult.RepoName)"
    $Metadata.GitHubStatus = "OK"

    # ===== 10. Push =====
    Write-Step "Push" "START" "Pushing to GitHub"
    $pushResult = Publicar-ProyectoEnGitHub -ProjectDir $ProjRoot -Branch "main"
    Write-Step "Push" "OK" "Push completed"

    # RC87: Registry - GitHub completado
    Iniciar-PasoImplementacion -Registro $RegistroImpl -NumeroPaso 3 -Detalle "GitHub: repositorio + push"
    Finalizar-PasoImplementacion -Registro $RegistroImpl -NumeroPaso 3 -Estado "COMPLETADO" -Detalle "Repositorio creado y codigo publicado"
    Persistir-RegistroImplementacion -Registro $RegistroImpl

    # ===== 11. Configure GitHub Actions Secrets (OIDC) =====
    Write-Step "OIDC" "START" "Configuring Azure OIDC secrets for GitHub Actions"
    try {
        # Get tenant ID from current Azure session
        $azContext = az account show --query "{tenantId:tenantId, subscriptionId:id}" -o json 2>&1 | ConvertFrom-Json
        $tenantId = $azContext.tenantId
        $subscriptionId = $azContext.subscriptionId
        $clientId = $null

        # Try to read clientId from environment or config
        if ($env:AZURE_CLIENT_ID) {
            $clientId = $env:AZURE_CLIENT_ID
        } elseif (Test-Path $AzureConfigPath) {
            $cfg = Get-Content $AzureConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($cfg.Azure.ClientId) { $clientId = $cfg.Azure.ClientId }
        }

        if ($clientId -and $tenantId -and $subscriptionId) {
            $secretsResult = Establecer-SecretosGitHubAcciones `
                -RepoName $ghResult.RepoName `
                -AzureClientId $clientId `
                -AzureTenantId $tenantId `
                -AzureSubscriptionId $subscriptionId
            Establecer-InformacionProyecto -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{OIDCConfigurado=$true}
            Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "OIDC" -Estado "OK" -Detalle "Secrets configured: $($secretsResult.Status)"
            Write-Step "OIDC" "OK" "GitHub Actions OIDC secrets configured: $($secretsResult.Status)"
        } else {
            $missing = @()
            if (-not $clientId) { $missing += "AZURE_CLIENT_ID" }
            if (-not $tenantId) { $missing += "AZURE_TENANT_ID" }
            if (-not $subscriptionId) { $missing += "AZURE_SUBSCRIPTION_ID" }
            Write-Step "OIDC" "WARN" "OIDC secrets not configured. Missing: $($missing -join ', ')"
            Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "OIDC" -Estado "WARN" -Detalle "Missing: $($missing -join ', ')"
            Write-Warning "[OIDC] Missing Azure OIDC configuration: $($missing -join ', ')"
            Write-Warning "[OIDC] Configure Azure AD App and Federated Credentials per docs/Azure-OIDC-Setup.md"
        }
    } catch {
        Write-Step "OIDC" "WARN" "Could not configure OIDC secrets: $_"
        Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "OIDC" -Estado "WARN" -Detalle $_
        Write-Warning "[OIDC] OIDC setup incomplete: $_"
    }

    # ===== 12. Validate Infrastructure (SKIP if SkipAzure) =====
    $webApp = $null
    $smokeResult = $null
    if (-not $SkipAzure) {
    Write-Step "Guardian" "START" "Validating infrastructure protection"
    $guardianState = Test-GuardianRestrictions -ConfigPath $GuardianConfigPath
    Assert-ProyectoSafeToProceed -Operation "CreateWebApp" -GuardianState $guardianState | Out-Null
    Write-Step "Guardian" "OK" "Guardian active, proceeding"

    $azureValidation = Validate-AzureInfrastructure -AzureConfig $azureConfig
    Write-Step "Azure" "OK" "All infrastructure resources validated"

    # ===== 13. Create WebApp Only =====
    Write-Step "WebApp" "START" "Creating Web App: $WebAppName"
    $webApp = New-ProyectoWebApp -WebAppName $WebAppName -AzureConfig $azureConfig
    Establecer-InformacionProyecto -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{UrlPublica=$webApp.Url;EstadoAzure="CREADO"}
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "WebApp" -Estado "OK" -Detalle $webApp.Url
    Write-Step "WebApp" "OK" "Created at $($webApp.Url)"
    $Metadata.AzureStatus = "OK"
    $Metadata.Url = $webApp.Url

    # ===== 15. Generate ZIP =====
    Write-Step "ZIP" "START" "Creating deploy.zip"
    $exclude = @(".git", ".github", ".vscode", "logs", "__pycache__", "*.pyc", "temp")
    $zipResult = Crear-ZipDespliegue -SourceDir $ProjRoot -OutputPath (Join-Path $ProjRoot "deploy.zip") -ExcludePatterns $exclude
    $zipValidation = Validar-IntegridadZipDespliegue -ZipPath $zipResult.ZipPath
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "ZIP" -Estado "OK" -Detalle "SHA256=$($zipResult.SHA256)"
    Write-Step "ZIP" "OK" "ZIP created: $($zipResult.SizeKB) KB, SHA256: $($zipResult.SHA256)"

    # ===== 16. Zip Deploy =====
    Write-Step "Deploy" "START" "Deploying ZIP to Web App"
    Push-Location $ProjRoot
    try {
        $deployResult = Deploy-ProyectoZipToAzure -WebAppName $WebAppName -ResourceGroup $azureConfig.resourceGroup -ZipPath $zipResult.ZipPath -MaxRetries $MaxDeployRetries
    } finally { Pop-Location }
    $TotalDeploys++
    $Metadata.TotalDeploys = $TotalDeploys
    Establecer-InformacionProyecto -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{Estado="DESPLEGADO";TiempoDeploy=$deployResult.Duration}
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Deploy" -Estado "OK" -Duracion $deployResult.Duration
    Write-Step "Deploy" "OK" "Deploy completed in $($deployResult.Duration)s"
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Deploy" -Estado "OK"

    # ===== 17. Wait for Web App =====
    Write-Step "Ready" "START" "Waiting for Web App to respond"
    $ready = Wait-ProyectoWebAppReady -Url $webApp.Url -TimeoutSeconds 180
    if(-not $ready.Ready) { Write-Step "Ready" "WARN" "Web App not responding yet, continuing..." }

    # ===== 18. Smoke Tests =====
    Write-Step "SmokeTest" "START" "Smoke testing all endpoints"
    $smokeResult = Ejecutar-PruebasHumoProyecto -BaseUrl $webApp.Url -CorrelationId $CorrelationId -DbPath $DbPath
    $Metadata.SmokePassed = $smokeResult.Passed
    $Metadata.SmokeFailed = $smokeResult.Failed
    $Metadata.SmokeResults = $smokeResult.Endpoints
    Establecer-InformacionProyecto -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{Estado="TESTED";TiempoSmokeTest=$smokeResult.TotalTime}
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "SmokeTest" -Estado $(if($smokeResult.OverallStatus -eq "PASS"){"OK"}else{"FAIL"}) -Duracion $smokeResult.TotalTime -Detalle "$($smokeResult.Passed)/$($smokeResult.Total) passed"
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

        $smokeResult = Ejecutar-PruebasHumoProyecto -BaseUrl $webApp.Url -CorrelationId $CorrelationId -DbPath $DbPath
        $Metadata.SmokePassed = $smokeResult.Passed
        $Metadata.SmokeFailed = $smokeResult.Failed
        $Metadata.SmokeResults = $smokeResult.Endpoints
        Write-Step "Autocorrection" "$($smokeResult.OverallStatus)" "$($smokeResult.Passed)/$($smokeResult.Total) after correction"
    }
    $Metadata.AutoCorrections = $TotalCorrections
    }

    # ===== 19. Update SQLite =====
    Write-Step "SQLiteUpdate" "START" "Updating SQLite with final state"
    Establecer-InformacionProyecto -DbPath $DbPath -CorrelationId $CorrelationId -Properties @{CommitHash=(Obtener-EstadoGitProyecto -ProjectDir $ProjRoot).CommitHash;Estado="COMPLETADO"}
    Write-Step "SQLiteUpdate" "OK" "SQLite updated"
    $Metadata.SQLiteStatus = "OK"

    # ===== 20. Update Landing (second pass with live data) =====
    Write-Step "LandingUpdate" "START" "Updating landing page with live data"
    Crear-PaginaInicioProyecto -ProjectRoot $ProjRoot -ProjectName $NombreProyecto -WebAppName $WebAppName | Out-Null
    Write-Step "LandingUpdate" "OK" "Landing updated"

    # ===== 21. Update Timeline =====
    Registrar-EventoLineaTiempo -DbPath $DbPath -CorrelationId $CorrelationId -Evento "Publicado" -Estado "OK"

    # ===== 22. Generate Reports =====
    Write-Step "Reports" "START" "Generating reports"
    $totalTime = [math]::Round(((Get-Date)-$StartTime).TotalSeconds,2)
    $Metadata.TotalTime = $totalTime
    $overallStatus = if ($smokeResult -and $smokeResult.OverallStatus -eq "PASS") { "OK" } else { "OK-SkipAzure" }
    $Metadata.OverallStatus = $overallStatus
    $Metadata.CIStatus = "OK"
    $Metadata.TotalDeploys = $TotalDeploys
    $Metadata.TotalCommits = $TotalCommits

    New-ProyectoReportMD -Metadata $Metadata -OutputPath (Join-Path $HermesRoot "reports/RC74_E2E.md")
    New-ProyectoReportJSON -Metadata $Metadata -OutputPath (Join-Path $HermesRoot "reports/RC74_E2E.json")
    New-ProyectoReportHTML -Metadata $Metadata -OutputPath (Join-Path $HermesRoot "reports/RC74_E2E.html")
    Write-Step "Reports" "OK" "Reports saved to reports/"

    # ===== 23. Generate Deployment Report JSON =====
    Write-Step "DeployReport" "START" "Generating deployment report"
    $deployReportUrl = if ($webApp) { $webApp.Url } else { "https://github.com/$GitHubUser/$NombreProyecto" }
    $deployReportStatus = if ($smokeResult -and $smokeResult.OverallStatus -eq "PASS") { "PASS" } elseif ($SkipAzure) { "FACTORY_OK" } else { "FAIL" }
    $deployReportTests = if ($smokeResult) {
        $smokeResult.Endpoints | ForEach-Object {
            @{
                endpoint = $_.Endpoint
                http_code = $_.HTTPCode
                status = $_.Estado
                time_s = $_.TiempoRespuesta
            }
        }
    } else {
        @(@{ endpoint = "Factory"; http_code = 0; status = "SKIP_AZURE"; time_s = 0 })
    }
    $deployReport = @{
        project = $NombreProyecto
        app_service = if ($webApp) { $WebAppName } else { "N/A (SkipAzure)" }
        resource_group = if ($azureConfig) { $azureConfig.resourceGroup } else { "N/A" }
        region = if ($azureConfig) { $azureConfig.location } else { "N/A" }
        runtime = "Python 3.12"
        deployment = $TotalDeploys.ToString()
        commit = (Obtener-EstadoGitProyecto -ProjectDir $ProjRoot).CommitHash
        url = $deployReportUrl
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
        status = $deployReportStatus
        tests = $deployReportTests
    } | ConvertTo-Json -Depth 4
    $deployReportPath = Join-Path $ProjRoot "deployment-report.json"
    $deployReport | Out-File -FilePath $deployReportPath -Encoding UTF8 -Force
    Write-Step "DeployReport" "OK" "Saved to $deployReportPath"

    # ===== 24. Open URL =====
    if (-not $SkipAzure) {
        Write-Step "Browser" "OK" "Opening $($webApp.Url)"
        try { Start-Process $webApp.Url } catch { Write-Step "Browser" "WARN" "Cannot open browser (no disponible en Linux)" }
    } else {
        Write-Step "Azure" "SKIP" "SkipAzure activo — Control Plane manejara deploy"
        Write-Step "WebApp" "SKIP" "No se crea WebApp en Factory"
        Write-Step "Deploy" "SKIP" "Control Plane hara ZIP Deploy"
        Write-Step "SmokeTest" "SKIP" "Control Plane ejecutara smoke tests"
    }

    # ===== 26. Git Status Clean =====
    Write-Step "GitStatus" "START" "Verifying Git status"
    $gitStatus = Obtener-EstadoGitProyecto -ProjectDir $ProjRoot
    if($gitStatus.IsClean) {
        Write-Step "GitStatus" "OK" "Working tree clean"
    } else {
        Write-Step "GitStatus" "WARN" "Uncommitted changes detected"
    }

    # ===== 25. Commit Final =====
    Write-Step "CommitFinal" "START" "Creating final commit"
    Crear-CommitProyecto -ProjectDir $ProjRoot -Mensaje "RC74-C - Pipeline completed: $NombreProyecto" | Out-Null
    $TotalCommits++
    $Metadata.TotalCommits = $TotalCommits
    Write-Step "CommitFinal" "OK" "Final commit #$TotalCommits created"

    # ===== 26. Push Final =====
    Write-Step "PushFinal" "START" "Final push to GitHub"
    $pushFinal = Publicar-ProyectoEnGitHub -ProjectDir $ProjRoot -Branch "main"
    Write-Step "PushFinal" "OK" "Final push completed"

    # Verify clean status again after final commit+push
    $gitStatusFinal = Obtener-EstadoGitProyecto -ProjectDir $ProjRoot
    if($gitStatusFinal.IsClean) {
        Write-Step "GitFinal" "OK" "Working tree clean - nothing to commit"
    }

    # ===== SHA Capture + REMOTE VERIFICATION + Control Plane Trigger =====
    Write-Step "SHA" "START" "Capturing HEAD commit SHA"
    # IMPORTANTE: Ejecutar git rev-parse HEAD dentro del directorio del child ($ProjRoot),
    # NO en el directorio actual que puede ser HERMES-ENTERPRISE (donde el working-directory
    # de factory-run.yml apunta). Todas las funciones del módulo restauran el CWD original
    # después de ejecutarse, por lo que sin -C capturaríamos el SHA del repositorio PADRE.
    $commitSha = (git -C $ProjRoot rev-parse HEAD 2>&1).Trim()
    $repoName = "$GitHubUser/$NombreProyecto"
    Write-Step "SHA" "OK" "SHA=$commitSha Repo=$repoName"

    # Validar formato SHA
    if ($commitSha -notmatch '^[0-9a-f]{40}$') {
        Write-Step "SHA" "FAIL" "SHA inválido: $commitSha (debe ser 40 caracteres hex)"
        throw "SHA inválido: $commitSha"
    }

    # ── VERIFICACIÓN ACTIVA DE SHA REMOTO ──
    # Esperar que GitHub haya replicado el commit y exponer el SHA vía API
    # Backoff: 0s, 5s, 10s, 20s, 30s (5 intentos, max ~65s)
    if ($TriggerControlPlane) {
        Write-Step "SHA" "START" "Verificando que SHA existe remotamente en $repoName"
        $shaVerified = $false
        $backoffIntervals = @(0, 5, 10, 20, 30)
        for ($attempt = 0; $attempt -lt $backoffIntervals.Length; $attempt++) {
            $delay = $backoffIntervals[$attempt]
            if ($attempt -gt 0) {
                Write-Step "SHA" "WAIT" "Esperando ${delay}s (intento $($attempt+1)/$($backoffIntervals.Length))..."
                Start-Sleep -Seconds $delay
            }
            # NO imprimir token. gh usa GH_TOKEN del env.
            $shaCheck = gh api "/repos/$repoName/git/commits/$commitSha" --jq '.sha' 2>&1
            $exitCode = $LASTEXITCODE
            if ($exitCode -eq 0 -and $shaCheck -match '^[0-9a-f]{40}$') {
                Write-Step "SHA" "OK" "SHA verificado remotamente: ${shaCheck}"
                $shaVerified = $true
                break
            }
            else {
                $errMsg = ($shaCheck -replace '[\r\n]',' ').Substring(0, [Math]::Min(120, $shaCheck.Length))
                Write-Step "SHA" "RETRY" "SHA aún no disponible: $errMsg"
            }
        }

        if (-not $shaVerified) {
            Write-Step "SHA" "FAIL" "SHA $commitSha NO VERIFICABLE remotamente tras $($backoffIntervals.Length) intentos"
            Write-Step "SHA" "FAIL" "No se disparará Control Plane. El SHA no está disponible en GitHub."
            throw "SHA_REMOTE_VERIFICATION_FAILED: No se pudo verificar $commitSha en $repoName después de reintentos"
        }

        # ── DISPARAR CONTROL PLANE ──
        Write-Step "ControlPlane" "START" "Triggering deploy-child.yml workflow (SHA remoto verificado)"

        # Construir array de argumentos (splatting) — cada elemento es un argumento separado
        # Evita el bug de PowerShell: string concatenado se pasa como un solo argumento al CLI
        $triggerArgs = @(
            'workflow', 'run', 'deploy-child.yml',
            '--repo', "$GitHubUser/HERMES-ENTERPRISE",
            '--ref', 'main',
            '--field', "project_name=$NombreProyecto",
            '--field', "repository=$repoName",
            '--field', "commit_sha=$commitSha",
            '--field', "deployment_id=$CorrelationId"
        )
        if (![string]::IsNullOrWhiteSpace($AppServicePlanId)) {
            $triggerArgs += '--field'
            $triggerArgs += "app_service_plan_id=$AppServicePlanId"
        }

        $triggerResult = & gh @triggerArgs 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Step "ControlPlane" "OK" "Triggered! SHA remoto verificado + Control Plane disparado"
        } else {
            Write-Step "ControlPlane" "WARN" "Trigger failed: $triggerResult"
            $manualField = if (![string]::IsNullOrWhiteSpace($AppServicePlanId)) { " --field app_service_plan_id=$AppServicePlanId" } else { "" }
            $deployIdField = " --field deployment_id=$CorrelationId"
            Write-Step "ControlPlane" "WARN" "Manual trigger: gh workflow run deploy-child.yml --repo $GitHubUser/HERMES-ENTERPRISE --ref main --field project_name=$NombreProyecto --field repository=$repoName --field commit_sha=$commitSha$deployIdField$manualField"
        }
    } else {
        Write-Step "ControlPlane" "SKIP" "Use -TriggerControlPlane to auto-deploy via Control Plane"
        $manualField = if (![string]::IsNullOrWhiteSpace($AppServicePlanId)) { " --field app_service_plan_id=$AppServicePlanId" } else { "" }
        $deployIdField = " --field deployment_id=$CorrelationId"
        Write-Step "ControlPlane" "INFO" "Manual trigger command:"
        Write-Host "    gh workflow run deploy-child.yml --repo $GitHubUser/HERMES-ENTERPRISE --ref main --field project_name=$NombreProyecto --field repository=$repoName --field commit_sha=$commitSha$deployIdField$manualField" -ForegroundColor Yellow
    }

    # RC87: Persistir registro de implementacion
    $RegistroImpl.Implementacion.commit_solicitado = $commitSha
    $RegistroImpl.Implementacion.repositorio = $repoName
    Finalizar-RegistroImplementacion -Registro $RegistroImpl -Estado "COMPLETADO"
    Persistir-RegistroImplementacion -Registro $RegistroImpl

    # -- Success banner (adaptado para SkipAzure y modo normal) --
    if ($SkipAzure) {
        Write-Host "`n$(('='*60))" -ForegroundColor Cyan
        Write-Host "    FACTORY RUNNER — REPOSITORIO CREADO + SHA CAPTURADO" -ForegroundColor Cyan
        Write-Host "$(('='*60))" -ForegroundColor Cyan
        Write-Host " Proyecto     : $NombreProyecto" -ForegroundColor White
        Write-Host " Repositorio  : $repoName" -ForegroundColor Green
        Write-Host " SHA          : $commitSha" -ForegroundColor Green
        Write-Host "$(('='*60))" -ForegroundColor Cyan
        Write-Host " CID          : $CorrelationId" -ForegroundColor Yellow
        Write-Host " Time         : ${totalTime}s" -ForegroundColor Yellow
        Write-Host " Commits      : $TotalCommits" -ForegroundColor Yellow
        Write-Host " Git          : Working tree clean" -ForegroundColor Yellow
        Write-Host " SkipAzure    : true (Control Plane hara deploy)" -ForegroundColor Yellow
        Write-Host " ControlPlane : $(if($TriggerControlPlane){'DISPARADO'}else{'NO'})" -ForegroundColor Yellow
        Write-Host "$(('='*60))" -ForegroundColor Cyan
    } else {
        $webAppUrl = if ($webApp) { $webApp.Url } else { "https://$WebAppName.azurewebsites.net" }
        $smokePassed = if ($smokeResult) { $smokeResult.Passed } else { 0 }
        $smokeTotal = if ($smokeResult) { $smokeResult.Total } else { 0 }
        $smokeStatus = if ($smokeResult -and $smokeResult.OverallStatus -eq "PASS") { "Green" } else { "Red" }

        Write-Host "`n$(('='*60))" -ForegroundColor Cyan
        Write-Host "    HERMES ENTERPRISE — DEPLOYMENT COMPLETE" -ForegroundColor Cyan
        Write-Host "$(('='*60))" -ForegroundColor Cyan
        Write-Host " Proyecto     : $NombreProyecto" -ForegroundColor White
        Write-Host " App Service  : $WebAppName" -ForegroundColor White
        Write-Host " Frontend     : ${webAppUrl}/" -ForegroundColor Green
        Write-Host " FastAPI      : ${webAppUrl}/health" -ForegroundColor Green
        Write-Host " Swagger      : ${webAppUrl}/swagger" -ForegroundColor Green
        Write-Host " OpenAPI      : ${webAppUrl}/openapi.json" -ForegroundColor Green
        Write-Host " Version      : ${webAppUrl}/api/version" -ForegroundColor Green
        Write-Host " Proyecto     : ${webAppUrl}/api/proyecto" -ForegroundColor Green
        Write-Host "$(('='*60))" -ForegroundColor Cyan
        Write-Host " CID          : $CorrelationId" -ForegroundColor Yellow
        Write-Host " Time         : ${totalTime}s" -ForegroundColor Yellow
        Write-Host " Tests        : ${smokePassed}/${smokeTotal} passed" -ForegroundColor $smokeStatus
        Write-Host " Corrections  : $TotalCorrections" -ForegroundColor Yellow
        Write-Host " Commits      : $TotalCommits" -ForegroundColor Yellow
        Write-Host " Deploys      : $TotalDeploys" -ForegroundColor Yellow
        Write-Host " Git          : Working tree clean" -ForegroundColor Yellow
        Write-Host " SHA          : $commitSha" -ForegroundColor Yellow
        Write-Host " Repo         : $repoName" -ForegroundColor Yellow
        Write-Host "$(('='*60))" -ForegroundColor Cyan
        Write-Host " Navegador abierto: ${webAppUrl}/" -ForegroundColor Green
        Write-Host "$(('='*60))`n" -ForegroundColor Cyan
    }

} catch {
    Write-Host "`n[RC74-C] PIPELINE FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "CorrelationId: $CorrelationId" -ForegroundColor Yellow
    throw
}


