<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : HermesPersistence.psm1
Propósito:
    Módulo de persistencia para Hermes Enterprise.
    Proporciona acceso a SQLite mediante:
      1. HermesSQLiteProvider.dll (preferido)
      2. sqlite3 CLI fallback (cuando el DLL no está disponible)
====================================================================================================
#>

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
        UseCliFallback   = $false  # true when using sqlite3 CLI instead of DLL
    }
    return $mgr
}

function Assert-HermesDatabaseConnection {
    [CmdletBinding()][OutputType([bool])] param([psobject]$Manager)
    if (-not $Manager.IsConnected) {
        throw "Database is not connected. Call Connect-HermesDatabase first."
    }
    Write-Verbose "Connection OK - TotalQueries: $($Manager.TotalQueries)"
    return $true
}

function Connect-HermesDatabase {
    [CmdletBinding()][OutputType([void])] param([psobject]$Manager)

    # ── Step 1: Ensure directory exists ─────────────────────────────────────
    $dbDir = Split-Path $Manager.DatabasePath -Parent
    if ($dbDir -and -not (Test-Path $dbDir)) {
        New-Item -ItemType Directory -Path $dbDir -Force | Out-Null
    }

    # ── Try HermesSQLiteProvider.dll first ──────────────────────────────────
    $asmPath = Join-Path $PSScriptRoot '..\..\lib\HermesSQLiteProvider.dll'
    if (Test-Path $asmPath) {
        try {
            $resolvedPath = Resolve-Path $asmPath -ErrorAction Stop
            $asm = [System.Reflection.Assembly]::LoadFrom($resolvedPath)
            if ($asm) {
                $connType = $asm.GetType('Hermes.Data.SQLite.HermesSQLiteConnection')
                if ($connType) {
                    $conn = [Activator]::CreateInstance($connType, $Manager.ConnectionString)
                    if ($conn) {
                        $conn.Open()
                        $Manager.Connection = $conn
                        $Manager.IsConnected = $true
                        $Manager.ConnectionCount++
                        $Manager.UseCliFallback = $false
                        Write-Verbose "Connected to $($Manager.DatabasePath) via HermesSQLiteProvider.dll"
                        return
                    }
                }
            }
        }
        catch {
            Write-Warning "HermesSQLiteProvider.dll load failed: $_"
        }
    }

    # ── Fallback: sqlite3 CLI ───────────────────────────────────────────────
    $sqliteExe = Get-Command sqlite3 -ErrorAction SilentlyContinue
    if (-not $sqliteExe) {
        throw "Neither HermesSQLiteProvider.dll nor sqlite3 CLI are available. Install sqlite3 or build HermesSQLiteProvider.dll."
    }

    $Manager.IsConnected = $true
    $Manager.ConnectionCount++
    $Manager.UseCliFallback = $true
    Write-Verbose "Connected to $($Manager.DatabasePath) via sqlite3 CLI fallback"
}

function Disconnect-HermesDatabase {
    [CmdletBinding()][OutputType([void])] param([psobject]$Manager)
    $Manager.Connection = $null
    $Manager.IsConnected = $false
    $Manager.UseCliFallback = $false
    Write-Verbose "Disconnected"
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

    if ($Manager.UseCliFallback) {
        return Invoke-HermesSql_Cli -Manager $Manager -Sql $Sql -Parameters $Parameters -Mode $Mode
    }

    # ── DLL mode (original HermesSQLiteProvider) ────────────────────────────
    return Invoke-HermesSql_Dll -Manager $Manager -Sql $Sql -Parameters $Parameters -Mode $Mode
}

# ── DLL mode (original, uses HermesSQLiteConnection) ──────────────────────────
function Invoke-HermesSql_Dll {
    [CmdletBinding()] param(
        [psobject]$Manager,
        [string]$Sql,
        [hashtable]$Parameters = @{},
        [string]$Mode
    )

    $inlineSql = $Sql
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
            $dt.Load($reader)
            $reader.Close()
            return $dt
        }
    }
    catch {
        Write-Warning "Invoke-HermesSql Error: $_"
        Write-Warning "SQL: $inlineSql"
        throw
    }
}

