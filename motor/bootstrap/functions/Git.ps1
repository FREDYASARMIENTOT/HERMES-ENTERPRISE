function Initialize-Git {
    param([string]$ProjectPath)
    Set-Location $ProjectPath
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Warn "git no disponible"; return $false }
    if (-not (Test-Path (Join-Path $ProjectPath '.git'))) {
        git init | Out-Null
        git add . | Out-Null
        git commit -m "chore: initial commit" --author="Hermes <hermes@example.local>" | Out-Null
        return $true
    }
    return $false
}
