function New-ProyectoReportMD {
    <#
    .SYNOPSIS
        Generates a Markdown report for the project.
    .PARAMETER Metadata
        Hashtable with all project metadata.
    .PARAMETER OutputPath
        Path for the .md report file.
    .OUTPUTS
        Path to the generated report.
    #>
    param(
        [Parameter(Mandatory)] [hashtable] $Metadata,
        [Parameter(Mandatory)] [string] $OutputPath
    )

    $reportDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }

    $smokePassed = if ($Metadata.SmokePassed) { $Metadata.SmokePassed } else { 0 }
    $smokeFailed = if ($Metadata.SmokeFailed) { $Metadata.SmokeFailed } else { 0 }
    $smokeTotal = $smokePassed + $smokeFailed

    $lines = @()
    $lines += "# RC74 Report - $($Metadata.ProjectName)"
    $lines += ""
    $lines += "> **CorrelationId:** $($Metadata.CorrelationId)"
    $lines += ""
    $lines += "## Resumen Ejecutivo"
    $lines += ""
    $lines += "| Metrica | Valor |"
    $lines += "|---------|-------|"

    $fields = @(
        @("Proyecto", $Metadata.ProjectName),
        @("Web App", $Metadata.WebAppName),
        @("URL", $Metadata.Url),
        @("Estado", $Metadata.OverallStatus),
        @("Tiempo Total", "$($Metadata.TotalTime)s"),
        @("Correcciones Automaticas", "$($Metadata.AutoCorrections)"),
        @("Commits", "$($Metadata.TotalCommits)"),
        @("Despliegues", "$($Metadata.TotalDeploys)"),
        @("Azure Status", $Metadata.AzureStatus),
        @("GitHub Status", $Metadata.GitHubStatus),
        @("CI Status", $Metadata.CIStatus),
        @("SQLite Status", $Metadata.SQLiteStatus),
        @("Smoke Test", "$smokePassed/$smokeTotal passed")
    )

    foreach ($f in $fields) {
        $lines += "| $($f[0]) | $($f[1]) |"
    }

    $lines += ""
    $lines += "## Smoke Test Results"
    $lines += ""
    $lines += "| Endpoint | HTTP | Estado | Tiempo |"
    $lines += "|----------|------|--------|--------|"

    if ($Metadata.SmokeResults) {
        foreach ($s in $Metadata.SmokeResults) {
            $lines += "| $($s.Endpoint) | $($s.HTTPCode) | $($s.Estado) | $($s.TiempoRespuesta)s |"
        }
    }

    $lines += ""
    $lines += "## Timeline"
    $lines += ""

    $events = @("Workspace", "Git", "GitHub", "SQLite", "Build", "ZIP", "Deploy", "SmokeTest", "Publicado")
    foreach ($ev in $events) {
        $status = if ($Metadata.Timeline -and $Metadata.Timeline[$ev]) { $Metadata.Timeline[$ev] } else { "PENDIENTE" }
        $lines += "- **$ev**: $status"
    }

    $lines += ""
    $lines += "---"
    $lines += ""
    $lines += "*Powered by Hermes Enterprise*"

    $content = $lines -join "`n"
    $content | Out-File -FilePath $OutputPath -Encoding UTF8 -Force

    Write-Host "[Reporting] Markdown report generated: $OutputPath"
    return $OutputPath
}

function New-ProyectoReportJSON {
    <#
    .SYNOPSIS
        Generates a JSON report for the project.
    .PARAMETER Metadata
        Hashtable with all project metadata.
    .PARAMETER OutputPath
        Path for the .json report file.
    .OUTPUTS
        Path to the generated report.
    #>
    param(
        [Parameter(Mandatory)] [hashtable] $Metadata,
        [Parameter(Mandatory)] [string] $OutputPath
    )

    $reportDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }

    $report = @{
        report = "RC74_E2E"
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        correlationId = $Metadata.CorrelationId
        projectName = $Metadata.ProjectName
        webAppName = $Metadata.WebAppName
        url = $Metadata.Url
        overallStatus = $Metadata.OverallStatus
        totalTime = $Metadata.TotalTime
        autoCorrections = $Metadata.AutoCorrections
        totalCommits = $Metadata.TotalCommits
        totalDeploys = $Metadata.TotalDeploys
        azureStatus = $Metadata.AzureStatus
        gitHubStatus = $Metadata.GitHubStatus
        ciStatus = $Metadata.CIStatus
        sqliteStatus = $Metadata.SQLiteStatus
        smokeTest = @{
            passed = $Metadata.SmokePassed
            failed = $Metadata.SmokeFailed
            total = ($Metadata.SmokePassed + $Metadata.SmokeFailed)
            results = $Metadata.SmokeResults
        }
        timeline = $Metadata.Timeline
    }

    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8 -Force

    Write-Host "[Reporting] JSON report generated: $OutputPath"
    return $OutputPath
}

