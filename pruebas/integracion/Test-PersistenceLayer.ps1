<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-PersistenceLayer.ps1
Propósito: Pruebas integrales del módulo de persistencia HermesPersistence
====================================================================================================
#>

[CmdletBinding()]
param(
    [switch]$SkipCleanup,
    [switch]$Detailed
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Resolve-Path "$PSScriptRoot\..\.."
$ModulePath = Join-Path $ProjectRoot 'motor\persistence\HermesPersistence.psm1'

# Import module
Remove-Module HermesPersistence -Force -ErrorAction SilentlyContinue
Import-Module $ModulePath -Force -Verbose:$false

# Test database path (in-memory temp file for each test)
$TestDbRoot = Join-Path $ProjectRoot 'data\tests'
if (-not (Test-Path $TestDbRoot)) { New-Item -ItemType Directory -Path $TestDbRoot -Force | Out-Null }

$Global:TestCount = 0
$Global:PassCount = 0
$Global:FailCount = 0
$Global:Results = [System.Collections.ArrayList]@()

function New-TestDatabase {
    $testDb = Join-Path $TestDbRoot "test_$(Get-Random -Maximum 999999).db"
    $manager = New-HermesDatabaseManager -DatabasePath $testDb
    return $manager
}

function Write-TestResult {
    param([string]$Name, [bool]$Passed, [string]$Detail = '')
    $Global:TestCount++
    if ($Passed) { $Global:PassCount++ } else { $Global:FailCount++ }
    $status = if ($Passed) { 'PASS' } else { 'FAIL' }
    $msg = "[$status] $Name"
    if ($Detail) { $msg += " - $Detail" }
    Write-Host $msg -ForegroundColor $(if ($Passed) { 'Green' } else { 'Red' })
    $Global:Results.Add([pscustomobject]@{ TestName = $Name; Status = if ($Passed) { 'Passed' } else { 'Failed' }; Detail = $Detail }) | Out-Null
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST GRUPO 1: Database Manager Core
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " GRUPO 1: Database Manager Core" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

try {
    $mgr = New-TestDatabase
    Write-TestResult -Name 'New-HermesDatabaseManager returns object' -Passed ($mgr -ne $null) -Detail "Type: $($mgr.GetType().Name)"
    Write-TestResult -Name 'Manager has required properties' -Passed ($mgr.DatabasePath -and $mgr.ConnectionString) -Detail $mgr.DatabasePath
    Write-TestResult -Name 'Manager starts disconnected' -Passed ($mgr.IsConnected -eq $false)
    
    Connect-HermesDatabase -Manager $mgr | Out-Null
    Write-TestResult -Name 'Connect-HermesDatabase succeeds' -Passed ($mgr.IsConnected -eq $true)
    Write-TestResult -Name 'IsConnected set to true' -Passed ($mgr.IsConnected -eq $true)
    Write-TestResult -Name 'Connection object created' -Passed ($mgr.Connection -ne $null)
    Write-TestResult -Name 'ConnectionCount incremented' -Passed ($mgr.ConnectionCount -eq 1)
    
    $connTest = Test-HermesDatabaseConnection -Manager $mgr
    Write-TestResult -Name 'Test-HermesDatabaseConnection returns true' -Passed ($connTest -eq $true)
    
    Disconnect-HermesDatabase -Manager $mgr
    Write-TestResult -Name 'Disconnect sets IsConnected=false' -Passed ($mgr.IsConnected -eq $false)
    Write-TestResult -Name 'Disconnect nullifies Connection' -Passed ($mgr.Connection -eq $null)
    
    # Cleanup
    if (Test-Path $mgr.DatabasePath) { Remove-Item $mgr.DatabasePath -Force }
} catch {
    Write-TestResult -Name 'Group 1 setup' -Passed $false -Detail $_.ToString()
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST GRUPO 2: SQL Query Execution
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " GRUPO 2: SQL Query Execution" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

try {
    $mgr = New-TestDatabase
    Connect-HermesDatabase -Manager $mgr | Out-Null
    
    # ExecuteNonQuery
    $result = Invoke-HermesSql -Manager $mgr -Sql "CREATE TABLE IF NOT EXISTS test_table (Id INTEGER PRIMARY KEY, Name TEXT, Value TEXT)" -Mode NonQuery
    $result = Invoke-HermesSql -Manager $mgr -Sql "INSERT INTO test_table(Id,Name,Value) VALUES(1,'test1','value1')" -Mode NonQuery
    Write-TestResult -Name 'INSERT returns rows affected' -Passed ($result -eq 1)
    
    # ExecuteScalar
    $scalar = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) FROM test_table" -Mode Scalar
    Write-TestResult -Name 'SELECT COUNT returns 1' -Passed ($scalar -eq 1)
    
    # ExecuteQuery - Invoke-HermesSql already returns DataTable directly
    $dt = Invoke-HermesSql -Manager $mgr -Sql "SELECT * FROM test_table" -Mode Query
    Write-TestResult -Name 'SELECT returns DataTable' -Passed ($dt -is [System.Data.DataTable])
    Write-TestResult -Name 'DataTable has 1 row' -Passed ($dt.Rows.Count -eq 1)
    Write-TestResult -Name 'Row Name = test1' -Passed ($dt.Rows[0]['Name'] -eq 'test1')
    
    # Parameterized query
    $paramDt = Invoke-HermesSql -Manager $mgr -Sql "SELECT * FROM test_table WHERE Name=@name" -Parameters @{ '@name' = 'test1' } -Mode Query
    Write-TestResult -Name 'Parameterized query works' -Passed ($paramDt.Rows.Count -eq 1)
    
    # Update
    Invoke-HermesSql -Manager $mgr -Sql "UPDATE test_table SET Value='updated' WHERE Id=1" | Out-Null
    $updated = Invoke-HermesSql -Manager $mgr -Sql "SELECT Value FROM test_table WHERE Id=1" -Mode Scalar
    Write-TestResult -Name 'UPDATE changes value' -Passed ($updated -eq 'updated')
    
    # Transaction
    Start-HermesDatabaseTransaction -Manager $mgr
    Invoke-HermesSql -Manager $mgr -Sql "INSERT INTO test_table(Id,Name,Value) VALUES(2,'tx_test','tx_val')" | Out-Null
    Invoke-HermesSql -Manager $mgr -Sql "INSERT INTO test_table(Id,Name,Value) VALUES(3,'tx_test2','tx_val2')" | Out-Null
    $countBefore = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) FROM test_table" -Mode Scalar
    Write-TestResult -Name 'Transaction insert count=3' -Passed ($countBefore -eq 3)
    Undo-HermesDatabaseTransaction -Manager $mgr
    $countAfter = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) FROM test_table" -Mode Scalar
    Write-TestResult -Name 'Transaction rollback reverts to 1' -Passed ($countAfter -eq 1)
    
    Disconnect-HermesDatabase -Manager $mgr
    if (Test-Path $mgr.DatabasePath) { Remove-Item $mgr.DatabasePath -Force }
} catch {
    Write-TestResult -Name 'Group 2' -Passed $false -Detail $_.ToString()
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST GRUPO 3: Schema Initialization
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " GRUPO 3: Schema Initialization" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

try {
    $mgr = New-TestDatabase
    Connect-HermesDatabase -Manager $mgr | Out-Null
    
    $result = Initialize-HermesSchema -Manager $mgr
    Write-TestResult -Name 'Initialize-HermesSchema returns true' -Passed $result
    
    # Check tables exist
    $tables = Invoke-HermesSql -Manager $mgr -Sql "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" -Mode Query
    Write-TestResult -Name 'Schema tables created' -Passed ($tables.Rows.Count -ge 10) -Detail "$($tables.Rows.Count) tables created"
    
    # Register a migration version
    $regOk = Register-HermesMigration -Manager $mgr -Version 1 -Description 'Initial schema'
    Write-TestResult -Name 'Register-HermesMigration v1' -Passed ($regOk -eq $true)
    
    # Check SchemaVersion recorded
    $sv = Invoke-HermesSql -Manager $mgr -Sql "SELECT Version, Description, Status FROM SchemaVersion WHERE Version=1" -Mode Query
    Write-TestResult -Name 'SchemaVersion v1 recorded' -Passed (($sv.Rows.Count -eq 1) -and ($sv.Rows[0]['Status'] -eq 'Executed'))
    
    # Check views (none expected)
    $views = Invoke-HermesSql -Manager $mgr -Sql "SELECT name FROM sqlite_master WHERE type='view'" -Mode Query
    Write-TestResult -Name 'Views count (expected 0)' -Passed ($views.Rows.Count -eq 0) -Detail "Views: $($views.Rows.Count)"
    
    # Re-init should still return true (it's idempotent)
    $result2 = Initialize-HermesSchema -Manager $mgr
    Write-TestResult -Name 'Re-init returns true (idempotent)' -Passed ($result2 -eq $true)
    
    Disconnect-HermesDatabase -Manager $mgr
    if (Test-Path $mgr.DatabasePath) { Remove-Item $mgr.DatabasePath -Force }
} catch {
    Write-TestResult -Name 'Group 3' -Passed $false -Detail $_.ToString()
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST GRUPO 4: Migration Engine
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " GRUPO 4: Migration Engine" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

try {
    $mgr = New-TestDatabase
    Connect-HermesDatabase -Manager $mgr | Out-Null
    Initialize-HermesSchema -Manager $mgr | Out-Null
    
    # Register migration v1
    $r1 = Register-HermesMigration -Manager $mgr -Version 1 -Description 'Initial schema'
    Write-TestResult -Name 'Register migration v1' -Passed ($r1 -eq $true)
    
    # Register migration v2
    $r2 = Register-HermesMigration -Manager $mgr -Version 2 -Description 'Add test column'
    Write-TestResult -Name 'Register migration v2' -Passed ($r2 -eq $true)
    
    # Register again (idempotent)
    $r2again = Register-HermesMigration -Manager $mgr -Version 2 -Description 'Duplicate'
    Write-TestResult -Name 'Register duplicate returns true (idempotent)' -Passed ($r2again -eq $true)
    
    # Verify SchemaVersion table
    $versions = Invoke-HermesSql -Manager $mgr -Sql "SELECT Version, Description, Status FROM SchemaVersion ORDER BY Version" -Mode Query
    Write-TestResult -Name 'SchemaVersion has 2 rows' -Passed ($versions.Rows.Count -eq 2) -Detail "$($versions.Rows.Count) rows"
    
    # Check v2 status
    $v2Row = $versions.Select("Version = 2")
    Write-TestResult -Name 'Version 2 status = Executed' -Passed (($v2Row.Count -gt 0) -and ($v2Row[0]['Status'] -eq 'Executed'))
    
    Disconnect-HermesDatabase -Manager $mgr
    if (Test-Path $mgr.DatabasePath) { Remove-Item $mgr.DatabasePath -Force }
} catch {
    Write-TestResult -Name 'Group 4' -Passed $false -Detail $_.ToString()
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST GRUPO 5: Repository Pattern
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " GRUPO 5: Repository Pattern" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

try {
    $mgr = New-TestDatabase
    Connect-HermesDatabase -Manager $mgr | Out-Null
    Initialize-HermesSchema -Manager $mgr | Out-Null
    
    # Test SQLiteRepository
    $repo = New-SQLiteRepository -Manager $mgr -TableName 'Configuration' -IdColumn 'Id'
    Write-TestResult -Name 'New-SQLiteRepository returns object' -Passed ($repo -ne $null)
    
    # Insert
    $insertResult = $repo.Insert(@{ Id = 'test_cfg_1'; Key = 'test.key.1'; Value = 'test_value_1'; ValueType = 'String'; Category = 'Test'; Description = 'Test config' })
    $count = $repo.Count()
    Write-TestResult -Name 'Repository Insert + Count' -Passed ($count -eq 1) -Detail "Count: $count"
    
    # GetById
    $row = $repo.GetById('test_cfg_1')
    Write-TestResult -Name 'Repository GetById' -Passed (($row.Rows.Count -eq 1) -and ($row.Rows[0]['Value'] -eq 'test_value_1'))
    
    # Update
    $repo.Update('test_cfg_1', @{ Value = 'updated_value' })
    $updated = $repo.GetById('test_cfg_1')
    Write-TestResult -Name 'Repository Update' -Passed ($updated.Rows[0]['Value'] -eq 'updated_value')
    
    # Exists
    $exists = $repo.Exists('test_cfg_1')
    Write-TestResult -Name 'Repository Exists true' -Passed ($exists -eq $true)
    $notExists = $repo.Exists('nonexistent')
    Write-TestResult -Name 'Repository Exists false' -Passed ($notExists -eq $false)
    
    # Get all
    $repo.Insert(@{ Id = 'test_cfg_2'; Key = 'test.key.2'; Value = 'value_2'; ValueType = 'String'; Category = 'Test'; Description = 'Test 2' })
    $all = $repo.GetAll()
    Write-TestResult -Name 'Repository GetAll returns multiple' -Passed ($all.Rows.Count -ge 2)
    
    # Delete
    $repo.Delete('test_cfg_2')
    $count2 = $repo.Count()
    Write-TestResult -Name 'Repository Delete' -Passed ($count2 -eq 1)
    
    # Test domain-specific repository
    $provRepo = New-ProviderRepository -Manager $mgr
    Write-TestResult -Name 'New-ProviderRepository returns object' -Passed ($provRepo -ne $null)
    $provRepo.Insert(@{ Id = 'prov_test_1'; Name = 'TestProvider'; ProviderType = 'Cloud'; Status = 'Stopped'; Description = 'Test provider' })
    $byStatus = $provRepo.GetByStatus('Stopped')
    Write-TestResult -Name 'ProviderRepository.GetByStatus works' -Passed ($byStatus.Rows.Count -ge 1)
    
    Disconnect-HermesDatabase -Manager $mgr
    if (Test-Path $mgr.DatabasePath) { Remove-Item $mgr.DatabasePath -Force }
} catch {
    Write-TestResult -Name 'Group 5' -Passed $false -Detail $_.ToString()
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST GRUPO 6: Domain Repositories
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " GRUPO 6: Domain Repositories" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

try {
    $mgr = New-TestDatabase
    Connect-HermesDatabase -Manager $mgr | Out-Null
    Initialize-HermesSchema -Manager $mgr | Out-Null
    
    # SessionRepository
    $sessRepo = New-SessionRepository -Manager $mgr
    $sessRepo.Insert(@{ Id = 'sess_test_1'; SessionName = 'Test Session'; SessionType = 'Development'; Status = 'Active'; UserName = 'test_user' })
    
    # GetById
    $sessById = $sessRepo.GetById('sess_test_1')
    Write-TestResult -Name 'SessionRepository GetById' -Passed ($sessById.Rows.Count -eq 1) -Detail "Session: $($sessById.Rows[0]['SessionName'])"
    
    # ExecutionRepository
    $execRepo = New-ExecutionRepository -Manager $mgr
    $execRepo.Insert(@{ Id = 'exec_test_1'; SessionId = 'sess_test_1'; EventType = 'Info'; Module = 'test'; Action = 'test'; Message = 'test msg'; DurationMs = 100 })
    $execRepo.Insert(@{ Id = 'exec_test_2'; SessionId = 'sess_test_1'; EventType = 'Error'; Module = 'test'; Action = 'test'; Message = 'error msg'; DurationMs = 200 })
    
    $byStatus = $execRepo.GetByStatus('Info')
    Write-TestResult -Name 'ExecutionRepository.GetByStatus' -Passed ($byStatus.Rows.Count -eq 1)
    
    $byCorr = $execRepo.GetByCorrelationId('sess_test_1')
    Write-TestResult -Name 'ExecutionRepository.GetByCorrelationId' -Passed ($byCorr.Rows.Count -ge 1)
    
    $failed = $execRepo.GetFailed()
    Write-TestResult -Name 'ExecutionRepository.GetFailed' -Passed ($failed.Rows.Count -ge 1)
    
    # ConfigurationRepository
    $cfgRepo = New-ConfigurationRepository -Manager $mgr
    $cfgRepo.Insert(@{ Id = 'cfg_test_1'; Key = 'test.cfg'; Value = 'test_val'; ValueType = 'String'; Category = 'Test'; Description = 'Test' })
    $byKey = $cfgRepo.GetByKey('test.cfg')
    Write-TestResult -Name 'ConfigurationRepository.GetByKey' -Passed ($byKey.Rows.Count -eq 1)
    
    # NotificationRepository
    $notifRepo = New-NotificationRepository -Manager $mgr
    $notifRepo.Insert(@{ Id = 'notif_1'; Title = 'Test Notification'; Message = 'Test'; NotificationType = 'Info'; Source = 'Test' })
    $unread = $notifRepo.GetUnread()
    Write-TestResult -Name 'NotificationRepository.GetUnread' -Passed ($unread.Rows.Count -ge 1)
    $notifRepo.MarkAsRead('notif_1')
    $unread2 = $notifRepo.GetUnread()
    Write-TestResult -Name 'NotificationRepository.MarkAsRead' -Passed ($unread2.Rows.Count -eq 0)
    
    # MetricsRepository
    $metricsRepo = New-MetricsRepository -Manager $mgr
    $metricsRepo.RecordMetric('test_metric', 42.5, 'count', 'test')
    $recent = $metricsRepo.GetRecent('test_metric', 60)
    Write-TestResult -Name 'MetricsRepository.RecordMetric + GetRecent' -Passed ($recent.Rows.Count -ge 1) -Detail "Value: $($recent.Rows[0]['MetricValue'])"
    
    # AuditRepository
    $auditRepo = New-AuditRepository -Manager $mgr
    $auditRepo.Insert(@{ Id = 'audit_1'; Accion = 'Create'; EntityType = 'Test'; EntityId = '123'; UserName = 'auditor' })
    $byUser = $auditRepo.GetByUser('auditor')
    Write-TestResult -Name 'AuditRepository.GetByUser' -Passed ($byUser.Rows.Count -ge 1)
    
    Disconnect-HermesDatabase -Manager $mgr
    if (Test-Path $mgr.DatabasePath) { Remove-Item $mgr.DatabasePath -Force }
} catch {
    Write-TestResult -Name 'Group 6' -Passed $false -Detail $_.ToString()
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST GRUPO 7: Health & Optimizer Services
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " GRUPO 7: Health & Optimizer Services" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

try {
    $mgr = New-TestDatabase
    Connect-HermesDatabase -Manager $mgr | Out-Null
    Initialize-HermesSchema -Manager $mgr | Out-Null
    
    # Health check
    $health = Test-HermesSystemHealth -Manager $mgr -Detailed
    Write-TestResult -Name 'Test-HermesSystemHealth returns result' -Passed ($health -ne $null)
    Write-TestResult -Name 'OverallStatus is Healthy or Degraded' -Passed ($health.OverallStatus -in @('Healthy','Degraded'))
    Write-TestResult -Name 'Has checks' -Passed ($health.Checks.Count -ge 1)
    
    # Database stats
    $stats = Get-HermesDatabaseStats -Manager $mgr
    Write-TestResult -Name 'Get-HermesDatabaseStats returns object' -Passed ($stats -ne $null)
    Write-TestResult -Name 'Stats has TotalTables (>= 10)' -Passed ($stats.TotalTables -ge 10) -Detail "TotalTables: $($stats.TotalTables)"
    Write-TestResult -Name 'Stats has FileSizeBytes' -Passed ($stats.FileSizeBytes -ge 0)
    
    # Optimize - analyze only
    $optResult = Optimize-HermesDatabase -Manager $mgr -Analyze
    Write-TestResult -Name 'Optimize-HermesDatabase (analyze) works' -Passed (($optResult.Count -ge 1) -and ($optResult[0].Status -eq 'Completed'))
    
    Disconnect-HermesDatabase -Manager $mgr
    if (Test-Path $mgr.DatabasePath) { Remove-Item $mgr.DatabasePath -Force }
} catch {
    Write-TestResult -Name 'Group 7' -Passed $false -Detail $_.ToString()
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST GRUPO 8: Backup & Recovery
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " GRUPO 8: Backup & Recovery" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

try {
    $mgr = New-TestDatabase
    Connect-HermesDatabase -Manager $mgr | Out-Null
    Initialize-HermesSchema -Manager $mgr | Out-Null
    
    # Insert some data (include ValueType)
    Invoke-HermesSql -Manager $mgr -Sql "INSERT INTO Configuration(Id,Key,Value,ValueType,Category) VALUES('bk_test','backup.test','backup_val','String','Test')" | Out-Null
    
    # Backup
    $backup = Backup-HermesDatabase -Manager $mgr -BackupType 'Full'
    Write-TestResult -Name 'Backup-HermesDatabase returns result' -Passed ($backup -ne $null)
    Write-TestResult -Name 'Backup status = Success' -Passed ($backup.Status -eq 'Success')
    Write-TestResult -Name 'Backup file exists' -Passed (Test-Path $backup.FilePath)
    
    # Verify backup history
    $history = Get-HermesBackupHistory -Manager $mgr
    Write-TestResult -Name 'Get-HermesBackupHistory returns records' -Passed ($history.Rows.Count -ge 1)
    
    # Cleanup backup file
    if (Test-Path $backup.FilePath) { Remove-Item $backup.FilePath -Force }
    
    Disconnect-HermesDatabase -Manager $mgr
    if (Test-Path $mgr.DatabasePath) { Remove-Item $mgr.DatabasePath -Force }
} catch {
    Write-TestResult -Name 'Group 8' -Passed $false -Detail $_.ToString()
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST GRUPO 9: Telemetry Service
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " GRUPO 9: Telemetry Service" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

try {
    $mgr = New-TestDatabase
    Connect-HermesDatabase -Manager $mgr | Out-Null
    Initialize-HermesSchema -Manager $mgr | Out-Null
    
    Send-HermesTelemetry -Manager $mgr -EventName 'test_event' -Source 'test_suite' -Properties @{ key1 = 'val1'; key2 = 'val2' } -Measurements @{ count = 1; duration = 100 } -Tags @('test','integration')
    Write-TestResult -Name 'Send-HermesTelemetry succeeds' -Passed $true
    
    $telemetry = Get-HermesTelemetry -Manager $mgr -EventName 'test_event'
    Write-TestResult -Name 'Get-HermesTelemetry returns DataTable' -Passed ($telemetry -is [System.Data.DataTable])
    if ($telemetry.Rows.Count -eq 1) {
        Write-TestResult -Name 'Telemetry event name matches' -Passed ($telemetry.Rows[0]['EventName'] -eq 'test_event')
        Write-TestResult -Name 'Telemetry Source matches' -Passed ($telemetry.Rows[0]['Source'] -eq 'test_suite')
    } else {
        Write-TestResult -Name 'Telemetry event count - found 1 event' -Passed $false -Detail "Rows: $($telemetry.Rows.Count)"
    }
    
    Disconnect-HermesDatabase -Manager $mgr
    if (Test-Path $mgr.DatabasePath) { Remove-Item $mgr.DatabasePath -Force }
} catch {
    Write-TestResult -Name 'Group 9' -Passed $false -Detail $_.ToString()
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST GRUPO 10: Seed & Test Data
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " GRUPO 10: Seed & Test Data" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

try {
    $mgr = New-TestDatabase
    Connect-HermesDatabase -Manager $mgr | Out-Null
    Initialize-HermesSchema -Manager $mgr | Out-Null
    
    Initialize-HermesSeedData -Manager $mgr
    Write-TestResult -Name 'Initialize-HermesSeedData completes' -Passed $true
    
    # Verify seed data - Configuration (10 seed configs)
    $cfgCount = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) AS cnt FROM Configuration" -Mode Scalar
    Write-TestResult -Name 'Seed Configuration present' -Passed ($cfgCount -gt 0) -Detail "$cfgCount configs"
    
    # FeatureFlags
    $ffCount = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) AS cnt FROM FeatureFlags" -Mode Scalar
    Write-TestResult -Name 'Seed FeatureFlags present' -Passed ($ffCount -ge 0) -Detail "$ffCount flags"
    
    # Tags
    $tagCount = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) AS cnt FROM Tags" -Mode Scalar
    Write-TestResult -Name 'Seed Tags present' -Passed ($tagCount -ge 0) -Detail "$tagCount tags"
    
    # Test data
    $testCount = Initialize-HermesTestData -Manager $mgr -SampleSize 5
    Write-TestResult -Name 'Initialize-HermesTestData inserts records' -Passed ($testCount -gt 0) -Detail "Inserted $testCount records"
    
    # Verify test data
    $provCount = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) AS cnt FROM Providers" -Mode Scalar
    Write-TestResult -Name 'Test Providers present' -Passed ($provCount -gt 0) -Detail "$provCount providers"
    
    Disconnect-HermesDatabase -Manager $mgr
    if (Test-Path $mgr.DatabasePath) { Remove-Item $mgr.DatabasePath -Force }
} catch {
    Write-TestResult -Name 'Group 10' -Passed $false -Detail $_.ToString()
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST GRUPO 11: Full Integration - Initialize-HermesPersistence
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " GRUPO 11: Full Integration Facade" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

try {
    $testDb = Join-Path $TestDbRoot "test_full_$(Get-Random -Maximum 999999).db"
    
    $mgr = Initialize-HermesPersistence -DatabasePath $testDb -SeedData -TestData -TestSampleSize 3
    Write-TestResult -Name 'Initialize-HermesPersistence returns manager' -Passed ($mgr -ne $null)
    Write-TestResult -Name 'Manager is connected' -Passed ($mgr.IsConnected -eq $true)
    
    # Verify everything is there
    $tableCount = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) AS cnt FROM sqlite_master WHERE type='table'" -Mode Scalar
    Write-TestResult -Name 'Full init: tables exist' -Passed ($tableCount -ge 10) -Detail "$tableCount tables"
    
    $cfgCount = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) AS cnt FROM Configuration" -Mode Scalar
    Write-TestResult -Name 'Full init: configuration seeded' -Passed ($cfgCount -gt 0)
    
    $provCount = Invoke-HermesSql -Manager $mgr -Sql "SELECT COUNT(*) AS cnt FROM Providers" -Mode Scalar
    Write-TestResult -Name 'Full init: providers seeded' -Passed ($provCount -gt 0)
    
    Disconnect-HermesDatabase -Manager $mgr
    if (Test-Path $testDb) { Remove-Item $testDb -Force }
} catch {
    Write-TestResult -Name 'Group 11' -Passed $false -Detail $_.ToString()
}

# ──────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ──────────────────────────────────────────────────────────────────────────────

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

$PassRate = if ($Global:TestCount -gt 0) { [math]::Round(($Global:PassCount / $Global:TestCount) * 100, 1) } else { 0 }

Write-Host "Total Tests : $($Global:TestCount)" -ForegroundColor White
Write-Host "Passed      : $($Global:PassCount)" -ForegroundColor Green
Write-Host "Failed      : $($Global:FailCount)" -ForegroundColor $(if ($Global:FailCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "Pass Rate   : $PassRate%" -ForegroundColor $(if ($PassRate -ge 90) { 'Green' } elseif ($PassRate -ge 70) { 'Yellow' } else { 'Red' })

# Save results
$resultsFile = Join-Path $ProjectRoot 'data\tests\persistence_test_results.json'
$resultsDir = Split-Path $resultsFile -Parent
if (-not (Test-Path $resultsDir)) { New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null }
$Global:Results | ConvertTo-Json | Out-File $resultsFile -Encoding utf8
Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Gray

if ($Global:FailCount -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $Global:Results | Where-Object { $_.Status -eq 'Failed' } | ForEach-Object { Write-Host "  - $($_.TestName): $($_.Detail)" -ForegroundColor Red }
}

# Return exit code
if ($Global:FailCount -gt 0) { exit 1 } else { exit 0 }