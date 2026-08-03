param([string]$DatabasePath = "data/hermes_final_test.db")
Import-Module "$PSScriptRoot\..\motor\persistence\HermesPersistence.psm1" -Force -ErrorAction Stop

$mgr = New-HermesDatabaseManager -DatabasePath $DatabasePath
Connect-HermesDatabase -Manager $mgr

$cnt = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) FROM UseCaseCatalog" -Mode Scalar
Write-Host "Use Cases in DB : $cnt"

$cnt2 = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) FROM CapabilityCatalog" -Mode Scalar
Write-Host "Capabilities     : $cnt2"

$cnt3 = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) FROM ProviderCatalog" -Mode Scalar
Write-Host "Providers        : $cnt3"

$cnt4 = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) FROM EngineCatalog" -Mode Scalar
Write-Host "Engines          : $cnt4"

Disconnect-HermesDatabase -Manager $mgr