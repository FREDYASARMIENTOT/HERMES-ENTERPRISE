<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : DatabaseManager.ps1
Propósito: Gestor principal de base de datos SQLite con resolución automática de ruta
====================================================================================================
#>

Set-StrictMode -Version Latest

function Resolve-HermesDatabasePath {
    <#
    .SYNOPSIS
        Resuelve automáticamente la ruta de hermes.db según el sistema operativo y entorno.
    .DESCRIPTION
        Desarrollo: /workspace/data/hermes.db
        Windows: D:\HERMES-ENTERPRISE\data\hermes.db
        Azure Linux: /home/data/hermes.db
        Docker: /var/lib/hermes/hermes.db
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $workspaceRoot = Resolve-Path "$PSScriptRoot\..\..\.." -ErrorAction SilentlyContinue
    if (-not $workspaceRoot) { $workspaceRoot = 'D:\HERMES-ENTERPRISE' }

    $os = [System.Environment]::OSVersion.Platform.ToString().ToLower()
    $isWindows = $os -match 'win'

    if ($isWindows) {
        $dataDir = Join-Path $workspaceRoot 'data'
    }
    elseif ($env:DOCKER_CONTAINER -eq 'true') {
        $dataDir = '/var/lib/hermes'
    }
    elseif ($env:AZURE_FUNCTIONS_ENVIRONMENT -or $env:WEBSITE_SITE_NAME) {
        $dataDir = '/home/data'
    }
    else {
        $dataDir = '/workspace/data'
    }

    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    }

    return Join-Path $dataDir 'hermes.db'
}

function New-HermesDatabaseManager {
    <#
    .SYNOPSIS
        Crea una nueva instancia del gestor de base de datos.
    #>
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$DatabasePath = (Resolve-HermesDatabasePath)
    )

    $connectionString = "Data Source=$DatabasePath;Version=3;Pooling=True;Max Pool Size=100;"

    return [pscustomobject][ordered]@{
        DatabasePath        = $DatabasePath
        ConnectionString    = $connectionString
        IsConnected         = $false
        Connection          = $null
        Transaction         = $null
        CreatedAt           = (Get-Date)
        LastConnectionTime  = $null
        ConnectionCount     = 0
        TotalQueries        = 0
        FailedQueries       = 0
    }
}

function Connect-HermesDatabase {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Manager
    )

    try {
        Add-Type -Path (Join-Path $PSScriptRoot '..\..\..\lib\System.Data.SQLite.dll') -ErrorAction SilentlyContinue
        if (-not ([System.Management.Automation.PSTypeName]'System.Data.SQLite.SQLiteConnection').Type) {
            Add-Type -AssemblyName System.Data.SQLite -ErrorAction SilentlyContinue
        }
    }
    catch {
        # SQLite may not be available as assembly - try via ADO.NET
    }

    try {
        $connection = New-Object System.Data.SQLite.SQLiteConnection($Manager.ConnectionString)
        $connection.Open()
        $Manager.Connection = $connection
        $Manager.IsConnected = $true
        $Manager.LastConnectionTime = Get-Date
        $Manager.ConnectionCount++
        return $true
    }
    catch {
        Write-Warning "Error connecting to database: $_"
        $Manager.IsConnected = $false
        return $false
    }
}

function Disconnect-HermesDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Manager
    )

    if ($Manager.Transaction) {
        try { $Manager.Transaction.Rollback() } catch {}
        $Manager.Transaction = $null
    }

    if ($Manager.Connection -and $Manager.Connection.State -eq 'Open') {
        try { $Manager.Connection.Close() } catch {}
        try { $Manager.Connection.Dispose() } catch {}
    }

    $Manager.Connection = $null
    $Manager.IsConnected = $false
}

function Test-HermesDatabaseConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Manager
    )

    try {
        if (-not $Manager.Connection -or $Manager.Connection.State -ne 'Open') {
            return $false
        }
        $cmd = $Manager.Connection.CreateCommand()
        $cmd.CommandText = 'SELECT 1'
        $result = $cmd.ExecuteScalar()
        return ($result -eq 1)
    }
    catch {
        return $false
    }
}

