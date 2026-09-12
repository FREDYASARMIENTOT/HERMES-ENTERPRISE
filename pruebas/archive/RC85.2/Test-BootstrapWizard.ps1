<#
.SYNOPSIS
    Tests del Wizard Bootstrap (Sprint 2) - suite regex completa.
.DESCRIPTION
    25+ casos: 11 positivos + 14+ negativos. Validación case-sensitive.
.NOTES
    Proyecto  : HERMES-ENTERPRISE
    Sprint    : Paso 2
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RutaRepo  = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$RutaWizard = Join-Path $RutaRepo "motor\bootstrap\engine\BootstrapWizard.ps1"
. $RutaWizard

$p=0; $f=0
function T($nombre, $entrada, $esperaValido) {
    $r = Test-HermesBootstrapNombreProyecto -Nombre $entrada
    $ok = ($r.EsValido -eq $esperaValido)
    $etiq = if ($esperaValido) { 'VALID' } else { 'INVAL' }
    if ($ok) { $script:p++; Write-Host "[OK] $etiq '$entrada'" -Fo Green }
    else     { $script:f++; Write-Host "[X]  $etiq '$entrada' (Esper=$esperaValido Obten=$($r.EsValido)) $($r.Errores -join ';')" -Fo Red }
}

Write-Host "`n===========================================" -Fo Cyan
Write-Host " TESTS WIZARD - Suite regex" -Fo Cyan
Write-Host "===========================================`n" -Fo Cyan

# ── POSITIVOS (11 casos) ─────────────────────────────────────────
Write-Host "─ Positivos ─" -Fo Yellow
T 'PY_Encuesta_Percepcion'          'PY_Encuesta_Percepcion'          $true
T 'py_encuesta'                     'py_encuesta'                     $true
T 'MiProyecto2026'                  'MiProyecto2026'                  $true
T 'Mi-Proyecto'                     'Mi-Proyecto'                     $true
T 'Proyecto_AI'                    'Proyecto_AI'                    $true
T 'aaa (minimo)'                    'aaa'                             $true
T 'A1a'                             'A1a'                             $true
T '64 chars (maximo)'               'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'  $true
T 'A_a'                             'A_a'                             $true
T 'Z-9'                             'Z-9'                             $true
T 'Test_123-proyecto'               'Test_123-proyecto'               $true

# ── NEGATIVOS (14 casos) ─────────────────────────────────────────
Write-Host "`n─ Negativos ─" -Fo Yellow
T 'vacio'                           ''                                  $false
T 'solo espacios'                   '   '                               $false
T '2 chars (muy corto)'             'ab'                                $false
T 'inicia con numero'               '1Proyecto'                         $false
T 'inicia con guion medio'          '-Proyecto'                         $false
T 'inicia con guion bajo'           '_Proyecto'                         $false
T 'espacio interno'                 'Mi Proyecto'                       $false
T 'caracter #'                      'Proyecto#'                         $false
T 'caracter *'                      'Proyecto*'                         $false
T 'caracter ?'                      'Proyecto?'                         $false
T 'caracter %'                      'Proyecto%'                         $false
T 'tilde'                           'Proyectó'                           $false
T '65 chars (muy largo)'            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' $false
T 'punto prohibido'                 'Proyecto.AI'                       $false

# ── Case-sensitive ────────────────────────────────────────────────
Write-Host "`n─ Case-sensitive ─" -Fo Yellow
$mayus = Test-HermesBootstrapNombreProyecto -Nombre 'MiProyecto'
$minus = Test-HermesBootstrapNombreProyecto -Nombre 'miproyecto'
$csOk  = $mayus.EsValido -and $minus.EsValido -and $mayus.Errores.Count -eq 0 -and $minus.Errores.Count -eq 0
if ($csOk) { $p++; Write-Host "[OK] ambas variantes conservan capitalizacion" -Fo Green }
else       { $f++; Write-Host "[X]  case-sensitive falla" -Fo Red }

# ── REPORTE ───────────────────────────────────────────────────────
$total = $p + $f
$cov   = if ($total) { [math]::Round(($p/$total)*100,2) } else { 0 }
Write-Host "`n===========================================" -Fo Cyan
Write-Host " RESULTADO: $p/$total ($cov%)" -Fo $(if($f -eq 0){'Green'}else{'Red'})
Write-Host "===========================================`n" -Fo Cyan
exit $(if($f -eq 0){0}else{1})
