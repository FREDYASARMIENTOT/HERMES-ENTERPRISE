<#
Validation.ps1 — Validaciones del sistema Hermes
No exportadas. Solo uso interno.
#>

function _Test-PythonAvailable {
    try {
        $v = & python --version 2>&1
        return ($LASTEXITCODE -eq 0) -and (-not [string]::IsNullOrEmpty($v))
    } catch { return $false }
}

function _Test-GitAvailable {
    try {
        $v = & git --version 2>&1
        return ($LASTEXITCODE -eq 0) -and (-not [string]::IsNullOrEmpty($v))
    } catch { return $false }
}

function _Test-Sqlite3Available {
    try {
        $v = & sqlite3.exe --version 2>&1
        return ($LASTEXITCODE -eq 0) -and (-not [string]::IsNullOrEmpty($v))
    } catch { return $false }
}

function _Test-HermesDb {
    $db = _Get-HermesDb
    return (Test-Path $db)
}

function _Test-GitRepository {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    $gitDir = Join-Path $Path '.git'
    return (Test-Path $gitDir)
}

function _Test-PathExists {
    param([string]$Path)
    return (Test-Path $Path)
}

function _Test-PathIsWritable {
    param([string]$Path)
    try {
        $testFile = Join-Path $Path ".test_$(Get-Random)"
        $null > $testFile 2>$null
        $result = Test-Path $testFile
        if ($result) { Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue }
        return $result
    } catch { return $false }
}

function _Test-ValidProjectName {
    param([string]$Name)
    if ([string]::IsNullOrEmpty($Name)) { return $false }
    if ($Name.Length -gt 100) { return $false }
    # Allow: letters, numbers, spaces, hyphens, underscores
    return ($Name -match '^[a-zA-Z0-9 _-]+$')
}

function _Test-ValidPath {
    param([string]$Path)
    if ([string]::IsNullOrEmpty($Path)) { return $false }
    try {
        $null = [System.IO.Path]::GetFullPath($Path)
        return $true
    } catch { return $false }
}

function _Get-PythonVersion {
    try {
        $v = & python --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $v) {
            return ($v -replace 'Python ', '').Trim()
        }
    } catch {
        Write-Verbose "Python not found: $_"
    }
    return $null
}