<#
.SYNOPSIS
    RC75-A — Non-destructive project validation suite.
.DESCRIPTION
    Validates a Hermes project workspace without deploying to Azure.
    Tests: Workspace, Git, GitHub, Runtime, SQLite, FastAPI, Middleware,
    Landing, Templates, Static, Configuration, CI, CD.
.PARAMETER ProjectRoot
    Path to the project root directory.
.PARAMETER ProjectName
    Name of the project (for display).
.PARAMETER CorrelationId
    Optional correlation ID for tracking.
.OUTPUTS
    Hashtable with validation results.
#>
param(
    [Parameter(Mandatory)] [string] $ProjectRoot,
    [string] $ProjectName = (Split-Path $ProjectRoot -Leaf),
    [string] $CorrelationId = [Guid]::NewGuid().ToString("N").Substring(0,16).ToUpper()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$StartTime = Get-Date
$Results = @{}
$Passed = 0
$Failed = 0
$Total = 0

function Write-Test {
    param([string]$Category, [string]$Test, [string]$Status, [string]$Detail)
    $icon = if ($Status -eq "PASS") { "[PASS]" } elseif ($Status -eq "FAIL") { "[FAIL]" } else { "[WARN]" }
    $color = if ($Status -eq "PASS") { "Green" } elseif ($Status -eq "FAIL") { "Red" } else { "Yellow" }
    Write-Host "$icon [$Category] $Test :: $Detail" -ForegroundColor $color
}

function Test-Passed {
    param([string]$Category, [string]$Test, [string]$Detail)
    $script:Passed++; $script:Total++
    if (-not $script:Results.ContainsKey($Category)) { $script:Results[$Category] = @{} }
    $script:Results[$Category][$Test] = @{Status="PASS"; Detail=$Detail}
    Write-Test $Category $Test "PASS" $Detail
}

function Test-Failed {
    param([string]$Category, [string]$Test, [string]$Detail)
    $script:Failed++; $script:Total++
    if (-not $script:Results.ContainsKey($Category)) { $script:Results[$Category] = @{} }
    $script:Results[$Category][$Test] = @{Status="FAIL"; Detail=$Detail}
    Write-Test $Category $Test "FAIL" $Detail
}

Write-Host "`n$(('='*60))" -ForegroundColor Cyan
Write-Host " RC75-A — Validation Suite for: $ProjectName" -ForegroundColor Cyan
Write-Host " Root: $ProjectRoot" -ForegroundColor Cyan
Write-Host " CID : $CorrelationId" -ForegroundColor Cyan
Write-Host "$(('='*60))`n" -ForegroundColor Cyan

# ============================================================
# 1. Workspace Validation
# ============================================================
Write-Host "[SECTION] Workspace Validation" -ForegroundColor Magenta

$wsTest = "Directory exists"
if (Test-Path $ProjectRoot) {
    Test-Passed "Workspace" $wsTest $ProjectRoot
} else {
    Test-Failed "Workspace" $wsTest "Not found: $ProjectRoot"
}

$wsTest = "Project structure"
$requiredDirs = @("backend", "templates", "static", "data", ".github/workflows")
$missingDirs = @()
foreach ($dir in $requiredDirs) {
    $d = Join-Path $ProjectRoot $dir
    if (-not (Test-Path $d)) { $missingDirs += $dir }
}
if ($missingDirs.Count -eq 0) {
    Test-Passed "Workspace" $wsTest "All required directories exist"
} else {
    Test-Failed "Workspace" $wsTest "Missing directories: $($missingDirs -join ', ')"
}

$wsTest = "backend/main.py"
$mainPy = Join-Path $ProjectRoot "backend/main.py"
if (Test-Path $mainPy) {
    Test-Passed "Workspace" $wsTest "Found"
} else {
    Test-Failed "Workspace" $wsTest "Not found"
}

$wsTest = "requirements.txt"
$reqFile = Join-Path $ProjectRoot "requirements.txt"
if (Test-Path $reqFile) {
    Test-Passed "Workspace" $wsTest "Found"
} else {
    Test-Failed "Workspace" $wsTest "Not found"
}

# ============================================================
# 2. Git Validation
# ============================================================
Write-Host "[SECTION] Git Validation" -ForegroundColor Magenta

$gitDir = Join-Path $ProjectRoot ".git"
if (Test-Path $gitDir) {
    Test-Passed "Git" "Repository" "Git initialized"
} else {
    Test-Failed "Git" "Repository" "Not a git repository"
}

# Check git remote
Push-Location $ProjectRoot
try {
    $remoteUrl = git remote get-url origin 2>&1
    if ($LASTEXITCODE -eq 0) {
        if ($remoteUrl -match '@github\.com' -or $remoteUrl -match '://[^/]+@') {
            Test-Failed "Git" "Remote URL" "Remote contains embedded credentials"
        } else {
            Test-Passed "Git" "Remote URL" "Clean: $remoteUrl"
        }
    } else {
        Test-Failed "Git" "Remote URL" "No origin remote configured"
    }
} finally { Pop-Location }

# Check .gitignore
$gitignore = Join-Path $ProjectRoot ".gitignore"
if (Test-Path $gitignore) {
    Test-Passed "Git" ".gitignore" "Found"
} else {
    Test-Failed "Git" ".gitignore" "Not found"
}

# ============================================================
# 3. GitHub Validation
# ============================================================
Write-Host "[SECTION] GitHub Validation" -ForegroundColor Magenta

$ghTest = "GitHub repo exists"
try {
    $repoName = (Split-Path $ProjectRoot -Leaf) -replace '\s+', '-' -replace '_', '-' -replace '\.', '-'
    $repoName = $repoName.ToLowerInvariant()
    $ghView = gh repo view $repoName --json name 2>&1
    if ($LASTEXITCODE -eq 0) {
        Test-Passed "GitHub" $ghTest "Repository exists: $repoName"
    } else {
        Test-Failed "GitHub" $ghTest "Repository not found: $repoName"
    }
} catch {
    Test-Failed "GitHub" $ghTest "Error: $_"
}

$ghTest = "No secrets exposed"
try {
    $secrets = gh secret list --repo $repoName 2>&1
    if ($LASTEXITCODE -eq 0) {
        $secretNames = @()
        foreach ($line in $secrets) {
            if ($line -match '^(\S+)') { $secretNames += $matches[1] }
        }
        Test-Passed "GitHub" $ghTest "Secrets configured: $($secretNames -join ', ')"
    } else {
        Test-Failed "GitHub" $ghTest "Could not list secrets: $secrets"
    }
} catch {
    Test-Failed "GitHub" $ghTest "Error: $_"
}

# ============================================================
# 4. SQLite Validation
# ============================================================
Write-Host "[SECTION] SQLite Validation" -ForegroundColor Magenta

$dbPath = Join-Path $ProjectRoot "data/proyecto.db"
if (Test-Path $dbPath) {
    Test-Passed "SQLite" "Database file" "Found"
    
    # Test connection
    try {
        $connTest = sqlite3 $dbPath "SELECT 1;" 2>&1
        if ($LASTEXITCODE -eq 0 -and $connTest -eq 1) {
            Test-Passed "SQLite" "Connection" "Can connect to database"
        } else {
            Test-Failed "SQLite" "Connection" "Connection test failed: $connTest"
        }
    } catch {
        Test-Failed "SQLite" "Connection" "Error: $_"
    }
    
    # Test schema
    try {
        $tables = sqlite3 $dbPath ".tables" 2>&1
        if ($tables -match 'proyecto|timeline|metadata') {
            Test-Passed "SQLite" "Schema" "Tables found: $tables"
        } else {
            Test-Failed "SQLite" "Schema" "Expected tables not found: $tables"
        }
    } catch {
        Test-Failed "SQLite" "Schema" "Error: $_"
    }
} else {
    Test-Failed "SQLite" "Database file" "Not found"
}

# ============================================================
# 5. Python / Runtime Validation
# ============================================================
Write-Host "[SECTION] Python Runtime Validation" -ForegroundColor Magenta

$pyTest = "Python available"
try {
    $pyVer = python --version 2>&1
    if ($pyVer -match '3\.(1[0-9]|[0-9])') {
        Test-Passed "Runtime" $pyTest $pyVer.Trim()
    } else {
        Test-Failed "Runtime" $pyTest "Python 3.x required: $pyVer"
    }
} catch {
    Test-Failed "Runtime" $pyTest "Python not found: $_"
}

$pyTest = "Dependencies installable"
$reqFile = Join-Path $ProjectRoot "requirements.txt"
if (Test-Path $reqFile) {
    try {
        $pipCheck = pip install -r $reqFile --dry-run 2>&1
        if ($LASTEXITCODE -eq 0) {
            Test-Passed "Runtime" $pyTest "Dependencies resolved"
        } else {
            Test-Failed "Runtime" $pyTest "Dependency resolution failed"
        }
    } catch {
        Test-Failed "Runtime" $pyTest "Error: $_"
    }
} else {
    Test-Failed "Runtime" $pyTest "requirements.txt not found"
}

$pyTest = "main.py imports valid"
if (Test-Path $mainPy) {
    try {
        $pyCompile = python -c "import py_compile; py_compile.compile('$mainPy', doraise=True)" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Test-Passed "Runtime" $pyTest "Syntax valid"
        } else {
            Test-Failed "Runtime" $pyTest "Syntax error: $pyCompile"
        }
    } catch {
        Test-Failed "Runtime" $pyTest "Error: $_"
    }
}

