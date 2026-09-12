<#
.SYNOPSIS
    Tests unitarios del contrato BootstrapState (Paso 1 - contratos puros).
.DESCRIPTION
    Cubre: creación, serialización, deserialización, clonación, igualdad,
    validación. No prueba lógica de dominio (eso pertenece a sprints futuros).
.NOTES
    Proyecto    : HERMES-ENTERPRISE
    Autor       : Fredy Alejandro Sarmiento Torres
    Version     : 1.0.1 (refactor minimalista)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaRepositorio = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $RutaRepositorio "motor\bootstrap\engine\BootstrapState.ps1")

$testsPasaron = 0; $testsFallaron = 0
function Assert { param([string]$N, [bool]$C, [string]$D = "")
    if ($C) { $script:testsPasaron++; Write-Host "V $N" -Fo Green; if ($D) { Write-Host "  $D" -Fo Gray } }
    else    { $script:testsFallaron++; Write-Host "X $N" -Fo Red;   if ($D) { Write-Host "  $D" -Fo Yellow } }
}

Write-Host "`n========================================" -Fo Cyan
Write-Host " TESTS MINIMOS: BootstrapState" -Fo Cyan
Write-Host "========================================`n" -Fo Cyan

# ── creación ──────────────────────────────────────────────────────
$s = New-HermesBootstrapState
Assert "Creacion"        ($null -ne $s)                                    "estado creado"
Assert "Id es GUID"      ([guid]::TryParse($s.Id, [ref][guid]::Empty))     "Id: $($s.Id)"
Assert "Phase inicial"   ($s.Phase -eq [BootstrapPhase]::Fase00)           "Fase00"
Assert "Status inicial"  ($s.Status -eq [PhaseStatus]::Pending)            "Pending"
Assert "StartedAt set"   (-not [string]::IsNullOrWhiteSpace($s.StartedAt)) "$($s.StartedAt)"
Assert "FinishedAt null" ($null -eq $s.FinishedAt)

# ── serialización ─────────────────────────────────────────────────
$json = ConvertTo-HermesBootstrapJson -State $s
Assert "Serializa a JSON" (-not [string]::IsNullOrWhiteSpace($json)) "$($json.Length) chars"
Assert "JSON contiene Id" ($json -match [regex]::Escape($s.Id))

# ── deserialización ───────────────────────────────────────────────
$d  = ConvertFrom-HermesBootstrapJson -Json $json
Assert "Deserializa"        ($null -ne $d -and $d.Id -eq $s.Id)
Assert "Mantiene estructura" ($null -ne $d.PSObject.Properties["Phase"] -and $null -ne $d.PSObject.Properties["Status"])

# ── round-trip ────────────────────────────────────────────────────
$j1 = ConvertTo-HermesBootstrapJson -State $s
$j2 = ConvertTo-HermesBootstrapJson -State (ConvertFrom-HermesBootstrapJson -Json $j1)
Assert "Round-trip estable" ($j1.Length -eq $j2.Length)

# ── clonación inmutable ──────────────────────────────────────────
$id0   = $s.Id
$ph0   = $s.Phase
$j     = @{ Phase = [BootstrapPhase]::Fase05 }
$clone = Copy-HermesBootstrapState -State $s -Overrides $j
Assert "Clon existe"            ($null -ne $clone)
Assert "Original no mutado"     ($s.Phase -eq $ph0 -and $s.Id -eq $id0) "Phase sigue $ph0"
Assert "Clon aplico override"   ($clone.Phase -eq [BootstrapPhase]::Fase05 -or $clone.Phase -eq "Fase05")
Assert "Id preservado en clon"  ($clone.Id -eq $id0)

# ── igualdad ──────────────────────────────────────────────────────
$jA = ConvertTo-HermesBootstrapJson -State $s
$jB = ConvertTo-HermesBootstrapJson -State (ConvertFrom-HermesBootstrapJson -Json $jA)
Assert "Igualdad via JSON" ($jA -eq $jB)

# ── validación: estado válido ────────────────────────────────────
$r = Test-HermesBootstrapState -State $s
Assert "Estado valido pasa"  $r.EsValido

# ── validación: estado inválido ──────────────────────────────────
$inv = [PSCustomObject]@{ Phase = [BootstrapPhase]::Fase00; Status = [PhaseStatus]::Pending }
$r2  = Test-HermesBootstrapState -State $inv
Assert "Sin Id falla" (-not $r2.EsValido) "errores: $($r2.Errores.Count)"

# ── validación: enum fuera de rango ──────────────────────────────
$inv2 = [PSCustomObject]@{ Id = ([guid]::NewGuid()).ToString(); Phase = 999; Status = [PhaseStatus]::Pending; StartedAt = [datetime]::UtcNow.ToString("o") }
$r3   = Test-HermesBootstrapState -State $inv2
Assert "Phase invalido falla" (-not $r3.EsValido) "errores: $($r3.Errores -join '; ')"

# ── reporte ───────────────────────────────────────────────────────
$total = $testsPasaron + $testsFallaron
$cov   = if ($total -gt 0) { [math]::Round(($testsPasaron / $total) * 100, 2) } else { 0 }
Write-Host "`n========================================" -Fo Cyan
Write-Host " RESULTADO: $testsPasaron/$total  (cobertura $cov%)" -Fo $(if ($testsFallaron -eq 0) { "Green" } else { "Red" })
Write-Host "========================================`n" -Fo Cyan
exit $(if ($testsFallaron -eq 0) { 0 } else { 1 })
