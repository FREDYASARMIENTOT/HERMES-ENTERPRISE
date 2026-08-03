param([string]$DatabasePath = "data/hermes_debug2.db")
Import-Module "$PSScriptRoot\..\motor\persistence\HermesPersistence.psm1" -Force -ErrorAction Stop
$mgr = New-HermesDatabaseManager -DatabasePath $DatabasePath
Connect-HermesDatabase -Manager $mgr
$null = Initialize-HermesSchema -Manager $mgr
$result = Invoke-HermesSql -Manager $mgr -Sql "CREATE TABLE IF NOT EXISTS DebugTable (Id TEXT PRIMARY KEY, Name TEXT)" -Mode NonQuery
Write-Host "Create result: $result"
$r = Invoke-HermesSql -Manager $mgr -Sql "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" -Mode Query
$r | Format-Table -AutoSize
$null = Invoke-HermesSql -Manager $mgr -Sql "DROP TABLE IF EXISTS DebugTable" -Mode NonQuery
Disconnect-HermesDatabase -Manager $mgr
Remove-Item -Path $DatabasePath -Force -ErrorAction SilentlyContinue