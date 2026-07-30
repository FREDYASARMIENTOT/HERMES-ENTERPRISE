Param()
Write-Host "VerifyGitHub: simple gh auth check"
try {
    $status = gh auth status 2>&1
    Write-Host $status
    if ($status -match 'Logged in to github.com') { exit 0 } else { exit 1 }
} catch {
    Write-Error $_.Exception.Message; exit 1
}
