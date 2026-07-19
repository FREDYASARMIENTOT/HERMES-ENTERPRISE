function Create-PythonEnvironment {
    param([string]$ProjectPath)
    $pythonCmd = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $pythonCmd) { Write-Warn 'python not available'; return $null }
    $venvPath = Join-Path $ProjectPath '.venv'
    & $pythonCmd -m venv $venvPath
    return $venvPath
}
