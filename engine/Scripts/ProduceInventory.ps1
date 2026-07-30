# Repository inventory script
$repo = 'D:/HERMES-ENTERPRISE'
$reports = Join-Path $repo 'reports'
if(-not (Test-Path $reports)) { New-Item -ItemType Directory -Path $reports | Out-Null }
# Tree
$tree = Get-ChildItem -Path $repo -Recurse | Select-Object FullName,PSIsContainer,Length
$tree | ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'RepositoryTree.json') -Encoding utf8
# Counts
$counts = @{ Files = (Get-ChildItem -Path $repo -Recurse -File).Count; Dirs = (Get-ChildItem -Path $repo -Recurse -Directory).Count }
$counts | ConvertTo-Json | Out-File (Join-Path $reports 'RepositoryCounts.json') -Encoding utf8
# Lists
Get-ChildItem -Path $repo -Recurse -Include *.psm1 | Select-Object FullName | ConvertTo-Json | Out-File (Join-Path $reports 'ModulesList.json') -Encoding utf8
Get-ChildItem -Path $repo -Recurse -Include *.ps1 | Select-Object FullName | ConvertTo-Json | Out-File (Join-Path $reports 'ScriptsList.json') -Encoding utf8
Get-ChildItem -Path $repo -Recurse -Include *.json | Select-Object FullName | ConvertTo-Json | Out-File (Join-Path $reports 'JsonList.json') -Encoding utf8
Get-ChildItem -Path $repo -Recurse -Include *.yml,*.yaml | Select-Object FullName | ConvertTo-Json | Out-File (Join-Path $reports 'YamlList.json') -Encoding utf8
Get-ChildItem -Path $repo -Recurse -Include *.py | Select-Object FullName | ConvertTo-Json | Out-File (Join-Path $reports 'PythonList.json') -Encoding utf8
Write-Output 'Inventory produced'
