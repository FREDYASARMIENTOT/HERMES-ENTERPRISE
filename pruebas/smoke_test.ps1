param(
    [string]$Url = "https://as-hermesenterprise.azurewebsites.net"
)

$start = Get-Date
$results = @{}

Write-Host "=== SMOKE TEST RC72 ===" -ForegroundColor Cyan
Write-Host "Url: $Url"
Write-Host ("Inicio: {0}`n" -f $start.ToString("yyyy-MM-dd HH:mm:ss"))

$endpoints = @(
    '/',
    '/api/version',
    '/api/health',
    '/api/proyecto',
    '/api/workspace',
    '/api/git',
    '/api/github',
    '/api/sqlite',
    '/api/azure',
    '/api/entorno',
    '/api/despliegue',
    '/api/telemetria',
    '/swagger'
)

foreach ($ep in $endpoints) {
    $fullUrl = "$Url$ep"
    $t = Measure-Command {
        try {
            $r = Invoke-WebRequest -Uri $fullUrl -UseBasicParsing -TimeoutSec 15
            $sc = $r.StatusCode
            $len = $r.Content.Length
            if ($r.Headers.ContainsKey('Content-Type')) {
                $ct = $r.Headers['Content-Type']
            } else {
                $ct = ''
            }
        } catch {
            $sc = $_.Exception.Message
            $len = 0
            $ct = ''
        }
    }
    
    $elapsed = [math]::Round($t.TotalSeconds, 2)
    $result = @{
        'status' = $sc
        'bytes' = $len
        'time' = $elapsed
        'type' = $ct
    }
    $results[$ep] = $result
    
    if ($sc -eq 200) {
        Write-Host ("  GET {0,-22} HTTP {1,-3} {2,6}bytes {3,5}s" -f $ep, $sc, $len, $elapsed) -ForegroundColor Green
    } else {
        Write-Host ("  GET {0,-22} ERROR: {1}" -f $ep, $sc) -ForegroundColor Red
    }
}

$total = [math]::Round(($(Get-Date) - $start).TotalSeconds, 1)
$failed = ($results.Values | Where-Object { $_.status -ne 200 }).Count
$passed = $results.Count - $failed

Write-Host ""
Write-Host ("Tiempo total: {0} segundos" -f $total)
Write-Host ("Resultados: {0} pasaron, {1} fallaron de {2}" -f $passed, $failed, $results.Count)

if ($failed -eq 0) {
    Write-Host "SMOKE TEST PASSED" -ForegroundColor Green
    return $true
} else {
    Write-Host "SMOKE TEST FAILED" -ForegroundColor Red
    return $false
}