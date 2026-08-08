function Invoke-ProyectoSmokeTests {
    <#
    .SYNOPSIS
        Executes smoke tests against a deployed Web App.
    .PARAMETER BaseUrl
        Base URL of the deployed application.
    .PARAMETER CorrelationId
        Correlation ID for logging.
    .PARAMETER DbPath
        Path to SQLite database for registering results.
    .OUTPUTS
        Hashtable with smoke test results.
    #>
    param(
        [Parameter(Mandatory)] [string] $BaseUrl,
        [Parameter(Mandatory)] [string] $CorrelationId,
        [string] $DbPath = ""
    )

    $startTime = Get-Date

    $endpoints = @(
        "/health",
        "/api/version",
        "/api/proyecto",
        "/api/workspace",
        "/api/git",
        "/api/github",
        "/api/sqlite",
        "/api/azure",
        "/api/despliegue"
    )

    $results = @()
    $passed = 0
    $failed = 0

    Write-Host "[SmokeTests] Starting smoke tests for: $BaseUrl"
    Write-Host ""

    foreach ($endpoint in $endpoints) {
        $url = "$BaseUrl$endpoint"
        $testStart = Get-Date

        try {
            $response = Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing -TimeoutSec 15
            $httpCode = $response.StatusCode
            $responseTime = [math]::Round(((Get-Date) - $testStart).TotalSeconds, 3)
            $status = if ($httpCode -eq 200) { "PASS" } else { "FAIL" }

            Write-Host "  [$status] $url -> $httpCode (${responseTime}s)"
        }
        catch {
            $httpCode = 0
            $responseTime = [math]::Round(((Get-Date) - $testStart).TotalSeconds, 3)
            $status = "FAIL"
            Write-Host "  [FAIL] $url -> ERROR (${responseTime}s)"
        }

        $result = @{
            Endpoint = $endpoint
            Url = $url
            HTTPCode = $httpCode
            Estado = $status
            TiempoRespuesta = $responseTime
        }
        $results += $result

        if ($status -eq "PASS") { $passed++ } else { $failed++ }
    }

    $elapsed = (Get-Date) - $startTime
    $totalTime = [math]::Round($elapsed.TotalSeconds, 2)

    Write-Host ""
    Write-Host "[SmokeTests] Results: $passed passed, $failed failed, ${totalTime}s total"

    if ($DbPath -and (Test-Path $DbPath)) {
        foreach ($r in $results) {
            try {
                $sql = @"
INSERT INTO SmokeTestResults (CorrelationId, Endpoint, HTTPCode, Estado, TiempoRespuesta)
VALUES ('$CorrelationId', '$($r.Endpoint)', $($r.HTTPCode), '$($r.Estado)', $($r.TiempoRespuesta));
"@
                sqlite3 $DbPath $sql 2>&1 | Out-Null
            }
            catch {
                # SQLite registration is non-critical
            }
        }
    }

    $overallStatus = if ($failed -eq 0) { "PASS" } else { "FAIL" }

    return @{
        Endpoints = $results
        Passed = $passed
        Failed = $failed
        Total = $endpoints.Count
        TotalTime = $totalTime
        OverallStatus = $overallStatus
    }
}

function Test-ProyectoLanding {
    <#
    .SYNOPSIS
        Tests that the landing page returns HTTP 200.
    .PARAMETER BaseUrl
        Base URL of the deployed application.
    .OUTPUTS
        Hashtable with landing test result.
    #>
    param(
        [Parameter(Mandatory)] [string] $BaseUrl
    )

    $startTime = Get-Date

    try {
        $response = Invoke-WebRequest -Uri $BaseUrl -Method GET -UseBasicParsing -TimeoutSec 15
        $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)

        $body = $response.Content
        $hasTitle = $body -match "<title>"
        $hasHero = $body -match "hero-section"

        return @{
            Url = $BaseUrl
            HTTPCode = $response.StatusCode
            Time = $elapsed
            LandingOk = ($response.StatusCode -eq 200)
            HasTitle = $hasTitle
            HasHero = $hasHero
        }
    }
    catch {
        return @{
            Url = $BaseUrl
            HTTPCode = 0
            Time = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            LandingOk = $false
            Error = $_.Exception.Message
        }
    }
}

Export-ModuleMember -Function Invoke-ProyectoSmokeTests, Test-ProyectoLanding