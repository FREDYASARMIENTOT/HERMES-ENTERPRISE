# Test-GitSecrets.ps1
# Security-first pre-push secret scanner
# Migrado desde tests/security/Test-GitSecrets.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\HERMES-ENTERPRISE'
$envPath = Join-Path $RepoRoot '.env'
$envExamplePath = Join-Path $RepoRoot '.env.example'

Write-Host "Repository root: $RepoRoot"

# 1. Validate .env and .env.example
$hasEnv = Test-Path $envPath
$hasEnvExample = Test-Path $envExamplePath
Write-Host ".env present: $hasEnv ; .env.example present: $hasEnvExample"

# 2. Scan working tree for risky patterns
$patterns = @('API_KEY','API-KEY','OPENAI','AZURE','AZURE_','TOKEN','SECRET','PASSWORD','Bearer','KEY=','SECRET=','FOUNDARY','FOUNDARY_KEY')
$matches = @()
foreach ($p in $patterns) {
    try {
        $r = git -C $RepoRoot grep -n -- "${p}" 2>$null
        if ($r) { $matches += $r }
    } catch { Write-Debug "Git grep failed for pattern: $p" }
}

# 3. Scan commit history (recent commits)
$historyMatches = @()
try {
    $revlist = git -C $RepoRoot rev-list --all
    foreach ($c in $revlist) {
        foreach ($p in $patterns) {
            try {
                $r = git -C $RepoRoot grep -n "${p}" $c -- 2>$null
                if ($r) { $historyMatches += ("${c}:`n$r") }
            } catch { Write-Debug "Git grep history failed: $p @ $c" }
        }
    }
} catch { Write-Debug "Git rev-list failed" }

# Consolidate
$allMatches = $matches + $historyMatches
if ($allMatches.Count -gt 0) {
    Write-Host "SECURITY ALERT: potential secrets found:" -ForegroundColor Red
    $allMatches | Select-Object -First 200 | ForEach-Object { Write-Host $_ }
    exit 1
} else {
    Write-Host "No obvious secrets found in working tree or history scan."
    exit 0
}