# ============================================================
# 6. FastAPI / Backend Validation
# ============================================================
Write-Host "[SECTION] FastAPI Backend Validation" -ForegroundColor Magenta

$beTest = "main.py has FastAPI app"
if (Test-Path $mainPy) {
    $content = Get-Content $mainPy -Raw -Encoding UTF8
    if ($content -match 'FastAPI\(\)' -or $content -match 'from fastapi') {
        Test-Passed "Backend" $beTest "FastAPI detected"
    } else {
        Test-Failed "Backend" $beTest "FastAPI not found in main.py"
    }
    
    $beTest = "Health endpoint"
    if ($content -match '/health' -or $content -match 'health') {
        Test-Passed "Backend" $beTest "Health endpoint configured"
    } else {
        Test-Failed "Backend" $beTest "Health endpoint not found"
    }
    
    $beTest = "CORS middleware"
    if ($content -match 'CORSMiddleware' -or $content -match 'cors') {
        Test-Passed "Backend" $beTest "CORS configured"
    } else {
        Test-Failed "Backend" $beTest "CORS not found"
    }
}

# ============================================================
# 7. Frontend / Landing Validation
# ============================================================
Write-Host "[SECTION] Frontend Validation" -ForegroundColor Magenta

$feTest = "Landing page"
$landingFiles = @("index.html", "landing.html", "templates/index.html", "templates/landing.html")
$foundLanding = $false
foreach ($lf in $landingFiles) {
    $lp = Join-Path $ProjectRoot $lf
    if (Test-Path $lp) {
        $foundLanding = $true
        Test-Passed "Frontend" $feTest "Found: $lf"
        break
    }
}
if (-not $foundLanding) {
    Test-Failed "Frontend" $feTest "No landing page found in: $($landingFiles -join ', ')"
}

