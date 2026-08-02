# HermesPersistence.psm1
# Módulo de persistencia para Hermes Enterprise
# Proporciona acceso a SQLite mediante System.Data.SQLite

Set-StrictMode -Version 3

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 1: FUNCIONES DE GESTIÓN DE BASE DE DATOS
# ──────────────────────────────────────────────────────────────────────────────

function New-HermesDatabaseManager {
    [CmdletBinding()][OutputType([psobject])] param(
        [string]$DatabasePath = 'hermes.db'
    )
    $mgr = [pscustomobject]@{
        DatabasePath     = $DatabasePath
        Connection       = $null
        ConnectionString = "Data Source=$DatabasePath;Version=3;Pooling=True;Max Pool Size=100;"
        TotalQueries     = 0
        IsConnected      = $false
        ConnectionCount  = 0
        _Transaction     = $null
    }
    return $mgr
}

function Assert-HermesDatabaseConnection {
    [CmdletBinding()][OutputType([bool])] param([psobject]$Manager)
    if (-not $Manager.Connection -or -not $Manager.IsConnected) {
        throw "Database is not connected. Call Connect-HermesDatabase first."
    }
    Write-Verbose "Connection OK - TotalQueries: $($Manager.TotalQueries)"
    return $true
}

function Connect-HermesDatabase {
    [CmdletBinding()][OutputType([void])] param([psobject]$Manager)

    # ── Step 1: Resolve DLL path ──────────────────────────────────────────
    $resolvedPath = $null
    try {
        $asmPath = Join-Path $PSScriptRoot '..\..\lib\HermesSQLiteProvider.dll'
        $resolvedPath = Resolve-Path $asmPath -ErrorAction Stop
    }
    catch {
        Write-Host "[Connect-HermesDatabase][STEP1:ResolvePath] EXCEPTION" -ForegroundColor Red
        Write-Host "  Exception type: $($_.Exception.GetType().FullName)"
        Write-Host "  Message: $_"
        Write-Host "  InnerException: $($_.Exception.InnerException)"
        if ($_.Exception.InnerException) { Write-Host "  Inner StackTrace: $($_.Exception.InnerException.StackTrace)" }
        Write-Host "  StackTrace: $($_.ScriptStackTrace)"
        throw "Connect-HermesDatabase Step 1 (ResolvePath) failed: $_"
    }

    # ── Step 2: Load Assembly ─────────────────────────────────────────────
    $asm = $null
    try {
        $asm = [System.Reflection.Assembly]::LoadFrom($resolvedPath)
        if (-not $asm) {
            throw "Assembly::LoadFrom returned null"
        }
    }
    catch {
        Write-Host "[Connect-HermesDatabase][STEP2:LoadAssembly] EXCEPTION" -ForegroundColor Red
        Write-Host "  Exception type: $($_.Exception.GetType().FullName)"
        Write-Host "  Message: $_"
        if ($_.Exception.InnerException) {
            Write-Host "  InnerException type: $($_.Exception.InnerException.GetType().FullName)"
            Write-Host "  InnerException Message: $($_.Exception.InnerException.Message)"
            Write-Host "  Inner StackTrace: $($_.Exception.InnerException.StackTrace)"
            try { Write-Host "  FusionLog: $($_.Exception.InnerException.FusionLog)" } catch {}
        }
        Write-Host "  StackTrace: $($_.ScriptStackTrace)"
        throw "Connect-HermesDatabase Step 2 (LoadAssembly) failed: $_"
    }

    # ── Step 3: Get HermesSQLiteConnection type ───────────────────────────
    $connType = $null
    try {
        $connType = $asm.GetType('Hermes.Data.SQLite.HermesSQLiteConnection')
        if (-not $connType) {
            $exported = ($asm.GetExportedTypes() | ForEach-Object { $_.FullName }) -join ', '
            throw "Type 'Hermes.Data.SQLite.HermesSQLiteConnection' not found in assembly. Exported types: [$exported]"
        }
    }
    catch {
        Write-Host "[Connect-HermesDatabase][STEP3:GetType] EXCEPTION" -ForegroundColor Red
        Write-Host "  Exception type: $($_.Exception.GetType().FullName)"
        Write-Host "  Message: $_"
        Write-Host "  InnerException: $($_.Exception.InnerException)"
        if ($_.Exception.InnerException) { Write-Host "  Inner StackTrace: $($_.Exception.InnerException.StackTrace)" }
        Write-Host "  StackTrace: $($_.ScriptStackTrace)"
        throw "Connect-HermesDatabase Step 3 (GetType) failed: $_"
    }

    # ── Step 4: Create instance ──────────────────────────────────────────
    $conn = $null
    try {
        $conn = [Activator]::CreateInstance($connType, $Manager.ConnectionString)
        if (-not $conn) {
            throw "Activator::CreateInstance returned null for type $($connType.FullName) with connection string '$($Manager.ConnectionString)'"
        }
    }
    catch {
        Write-Host "[Connect-HermesDatabase][STEP4:Constructor] EXCEPTION" -ForegroundColor Red
        Write-Host "  Exception type: $($_.Exception.GetType().FullName)"
        Write-Host "  Message: $_"
        Write-Host "  InnerException: $($_.Exception.InnerException)"
        if ($_.Exception.InnerException) { Write-Host "  Inner StackTrace: $($_.Exception.InnerException.StackTrace)" }
        Write-Host "  StackTrace: $($_.ScriptStackTrace)"
        throw "Connect-HermesDatabase Step 4 (Constructor) failed: $_"
    }

    # ── Step 5: Open connection ──────────────────────────────────────────
    try {
        $conn.Open()
    }
    catch {
        Write-Host "[Connect-HermesDatabase][STEP5:OpenConnection] EXCEPTION" -ForegroundColor Red
        Write-Host "  Exception type: $($_.Exception.GetType().FullName)"
        Write-Host "  Message: $_"
        Write-Host "  InnerException: $($_.Exception.InnerException)"
        if ($_.Exception.InnerException) { Write-Host "  Inner StackTrace: $($_.Exception.InnerException.StackTrace)" }
        Write-Host "  StackTrace: $($_.ScriptStackTrace)"
        throw "Connect-HermesDatabase Step 5 (Open) failed: $_"
    }

    # ── Success ───────────────────────────────────────────────────────────
    $Manager.Connection = $conn
    $Manager.IsConnected = $true
    $Manager.ConnectionCount++
    Write-Verbose "Connected to $($Manager.DatabasePath)"
    return
}

