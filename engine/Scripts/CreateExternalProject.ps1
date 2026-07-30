param([string]$Name)
$root='D:/Proyectos'
$proj=Join-Path $root $Name
if (Test-Path $proj) { Write-Output "Exists"; exit 1 }
New-Item -ItemType Directory -Path $proj | Out-Null
@('README.md','LICENSE','pyproject.toml','requirements.txt') | ForEach-Object { '' | Out-File -FilePath (Join-Path $proj $_) -Encoding utf8 }
@('src','tests','docs','.vscode') | ForEach-Object { New-Item -ItemType Directory -Path (Join-Path $proj $_) -Force | Out-Null }
# git init
git -C $proj init | Out-Null
# venv
python -m venv (Join-Path $proj '.venv')
# Reports
$report = [ordered]@{Project=$proj; Created=(Get-Date).ToString('o') }
$report | ConvertTo-Json | Out-File D:/Proyectos/CreationReport.json -Encoding utf8
Write-Output 'Created'
