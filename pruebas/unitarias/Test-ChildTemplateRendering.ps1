<# .SYNOPSIS RC83 Test-ChildTemplateRendering #>
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
foreach($n in @("factory","child-repo","ci","control-plane","oidc","asp-iaur","web-app","zip-deploy","readiness","functional-tests","evidence","online")){wt "Node $n" ($c -match "`"$n`"")}
Write-Host "[Test 4] Env Fallback" -ForegroundColor Yellow
foreach($v in @("HERMES_PROJECT_NAME","HERMES_REGION","HERMES_DEPLOYMENT_ID","HERMES_CORRELATION_ID","HERMES_WEBAPP_NAME")){wt "Env $v" ($c -match $v)}
Write-Host "[Test 5] SQL Parameterized" -ForegroundColor Yellow
wt "WHERE ?" ($c -match "WHERE CorrelationId = \?")
wt "execute params" ($c -match "c\.execute\(query, params\)")
Write-Host "[Test 6] HTML" -ForegroundColor Yellow
wt "ID card" ($c -match "IDENTIDAD")
wt "Pipeline" ($c -match "TRAZABILIDAD")
wt "Tests" ($c -match "PRUEBAS FUNCIONALES")
wt "Redoc" ($c -match "redoc")
wt "Footer" ($c -match "Hermes Enterprise")
Write-Host "[Test 7] Factory" -ForegroundColor Yellow
$fc=Get-Content (Join-Path $HermesRoot "tools\Crear-HermesProyecto.ps1") -Raw -Encoding UTF8
wt ".Replace() not -replace" ($fc -match "\.Replace\(")
wt "REGION" ($fc -match "REGION" -and $fc -match "Replace")
wt "DEPLOYMENT_ID" ($fc -match "DEPLOYMENT_ID" -and $fc -match "Replace")
wt "Location validation" ($fc -match "ContainsKey")
Write-Host "================================" -ForegroundColor Cyan
if($tf -eq 0){Write-Host "RESULT: ALL $tp PASSED" -ForegroundColor Green}else{Write-Host "RESULT: $tp/$tf" -ForegroundColor Red}
Write-Host "================================" -ForegroundColor Cyan
if($tf -gt 0){exit 1}