function Disconnect-HermesDatabase {
    [CmdletBinding()][OutputType([void])] param([psobject]$Manager)
    if ($Manager.Connection -and $Manager.IsConnected) {
        try { $Manager.Connection.Close() } catch { }
        $Manager.Connection = $null
        $Manager.IsConnected = $false
        Write-Verbose "Disconnected"
    }
}

function Invoke-HermesSql {
    [CmdletBinding()] param(
        [psobject]$Manager,
        [string]$Sql,
        [hashtable]$Parameters = @{},
        [ValidateSet('NonQuery','Query','Scalar')][string]$Mode = 'NonQuery'
    )
    $null = Assert-HermesDatabaseConnection -Manager $Manager
    $Manager.TotalQueries++

    # WORKAROUND: HermesSQLiteProvider.dll has a bug where sqlite3_bind_text uses
    # IntPtr.Zero (SQLITE_STATIC) instead of SQLITE_TRANSIENT, causing string params
    # to bind from freed memory (stores null bytes). We inline string values directly
    # into SQL with proper single-quote escaping instead of using parameter binding.

    $inlineSql = $Sql
    # Process parameters in order of longest placeholder first to avoid substring collisions
    # e.g. "@ValueType" must be replaced before "@Value" since "@Value" is a substring of "@ValueType"
    $sortedKeys = $Parameters.Keys | ForEach-Object {
        if ($_.StartsWith('@')) { $_ } else { "@$_" }
    } | Sort-Object Length -Descending
    foreach ($placeholder in $sortedKeys) {
        $key = if ($placeholder.StartsWith('@')) { $placeholder } else { "@$placeholder" }
        $val = $Parameters[$key]
        if ($null -eq $val -or $val -eq [DBNull]::Value) {
            $inlineSql = $inlineSql.Replace($placeholder, 'NULL')
        } elseif ($val -is [string]) {
            $inlineSql = $inlineSql.Replace($placeholder, "'$($val.Trim().Replace("'","''"))'")
        } elseif ($val -is [int] -or $val -is [long] -or $val -is [int16] -or $val -is [byte]) {
            $inlineSql = $inlineSql.Replace($placeholder, "$val")
        } elseif ($val -is [double] -or $val -is [float] -or $val -is [decimal]) {
            $inlineSql = $inlineSql.Replace($placeholder, "$val".Replace(',', '.'))
        } elseif ($val -is [bool]) {
            $inlineSql = $inlineSql.Replace($placeholder, $(if ($val) { '1' } else { '0' }))
        } else {
            $inlineSql = $inlineSql.Replace($placeholder, "'$("$val".Replace("'","''"))'")
        }
    }

    $cmd = $Manager.Connection.CreateCommand()
    $cmd.CommandText = $inlineSql
    try {
        if ($Mode -eq 'NonQuery') {
            return $cmd.ExecuteNonQuery()
        }
        elseif ($Mode -eq 'Scalar') {
            $result = $cmd.ExecuteScalar()
            if ($null -eq $result -or $result -eq [DBNull]::Value) { return 0 }
            if ($result -is [string]) { return $result }
            if ($result -is [int]) { return $result }
            if ($result -is [long]) { return [int]$result }
            if ($result -is [double] -or $result -is [float] -or $result -is [decimal]) { return $result }
            return $result.ToString()
        }
        elseif ($Mode -eq 'Query') {
            $reader = $cmd.ExecuteReader()
            $dt = New-Object System.Data.DataTable
            [void]$dt.Load($reader)
            $reader.Close()
            return , $dt
        }
    }
    catch {
        throw "SQL error: $_ (sql: $Sql)"
    }
    finally {
        $cmd.Dispose()
    }
}

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 2: SCHEMA MANAGEMENT
# ──────────────────────────────────────────────────────────────────────────────

function Initialize-HermesSchema {
    [CmdletBinding()][OutputType([bool])] param([psobject]$Manager)
    $tables = @(
        "CREATE TABLE IF NOT EXISTS Configuration (
            Id TEXT PRIMARY KEY,
            Key TEXT NOT NULL UNIQUE,
            Value TEXT NOT NULL,
            ValueType TEXT NOT NULL CHECK(ValueType IN('String','Int','Bool','Json','Float','SecureString')),
            Category TEXT NOT NULL DEFAULT 'General',
            Description TEXT NOT NULL DEFAULT '',
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
            UpdatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS TelemetryEvents (
            Id TEXT PRIMARY KEY,
            EventName TEXT NOT NULL,
            Source TEXT NOT NULL DEFAULT 'System',
            Category TEXT NOT NULL DEFAULT 'Info',
            DataJson TEXT NOT NULL DEFAULT '{}',
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS Repositories (
            Id TEXT PRIMARY KEY,
            Name TEXT NOT NULL UNIQUE,
            Type TEXT NOT NULL CHECK(Type IN('Git','Local','S3','AzureBlob','Custom')),
            ConnectionString TEXT NOT NULL DEFAULT '',
            ConfigJson TEXT NOT NULL DEFAULT '{}',
            IsActive INTEGER NOT NULL DEFAULT 1,
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
            UpdatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS Sessions (
            Id TEXT PRIMARY KEY,
            SessionName TEXT NOT NULL,
            SessionType TEXT NOT NULL CHECK(SessionType IN('Development','Production','Testing','Maintenance')),
            Status TEXT NOT NULL CHECK(Status IN('Active','Inactive','Closed','Archived','Completed')),
            StartTime TEXT NOT NULL DEFAULT (datetime('now')),
            EndTime TEXT,
            MaxMemoryMB INTEGER NOT NULL DEFAULT 1024,
            TimeoutMinutes INTEGER NOT NULL DEFAULT 60,
            UserName TEXT NOT NULL DEFAULT '',
            ConfigJson TEXT NOT NULL DEFAULT '{}',
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
            UpdatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS ExecutionLog (
            Id TEXT PRIMARY KEY,
            SessionId TEXT NOT NULL REFERENCES Sessions(Id),
            EventType TEXT NOT NULL CHECK(EventType IN('Info','Warning','Error','Debug','Critical')),
            Module TEXT NOT NULL,
            Action TEXT NOT NULL,
            Message TEXT NOT NULL DEFAULT '',
            DataJson TEXT NOT NULL DEFAULT '{}',
            DurationMs INTEGER NOT NULL DEFAULT 0,
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS BackupHistory (
            Id TEXT PRIMARY KEY,
            FileName TEXT NOT NULL,
            FilePath TEXT NOT NULL,
            FileSizeBytes INTEGER NOT NULL DEFAULT 0,
            BackupType TEXT NOT NULL CHECK(BackupType IN('Full','Incremental','Differential','Snapshot')),
            Status TEXT NOT NULL CHECK(Status IN('Success','Failed','InProgress')),
            Checksum TEXT NOT NULL DEFAULT '',
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
            CompletedAt TEXT
        )",
        "CREATE TABLE IF NOT EXISTS Snapshots (
            Id TEXT PRIMARY KEY,
            SnapshotName TEXT NOT NULL,
            Description TEXT NOT NULL DEFAULT '',
            DataJson TEXT NOT NULL DEFAULT '{}',
            Version INTEGER NOT NULL DEFAULT 1,
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS SchemaVersion (
            Version INTEGER PRIMARY KEY,
            AppliedAt TEXT NOT NULL DEFAULT (datetime('now')),
            Description TEXT NOT NULL DEFAULT '',
            Status TEXT NOT NULL DEFAULT 'Executed'
        )",
        "CREATE TABLE IF NOT EXISTS NotificationHistory (
            Id TEXT PRIMARY KEY,
            Title TEXT NOT NULL,
            Message TEXT NOT NULL,
            NotificationType TEXT NOT NULL CHECK(NotificationType IN('Info','Warning','Error','Success')),
            Source TEXT NOT NULL DEFAULT 'System',
            IsRead INTEGER NOT NULL DEFAULT 0,
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS AuditLog (
            Id TEXT PRIMARY KEY,
            Accion TEXT NOT NULL,
            EntityType TEXT NOT NULL,
            EntityId TEXT NOT NULL DEFAULT '',
            UserName TEXT NOT NULL DEFAULT 'system',
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS Tags (
            Id TEXT PRIMARY KEY,
            Name TEXT NOT NULL UNIQUE,
            Color TEXT NOT NULL DEFAULT 'gray',
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS FeatureFlags (
            Id TEXT PRIMARY KEY,
            Name TEXT NOT NULL UNIQUE,
            IsEnabled INTEGER NOT NULL DEFAULT 0,
            Description TEXT NOT NULL DEFAULT '',
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS Providers (
            Id TEXT PRIMARY KEY,
            Name TEXT NOT NULL UNIQUE,
            ProviderType TEXT NOT NULL CHECK(ProviderType IN('Cloud','Local','Hybrid','External')),
            Status TEXT NOT NULL CHECK(Status IN('Running','Stopped','Error','Starting','Stopping')),
            Description TEXT NOT NULL DEFAULT '',
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
            UpdatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS Metrics (
            Id TEXT PRIMARY KEY,
            MetricName TEXT NOT NULL,
            MetricValue REAL NOT NULL,
            Unit TEXT NOT NULL DEFAULT '',
            Source TEXT NOT NULL DEFAULT 'system',
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )"
    )
    foreach ($sql in $tables) {
        $null = Invoke-HermesSql -Manager $Manager -Sql $sql -Mode NonQuery
    }
    Write-Verbose "Schema initialized"
    return $true
}

function Initialize-HermesSeedData {
    [CmdletBinding()][OutputType([void])] param([psobject]$Manager)
    $configs = @(
        @{Id='cfg_sys_001'; Key='system.version'; Value='1.0.0'; ValueType='String'; Category='System'; Description='System version'},
        @{Id='cfg_sys_002'; Key='system.name'; Value='Hermes Enterprise'; ValueType='String'; Category='System'; Description='System name'},
        @{Id='cfg_sys_003'; Key='system.debug'; Value='false'; ValueType='Bool'; Category='System'; Description='Debug mode'},
        @{Id='cfg_sys_004'; Key='system.env'; Value='production'; ValueType='String'; Category='System'; Description='Environment'},
        @{Id='cfg_log_001'; Key='log.level'; Value='Info'; ValueType='String'; Category='Logging'; Description='Log level'},
        @{Id='cfg_log_002'; Key='log.retention'; Value='30'; ValueType='Int'; Category='Logging'; Description='Log retention days'},
        @{Id='cfg_perf_001'; Key='performance.maxThreads'; Value='4'; ValueType='Int'; Category='Performance'; Description='Max threads'},
        @{Id='cfg_perf_002'; Key='performance.timeout'; Value='5000'; ValueType='Int'; Category='Performance'; Description='Timeout ms'},
        @{Id='cfg_sec_001'; Key='security.maxAttempts'; Value='3'; ValueType='Int'; Category='Security'; Description='Max login attempts'},
        @{Id='cfg_sec_002'; Key='security.tokenExpiry'; Value='3600'; ValueType='Int'; Category='Security'; Description='Token expiry seconds'}
    )
    foreach ($c in $configs) {
        try {
            $null = Invoke-HermesSql -Manager $Manager -Sql "INSERT OR IGNORE INTO Configuration (Id, Key, Value, ValueType, Category, Description) VALUES (@Id, @Key, @Value, @ValueType, @Category, @Description)" -Parameters @{
                '@Id' = $c.Id; '@Key' = $c.Key; '@Value' = $c.Value; '@ValueType' = $c.ValueType; '@Category' = $c.Category; '@Description' = $c.Description
            }
        } catch { Write-Warning "Seed config '$($c.Key)': $_" }
    }
    # Seed session
    try {
        $null = Invoke-HermesSql -Manager $Manager -Sql "INSERT OR IGNORE INTO Sessions (Id, SessionName, SessionType, Status) VALUES (@Id, @Name, @Type, @Status)" -Parameters @{
            '@Id' = 'seed_session_001'; '@Name' = 'Default Session'; '@Type' = 'Development'; '@Status' = 'Active'
        }
    } catch { Write-Warning "Seed session: $_" }
    Write-Verbose "Seed data initialized"
}

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 3: REPOSITORY BASE
# ──────────────────────────────────────────────────────────────────────────────

function New-HermesRepositoryBase {
    [CmdletBinding()][OutputType([psobject])] param(
        [psobject]$Manager,
        [string]$TableName,
        [string]$IdColumn = 'Id',
        [string[]]$Columns = @('*')
    )
    $base = [pscustomobject]@{
        Manager   = $Manager
        TableName = $TableName
        IdColumn  = $IdColumn
        Columns   = $Columns
    }
    # Insert
    $base | Add-Member -MemberType ScriptMethod -Name Insert -Force -Value { param([hashtable]$data)
        $cols = ($data.Keys | ForEach-Object { "[$_]" }) -join ', '
        $vals = ($data.Keys | ForEach-Object { "@$_" }) -join ', '
        $params = @{}; foreach ($k in $data.Keys) { $params["@$k"] = $data[$k] }
        $null = Invoke-HermesSql -Manager $this.Manager -Sql "INSERT INTO [$($this.TableName)] ($cols) VALUES ($vals)" -Parameters $params
    }
    # Update
    $base | Add-Member -MemberType ScriptMethod -Name Update -Force -Value { param([string]$id, [hashtable]$data)
        $sets = ($data.Keys | ForEach-Object { "[$_] = @$_" }) -join ', '
        $params = @{}; foreach ($k in $data.Keys) { $params["@$k"] = $data[$k] }
        $params["@id"] = $id
        $null = Invoke-HermesSql -Manager $this.Manager -Sql "UPDATE [$($this.TableName)] SET $sets WHERE [$($this.IdColumn)] = @id" -Parameters $params
    }
    # Delete
    $base | Add-Member -MemberType ScriptMethod -Name Delete -Force -Value { param([string]$id)
        $null = Invoke-HermesSql -Manager $this.Manager -Sql "DELETE FROM [$($this.TableName)] WHERE [$($this.IdColumn)] = @id" -Parameters @{ '@id' = $id }
    }
    # GetById (reconstructed DataTable)
    $base | Add-Member -MemberType ScriptMethod -Name GetById -Force -Value { param([string]$id)
        $sql = "SELECT * FROM [$($this.TableName)] WHERE [$($this.IdColumn)] = @id"
        $rows = @(Invoke-HermesSql -Manager $this.Manager -Sql $sql -Parameters @{ '@id' = $id } -Mode Query)
        if ($rows.Count -eq 0) {
            $dt = New-Object System.Data.DataTable
        } elseif ($rows[0] -is [System.Data.DataTable]) {
            $dt = [System.Data.DataTable]$rows[0]
        } else {
            $dt = $rows[0].Table.Clone()
            foreach ($r in $rows) { [void]$dt.Rows.Add($r.ItemArray) }
        }
        return , $dt
    }
    # GetAll (reconstructed DataTable)
    $base | Add-Member -MemberType ScriptMethod -Name GetAll -Force -Value {
        $rows = @(Invoke-HermesSql -Manager $this.Manager -Sql "SELECT * FROM [$($this.TableName)]" -Mode Query)
        if ($rows.Count -eq 0) {
            $dt = New-Object System.Data.DataTable
        } elseif ($rows[0] -is [System.Data.DataTable]) {
            $dt = [System.Data.DataTable]$rows[0]
        } else {
            $dt = $rows[0].Table.Clone()
            foreach ($r in $rows) { [void]$dt.Rows.Add($r.ItemArray) }
        }
        return , $dt
    }
    # Count
    $base | Add-Member -MemberType ScriptMethod -Name Count -Force -Value {
        return (Invoke-HermesSql -Manager $this.Manager -Sql "SELECT COUNT(*) AS cnt FROM [$($this.TableName)]" -Mode Scalar)
    }
    # Exists
    $base | Add-Member -MemberType ScriptMethod -Name Exists -Force -Value { param([string]$id)
        $result = Invoke-HermesSql -Manager $this.Manager -Sql "SELECT COUNT(*) AS cnt FROM [$($this.TableName)] WHERE [$($this.IdColumn)] = @id" -Parameters @{ '@id' = $id } -Mode Scalar
        return ($result -gt 0)
    }
    return $base
}

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 4: SQLITE REPOSITORY BUILDER
# ──────────────────────────────────────────────────────────────────────────────

function New-SQLiteRepository {
    [CmdletBinding()][OutputType([psobject])] param(
        [psobject]$Manager,
        [string]$TableName,
        [string]$IdColumn = 'Id',
        [string[]]$Columns = @('*'),
        [hashtable]$CustomMethods = @{}
    )
    $repo = New-HermesRepositoryBase -Manager $Manager -TableName $TableName -IdColumn $IdColumn -Columns $Columns

    # Copy custom methods - explicitly recreate them to avoid ScriptMethod enumeration issues
    foreach ($methodName in $CustomMethods.Keys) {
        $scriptBlock = $CustomMethods[$methodName]
        if ($methodName -eq 'Exists') {
            # Exists is already defined in base, but can be overridden
            $repo | Add-Member -MemberType ScriptMethod -Name $methodName -Force -Value $scriptBlock
        } elseif ($methodName -in @('GetById', 'GetAll', 'Query')) {
            # Query methods need DataTable reconstruction
            $wrapper = {
                param([string]$id = $null, [string]$sql = $null, [hashtable]$params = @{})
                $result = @(& $scriptBlock -Manager $this.Manager -Sql $sql -Parameters $params -Mode Query 2>$null)
                # If we got here, custom method already handled it
                return $result
            }.GetNewClosure()
            # Since the closure doesn't work well with ScriptMethod, just use the original ScriptBlock
            $repo | Add-Member -MemberType ScriptMethod -Name $methodName -Force -Value $scriptBlock
        } else {
            $repo | Add-Member -MemberType ScriptMethod -Name $methodName -Force -Value $scriptBlock
        }
    }

    $repo.PSObject.TypeNames.Insert(0, "Hermes.$TableName")
    return $repo
}

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 5: REPOSITORIOS DE DOMINIO
# ──────────────────────────────────────────────────────────────────────────────

function New-ConfigurationRepository {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    return New-SQLiteRepository -Manager $Manager -TableName 'Configuration' -IdColumn 'Id' -Columns @('Id','Key','Value','ValueType','Category','Description','CreatedAt','UpdatedAt')
}

function New-TelemetryRepository {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    return New-SQLiteRepository -Manager $Manager -TableName 'TelemetryEvents' -IdColumn 'Id' -Columns @('Id','EventName','Source','Category','DataJson','CreatedAt')
}

function New-SessionRepository {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    return New-SQLiteRepository -Manager $Manager -TableName 'Sessions' -IdColumn 'Id' -Columns @('Id','SessionName','SessionType','Status','StartTime','EndTime','MaxMemoryMB','TimeoutMinutes','ConfigJson','CreatedAt','UpdatedAt')
}

function New-ExecutionLogRepository {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    return New-SQLiteRepository -Manager $Manager -TableName 'ExecutionLog' -IdColumn 'Id' -Columns @('Id','SessionId','EventType','Module','Action','Message','DataJson','DurationMs','CreatedAt')
}

function New-BackupRepository {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    return New-SQLiteRepository -Manager $Manager -TableName 'BackupHistory' -IdColumn 'Id' -Columns @('Id','FileName','FilePath','FileSizeBytes','BackupType','Status','Checksum','CreatedAt','CompletedAt')
}

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 6: FUNCIONES DE RESPALDO
# ──────────────────────────────────────────────────────────────────────────────

function Backup-HermesDatabase {
    [CmdletBinding()][OutputType([psobject])] param(
        [psobject]$Manager,
        [string]$BackupPath,
        [ValidateSet('Full','Incremental','Differential','Snapshot')][string]$BackupType = 'Full'
    )
    $null = Assert-HermesDatabaseConnection -Manager $Manager

    $backupId = [guid]::NewGuid().ToString()
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $fileName = "hermes_backup_${timestamp}_${BackupType}.db"
    if (-not $BackupPath) { $BackupPath = Split-Path $Manager.DatabasePath -Parent }
    $fullPath = Join-Path $BackupPath $fileName

    try {
        # Ensure backup directory exists
        $backupDir = Split-Path $fullPath -Parent
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }

        if ($BackupType -eq 'Full') {
            # Clone database connection and backup using VACUUM INTO approach
            # Since HermesSQLiteConnection doesn't have BackupDatabase, use manual copy with lock prevention
            $Manager.Connection.Close()
            Copy-Item -Path $Manager.DatabasePath -Destination $fullPath -Force
            $Manager.Connection.Open()
        }
        else {
            Copy-Item -Path $Manager.DatabasePath -Destination $fullPath -Force
        }

        $fileInfo = Get-Item $fullPath
        $checksum = if (Get-Command Get-FileHash -ErrorAction SilentlyContinue) {
            (Get-FileHash $fullPath -Algorithm SHA256).Hash
        } else { '' }

        $result = [pscustomobject]@{
            Id = $backupId
            FileName = $fileName
            FilePath = $fullPath
            FileSizeBytes = $fileInfo.Length
            BackupType = $BackupType
            Status = 'Success'
            Checksum = $checksum
            CreatedAt = (Get-Date -Format 'o')
            CompletedAt = (Get-Date -Format 'o')
        }

        $repo = New-BackupRepository -Manager $Manager
        try {
            $repo.Insert(@{
                Id = $backupId
                FileName = $fileName
                FilePath = $fullPath
                FileSizeBytes = $fileInfo.Length
                BackupType = $BackupType
                Status = 'Success'
                Checksum = $checksum
            })
        } catch { Write-Warning "Could not save backup record: $_" }

        return $result
    }
    catch {
        throw "Backup failed: $_"
    }
}

function Restore-HermesDatabase {
    [CmdletBinding()][OutputType([void])] param(
        [psobject]$Manager,
        [string]$BackupFilePath
    )
    $null = Assert-HermesDatabaseConnection -Manager $Manager
    if (-not (Test-Path $BackupFilePath)) { throw "Backup file not found: $BackupFilePath" }
    try {
        Disconnect-HermesDatabase -Manager $Manager
        Copy-Item -Path $BackupFilePath -Destination $Manager.DatabasePath -Force
        Connect-HermesDatabase -Manager $Manager
        Write-Verbose "Restored from $BackupFilePath"
    }
    catch {
        throw "Restore failed: $_"
    }
}

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 7: FUNCIONES DE TELEMETRÍA Y CONSULTA
# ──────────────────────────────────────────────────────────────────────────────

function Get-HermesTelemetry {
    [CmdletBinding()][OutputType([System.Data.DataTable])] param(
        [psobject]$Manager,
        [string]$Source = '*',
        [string]$Category = '*',
        [string]$EventName = '*',
        [string]$DateFrom = '',
        [string]$DateTo = '',
        [int]$Limit = 100
    )
    $conditions = @()
    $params = @{}
    if ($Source -and $Source -ne '*') { $conditions += "Source = @source"; $params['@source'] = $Source }
    if ($Category -and $Category -ne '*') { $conditions += "Category = @category"; $params['@category'] = $Category }
    if ($EventName -and $EventName -ne '*') { $conditions += "EventName LIKE @event"; $params['@event'] = "%$EventName%" }
    if ($DateFrom) { $conditions += "CreatedAt >= @dateFrom"; $params['@dateFrom'] = $DateFrom }
    if ($DateTo) { $conditions += "CreatedAt <= @dateTo"; $params['@dateTo'] = $DateTo }
    $where = if ($conditions.Count -gt 0) { "WHERE $($conditions -join ' AND ')" } else { '' }
    $params['@limit'] = $Limit
    return Invoke-HermesSql -Manager $Manager -Sql "SELECT * FROM TelemetryEvents $where ORDER BY CreatedAt DESC LIMIT @limit" -Parameters $params -Mode Query
}

function Register-HermesTelemetryEvent {
    [CmdletBinding()][OutputType([string])] param(
        [psobject]$Manager,
        [string]$EventName,
        [string]$Source = 'System',
        [string]$Category = 'Info',
        [string]$DataJson = '{}'
    )
    $id = [guid]::NewGuid().ToString()
    $repo = New-TelemetryRepository -Manager $Manager
    $repo.Insert(@{ Id = $id; EventName = $EventName; Source = $Source; Category = $Category; DataJson = $DataJson })
    return $id
}

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 8: FUNCIONES DE TEST Y DIAGNÓSTICO
# ──────────────────────────────────────────────────────────────────────────────

function Test-HermesDatabaseConnection {
    [CmdletBinding()][OutputType([bool])] param([psobject]$Manager)
    if (-not $Manager.Connection -or -not $Manager.IsConnected) { return $false }
    try {
        $cmd = $Manager.Connection.CreateCommand()
        $cmd.CommandText = 'SELECT 1'
        $result = $cmd.ExecuteScalar()
        $cmd.Dispose()
        return ($null -ne $result)
    } catch { return $false }
}

function Start-HermesDatabaseTransaction {
    [CmdletBinding()][OutputType([void])] param([psobject]$Manager)
    $null = Assert-HermesDatabaseConnection -Manager $Manager
    $Manager._Transaction = $Manager.Connection.BeginTransaction()
}

function Undo-HermesDatabaseTransaction {
    [CmdletBinding()][OutputType([void])] param([psobject]$Manager)
    if ($Manager._Transaction) {
        try { $Manager._Transaction.Rollback() } catch { }
        try { $Manager._Transaction.Dispose() } catch { }
        $Manager._Transaction = $null
    }
}

function New-ProviderRepository {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    return New-SQLiteRepository -Manager $Manager -TableName 'Providers' -IdColumn 'Id' -Columns @('Id','Name','ProviderType','Status','Description','CreatedAt','UpdatedAt') -CustomMethods @{
        'GetByStatus' = { param([string]$status) return Invoke-HermesSql -Manager $this.Manager -Sql "SELECT * FROM Providers WHERE Status = @status" -Parameters @{ '@status' = $status } -Mode Query }
    }
}

function New-ExecutionRepository {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    return New-SQLiteRepository -Manager $Manager -TableName 'ExecutionLog' -IdColumn 'Id' -Columns @('Id','SessionId','EventType','Module','Action','Message','DataJson','DurationMs','CreatedAt') -CustomMethods @{
        'GetByStatus' = { param([string]$status) return Invoke-HermesSql -Manager $this.Manager -Sql "SELECT * FROM ExecutionLog WHERE EventType = @status" -Parameters @{ '@status' = $status } -Mode Query }
        'GetByCorrelationId' = { param([string]$corrId) return Invoke-HermesSql -Manager $this.Manager -Sql "SELECT * FROM ExecutionLog WHERE SessionId = @sid" -Parameters @{ '@sid' = $corrId } -Mode Query }
        'GetFailed' = { return Invoke-HermesSql -Manager $this.Manager -Sql "SELECT * FROM ExecutionLog WHERE EventType IN ('Error','Critical')" -Mode Query }
    }
}

function New-ConfigurationRepository {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    return New-SQLiteRepository -Manager $Manager -TableName 'Configuration' -IdColumn 'Id' -Columns @('Id','Key','Value','ValueType','Category','Description','CreatedAt','UpdatedAt') -CustomMethods @{
        'GetByKey' = { param([string]$key) return Invoke-HermesSql -Manager $this.Manager -Sql "SELECT * FROM Configuration WHERE Key = @key" -Parameters @{ '@key' = $key } -Mode Query }
    }
}

function New-NotificationRepository {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    return New-SQLiteRepository -Manager $Manager -TableName 'NotificationHistory' -IdColumn 'Id' -Columns @('Id','Title','Message','NotificationType','Source','IsRead','CreatedAt') -CustomMethods @{
        'GetUnread' = { return Invoke-HermesSql -Manager $this.Manager -Sql "SELECT * FROM NotificationHistory WHERE IsRead = 0" -Mode Query }
        'MarkAsRead' = { param([string]$id) $null = Invoke-HermesSql -Manager $this.Manager -Sql "UPDATE NotificationHistory SET IsRead = 1 WHERE Id = @id" -Parameters @{ '@id' = $id } }
    }
}

function New-MetricsRepository {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    return New-SQLiteRepository -Manager $Manager -TableName 'Metrics' -IdColumn 'Id' -Columns @('Id','MetricName','MetricValue','Unit','Source','CreatedAt') -CustomMethods @{
        'RecordMetric' = { param([string]$name, [double]$value, [string]$unit, [string]$source)
            $this.Insert(@{ Id = [guid]::NewGuid().ToString(); MetricName = $name; MetricValue = $value; Unit = $unit; Source = $source })
        }
        'GetRecent' = { param([string]$name, [int]$minutes)
            return Invoke-HermesSql -Manager $this.Manager -Sql "SELECT * FROM Metrics WHERE MetricName = @name AND CreatedAt >= datetime('now','-$minutes minutes') ORDER BY CreatedAt DESC" -Parameters @{ '@name' = $name } -Mode Query
        }
    }
}

function New-AuditRepository {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    return New-SQLiteRepository -Manager $Manager -TableName 'AuditLog' -IdColumn 'Id' -Columns @('Id','Accion','EntityType','EntityId','UserName','CreatedAt') -CustomMethods @{
        'GetByUser' = { param([string]$user) return Invoke-HermesSql -Manager $this.Manager -Sql "SELECT * FROM AuditLog WHERE UserName = @user" -Parameters @{ '@user' = $user } -Mode Query }
    }
}

function Test-HermesSystemHealth {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager, [switch]$Detailed)
    $null = Assert-HermesDatabaseConnection -Manager $Manager
    $checks = [System.Collections.ArrayList]@()
    $overall = 'Healthy'
    
    # Check 1: Connection
    try {
        Test-HermesDatabaseConnection -Manager $Manager | Out-Null
        [void]$checks.Add([pscustomobject]@{ Check = 'Connection'; Status = 'Healthy'; Detail = '' })
    } catch {
        $overall = 'Degraded'
        [void]$checks.Add([pscustomobject]@{ Check = 'Connection'; Status = 'Degraded'; Detail = $_.Message })
    }
    
    # Check 2: Schema
    try {
        $tables = Invoke-HermesSql -Manager $Manager -Sql "SELECT COUNT(*) AS cnt FROM sqlite_master WHERE type='table'" -Mode Scalar
        [void]$checks.Add([pscustomobject]@{ Check = 'Schema'; Status = 'Healthy'; Detail = "$tables tables" })
    } catch {
        $overall = 'Degraded'
        [void]$checks.Add([pscustomobject]@{ Check = 'Schema'; Status = 'Degraded'; Detail = $_.Message })
    }
    
    # Check 3: Integrity (PRAGMA)
    try {
        $integrity = Invoke-HermesSql -Manager $Manager -Sql "PRAGMA integrity_check" -Mode Scalar
        if ($integrity -eq 'ok') {
            [void]$checks.Add([pscustomobject]@{ Check = 'Integrity'; Status = 'Healthy'; Detail = 'ok' })
        } else {
            $overall = 'Degraded'
            [void]$checks.Add([pscustomobject]@{ Check = 'Integrity'; Status = 'Degraded'; Detail = $integrity })
        }
    } catch {
        [void]$checks.Add([pscustomobject]@{ Check = 'Integrity'; Status = 'Unknown'; Detail = $_.Message })
    }
    
    return [pscustomobject]@{
        OverallStatus = $overall
        Checks = $checks
    }
}

function Get-HermesDatabaseStats {
    [CmdletBinding()][OutputType([psobject])] param([psobject]$Manager)
    $null = Assert-HermesDatabaseConnection -Manager $Manager
    $totalTables = Invoke-HermesSql -Manager $Manager -Sql "SELECT COUNT(*) AS cnt FROM sqlite_master WHERE type='table'" -Mode Scalar
    $totalViews = Invoke-HermesSql -Manager $Manager -Sql "SELECT COUNT(*) AS cnt FROM sqlite_master WHERE type='view'" -Mode Scalar
    $fileSize = if (Test-Path $Manager.DatabasePath) { (Get-Item $Manager.DatabasePath).Length } else { 0 }
    return [pscustomobject]@{
        TotalTables = [int]$totalTables
        TotalViews = [int]$totalViews
        FileSizeBytes = $fileSize
        TotalQueries = $Manager.TotalQueries
    }
}

function Optimize-HermesDatabase {
    [CmdletBinding()][OutputType([array])] param([psobject]$Manager, [switch]$Analyze, [switch]$Vacuum)
    $null = Assert-HermesDatabaseConnection -Manager $Manager
    $results = [System.Collections.ArrayList]@()
    
    if ($Analyze -or (-not $Vacuum)) {
        try {
            Invoke-HermesSql -Manager $Manager -Sql "ANALYZE" -Mode NonQuery | Out-Null
            [void]$results.Add([pscustomobject]@{ Operation = 'ANALYZE'; Status = 'Completed' })
        } catch {
            [void]$results.Add([pscustomobject]@{ Operation = 'ANALYZE'; Status = 'Failed'; Error = $_.Message })
        }
    }
    
    if ($Vacuum) {
        try {
            Invoke-HermesSql -Manager $Manager -Sql "VACUUM" -Mode NonQuery | Out-Null
            [void]$results.Add([pscustomobject]@{ Operation = 'VACUUM'; Status = 'Completed' })
        } catch {
            [void]$results.Add([pscustomobject]@{ Operation = 'VACUUM'; Status = 'Failed'; Error = $_.Message })
        }
    }
    
    return , [array]$results.ToArray()
}

function Get-HermesBackupHistory {
    [CmdletBinding()][OutputType([System.Data.DataTable])] param([psobject]$Manager)
    return Invoke-HermesSql -Manager $Manager -Sql "SELECT * FROM BackupHistory ORDER BY CreatedAt DESC" -Mode Query
}

function Register-HermesMigration {
    [CmdletBinding()][OutputType([bool])] param(
        [psobject]$Manager,
        [int]$Version,
        [string]$Description = ''
    )
    try {
        # Check if migration already exists
        $existing = Invoke-HermesSql -Manager $Manager -Sql "SELECT COUNT(*) AS cnt FROM SchemaVersion WHERE Version = @v" -Parameters @{ '@v' = $Version } -Mode Scalar
        if ($existing -gt 0) {
            Write-Verbose "Migration v$Version already applied"
            return $true
        }
        $null = Invoke-HermesSql -Manager $Manager -Sql "INSERT INTO SchemaVersion (Version, Description, Status) VALUES (@v, @desc, 'Executed')" -Parameters @{ '@v' = $Version; '@desc' = $Description }
        Write-Verbose "Migration v$Version registered: $Description"
        return $true
    }
    catch {
        Write-Warning "Register-HermesMigration v$Version failed: $_"
        return $false
    }
}

function Send-HermesTelemetry {
    [CmdletBinding()][OutputType([void])] param(
        [psobject]$Manager,
        [string]$EventName,
        [string]$Source = 'System',
        [hashtable]$Properties = @{},
        [hashtable]$Measurements = @{},
        [string[]]$Tags = @()
    )
    $data = [pscustomobject]@{ Properties = $Properties; Measurements = $Measurements; Tags = $Tags } | ConvertTo-Json -Compress
    $null = Register-HermesTelemetryEvent -Manager $Manager -EventName $EventName -Source $Source -Category 'Info' -DataJson $data
}

function Initialize-HermesTestData {
    [CmdletBinding()][OutputType([int])] param([psobject]$Manager, [int]$SampleSize = 3)
    $count = 0
    for ($i = 1; $i -le $SampleSize; $i++) {
        try {
            Invoke-HermesSql -Manager $Manager -Sql "INSERT OR IGNORE INTO Providers (Id, Name, ProviderType, Status, Description) VALUES (@Id, @Name, @Type, @Status, @Desc)" -Parameters @{
                '@Id' = "test_prov_$i"; '@Name' = "TestProvider$i"; '@Type' = @('Cloud','Local','Hybrid')[$i % 3]; '@Status' = @('Running','Stopped','Error')[$i % 3]; '@Desc' = "Test provider $i"
            } | Out-Null
            $count++
        } catch {}
    }
    return $count
}

function Initialize-HermesPersistence {
    [CmdletBinding()][OutputType([psobject])] param(
        [string]$DatabasePath,
        [switch]$SeedData,
        [switch]$TestData,
        [int]$TestSampleSize = 5
    )
    $manager = New-HermesDatabaseManager -DatabasePath $DatabasePath
    $null = Connect-HermesDatabase -Manager $manager
    $null = Initialize-HermesSchema -Manager $manager
    if ($SeedData) { Initialize-HermesSeedData -Manager $manager | Out-Null }
    if ($TestData) { Initialize-HermesTestData -Manager $manager -SampleSize $TestSampleSize | Out-Null }
    , $manager
}

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 9: EXPORTS
# ──────────────────────────────────────────────────────────────────────────────

Export-ModuleMember -Function @(
    'New-HermesDatabaseManager',
    'Assert-HermesDatabaseConnection',
    'Connect-HermesDatabase',
    'Disconnect-HermesDatabase',
    'Invoke-HermesSql',
    'Test-HermesDatabaseConnection',
    'Start-HermesDatabaseTransaction',
    'Undo-HermesDatabaseTransaction',
    'Initialize-HermesSchema',
    'Initialize-HermesSeedData',
    'Initialize-HermesTestData',
    'Initialize-HermesPersistence',
    'New-HermesRepositoryBase',
    'New-SQLiteRepository',
    'New-ConfigurationRepository',
    'New-TelemetryRepository',
    'New-SessionRepository',
    'New-ExecutionLogRepository',
    'New-BackupRepository',
    'New-ProviderRepository',
    'New-ExecutionRepository',
    'New-NotificationRepository',
    'New-MetricsRepository',
    'New-AuditRepository',
    'Backup-HermesDatabase',
    'Restore-HermesDatabase',
    'Get-HermesTelemetry',
    'Register-HermesTelemetryEvent',
    'Send-HermesTelemetry',
    'Test-HermesSystemHealth',
    'Get-HermesDatabaseStats',
    'Optimize-HermesDatabase',
    'Get-HermesBackupHistory',
    'Register-HermesMigration'
)
