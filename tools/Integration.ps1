Param()
Write-Host "Integration tool: orchestration shim (no business logic)"
# Invoke sub-tools as needed
& powershell -NoProfile -ExecutionPolicy Bypass -File "$(Join-Path $PSScriptRoot 'VerifyEnvironment.ps1')"
& powershell -NoProfile -ExecutionPolicy Bypass -File "$(Join-Path $PSScriptRoot 'VerifyGitHub.ps1')"
& powershell -NoProfile -ExecutionPolicy Bypass -File "$(Join-Path $PSScriptRoot 'VerifyVSCode.ps1')"
exit $LASTEXITCODE
