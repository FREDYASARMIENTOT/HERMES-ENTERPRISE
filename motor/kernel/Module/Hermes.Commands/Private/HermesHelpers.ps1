<#
HermesHelpers.ps1 — Funciones auxiliares privadas del módulo Hermes.Commands
No exportadas. Solo uso interno.
#>

function _New-GuidH { return [guid]::NewGuid().ToString('N') }

function _Get-HermesRoot {
    $d = Split-Path -Parent $PSScriptRoot
    $d = Split-Path -Parent $d
    $d = Split-Path -Parent $d
    $d = Split-Path -Parent $d
    $d = Split-Path -Parent $d
    return (Resolve-Path $d).Path
}

function _Get-HermesDb {
    return Join-Path (_Get-HermesRoot) 'hermes.db'
}

function _Get-ConfigValue {
    param([string]$Key, [string]$Default = '')
    $db = _Get-HermesDb
    if (-not (Test-Path $db)) { return $Default }
    $v = & sqlite3.exe "`"$db`"" "SELECT Value FROM Configuration WHERE Key='$Key'" 2>$null
    if ([string]::IsNullOrEmpty($v)) { return $Default }
    return $v.Trim()
}

function _Set-ConfigValue {
    param([string]$Key, [string]$Value)
    $db = _Get-HermesDb
    if (-not (Test-Path $db)) { return }
    $val = $Value.Replace("'", "''")
    & sqlite3.exe "`"$db`"" "INSERT OR REPLACE INTO Configuration (Key, Value) VALUES ('$Key','$val')" 2>$null | Out-Null
}

function _Get-WorkingDir {
    $repo = _Get-HermesRoot
    if (Test-Path (Join-Path $repo '.git')) { return $repo }
    return $null
}

function _Get-ScriptCommand {
    param([string]$Name)
    $root = _Get-HermesRoot
    $p = Join-Path $root "scripts\$Name.ps1"
    if (Test-Path $p) { return $p }
    $p2 = Join-Path $root "tools\$Name.ps1"
    if (Test-Path $p2) { return $p2 }
    return $null
}

function _Get-RC56Pipeline {
    $root = _Get-HermesRoot
    $p = Join-Path $root 'motor\kernel\Pipeline\RC56-EnterprisePipeline.ps1'
    if (Test-Path $p) { return $p }
    return $null
}

function _Resolve-HermesToolPath {
    param([string]$RelativePath)
    $root = _Get-HermesRoot
    $p = Join-Path $root $RelativePath
    if (Test-Path $p) { return $p }
    return $null
}