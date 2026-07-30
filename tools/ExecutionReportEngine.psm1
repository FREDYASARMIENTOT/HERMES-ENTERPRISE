function New-ExecutionReport {
    param(
        [psobject]$Context
    )
    $repo = 'D:/HERMES-ENTERPRISE'
    $reports = Join-Path $repo 'reports'
    if (-not (Test-Path $reports)) { New-Item -ItemType Directory -Path $reports | Out-Null }
    $sessionId = [guid]::NewGuid().ToString()
    $execId = [guid]::NewGuid().ToString()
    $now = Get-Date
    $report = [ordered]@{
        SessionId = $sessionId
        ExecutionId = $execId
        Timestamp = $now.ToString('o')
        User = $env:USERNAME
        Hostname = $env:COMPUTERNAME
        Workspace = $Context.Workspace
        Project = $Context.ProjectName
        Result = $Context.Result
        Details = $Context.Details
    }
    $md = Join-Path $reports 'ExecutionReport.md'
    $json = Join-Path $reports 'ExecutionReport.json'
    $metrics = Join-Path $reports 'ExecutionMetrics.json'
    $timeline = Join-Path $reports 'ExecutionTimeline.json'
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $json -Encoding utf8
    "# Execution Report`n`n" + ($report | ConvertTo-Json -Depth 5) | Out-File -FilePath $md -Encoding utf8
    @{ Report=$md; Json=$json; Metrics=$metrics; Timeline=$timeline }
}
Export-ModuleMember -Function New-ExecutionReport