function New-ProyectoReportHTML {
    <#
    .SYNOPSIS
        Generates an HTML report for the project.
    .PARAMETER Metadata
        Hashtable with all project metadata.
    .PARAMETER OutputPath
        Path for the .html report file.
    .OUTPUTS
        Path to the generated report.
    #>
    param(
        [Parameter(Mandatory)] [hashtable] $Metadata,
        [Parameter(Mandatory)] [string] $OutputPath
    )

    $reportDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }

    $smokePassed = if ($Metadata.SmokePassed) { $Metadata.SmokePassed } else { 0 }
    $smokeFailed = if ($Metadata.SmokeFailed) { $Metadata.SmokeFailed } else { 0 }
    $smokeTotal = $smokePassed + $smokeFailed
    $overallStatus = $Metadata.OverallStatus
    $statusColor = if ($overallStatus -eq "OK") { "success" } else { "danger" }

    $html = @"
<!DOCTYPE html>
<html lang="es" data-bs-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>RC74 Report — $($Metadata.ProjectName)</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-dark text-light p-4">
<div class="container">
    <h1 class="mb-2">RC74 — $($Metadata.ProjectName)</h1>
    <p class="text-secondary">CorrelationId: $($Metadata.CorrelationId)</p>
    <span class="badge bg-$statusColor mb-4 p-2 fs-6">$overallStatus</span>

    <div class="row g-3 mt-2">
        <div class="col-md-6"><div class="card bg-dark border-secondary"><div class="card-body"><h5 class="card-title">URL</h5><a href="$($Metadata.Url)" target="_blank" class="text-info">$($Metadata.Url)</a></div></div></div>
        <div class="col-md-3"><div class="card bg-dark border-secondary"><div class="card-body"><h5 class="card-title">Tiempo Total</h5><span class="fs-4">$($Metadata.TotalTime)s</span></div></div></div>
        <div class="col-md-3"><div class="card bg-dark border-secondary"><div class="card-body"><h5 class="card-title">Web App</h5><span class="fs-4">$($Metadata.WebAppName)</span></div></div></div>
    </div>

    <h3 class="mt-4">Metricas</h3>
    <table class="table table-dark table-striped">
        <tr><td>Azure Status</td><td>$($Metadata.AzureStatus)</td></tr>
        <tr><td>GitHub Status</td><td>$($Metadata.GitHubStatus)</td></tr>
        <tr><td>CI Status</td><td>$($Metadata.CIStatus)</td></tr>
        <tr><td>SQLite Status</td><td>$($Metadata.SQLiteStatus)</td></tr>
        <tr><td>Correcciones</td><td>$($Metadata.AutoCorrections)</td></tr>
        <tr><td>Commits</td><td>$($Metadata.TotalCommits)</td></tr>
        <tr><td>Despliegues</td><td>$($Metadata.TotalDeploys)</td></tr>
        <tr><td>Smoke Test</td><td>$smokePassed/$smokeTotal passed</td></tr>
    </table>

    <h3 class="mt-4">Smoke Test</h3>
    <table class="table table-dark table-striped">
        <thead><tr><th>Endpoint</th><th>HTTP</th><th>Estado</th><th>Tiempo</th></tr></thead>
        <tbody>
"@

    if ($Metadata.SmokeResults) {
        foreach ($s in $Metadata.SmokeResults) {
            $color = if ($s.Estado -eq "PASS") { "success" } else { "danger" }
            $html += "<tr><td>$($s.Endpoint)</td><td>$($s.HTTPCode)</td><td><span class='badge bg-$color'>$($s.Estado)</span></td><td>$($s.TiempoRespuesta)s</td></tr>"
        }
    }

    $html += @"
        </tbody>
    </table>

    <h3 class="mt-4">Timeline</h3>
    <div class="list-group list-group-flush">
"@

    $events = @("Workspace", "Git", "GitHub", "SQLite", "Build", "ZIP", "Deploy", "SmokeTest", "Publicado")
    foreach ($ev in $events) {
        $status = if ($Metadata.Timeline -and $Metadata.Timeline[$ev]) { $Metadata.Timeline[$ev] } else { "PENDIENTE" }
        $color = if ($status -eq "OK") { "success" } else { "secondary" }
        $html += "<div class='list-group-item bg-dark border-secondary text-light'><span class='badge bg-$color me-2'>$status</span>$ev</div>"
    }

    $html += @"
    </div>

    <hr class="mt-4">
    <p class="text-secondary text-center">Powered by Hermes Enterprise</p>
</div>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8 -Force

    Write-Host "[Reporting] HTML report generated: $OutputPath"
    return $OutputPath
}

function New-BlankMetadata {
    <#
    .SYNOPSIS
        Creates a blank metadata hashtable with all keys initialized.
    .OUTPUTS
        Hashtable with default values.
    #>
    return @{
        ProjectName = ""
        WebAppName = ""
        Url = ""
        CorrelationId = ""
        OverallStatus = "PENDIENTE"
        TotalTime = 0
        AutoCorrections = 0
        TotalCommits = 0
        TotalDeploys = 0
        AzureStatus = "PENDIENTE"
        GitHubStatus = "PENDIENTE"
        CIStatus = "PENDIENTE"
        SQLiteStatus = "PENDIENTE"
        SmokePassed = 0
        SmokeFailed = 0
        SmokeResults = @()
        Timeline = @{}
    }
}

Export-ModuleMember -Function New-ProyectoReportMD, New-ProyectoReportJSON, New-ProyectoReportHTML, New-BlankMetadata