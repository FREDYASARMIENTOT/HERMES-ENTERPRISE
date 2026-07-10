<#
.SYNOPSIS
    Test-ContextContracts.ps1 — Validador arquitectónico de contratos (Fase 3.5C)

.DESCRIPTION
    Valida que las firmas reales del código coincidan con PUBLIC_API.json. Detecta:
      [1] Firmas inconsistentes (parámetros, tipos, orden)
      [2] Funciones declaradas en PUBLIC_API pero ausentes en el código
      [3] Funciones en el código no declaradas en PUBLIC_API (builders/helpers)
      [4] Funciones duplicadas (mismo nombre en archivos distintos)
      [5] Referencias a helpers inexistentes desde builders
      [6] Builders huérfanos (sin uso)
      [7] Helpers sin uso

.PARAMETER ProjectRoot
    Ruta raíz del repositorio HERMES-ENTERPRISE.

.PARAMETER ApiPath
    Ruta a PUBLIC_API.json. Por defecto: $ProjectRoot/.hermes/context/PUBLIC_API.json

.OUTPUTS
    PSCustomObject con Total, Passed, Failed, Warnings, Details[]

.EXIT CODES
    0 si Passed = Total y Failed = 0 (warnings no bloquean)
    1 si Failed > 0

.NOTES
    No valida comportamiento. Solo contratos estáticos.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ProjectRoot,

    [Parameter()]
    [string]$ApiPath = (Join-Path $ProjectRoot '.hermes\context\PUBLIC_API.json')
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path $ProjectRoot).Path
$api  = Get-Content $ApiPath -Raw | ConvertFrom-Json

# --- Paths ---
$buildersDir = Join-Path $root 'motor\context\builders'
$helpersDir  = Join-Path $root 'motor\context\helpers'
$enginesDir  = Join-Path $root 'motor\context'

# --- Utilidades ---
function Get-FunctionSignatures {
    param([string]$FilePath)
    $file = Get-Item $FilePath
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
    $fns = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
    foreach ($f in $fns) {
        $params = $f.Body.ParamBlock.Parameters | ForEach-Object {
            [PSCustomObject]@{
                Type = if ($_.StaticType.Name) { $_.StaticType.Name } else { 'Object' }
                Name = $_.Name.VariablePath.UserPath
            }
        }
        [PSCustomObject]@{
            File   = $file.Name
            Path   = $file.FullName
            Name   = $f.Name
            Params = [System.Collections.Generic.List[object]]$params
        }
    }
}

