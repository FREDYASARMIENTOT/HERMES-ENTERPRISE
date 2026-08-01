function Test-ProvisioningPrerequisites {
    param([string]$Target = 'Local')

    $errors = @()

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $errors += 'git missing' }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { $errors += 'gh missing' }
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) { $errors += 'python missing' }

    # Placeholder PAT check: returns true if gh auth status works
    try { gh auth status > $null; $ghAuth = $true } catch { $ghAuth = $false }
    if (-not $ghAuth) { $errors += 'gh unauthenticated' }

    if ($errors.Count -gt 0) {
        Write-Output "Prereq errors: $($errors -join ', ')"
        return $false
    }
    return $true
}
