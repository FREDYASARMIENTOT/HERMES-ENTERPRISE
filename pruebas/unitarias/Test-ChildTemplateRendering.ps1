<# .SYNOPSIS RC84 Test-ChildTemplateRendering #>
$HermesRoot="D:\HERMES-ENTERPRISE"
$tp=0;$tf=0
function wt([string]$n,[bool]$r){if($r){Write-Host "  [PASS] $n" -ForegroundColor Green;$script:tp++}else{Write-Host "  [FAIL] $n" -ForegroundColor Red;$script:tf++}}
$c=Get-Content (Join-Path $HermesRoot "tools\Templates\backend\main.py") -Raw -Encoding UTF8
Write-Host "[Test 1] Functions" -ForegroundColor Yellow
wt "_resolve_meta" ($c -match "def _resolve_meta")
wt "_build_pipeline" ($c -match "def _build_pipeline")
wt "consultar_sqlite_param" ($c -match "def consultar_sqlite_param")
Write-Host "[Test 2] Landing" -ForegroundColor Yellow
wt "response_class=HTMLResponse" ($c -match "response_class=HTMLResponse")
wt "Pipeline nodes defined" ($c -match "_PIPELINE_DEF")
Write-Host "[Test 3] Nodes" -ForegroundColor Yellow
# Nodes are defined with double quotes in Python:  "factory", "child-repo", etc.
foreach($n in @("factory","child-repo","ci","control-plane","oidc","asp-iaur","web-app","zip-deploy","readiness","functional-tests","evidence","online")){wt "Node $n" ($c -match "`"$n`"")}
Write-Host "[Test 4] Env Fallback" -ForegroundColor Yellow
foreach($v in @("HERMES_PROJECT_NAME","HERMES_REGION","HERMES_DEPLOYMENT_ID","HERMES_CORRELATION_ID","HERMES_WEBAPP_NAME")){wt "Env $v" ($c -match $v)}
Write-Host "[Test 5] SQL Parameterized" -ForegroundColor Yellow
wt "WHERE ?" ($c -match "WHERE CorrelationId = \?")
wt "execute params" ($c -match "c\.execute\(query, params\)")
Write-Host "[Test 6] UI Sections" -ForegroundColor Yellow
wt "IDENTIDAD section" ($c -match "IDENTIDAD DEL PROYECTO")
wt "INFRAESTRUCTURA section" ($c -match "INFRAESTRUCTURA")
wt "TRAZABILIDAD section" ($c -match "TRAZABILIDAD DE DESPLIEGUE")
wt "DETALLE DE IMPLEMENTACION" ($c -match "DETALLE DE IMPLEMENTACI")
wt "ACCESOS section" ($c -match "ACCESOS")
wt "PRUEBAS FUNCIONALES" ($c -match "PRUEBAS FUNCIONALES")
wt "Redoc" ($c -match "redoc")
wt "Footer" ($c -match "Hermes Enterprise")
Write-Host "[Test 7] Plan indicators" -ForegroundColor Yellow
wt "Plan REUTILIZADO badge" ($c -match "REUTILIZADO")
wt "Plan Creado NO" ($c -match "Plan Creado.*NO")
wt "Plan Reutilizado SI" ($c -match "Plan Reutilizado.*S")
wt "OIDC badge" ($c -match "OIDC")
Write-Host "[Test 8] No duplicates" -ForegroundColor Yellow
$accesosCount = ([regex]::Matches($c, "ACCESOS")).Count
wt "ACCESOS appears exactly once" ($accesosCount -eq 1)
Write-Host "[Test 9] Template placeholders" -ForegroundColor Yellow
# {{REGION}} and {{DEPLOYMENT_ID}} ARE valid template placeholders in variable definitions.
# They should exist in _REGION and _DEPLOYMENT_ID assignments (Factory replaces them later).
wt "REGION placeholder variable" ($c -match '_REGION = "\{\{REGION\}\}"')
wt "DEPLOYMENT_ID placeholder variable" ($c -match '_DEPLOYMENT_ID = "\{\{DEPLOYMENT_ID\}\}"')
Write-Host "[Test 10] Detail implementation" -ForegroundColor Yellow
wt "Factory mention" ($c -match "Crear-HermesProyecto")
wt "Control Plane mention" ($c -match "deploy-child.yml")
wt "ZIP Deploy mention" ($c -match "ZIP Deploy")
wt "Evidence mention" ($c -match "deployment-report.json")
Write-Host "[Test 11] Factory" -ForegroundColor Yellow
$fc=Get-Content (Join-Path $HermesRoot "tools\Crear-HermesProyecto.ps1") -Raw -Encoding UTF8
wt ".Replace() not -replace" ($fc -match "\.Replace\(")
wt "REGION" ($fc -match "REGION" -and $fc -match "Replace")
wt "DEPLOYMENT_ID" ($fc -match "DEPLOYMENT_ID" -and $fc -match "Replace")
wt "Location validation" ($fc -match "ContainsKey")
Write-Host "================================" -ForegroundColor Cyan
if($tf -eq 0){Write-Host "RESULT: ALL $tp PASSED" -ForegroundColor Green}else{Write-Host "RESULT: $tp/$tf" -ForegroundColor Red}
Write-Host "================================" -ForegroundColor Cyan
if($tf -gt 0){exit 1}