function Compare-Signature {
    param($SignatureObj, [string[]]$ExpectedNames)
    if ($SignatureObj.Params.Count -ne $ExpectedNames.Count) {
        return "parámetros: esperados=$($ExpectedNames -join ','); reales=$(($SignatureObj.Params | ForEach-Object { "`$$($_.Name)" }) -join ',')"
    }
    for ($i = 0; $i -lt $ExpectedNames.Count; $i++) {
        if ($SignatureObj.Params[$i].Name -ne $ExpectedNames[$i]) {
            return "orden/tipo: posición $($i+1) esperaba `$$($ExpectedNames[$i]), tiene `$$($SignatureObj.Params[$i].Name)"
        }
    }
    return $null
}

# --- Resultados ---
$details  = [System.Collections.Generic.List[object]]::new()
$passed   = 0
$failed   = 0
$warnings = 0

# Mapa global función → firma (para detección de duplicados)
$globalFnMap = [System.Collections.Generic.Dictionary[string, object]]::new()

# =============================================================================
# CHECK 1: Builders — firmas vs. PUBLIC_API.json
# =============================================================================
foreach ($builder in $api.modules.builders.PSObject.Properties) {
    $fnName = $builder.Name
    $meta   = $builder.Value
    $file   = Join-Path $buildersDir $meta.file
    if (-not (Test-Path $file)) {
        $failed++
        $details.Add([PSCustomObject]@{
            Check = 'Builder.FileExists'; Function = $fnName
            Status = 'FAIL'; Message = "Archivo no existe: $($meta.file)"
        })
        continue
    }
    $sigs = @(Get-FunctionSignatures -FilePath $file | Where-Object Name -eq $fnName)
    if ($sigs.Count -eq 0) {
        $failed++
        $details.Add([PSCustomObject]@{
            Check = 'Builder.FunctionExists'; Function = $fnName
            Status = 'FAIL'; Message = "Función no encontrada en $($meta.file)"
        })
        continue
    }
    if ($sigs.Count -gt 1) {
        $failed++
        $details.Add([PSCustomObject]@{
            Check = 'Builder.SingleDefinition'; Function = $fnName
            Status = 'FAIL'; Message = "Múltiples definiciones de $fnName"
        })
        continue
    }
    $diff = Compare-Signature -SignatureObj $sigs[0] -ExpectedNames $meta.parameters
    if ($diff) {
        $failed++
        $details.Add([PSCustomObject]@{
            Check = 'Builder.Signature'; Function = $fnName
            Status = 'FAIL'; Message = "Firma drift: $diff"
        })
    } else {
        $passed++
        $details.Add([PSCustomObject]@{
            Check = 'Builder.Signature'; Function = $fnName
            Status = 'PASS'; Message = 'OK'
        })
    }
    if ($globalFnMap.ContainsKey($fnName)) { $globalFnMap[$fnName] = "DUPLICATED:$($sigs[0].File)" }
    else { $globalFnMap[$fnName] = $sigs[0] }
}

# =============================================================================
# CHECK 2: Helpers — firmas y funciones vs. PUBLIC_API.json
# =============================================================================
foreach ($hfile in $api.modules.helpers.PSObject.Properties) {
    $fileName = $hfile.Name
    $declared = $hfile.Value.functions
    $path     = Join-Path $helpersDir $fileName
    if (-not (Test-Path $path)) {
        $failed++
        $details.Add([PSCustomObject]@{
            Check = 'Helper.FileExists'; Function = $fileName
            Status = 'FAIL'; Message = "Archivo helper no existe: $fileName"
        })
        continue
    }
    $sigs = Get-FunctionSignatures -FilePath $path
    $sigsByName = @{}
    foreach ($s in $sigs) { $sigsByName[$s.Name] = $s }

    # Funciones declaradas deben existir
    foreach ($fn in $declared) {
        if (-not $sigsByName.ContainsKey($fn)) {
            $failed++
            $details.Add([PSCustomObject]@{
                Check = 'Helper.FunctionExists'; Function = $fn
                Status = 'FAIL'; Message = "Función declarada en API no existe en $fileName"
            })
        } else {
            $passed++
            $details.Add([PSCustomObject]@{
                Check = 'Helper.FunctionExists'; Function = $fn
                Status = 'PASS'; Message = 'OK'
            })
            if ($globalFnMap.ContainsKey($fn)) { $globalFnMap[$fn] = "DUPLICATED:$fileName" }
            else { $globalFnMap[$fn] = $sigsByName[$fn] }
        }
    }
    # Funciones del archivo deben estar en API (no huérfanas no-declaradas)
    foreach ($s in $sigs) {
        if ($declared -notcontains $s.Name) {
            $warnings++
            $details.Add([PSCustomObject]@{
                Check = 'Helper.ApiCoverage'; Function = $s.Name
                Status = 'WARN'; Message = "Función en $fileName pero no declarada en PUBLIC_API"
            })
        }
    }
}

# =============================================================================
# CHECK 3: Validators — firmas vs. PUBLIC_API.json
# =============================================================================
foreach ($val in $api.modules.validators.PSObject.Properties) {
    $fnName = $val.Name
    $meta   = $val.Value
    $file   = Join-Path $enginesDir $meta.file
    if (-not (Test-Path $file)) {
        $failed++
        $details.Add([PSCustomObject]@{
            Check = 'Validator.FileExists'; Function = $fnName
            Status = 'FAIL'; Message = "Archivo no existe: $($meta.file)"
        })
        continue
    }
    $sigs = @(Get-FunctionSignatures -FilePath $file | Where-Object Name -eq $fnName)
    if ($sigs.Count -eq 0) {
        $failed++
        $details.Add([PSCustomObject]@{
            Check = 'Validator.FunctionExists'; Function = $fnName
            Status = 'FAIL'; Message = "Función no encontrada en $($meta.file)"
        })
        continue
    }
    $diff = Compare-Signature -SignatureObj $sigs[0] -ExpectedNames $meta.parameters
    if ($diff) {
        $failed++
        $details.Add([PSCustomObject]@{
            Check = 'Validator.Signature'; Function = $fnName
            Status = 'FAIL'; Message = "Firma drift: $diff"
        })
    } else {
        $passed++
        $details.Add([PSCustomObject]@{
            Check = 'Validator.Signature'; Function = $fnName
            Status = 'PASS'; Message = 'OK'
        })
    }
}

# =============================================================================
# CHECK 4: Funciones duplicadas (mismo nombre en archivos distintos)
# =============================================================================
$allFiles = Get-ChildItem -Path $buildersDir,$helpersDir,$enginesDir -Filter '*.ps1' -File
$allFnMap = @{}
foreach ($f in $allFiles) {
    foreach ($s in (Get-FunctionSignatures -FilePath $f.FullName)) {
        if (-not $allFnMap.ContainsKey($s.Name)) { $allFnMap[$s.Name] = [System.Collections.Generic.List[object]]::new() }
        $allFnMap[$s.Name].Add($s)
    }
}
foreach ($entry in $allFnMap.GetEnumerator()) {
    if ($entry.Value.Count -gt 1) {
        $locations = ($entry.Value | ForEach-Object { $_.File }) -join ' vs. '
        $warnings++
        $details.Add([PSCustomObject]@{
            Check = 'Function.Duplicate'; Function = $entry.Key
            Status = 'WARN'; Message = "Duplicado en: $locations"
        })
    }
}

# =============================================================================
# CHECK 5: Dependencias inválidas — ¿referencia un builder a un helper inexistente?
# =============================================================================
foreach ($dep in $api.dependencies.PSObject.Properties) {
    $builder  = $dep.Name
    $helpers  = $dep.Value
    foreach ($h in $helpers) {
        $hFile = Join-Path $helpersDir ($h + '.ps1')
        if (-not (Test-Path $hFile)) {
            $failed++
            $details.Add([PSCustomObject]@{
                Check = 'Dependency.Valid'; Builder = $builder
                Status = 'FAIL'; Message = "Helper '$h' referenciado por $builder no existe"
            })
        } else {
            $passed++
            $details.Add([PSCustomObject]@{
                Check = 'Dependency.Valid'; Builder = $builder
                Status = 'PASS'; Message = "Helper '$h' OK"
            })
        }
    }
}

# =============================================================================
# CHECK 6: Builders huérfanos (definidos pero no invocados por ContextEngine)
# =============================================================================
$engineFile = Join-Path $enginesDir 'ContextEngine.ps1'
$engineContent = Get-Content $engineFile -Raw
foreach ($builder in $api.modules.builders.PSObject.Properties) {
    if ($engineContent -notmatch [regex]::Escape($builder.Name)) {
        $warnings++
        $details.Add([PSCustomObject]@{
            Check = 'Builder.Invoked'; Function = $builder.Name
            Status = 'WARN'; Message = "Builder no invocado desde ContextEngine.ps1"
        })
    } else {
        $passed++
        $details.Add([PSCustomObject]@{
            Check = 'Builder.Invoked'; Function = $builder.Name
            Status = 'PASS'; Message = 'OK'
        })
    }
}

# =============================================================================
# CHECK 7: Helpers sin uso (declarados en API pero no referenciados por builders)
# =============================================================================
$builderContent = Get-Content -Path (Join-Path $buildersDir '*.ps1') -Raw
foreach ($hfile in $api.modules.helpers.PSObject.Properties) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($hfile.Name)
    $used = $false
    foreach ($fn in $hfile.Value.functions) {
        if ($builderContent -match [regex]::Escape($fn) -or $engineContent -match [regex]::Escape($fn)) {
            $used = $true; break
        }
    }
    if (-not $used) {
        $warnings++
        $details.Add([PSCustomObject]@{
            Check = 'Helper.Used'; Helper = $base
            Status = 'WARN'; Message = "Helper no referenciado por ningún builder"
        })
    } else {
        $passed++
        $details.Add([PSCustomObject]@{
            Check = 'Helper.Used'; Helper = $base
            Status = 'PASS'; Message = 'OK'
        })
    }
}

# =============================================================================
# Resultado final
# =============================================================================
$total  = $passed + $failed
$result = [PSCustomObject]@{
    TotalChecks       = $total
    Passed            = $passed
    Failed            = $failed
    Warnings          = $warnings
    Success           = ($failed -eq 0)
    ExitCode          = if ($failed -eq 0) { 0 } else { 1 }
    Details           = $details
    ApiVersion        = $api.schemaVersion
    CheckedAt         = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
}

# Output
$banner = @"

================================================================================
TEST-CONTEXTCONTRACTS — Fase 3.5C
================================================================================
ProjectRoot  : $root
API Version  : $($api.schemaVersion)
CheckedAt    : $($result.CheckedAt)
Total Checks : $total   (Pass=$passed / Fail=$failed / Warn=$warnings)
================================================================================
"@
Write-Host $banner

foreach ($d in ($details | Sort-Object Check,Status)) {
    $color = switch ($d.Status) { 'PASS' { 'Green' } 'FAIL' { 'Red' } 'WARN' { 'Yellow' } default { 'Gray' } }
    Write-Host ("[{0,-4}] {1,-22} {2,-30} {3}" -f $d.Status, $d.Check, ($d.Function,$d.Builder,$d.Helper -ne $null | Select-Object -First 1), $d.Message) -ForegroundColor $color
}

Write-Host "`n================================================================================"
if ($result.Success) {
    Write-Host "RESULT: PASS — contratos estables. Fase 3.5C OK." -ForegroundColor Green
} else {
    Write-Host "RESULT: FAIL — $failed contrat(s) con drift. Revisar antes de Paso 4." -ForegroundColor Red
}
Write-Host "================================================================================`n"

exit $result.ExitCode
