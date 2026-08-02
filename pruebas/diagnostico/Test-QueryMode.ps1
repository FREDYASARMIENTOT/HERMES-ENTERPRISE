[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

$ModulePath = Resolve-Path "$PSScriptRoot\..\..\motor\persistence\HermesPersistence.psm1"
Remove-Module HermesPersistence -Force -ErrorAction SilentlyContinue
Import-Module $ModulePath -Force -Verbose:$false

$testDb = Join-Path $env:TEMP "diag_query_$(Get-Random).db"
try {
    $mgr = New-HermesDatabaseManager -DatabasePath $testDb
    Connect-HermesDatabase -Manager $mgr | Out-Null
    
    Invoke-HermesSql -Manager $mgr -Sql "CREATE TABLE IF NOT EXISTS test_table (Id INTEGER PRIMARY KEY, Name TEXT, Value TEXT)" -Mode NonQuery
    Invoke-HermesSql -Manager $mgr -Sql "INSERT INTO test_table(Id,Name,Value) VALUES(1,'test1','value1')" -Mode NonQuery
    
    # Test Scalar
    $scalar = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) FROM test_table" -Mode Scalar
    Write-Host "Scalar result: $scalar (type: $($scalar.GetType().FullName))"
    
    # Test Query
    $rows = Invoke-HermesSql -Manager $mgr -Sql "SELECT * FROM test_table" -Mode Query
    Write-Host "rows type: $($rows.GetType().FullName)"
    Write-Host "rows is DataTable: $($rows -is [System.Data.DataTable])"
    
    if ($rows -is [System.Data.DataTable]) {
        Write-Host "Rows.Count: $($rows.Rows.Count)"
        Write-Host "Row[0]['Name']: $($rows.Rows[0]['Name'])"
    }
    
    # Check if it's an array
    $enumerable = [System.Collections.IEnumerable]$rows
    if ($enumerable -and -not ($rows -is [string])) {
        Write-Host "rows is IEnumerable"
        $count = 0
        foreach ($item in $rows) {
            $count++
            Write-Host "  item #$count type: $($item.GetType().FullName)"
            if ($item -is [System.Data.DataTable]) {
                Write-Host "  item IS a DataTable with $($item.Rows.Count) rows"
            }
        }
    }
    
    Disconnect-HermesDatabase -Manager $mgr
}
finally {
    if (Test-Path $testDb) { Remove-Item $testDb -Force }
}