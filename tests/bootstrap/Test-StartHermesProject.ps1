<#
.SYNOPSIS
    Regression Test Suite para Start-HermesProject.ps1
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Bootstrap = Resolve-Path "../../motor/bootstrap/Start-HermesProject.ps1"
$GoldenMaster = Resolve-Path "../../motor/bootstrap/Start-HermesProject_Clean.ps1" # Asegúrate de tener esta copia estable
$Verification = Join-Path $PSScriptRoot ".verification"

if (Test-Path $Verification) { Remove-Item $Verification -Recurse -Force }
New-Item $Verification -ItemType Directory | Out-Null

$Results = @()

function Invoke-Test {
    param([string]$Name, [scriptblock]$Action)
    Write-Host "========== $Name =========="
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
        & $Action
        $status="PASS"
        $errorMessage=""
    } catch {
        $status="FAIL"
        $errorMessage=$_.Exception.Message
    }
    $sw.Stop()
    $Results += [pscustomobject]@{ Test=$Name; Status=$status; Time=$sw.Elapsed.TotalSeconds; Error=$errorMessage }
}

# ESCENARIOS (1 al 10 según especificación)
Invoke-Test "Project with parameter" { & $Bootstrap -NombreDeProyecto Regression001 }
# Interactive mode: supply input via pipeline
Invoke-Test "Interactive mode" { "Regression002" | & $Bootstrap }
Invoke-Test "Invalid Name" { & $Bootstrap -NombreDeProyecto "***" }

# TODO: implement scenarios 4-10 with environment simulation (path modification, failures)

# GENERAR REPORTE EJECUTIVO
$PassCount = ($Results | Where-Object Status -eq "PASS").Count
$FailCount = ($Results | Where-Object Status -eq "FAIL").Count

Write-Host "`n========================================="
Write-Host "HERMES ENTERPRISE - TEST SUITE SUMMARY"
Write-Host "========================================="
Write-Host "Escenarios: $($Results.Count)"
Write-Host "PASS: $PassCount | FAIL:$FailCount"
Write-Host "Estado: $(if($FailCount -eq 0){'COMPLETADO'}else{'FALLIDO'})"
Write-Host "========================================="

if ($FailCount -gt 0) { exit 1 }
