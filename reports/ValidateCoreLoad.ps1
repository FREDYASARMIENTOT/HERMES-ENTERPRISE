Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$reportsDir = 'D:/HERMES-ENTERPRISE/reports'
if (-not (Test-Path $reportsDir)) { New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null }

$modules = @(
    'D:/HERMES-ENTERPRISE/Start-HermesProject.ps1',
    'D:/HERMES-ENTERPRISE/tools/HermesPathResolver.psm1',
    'D:/HERMES-ENTERPRISE/tools/EnterprisePipeline.ps1',
    'D:/HERMES-ENTERPRISE/motor/bootstrap/BootstrapOrchestrator.ps1',
    'D:/HERMES-ENTERPRISE/motor/scheduler/Scheduler.ps1',
    'D:/D/HERMES-ENTERPRISE/motor/config/Configuration.psm1'
)

$results = for ($i=0; $i -lt $modules.Count; $i++) {
    [PSCustomObject]@{
        Module = [System.IO.Path]::GetFileName($modules[$i])
        Path = $modules[$i]
        Status = 'PENDING'
        Error = $null
        TimeMs = 0
    }
}

for ($i = 0; $i -lt $modules.Count; $i++) {
    $path = $modules[$i]
    if (-not (Test-Path $path)) { $results[$i].Status = 'MISSING'; $results[$i].Error = 'File not found'; continue }
    try {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        Import-Module $path -Force -ErrorAction Stop
        $sw.Stop()
        $results[$i].Status = 'PASS'
        $results[$i].TimeMs = $sw.ElapsedMilliseconds
    } catch {
        $results[$i].Status = 'FAIL'
        $results[$i].Error = $_.Exception.Message
    }
}

$results | ConvertTo-Json -Depth 5 | Out-File -FilePath "$reportsDir/ModuleValidation.json" -Encoding utf8
$results | Format-Table -AutoSize | Out-String | Out-File -FilePath "$reportsDir/ModuleValidation.txt" -Encoding utf8

Write-Output 'Validación atómica completada.'
