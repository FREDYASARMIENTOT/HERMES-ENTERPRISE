Param()
$files = Get-ChildItem -Path motor/bootstrap -Recurse -Filter '*.ps1' | Sort-Object FullName
$report = [ordered]@{ timestamp = (Get-Date).ToString('o'); files = @() }
foreach ($f in $files) {
    $report.files += [ordered]@{ path = $f.FullName; lastWrite = $f.LastWriteTime.ToString('o'); length = $f.Length }
}
$report | ConvertTo-Json -Depth 10 | Set-Content -Path "reports/ReporteForenseWorkspace.json" -Encoding utf8
Write-Host "ReporteForenseWorkspace.json creado"
