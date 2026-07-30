# functions/VSCode.ps1
function Open-VSCode {
    param($Path)
    code -n $Path
}

function Configure-Workspace {
    param($ProjectPath)
    $vscodeDir = Join-Path $ProjectPath '.vscode'
    if (-not (Test-Path $vscodeDir)) { New-Item -ItemType Directory -Path $vscodeDir | Out-Null }
    $settings = @{
        "python.defaultInterpreterPath" = Join-Path $ProjectPath '.venv\Scripts\python.exe'
        "python.venvPath" = $ProjectPath
    }
    $settings | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $vscodeDir 'settings.json') -Force
}
