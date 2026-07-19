# Test-GitSecrets.ps1
# Security-first pre-push secret scanner
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path "$PSScriptRoot/../../" | Select-Object -ExpandProperty Path
$envPath = Join-Path $repoRoot '.env'
$envExamplePath = Join-Path $repoRoot '.env.example'

Write-Host "Repository root: $repoRoot"

# 1. Validate .env and .env.example
$hasEnv = Test-Path $envPath
$hasEnvExample = Test-Path $envExamplePath
Write-Host ".env present: $hasEnv ; .env.example present: $hasEnvExample"

# 2. Scan working tree for risky patterns
$patterns = @('API_KEY','API-KEY','OPENAI','AZURE','AZURE_','TOKEN','SECRET','PASSWORD','Bearer','KEY=','SECRET=','FOUNDARY','FOUNDARY_KEY')
$matches = @()
foreach ($p in $patterns) {
    try {
        $r = git -C $repoRoot grep -n -- "${p}" 2>$null
        if ($r) { $matches += $r }
    } catch { }
}

# 3. Scan commit history (recent commits)
$historyMatches = @()
try {
    $revlist = git -C $repoRoot rev-list --all
    foreach ($c in $revlist) {
        foreach ($p in $patterns) {
            try {
                $r = git -C $repoRoot grep -n "${p}" $c -- 2>$null
                if ($r) { $historyMatches += ("${c}:`n$r") }
            } catch { }
        }
    }
} catch { }

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