# ── CLI fallback mode (uses sqlite3.exe) ──────────────────────────────────────
function Invoke-HermesSql_Cli {
    [CmdletBinding()] param(
        [psobject]$Manager,
        [string]$Sql,
        [hashtable]$Parameters = @{},
        [string]$Mode
    )

    $sqliteExe = Get-Command sqlite3 -ErrorAction Stop

    # Inline parameters (same logic as DLL mode)
    $inlineSql = $Sql
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

    # ── Sanitize SQL: remove trailing semicolons for CLI compatibility ──────
    $cleanSql = $inlineSql.Trim().TrimEnd(';')

    # ── Execute via sqlite3 CLI ─────────────────────────────────────────────
    $dbPath = $Manager.DatabasePath

    if ($Mode -eq 'NonQuery') {
        $proc = Start-Process -FilePath $sqliteExe.Source -ArgumentList @($dbPath, $cleanSql) -NoNewWindow -Wait -PassThru -RedirectStandardOutput "NUL"
        return $proc.ExitCode
    }
    elseif ($Mode -eq 'Scalar') {
        $result = & $sqliteExe.Path $dbPath $cleanSql 2>&1
        $output = ($result | Out-String).Trim()
        if ([string]::IsNullOrEmpty($output)) { return 0 }
        # Try parse as number
        $parsed = 0
        if ([int]::TryParse($output, [ref]$parsed)) { return $parsed }
        $dbl = 0.0
        if ([double]::TryParse($output, [ref]$dbl)) { return $dbl }
        return $output
    }
    elseif ($Mode -eq 'Query') {
        # sqlite3 -header -csv for machine-readable output
        $result = & $sqliteExe.Path -header -csv $dbPath $cleanSql 2>&1
        $lines = ($result | Out-String).Trim() -split "`n"
        if ($lines.Count -le 1) {
            # No data or just header
            $dt = New-Object System.Data.DataTable
            return $dt
        }

        # Parse CSV header and rows
        $headerLine = $lines[0].Trim()
        $headers = ($headerLine -split ',').Trim().Trim('"')
        $dt = New-Object System.Data.DataTable
        foreach ($h in $headers) {
            [void]$dt.Columns.Add($h)
        }

        for ($i = 1; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            if ([string]::IsNullOrEmpty($line)) { continue }
            $values = $line -split ','
            $row = $dt.NewRow()
            for ($j = 0; $j -lt [Math]::Min($values.Count, $headers.Count); $j++) {
                $row[$j] = $values[$j].Trim().Trim('"')
            }
            $dt.Rows.Add($row)
        }

        return $dt
    }

    return 0
}

# ──────────────────────────────────────────────────────────────────────────────
# SECCIÓN 2: FUNCIONES DE GESTIÓN DE TABLAS Y ESQUEMAS
# ──────────────────────────────────────────────────────────────────────────────

