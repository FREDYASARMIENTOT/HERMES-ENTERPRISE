$mods = @(
    'D:/HERMES-ENTERPRISE/tools/WorkspaceResolver.psm1',
    'D:/HERMES-ENTERPRISE/tools/ProjectFactoryV2.psm1',
    'D:/HERMES-ENTERPRISE/tools/ProjectFactory.psm1',
    'D:/HERMES-ENTERPRISE/tools/Validation.psm1',
    'D:/HERMES-ENTERPRISE/tools/Registry.psm1',
    'D:/HERMES-ENTERPRISE/tools/ExecutionReportEngine.psm1'
)
$reports = 'D:/HERMES-ENTERPRISE/reports'
if (-not (Test-Path $reports)) { New-Item -ItemType Directory -Path $reports | Out-Null }
$trace = @()
foreach ($m in $mods) {
    $entry = [ordered]@{ Module=$m; Status='PENDING'; TimeMs=0; Error=$null; Stack=$null }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
        Import-Module $m -Force -ErrorAction Stop
        $sw.Stop(); $entry.Status='PASS'; $entry.TimeMs=$sw.ElapsedMilliseconds
    } catch {
        $sw.Stop(); $entry.Status='FAIL'; $entry.TimeMs=$sw.ElapsedMilliseconds; $entry.Error = $_.Exception.Message; $entry.Stack = $_.Exception | Out-String
        # Save the full error to a dedicated log
        $logf = Join-Path $reports ('ParserErrors.log')
        "===== Module: $m =====`n$($entry.Stack)`n" | Out-File -FilePath $logf -Append -Encoding utf8
    }
    $trace += $entry
}
$trace | ConvertTo-Json -Depth 6 | Out-File (Join-Path $reports 'ImportTrace.json') -Encoding utf8
$trace | Format-Table | Out-String | Out-File (Join-Path $reports 'ImportTrace.txt') -Encoding utf8
Write-Output 'Diagnostics complete'