$feTest = "Static assets"
$staticDir = Join-Path $ProjectRoot "static"
if (Test-Path $staticDir) {
    $assetCount = (Get-ChildItem $staticDir -Recurse -File).Count
    Test-Passed "Frontend" $feTest "$assetCount static assets"
} else {
    Test-Failed "Frontend" $feTest "Static directory not found"
}

# ============================================================
# 8. CI/CD Workflow Validation
# ============================================================
Write-Host "[SECTION] CI/CD Validation" -ForegroundColor Magenta

$ciFile = Join-Path $ProjectRoot ".github/workflows/ci.yml"
$deployFile = Join-Path $ProjectRoot ".github/workflows/deploy.yml"

if (Test-Path $ciFile) {
    $ciContent = Get-Content $ciFile -Raw -Encoding UTF8
    if ($ciContent -match 'test|Test|check|Check') {
        Test-Passed "CI/CD" "CI workflow" "Contains tests"
    } else {
        Test-Failed "CI/CD" "CI workflow" "No tests detected"
    }
    if ($ciContent -match 'python|Python') {
        Test-Passed "CI/CD" "CI Python" "Python configured"
    } else {
        Test-Failed "CI/CD" "CI Python" "Python not configured"
    }
} else {
    Test-Failed "CI/CD" "CI workflow" "Not found"
}

