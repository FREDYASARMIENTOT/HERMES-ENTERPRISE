Param()
Write-Host "VerifyEnvironment: basic checks"
$ok = $true
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Error 'git not found'; $ok = $false }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Error 'gh not found'; $ok = $false }
if (-not (Get-Command code -ErrorAction SilentlyContinue)) { Write-Host 'code (VSCode) not found - optional' }
if ($ok) { Write-Host 'Environment OK'; exit 0 } else { exit 1 }