function Initialize-HermesPersistence {
    [CmdletBinding()] param(
        [string]$DatabasePath = (Join-Path $PSScriptRoot '..\..\data\hermes_consolidated.db'),
        [switch]$ForceInit
    )
    $mgr = New-HermesDatabaseManager -DatabasePath $DatabasePath
    Connect-HermesDatabase -Manager $mgr

    # ── Create core catalog tables if they don't exist ──────────────────────
    $schemaSqls = @(
        "CREATE TABLE IF NOT EXISTS UseCaseCatalog (
            Id TEXT PRIMARY KEY,
            Name TEXT NOT NULL UNIQUE,
            Category TEXT NOT NULL DEFAULT '',
            Priority INTEGER NOT NULL DEFAULT 0,
            Status TEXT NOT NULL DEFAULT 'Active',
            Capability TEXT NOT NULL DEFAULT '',
            Provider TEXT DEFAULT '',
            Engine TEXT DEFAULT '',
            Dependencies TEXT DEFAULT '',
            InputParams TEXT DEFAULT '[]',
            OutputParams TEXT DEFAULT '[]'
        )",
        "CREATE TABLE IF NOT EXISTS CapabilityCatalog (
            Name TEXT PRIMARY KEY,
            Engine TEXT DEFAULT '',
            Provider TEXT DEFAULT '',
            EngineType TEXT DEFAULT ''
        )",
        "CREATE TABLE IF NOT EXISTS ProviderCatalog (
            Name TEXT PRIMARY KEY,
            ProviderType TEXT DEFAULT 'Internal',
            Status TEXT DEFAULT 'Active',
            Description TEXT DEFAULT ''
        )",
        "CREATE TABLE IF NOT EXISTS EngineCatalog (
            Name TEXT PRIMARY KEY,
            EngineType TEXT DEFAULT '',
            Status TEXT DEFAULT 'Active',
            Description TEXT DEFAULT ''
        )",
        "CREATE TABLE IF NOT EXISTS AuditMetadata (
            Id TEXT PRIMARY KEY,
            AuditType TEXT NOT NULL,
            TotalEntities INTEGER DEFAULT 0,
            CreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
        )",
        "CREATE TABLE IF NOT EXISTS Execution (
            Id TEXT PRIMARY KEY,
            UseCaseId TEXT NOT NULL,
            UseCaseName TEXT NOT NULL,
            Capability TEXT,
            Provider TEXT,
            Engine TEXT,
            Status TEXT NOT NULL DEFAULT 'Pending',
            CorrelationId TEXT,
            Input TEXT DEFAULT '{}',
            Output TEXT DEFAULT '{}',
            StartedAt TEXT,
            CompletedAt TEXT
        )",
        "CREATE TABLE IF NOT EXISTS ExecutionStep (
            Id TEXT PRIMARY KEY,
            ExecutionId TEXT NOT NULL,
            StepName TEXT NOT NULL,
            Status TEXT NOT NULL DEFAULT 'Pending',
            DurationMs INTEGER DEFAULT 0,
            StartedAt TEXT
        )",
        "CREATE TABLE IF NOT EXISTS ExecutionMetric (
            Id TEXT PRIMARY KEY,
            ExecutionId TEXT NOT NULL,
            MetricName TEXT NOT NULL,
            MetricValue REAL NOT NULL,
            Unit TEXT DEFAULT '',
            Source TEXT DEFAULT 'system'
        )",
        "CREATE TABLE IF NOT EXISTS ExecutionError (
            Id TEXT PRIMARY KEY,
            ExecutionId TEXT NOT NULL,
            StepName TEXT NOT NULL,
            ErrorMessage TEXT NOT NULL,
            Timestamp TEXT
        )",
        "CREATE TABLE IF NOT EXISTS ExecutionAudit (
            Id TEXT PRIMARY KEY,
            ExecutionId TEXT NOT NULL,
            Action TEXT NOT NULL,
            EntityType TEXT NOT NULL,
            EntityId TEXT NOT NULL,
            Timestamp TEXT
        )",
        "CREATE TABLE IF NOT EXISTS ExecutionContext (
            Id TEXT PRIMARY KEY,
            ExecutionId TEXT NOT NULL,
            ContextKey TEXT NOT NULL,
            ContextValue TEXT NOT NULL,
            ContextType TEXT DEFAULT 'String'
        )"
    )

    foreach ($sql in $schemaSqls) {
        try {
            $null = Invoke-HermesSql -Manager $mgr -Sql $sql -Mode NonQuery
        }
        catch {
            Write-Warning "Schema creation: $_ (sql: $($sql.Substring(0, [Math]::Min(80, $sql.Length))))"
        }
    }

    return $mgr
}

Export-ModuleMember -Function New-HermesDatabaseManager, Assert-HermesDatabaseConnection, Connect-HermesDatabase, Disconnect-HermesDatabase, Invoke-HermesSql, Initialize-HermesPersistence