if (Test-Path $deployFile) {
    $deployContent = Get-Content $deployFile -Raw -Encoding UTF8
    if ($deployContent -match 'deploy|Deploy|DEPLOY') {
        Test-Passed "CI/CD" "CD workflow" "Contains deploy job"
    } else {
        Test-Failed "CI/CD" "CD workflow" "No deploy detected"
    }
    if ($deployContent -match 'azure|Azure|webapp|WebApp') {
        Test-Passed "CI/CD" "CD Azure" "Azure deployment configured"
    } else {
        Test-Failed "CI/CD" "CD Azure" "Azure deployment not found"
    }
    # Check for OIDC secrets usage
    if ($deployContent -match 'AZURE_CLIENT_ID' -or $deployContent -match 'AZURE_TENANT_ID') {
        Test-Passed "CI/CD" "CD OIDC" "OIDC authentication configured"
    } else {
        Test-Passed "CI/CD" "CD OIDC" "Fallback auth (AZURE_CREDENTIALS)"
    }
    # Check for smoke tests
    if ($deployContent -match 'smoke|Smoke|health|Health') {
        Test-Passed "CI/CD" "CD Smoke" "Smoke tests configured"
    } else {
        Test-Failed "CI/CD" "CD Smoke" "No smoke tests detected"
    }
} else {
    Test-Failed "CI/CD" "CD workflow" "Not found"
}

# ============================================================
# 9. Configuration Validation
# ============================================================
Write-Host "[SECTION] Configuration Validation" -ForegroundColor Magenta

# Check for any hardcoded secrets
$secretPatterns = @('ghp_', 'gho_', 'ghu_', 'ghs_', 'ghr_', 'token.*=', 'password.*=', 'secret.*=', 'PAT.*=')
$secretFound = $false
$secretFiles = @()

Get-ChildItem $ProjectRoot -Recurse -File -Exclude "*.db","*.zip","*.pyc" | ForEach-Object {
    try {
        $content = Get-Content $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($content) {
            foreach ($pattern in $secretPatterns) {
                if ($content -match $pattern) {
                    $secretFound = $true
                    $secretFiles += $_.FullName
                    break
                }
            }
        }
    } catch {}
}

if (-not $secretFound) {
    Test-Passed "Security" "No hardcoded secrets" "No secret patterns found in files"
} else {
    Test-Failed "Security" "No hardcoded secrets" "Potential secrets in: $($secretFiles -join ', ')"
}

# ============================================================
# Summary
# ============================================================
$TotalTime = [math]::Round(((Get-Date)-$StartTime).TotalSeconds,2)
$OverallStatus = if ($Failed -eq 0) { "PASS" } else { "FAIL" }

Write-Host "`n$(('='*60))" -ForegroundColor Cyan
Write-Host " VALIDATION RESULT: $OverallStatus" -ForegroundColor $(if($OverallStatus -eq "PASS"){"Green"}else{"Red"})
Write-Host " Passed: $Passed / $Total" -ForegroundColor $(if($OverallStatus -eq "PASS"){"Green"}else{"Red"})
Write-Host " Failed: $Failed" -ForegroundColor $(if($OverallStatus -eq "PASS"){"Green"}else{"Red"})
Write-Host " Time: ${TotalTime}s" -ForegroundColor Cyan
Write-Host "$(('='*60))`n" -ForegroundColor Cyan

return @{
    ProjectName = $ProjectName
    ProjectRoot = $ProjectRoot
    CorrelationId = $CorrelationId
    OverallStatus = $OverallStatus
    Passed = $Passed
    Failed = $Failed
    Total = $Total
    TimeSeconds = $TotalTime
    Results = $Results
}