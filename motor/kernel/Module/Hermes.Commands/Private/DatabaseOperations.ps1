<#
DatabaseOperations.ps1 — Operaciones de base de datos SQLite
No exportadas. Solo uso interno.
#>

function _Write-HermesHistory {
    param(
        [string]$EventType,      # 'ProjectCreate', 'ProjectRemove', 'EnvCreate', etc.
        [string]$Action,
        [string]$Result = 'Pending',
        [string]$Detail = '',
        [string]$User = ''
    )
    $db = _Get-HermesDb
    if (-not (Test-Path $db)) { return }
    $id = _New-GuidH
    if ([string]::IsNullOrEmpty($User)) { $User = $env:USERNAME }
    $detail = $Detail.Replace("'", "''")
    $sql = "INSERT INTO EnvironmentHistory (Id,EnvironmentId,Provider,Action,PythonVersion,Result,ProjectName,User) VALUES ('$id','$EventType','Hermes.Commands','$Action','','$Result','$detail','$User')"
    & sqlite3.exe "`"$db`"" $sql 2>$null | Out-Null
}

function _Complete-HermesHistory {
    param(
        [string]$EventType,
        [string]$Result,
        [string]$Detail = ''
    )
    $db = _Get-HermesDb
    if (-not (Test-Path $db)) { return }
    $ts = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $sql = "UPDATE EnvironmentHistory SET EndTime='$ts', Duration=ROUND((julianday('$ts')-julianday(StartTime))*86400,2), Result='$Result' WHERE EnvironmentId='$EventType' AND Result='Pending'"
    & sqlite3.exe "`"$db`"" $sql 2>$null | Out-Null
}

function _Get-ProjectFromDb {
    param([string]$ProjectPath)
    $db = _Get-HermesDb
    if (-not (Test-Path $db)) { return $null }
    $p = $ProjectPath.Replace("'", "''")
    $row = & sqlite3.exe "`"$db`"" "SELECT Id,Name,Path,CreatedAt,UpdatedAt,Status,Version,Provider,PythonVersion FROM Projects WHERE Path='$p' LIMIT 1" 2>$null
    if ([string]::IsNullOrEmpty($row)) { return $null }
    $cols = $row -split '\|'
    if ($cols.Count -lt 9) { return $null }
    return [pscustomobject]@{
        Id            = $cols[0]
        Name          = $cols[1]
        Path          = $cols[2]
        CreatedAt     = $cols[3]
        UpdatedAt     = $cols[4]
        Status        = $cols[5]
        Version       = $cols[6]
        Provider      = $cols[7]
        PythonVersion = $cols[8]
    }
}

function _Register-ProjectInDb {
    param(
        [string]$ProjectPath,
        [string]$ProjectName,
        [string]$Version = '1.0.0',
        [string]$Provider = 'venv',
        [string]$PythonVersion = '',
        [string]$Status = 'Created'
    )
    $db = _Get-HermesDb
    if (-not (Test-Path $db)) { return }
    $id = _New-GuidH
    $now = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $p = $ProjectPath.Replace("'", "''")
    $n = $ProjectName.Replace("'", "''")
    $sql = "INSERT OR IGNORE INTO Projects (Id,Name,Path,CreatedAt,UpdatedAt,Status,Version,Provider,PythonVersion) VALUES ('$id','$n','$p','$now','$now','$Status','$Version','$Provider','$PythonVersion')"
    & sqlite3.exe "`"$db`"" $sql 2>$null | Out-Null
}

function _Update-ProjectInDb {
    param(
        [string]$ProjectPath,
        [string]$Status = '',
        [string]$Version = ''
    )
    $db = _Get-HermesDb
    if (-not (Test-Path $db)) { return }
    $now = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $p = $ProjectPath.Replace("'", "''")
    $sets = @("UpdatedAt='$now'")
    if ($Status) { $sets += "Status='$Status'" }
    if ($Version) { $sets += "Version='$Version'" }
    $setStr = $sets -join ','
    $sql = "UPDATE Projects SET $setStr WHERE Path='$p'"
    & sqlite3.exe "`"$db`"" $sql 2>$null | Out-Null
}

function _Remove-ProjectFromDb {
    param([string]$ProjectPath)
    $db = _Get-HermesDb
    if (-not (Test-Path $db)) { return }
    $p = $ProjectPath.Replace("'", "''")
    & sqlite3.exe "`"$db`"" "DELETE FROM Projects WHERE Path='$p'" 2>$null | Out-Null
}

function _Get-AllProjectsFromDb {
    $db = _Get-HermesDb
    if (-not (Test-Path $db)) { return @() }
    $rows = & sqlite3.exe "`"$db`"" "SELECT Id,Name,Path,CreatedAt,UpdatedAt,Status,Version,Provider,PythonVersion FROM Projects ORDER BY UpdatedAt DESC" 2>$null
    if ([string]::IsNullOrEmpty($rows)) { return @() }
    $result = @()
    foreach ($r in $rows -split "`n") {
        $r = $r.Trim()
        if ([string]::IsNullOrEmpty($r)) { continue }
        $cols = $r -split '\|'
        if ($cols.Count -lt 9) { continue }
        $result += [pscustomobject]@{
            Id            = $cols[0]
            Name          = $cols[1]
            Path          = $cols[2]
            CreatedAt     = $cols[3]
            UpdatedAt     = $cols[4]
            Status        = $cols[5]
            Version       = $cols[6]
            Provider      = $cols[7]
            PythonVersion = $cols[8]
        }
    }
    return $result
}