function Invoke-HermesDatabaseNonQuery {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Manager,

        [Parameter(Mandatory = $true)]
        [string]$Sql,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    $Manager.TotalQueries++
    try {
        if (-not $Manager.Connection -or $Manager.Connection.State -ne 'Open') {
            Connect-HermesDatabase -Manager $Manager | Out-Null
        }
        $cmd = $Manager.Connection.CreateCommand()
        $cmd.CommandText = $Sql
        foreach ($key in $Parameters.Keys) {
            $param = $cmd.CreateParameter()
            $param.ParameterName = $key
            $param.Value = $Parameters[$key]
            $cmd.Parameters.Add($param) | Out-Null
        }
        return $cmd.ExecuteNonQuery()
    }
    catch {
        $Manager.FailedQueries++
        throw "Database query failed: $_"
    }
}

function Invoke-HermesDatabaseQuery {
    [CmdletBinding()]
    [OutputType([System.Data.DataTable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Manager,

        [Parameter(Mandatory = $true)]
        [string]$Sql,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    $Manager.TotalQueries++
    try {
        if (-not $Manager.Connection -or $Manager.Connection.State -ne 'Open') {
            Connect-HermesDatabase -Manager $Manager | Out-Null
        }
        $cmd = $Manager.Connection.CreateCommand()
        $cmd.CommandText = $Sql
        foreach ($key in $Parameters.Keys) {
            $param = $cmd.CreateParameter()
            $param.ParameterName = $key
            $param.Value = $Parameters[$key]
            $cmd.Parameters.Add($param) | Out-Null
        }
        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
        $table = New-Object System.Data.DataTable
        $adapter.Fill($table) | Out-Null
        return $table
    }
    catch {
        $Manager.FailedQueries++
        throw "Database query failed: $_"
    }
}

function Invoke-HermesDatabaseScalar {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Manager,

        [Parameter(Mandatory = $true)]
        [string]$Sql,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    $Manager.TotalQueries++
    try {
        if (-not $Manager.Connection -or $Manager.Connection.State -ne 'Open') {
            Connect-HermesDatabase -Manager $Manager | Out-Null
        }
        $cmd = $Manager.Connection.CreateCommand()
        $cmd.CommandText = $Sql
        foreach ($key in $Parameters.Keys) {
            $param = $cmd.CreateParameter()
            $param.ParameterName = $key
            $param.Value = $Parameters[$key]
            $cmd.Parameters.Add($param) | Out-Null
        }
        return $cmd.ExecuteScalar()
    }
    catch {
        $Manager.FailedQueries++
        throw "Database query failed: $_"
    }
}

function Start-HermesDatabaseTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Manager
    )

    if (-not $Manager.Connection -or $Manager.Connection.State -ne 'Open') {
        Connect-HermesDatabase -Manager $Manager | Out-Null
    }
    $Manager.Transaction = $Manager.Connection.BeginTransaction()
}

function Complete-HermesDatabaseTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Manager
    )

    if ($Manager.Transaction) {
        $Manager.Transaction.Commit()
        $Manager.Transaction = $null
    }
}

function Undo-HermesDatabaseTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Manager
    )

    if ($Manager.Transaction) {
        $Manager.Transaction.Rollback()
        $Manager.Transaction = $null
    }
}

function Enable-HermesDatabasePragmas {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Manager
    )

    $pragmas = @(
        'PRAGMA journal_mode=WAL;',
        'PRAGMA synchronous=NORMAL;',
        'PRAGMA cache_size=-8000;',
        'PRAGMA busy_timeout=5000;',
        'PRAGMA foreign_keys=ON;',
        'PRAGMA temp_store=MEMORY;',
        'PRAGMA mmap_size=30000000000;'
    )

    foreach ($pragma in $pragmas) {
        Invoke-HermesDatabaseNonQuery -Manager $Manager -Sql $pragma | Out-Null
    }
}

Export-ModuleMember -Function Resolve-HermesDatabasePath,
                              New-HermesDatabaseManager,
                              Connect-HermesDatabase,
                              Disconnect-HermesDatabase,
                              Test-HermesDatabaseConnection,
                              Invoke-HermesDatabaseNonQuery,
                              Invoke-HermesDatabaseQuery,
                              Invoke-HermesDatabaseScalar,
                              Start-HermesDatabaseTransaction,
                              Complete-HermesDatabaseTransaction,
                              Undo-HermesDatabaseTransaction,
                              Enable-HermesDatabasePragmas