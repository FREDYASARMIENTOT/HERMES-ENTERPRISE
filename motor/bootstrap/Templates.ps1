# Templates module (esqueleto)
function Generate-Templates {
    param($ProjectPath)
    $templates = @('.github','README.md','LICENSE','CHANGELOG.md','CONTRIBUTING.md','.gitignore', '.env.example')
    foreach ($t in $templates) {
        $path = Join-Path $ProjectPath $t
        if (-not (Test-Path $path)) {
            New-Item -ItemType File -Path $path -Force | Out-Null
        }
    }
    return $true
}
