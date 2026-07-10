<#
.SYNOPSIS
    Test-BootstrapOrchestrator.ps1 - Verificación ejecutable Paso 4
.DESCRIPTION
    Ejecuta el orquestador y valida su salida.
    NO requiere Pester. Corre con pwsh puro.
.NOTES
    Paso 4 - BootstrapOrchestrator
#>
param([string]$ProjectRoot = 'D:\HERMES-ENTERPRISE')
$ErrorActionPreference = 'Stop'
$suite = 'Test-BootstrapOrchestrator'
$pass = 0; $fail = 0; $out = [System.Collections.ArrayList]::new()

function Assert($name, $cond, $detail='') {
    if ($cond) {
        $script:pass++
        $null = $out.Add("[PASS] $name")
    } else {
        $script:fail++
        $null = $out.Add("[FAIL] $name :: $detail")
    }
}

# ── Setup ──────────────────────────────────────────────────────
$orchestratorPath = Join-Path $ProjectRoot 'motor\bootstrap\engine\BootstrapOrchestrator.ps1'
. $orchestratorPath

# 1. Script existe y se carga
Assert 'Orchestrator file exists' (Test-Path $orchestratorPath)

# 2. Función principal disponible
$cmd = Get-Command Invoke-BootstrapOrchestrator -ErrorAction SilentlyContinue
Assert 'Function defined' ($null -ne $cmd)

# 3. Parámetros esperados
Assert 'Param ProjectPath' ($cmd.Parameters.ContainsKey('ProjectPath'))
Assert 'Param ContextPath' ($cmd.Parameters.ContainsKey('ContextPath'))
Assert 'Param Force' ($cmd.Parameters.ContainsKey('Force'))

# 4. Ejecución sin excepciones no capturadas
$tmpProject = Join-Path $env:TEMP "hermes-orchestrator-test-$([guid]::NewGuid().ToString('n').Substring(0,8))"
New-Item -ItemType Directory -Path $tmpProject -Force | Out-Null
try {
    $result = Invoke-BootstrapOrchestrator -ProjectPath $tmpProject -Force
    Assert 'Execution without throw' $true
} catch {
    Assert 'Execution without throw' $false ($_.Exception.Message)
    $result = $null
}

# 5. Resultado tiene la forma esperada
if ($result) {
    Assert 'Has Success field'      ($null -ne $result.PSObject.Properties['Success'])
    Assert 'Has StepsExecuted'      ($null -ne $result.PSObject.Properties['StepsExecuted'])
    Assert 'Has StepsFailed'        ($null -ne $result.PSObject.Properties['StepsFailed'])
    Assert 'Has TotalDuration'      ($null -ne $result.PSObject.Properties['TotalDuration'])
    Assert 'Has Errors'             ($null -ne $result.PSObject.Properties['Errors'])
    Assert 'Has Steps'              ($null -ne $result.PSObject.Properties['Steps'])
    Assert 'Has GeneratedAt'        ($null -ne $result.PSObject.Properties['GeneratedAt'])
}

# 6. Pasos ejecutados (5 de 6, ya que ContextEngine/VSCodeManager podrían no estar disponibles)
if ($result -and $result.Steps) {
    $stepNames = $result.Steps | ForEach-Object { $_.Step }
    Assert 'Has at least 3 steps'  ($stepNames.Count -ge 3)
    Assert 'First step is BootstrapState'    ($stepNames[0] -eq 'BootstrapState')
    Assert 'Second step is BootstrapWizard'  ($stepNames[1] -eq 'BootstrapWizard')
    Assert 'Third step is EnvironmentManager'($stepNames[2] -eq 'EnvironmentManager')
}

# 7. No lanzó excepciones sin captura (resultado debe existir)
Assert 'Returned result object' ($null -ne $result)

# 8. Tamaño del archivo <400 líneas (spec: ~150 líneas, tope 400)
$lineCount = (Get-Content $orchestratorPath).Count
Assert "File under 400 lines (actual: $lineCount)" ($lineCount -le 400)

# 9. No duplica validaciones de contratos
$content = Get-Content $orchestratorPath -Raw
Assert 'No Test-ContextContracts ref' ($content -notmatch 'Test-ContextContracts')
Assert 'No ContractValidation ref'   ($content -notmatch 'ContractValidation')

# 10. Delegación correcta: invoca los Step functions en lugar de reimplementar
Assert 'Delega a Invoke-GitManagerStep'      ($content -match 'Invoke-GitManagerStep')
Assert 'Delega a Invoke-ContextEngineStep'   ($content -match 'Invoke-ContextEngineStep')
Assert 'Delega a Invoke-VSCodeManagerStep'   ($content -match 'Invoke-VSCodeManagerStep')
Assert 'Delega a Invoke-BootstrapWizardStep' ($content -match 'Invoke-BootstrapWizardStep')

# 11. Cleanup
Remove-Item -Recurse -Force $tmpProject -ErrorAction SilentlyContinue

# 12. Salida final
Write-Host "`n========================================================================" -F Cyan
Write-Host " $suite" -F Cyan
Write-Host " $pass PASS / $fail FAIL" -F $(if ($fail -eq 0) { 'Green' } else { 'Red' })
Write-Host "========================================================================`n" -F Cyan
$out | ForEach-Object {
    $color = if ($_ -match '^\[PASS\]') { 'Green' } else { 'Red' }
    Write-Host $_ -F $color
}
Write-Host ""

exit [int]($fail -gt 0)
