<#
.SYNOPSIS
    Verifies the Use Case Catalog was persisted correctly in SQLite.
#>
param(
    [string]$DatabasePath = "data/hermes_test.db"
)

$ErrorActionPreference = 'Stop'

# Load HermesPersistence
Import-Module "$PSScriptRoot\..\motor\persistence\HermesPersistence.psm1" -Force -ErrorAction Stop

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  USE CASE CATALOG VERIFICATION" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Connect to database
$mgr = New-HermesDatabaseManager -DatabasePath $DatabasePath
Connect-HermesDatabase -Manager $mgr
Write-Host "[OK] Connected to: $DatabasePath" -ForegroundColor Green

# Verify UseCaseCatalog
Write-Host "`n=== USE CASE CATALOG ===" -ForegroundColor Green
$result = Invoke-HermesSql -Manager $mgr -Sql "SELECT Name, Capability, Engine, Provider FROM UseCaseCatalog ORDER BY Name" -Mode Query
$count = $result.Count
foreach ($row in $result) {
    Write-Host ("  {0,-30} {1,-35} {2,-18} {3}" -f $row.Name, $row.Capability, $row.Engine, $row.Provider)
}
Write-Host "Total Use Cases: $count" -ForegroundColor Yellow

# Verify CapabilityCatalog
Write-Host "`n=== CAPABILITY CATALOG ===" -ForegroundColor Green
$capResult = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) as cnt FROM CapabilityCatalog" -Mode Scalar
$capCount = $capResult
Write-Host "Total Capabilities: $capCount" -ForegroundColor Yellow

$capRows = Invoke-HermesSql -Manager $mgr -Sql "SELECT Name, Engine, Provider FROM CapabilityCatalog ORDER BY Name" -Mode Query
foreach ($row in $capRows) {
    Write-Host ("  {0,-40} {1,-18} {2}" -f $row.Name, $row.Engine, $row.Provider)
}

# Verify ProviderCatalog
Write-Host "`n=== PROVIDER CATALOG ===" -ForegroundColor Green
$provCount = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) FROM ProviderCatalog" -Mode Scalar
Write-Host "Total Providers: $provCount" -ForegroundColor Yellow

$provRows = Invoke-HermesSql -Manager $mgr -Sql "SELECT Name FROM ProviderCatalog ORDER BY Name" -Mode Query
foreach ($row in $provRows) {
    Write-Host ("  {0}" -f $row.Name)
}

# Verify EngineCatalog
Write-Host "`n=== ENGINE CATALOG ===" -ForegroundColor Green
$engCount = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) FROM EngineCatalog" -Mode Scalar
Write-Host "Total Engines: $engCount" -ForegroundColor Yellow

$engRows = Invoke-HermesSql -Manager $mgr -Sql "SELECT Name FROM EngineCatalog ORDER BY Name" -Mode Query
foreach ($row in $engRows) {
    Write-Host ("  {0}" -f $row.Name)
}

# Verify AuditMetadata
Write-Host "`n=== AUDIT METADATA ===" -ForegroundColor Green
$auditRows = Invoke-HermesSql -Manager $mgr -Sql "SELECT Id, AuditType, EntityCount FROM AuditMetadata ORDER BY CreatedAt DESC LIMIT 1" -Mode Query
foreach ($row in $auditRows) {
    Write-Host ("  Audit ID: {0}" -f $row.Id)
    Write-Host ("  Type: {0}" -f $row.AuditType)
    Write-Host ("  Entities: {0}" -f $row.EntityCount)
}

# Disconnect
Disconnect-HermesDatabase -Manager $mgr
Write-Host "`n[OK] Database connection closed." -ForegroundColor Green

# Summary
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  VERIFICATION COMPLETE" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ("  Use Cases    : {0}" -f $count) -ForegroundColor White
Write-Host ("  Capabilities : {0}" -f $capCount) -ForegroundColor White
Write-Host ("  Providers    : {0}" -f $provCount) -ForegroundColor White
Write-Host ("  Engines      : {0}" -f $engCount) -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan