Param()
Write-Host "VerifyVSCode: create .vscode/settings.json if requested"
param(
    [string]$ProjectPath = (Get-Location)
)
$vscodeDir = Join-Path $ProjectPath '.vscode'
if (-not (Test-Path $vscodeDir)) { New-Item -ItemType Directory -Path $vscodeDir | Out-Null }
$settings = @{
    "python.pythonPath" = "${ProjectPath}\\.venv\\Scripts\\python.exe"
    "terminal.integrated.profiles.windows" = @{}
}
$settings | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $vscodeDir 'settings.json') -Force
Write-Host "VSCode settings written to $vscodeDir\settings.json"
exit 0
