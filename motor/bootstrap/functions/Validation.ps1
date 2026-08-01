function Test-ProvisioningPrerequisites {
    param([string]$Target = 'Local')
    $gitOk = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
    if (-not $gitOk) { Write-Warn 'git missing'; return $false }
    if ($Target -eq 'GitHub') {
        $gh = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)
        if (-not $gh) { Write-Warn 'gh missing'; return $false }
        try { gh auth status | Out-Null; gh api user | Out-Null } catch { Write-Warn 'gh auth failed'; return $false }
    }
    return $true
}
