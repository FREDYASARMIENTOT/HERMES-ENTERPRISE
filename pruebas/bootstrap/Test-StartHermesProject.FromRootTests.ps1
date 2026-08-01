# pruebas/bootstrap/Test-StartHermesProject.FromRootTests.ps1
# Migrado desde tests/Test-StartHermesProject.ps1
Param()
$RepoRoot = 'D:\HERMES-ENTERPRISE'
Write-Host "Running bootstrap tests (invoking tools)"
$validate = Join-Path $RepoRoot 'tools\ValidateModules.ps1'
Write-Host "Invoking: $validate"
& powershell -NoProfile -ExecutionPolicy Bypass -File $validate
if ($LASTEXITCODE -ne 0) { Write-Error "ValidateModules failed"; exit 1 }
Write-Host "Tests successful"
exit 0