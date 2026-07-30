# tools/GenerateIntegrityReport.ps1
Param()
# Run ValidateModules and generate reports/ReporteIntegridad.json
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$validate = Join-Path $scriptDir 'ValidateModules.ps1'
& powershell -NoProfile -ExecutionPolicy Bypass -File $validate
$rc = $LASTEXITCODE
if ($rc -ne 0) { Write-Host "ValidateModules failed with code $rc"; exit $rc }
$modules = Get-ChildItem -Path (Join-Path $scriptDir '..\motor\bootstrap\functions') -Filter '*.ps1' -File | ForEach-Object { @{ name=$_.Name; path=$_.FullName; lastWrite=$_.LastWriteTime.ToString('o') } }
$report = @{ timestamp=(Get-Date).ToString('o'); status='PASS'; modules=$modules }
$report | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $scriptDir '..\reports\ReporteIntegridad.json') -Encoding utf8
Write-Host 'ReporteIntegridad.json creado'