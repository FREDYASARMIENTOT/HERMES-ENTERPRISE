$ErrorActionPreference = 'Stop'
Set-Location D:\HERMES-ENTERPRISE

# Run Test-PersistenceLayer.ps1 in a FRESH PowerShell process
Write-Host "Running Test-PersistenceLayer.ps1 in a fresh PowerShell process..." -ForegroundColor Cyan

$scriptBlock = {
    $ErrorActionPreference = 'Stop'
    Set-Location D:\HERMES-ENTERPRISE
    
    Write-Host "=== FRESH PROCESS: Starting Test-PersistenceLayer.ps1 ===" -ForegroundColor Cyan
    
    & .\pruebas\integracion\Test-PersistenceLayer.ps1
    
    Write-Host "=== FRESH PROCESS: Test-PersistenceLayer.ps1 completed ===" -ForegroundColor Cyan
}

powershell -NoProfile -ExecutionPolicy Bypass -Command $scriptBlock 2>&1

Write-Host "`nPersistence tests completed." -ForegroundColor Cyan