$ErrorActionPreference = 'Stop'
Set-Location D:\HERMES-ENTERPRISE

# Run in a FRESH PowerShell process to ensure new DLL is loaded
$scriptBlock = {
    $ErrorActionPreference = 'Stop'
    Set-Location D:\HERMES-ENTERPRISE
    
    Write-Host "=== STARTING FRESH POWERSHELL PROCESS ===" -ForegroundColor Cyan
    
    $dll = 'D:\HERMES-ENTERPRISE\lib\HermesSQLiteProvider.dll'
    Write-Host "Loading DLL: $dll" -ForegroundColor Yellow
    Write-Host "DLL exists: $(Test-Path $dll)" -ForegroundColor Yellow
    $dllInfo = Get-Item $dll
    Write-Host "DLL size: $($dllInfo.Length) bytes, LastWrite: $($dllInfo.LastWriteTime)" -ForegroundColor Yellow
    
    Add-Type -Path $dll
    
    $testDb = 'D:\HERMES-ENTERPRISE\data\tests\test_binding.db'
    if (Test-Path $testDb) { Remove-Item $testDb -Force }
    
    $conn = New-Object Hermes.Data.SQLite.HermesSQLiteConnection("Data Source=$testDb;Version=3;")
    $conn.Open()
    Write-Host "Connection State: $($conn.State)" -ForegroundColor Green
    
    $cmd = $conn.CreateCommand()
    
    # Create table
    $cmd.CommandText = 'CREATE TABLE IF NOT EXISTS t (Id INTEGER PRIMARY KEY, Name TEXT)'
    $cmd.ExecuteNonQuery()
    Write-Host "Table created" -ForegroundColor Green
    
    # INSERT with direct SQL (no params)
    $cmd.CommandText = "INSERT INTO t(Id,Name) VALUES(1,'hello')"
    $insertCount = $cmd.ExecuteNonQuery()
    Write-Host "Insert count: $insertCount" -ForegroundColor Green
    
    # SELECT without params - should work
    $cmd.CommandText = "SELECT * FROM t WHERE Id=1"
    $reader = $cmd.ExecuteReader()
    $count = 0
    while ($reader.Read()) { $count++ }
    $reader.Close()
    Write-Host "Non-param SELECT count: $count" -ForegroundColor Green
    
    # SELECT with @id param - check if parameter count mismatch or binding issue
    try {
        $cmd.CommandText = 'SELECT * FROM t WHERE Id=@id'
        $p = $cmd.CreateParameter()
        $p.ParameterName = '@id'
        $p.Value = 1
        $cmd.Parameters.Add($p) | Out-Null
        
        Write-Host "Executing with @id=1..." -ForegroundColor Yellow
        $reader2 = $cmd.ExecuteReader()
        $count2 = 0
        while ($reader2.Read()) { $count2++ }
        $reader2.Close()
        Write-Host "Param SELECT count: $count2" -ForegroundColor Yellow
    } catch {
        Write-Host "ERROR in param SELECT: $_" -ForegroundColor Red
        Write-Host "   Type: $($_.Exception.GetType().Name)" -ForegroundColor Red
        if ($_.Exception.InnerException) {
            Write-Host "   Inner: $($_.Exception.InnerException.Message)" -ForegroundColor Red
        }
    }
    
    # Also try with positional ? 
    try {
        $cmd.Parameters.Clear()
        $cmd.CommandText = 'SELECT * FROM t WHERE Id=?'
        $p2 = $cmd.CreateParameter()
        $p2.ParameterName = '?'
        $p2.Value = 1
        $cmd.Parameters.Add($p2) | Out-Null
        
        Write-Host "Executing with ?=1..." -ForegroundColor Yellow
        $reader3 = $cmd.ExecuteReader()
        $count3 = 0
        while ($reader3.Read()) { $count3++ }
        $reader3.Close()
        Write-Host "Positional param count: $count3" -ForegroundColor Yellow
    } catch {
        Write-Host "ERROR in positional SELECT: $_" -ForegroundColor Red
    }
    
    $conn.Close()
    Remove-Item $testDb -Force
    Write-Host "=== DONE ===" -ForegroundColor Green
}

# Execute in a fresh PowerShell process
powershell -NoProfile -ExecutionPolicy Bypass -Command $scriptBlock 2>&1

Write-Host "`nScript completed." -ForegroundColor Cyan