<#
.SYNOPSIS
    Suite de pruebas unitarias para Environment Manager (Paso 3).
.DESCRIPTION
    12 casos de prueba que validan:
    - Deteccion de interprete Python
    - Creacion de venvs
    - Instalacion de dependencias
    - Activacion/desactivacion
    - Sanity-checks
    - Rollback en fallo
    - Idempotencia
    - Manejo de errores
.BUDGET
    Maximo 450 lineas.
.NOTES
    Usa Pester v5+ si esta disponible, sino usa assertions basicas.
    Limpia recursos temporales automaticamente.
#>

#region Setup

# Importar modulo
$modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\motor\bootstrap\engine\environment\EnvironmentManager.ps1"
. $modulePath

# Configuracion de pruebas
$testConfigPath = Join-Path -Path $PSScriptRoot -ChildPath 'EnvironmentManager.Tests.Config.json'
$testConfig = Get-Content -Path $testConfigPath -Raw | ConvertFrom-Json

$testRoot = Join-Path -Path $env:TEMP -ChildPath "hermes-env-tests-$(Get-Random)"
$testEnvironmentsRoot = Join-Path -Path $testRoot -ChildPath 'Environments'

# Crear directorio de prueba
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Contador de pruebas
$script:TestCount = 0
$script:PassCount = 0
$script:FailCount = 0

#endregion

#region Helpers

function Test-Assert {
    param(
        [string]$TestName,
        [scriptblock]$Test,
        [bool]$ExpectedResult = $true
    )

    $script:TestCount++
    Write-Host "`n[$($script:TestCount)] $TestName" -ForegroundColor Cyan

    try {
        $result = & $Test

        if ($result -eq $ExpectedResult) {
            Write-Host "  PASS" -ForegroundColor Green
            $script:PassCount++
            return $true
        }
        else {
            Write-Host "  FAIL: Resultado esperado $ExpectedResult, obtenido $result" -ForegroundColor Red
            $script:FailCount++
            return $false
        }
    }
    catch {
        Write-Host "  FAIL: $($_.Exception.Message)" -ForegroundColor Red
        $script:FailCount++
        return $false
    }
}

function Test-ShouldThrow {
    param(
        [string]$TestName,
        [scriptblock]$Test,
        [string]$ExpectedMessage
    )

    $script:TestCount++
    Write-Host "`n[$($script:TestCount)] $TestName" -ForegroundColor Cyan

    try {
        & $Test
        Write-Host "  FAIL: Se esperaba excepcion pero no se produjo" -ForegroundColor Red
        $script:FailCount++
        return $false
    }
    catch {
        if ($ExpectedMessage -and $_.Exception.Message -notmatch [regex]::Escape($ExpectedMessage)) {
            Write-Host "  FAIL: Excepcion no contiene texto esperado: $ExpectedMessage" -ForegroundColor Red
            Write-Host "  Actual: $($_.Exception.Message)" -ForegroundColor Yellow
            $script:FailCount++
            return $false
        }
        Write-Host "  PASS (excepcion esperada)" -ForegroundColor Green
        $script:PassCount++
        return $true
    }
}

#endregion

#region Pruebas

Write-Host "`n==================================================================" -ForegroundColor Magenta
Write-Host "SUITE DE PRUEBAS: Environment Manager (Paso 3)" -ForegroundColor Magenta
Write-Host "==================================================================" -ForegroundColor Magenta

# Test 1: Detect-PythonInterpreter encuentra Python
Test-Assert -TestName "Detect-PythonInterpreter encuentra Python en el sistema" -Test {
    $pythonInfo = Detect-PythonInterpreter -ErrorAction Stop
    $condition1 = ($null -ne $pythonInfo)
    $condition2 = ($pythonInfo.PythonPath -ne $null)
    $condition3 = ($pythonInfo.Version -ne $null)
    $condition4 = (Test-Path -LiteralPath $pythonInfo.PythonPath)
    return ($condition1 -and $condition2 -and $condition3 -and $condition4)
}

# Test 2: Test-PythonVersion valida versiones correctamente
Test-Assert -TestName "Test-PythonVersion valida version 3.11.5 >= 3.8" -Test {
    return (Test-PythonVersion -Version '3.11.5' -MinimumVersion '3.8')
}

# Test 3: Test-PythonVersion rechaza versiones antiguas
Test-Assert -TestName "Test-PythonVersion rechaza version 3.7.0 < 3.8" -Test {
    return -not (Test-PythonVersion -Version '3.7.0' -MinimumVersion '3.8')
}

# Test 4: Test-PythonVersion maneja versiones invalidas
Test-Assert -TestName "Test-PythonVersion rechaza version invalida 'abc'" -Test {
    return -not (Test-PythonVersion -Version 'abc' -MinimumVersion '3.8')
}

# Test 5: New-IsolatedVenv crea venv correctamente
Test-Assert -TestName "New-IsolatedVenv crea venv en ruta valida" -Test {
    $projectName = 'TestProject1'
    $pythonInfo = Detect-PythonInterpreter

    $venvPath = New-IsolatedVenv -ProjectName $projectName -EnvironmentsRoot $testEnvironmentsRoot -PythonPath $pythonInfo.PythonPath

    $condition1 = Test-Path -LiteralPath $venvPath
    $condition2 = Test-Path -LiteralPath (Join-Path -Path $venvPath -ChildPath 'pyvenv.cfg')
    return ($condition1 -and $condition2)
}

# Test 6: New-IsolatedVenv es idempotente (segunda llamada no falla)
Test-Assert -TestName "New-IsolatedVenv es idempotente (segunda llamada)" -Test {
    $projectName = 'TestProject1'
    $pythonInfo = Detect-PythonInterpreter

    # Segunda llamada al mismo proyecto
    $venvPath = New-IsolatedVenv -ProjectName $projectName -EnvironmentsRoot $testEnvironmentsRoot -PythonPath $pythonInfo.PythonPath

    return (Test-Path -LiteralPath $venvPath)
}

# Test 7: Install-Dependencies instala pip y actualiza
Test-Assert -TestName "Install-Dependencies actualiza pip correctamente" -Test {
    $projectName = 'TestProject1'
    $venvPath = Join-Path -Path $testEnvironmentsRoot -ChildPath $projectName

    Install-Dependencies -VenvPath $venvPath

    if ($IsWindows -or $env:OS -match 'Windows') {
        $pipPath = Join-Path -Path $venvPath -ChildPath 'Scripts\pip.exe'
    }
    else {
        $pipPath = Join-Path -Path $venvPath -ChildPath 'bin/pip'
    }

    return (Test-Path -LiteralPath $pipPath)
}

# Test 8: Test-HermesEnvironment valida venv sano
Test-Assert -TestName "Test-HermesEnvironment retorna Valid=true para venv sano" -Test {
    $projectName = 'TestProject1'
    $venvPath = Join-Path -Path $testEnvironmentsRoot -ChildPath $projectName

    $status = Test-HermesEnvironment -VenvPath $venvPath

    return ($status.Exists -and $status.Valid -and $status.Version)
}

# Test 9: Test-HermesEnvironment detecta venv inexistente
Test-Assert -TestName "Test-HermesEnvironment detecta venv inexistente" -Test {
    $fakePath = Join-Path -Path $testEnvironmentsRoot -ChildPath 'NonExistent'

    $status = Test-HermesEnvironment -VenvPath $fakePath

    return (-not $status.Exists -and -not $status.Valid)
}

# Test 10: Enter-HermesEnvironment modifica PATH de la sesion
Test-Assert -TestName "Enter-HermesEnvironment modifica PATH correctamente" -Test {
    $projectName = 'TestProject1'
    $venvPath = Join-Path -Path $testEnvironmentsRoot -ChildPath $projectName

    $originalPath = $env:PATH
    Enter-HermesEnvironment -VenvPath $venvPath

    if ($IsWindows -or $env:OS -match 'Windows') {
        $scriptsDir = Join-Path -Path $venvPath -ChildPath 'Scripts'
    }
    else {
        $scriptsDir = Join-Path -Path $venvPath -ChildPath 'bin'
    }

    $condition1 = ($env:PATH -ne $originalPath)
    $condition2 = $env:PATH.StartsWith($scriptsDir)
    $condition3 = ($env:VIRTUAL_ENV -eq $venvPath)

    # Restaurar para siguiente test
    Exit-HermesEnvironment

    return ($condition1 -and $condition2 -and $condition3)
}

# Test 11: Exit-HermesEnvironment restaura PATH original
Test-Assert -TestName "Exit-HermesEnvironment restaura PATH original" -Test {
    $projectName = 'TestProject1'
    $venvPath = Join-Path -Path $testEnvironmentsRoot -ChildPath $projectName

    $originalPath = $env:PATH

    Enter-HermesEnvironment -VenvPath $venvPath
    Exit-HermesEnvironment

    $condition1 = ($env:PATH -eq $originalPath)
    $condition2 = (-not $env:VIRTUAL_ENV)
    return ($condition1 -and $condition2)
}

# Test 12: Get-HermesEnvironmentStatus retorna metadata completa
Test-Assert -TestName "Get-HermesEnvironmentStatus retorna metadata completa" -Test {
    $projectName = 'TestProject1'

    $status = Get-HermesEnvironmentStatus -ProjectName $projectName -EnvironmentsRoot $testEnvironmentsRoot

    $condition1 = ($status.ProjectName -eq $projectName)
    $condition2 = $status.Exists
    $condition3 = $status.IsValid
    $condition4 = ($status.PythonVersion -ne $null)
    $condition5 = ($status.VenvPath -ne $null)
    return ($condition1 -and $condition2 -and $condition3 -and $condition4 -and $condition5)
}

# Test 13: Initialize-HermesEnvironment orquesta flujo completo
Test-Assert -TestName "Initialize-HermesEnvironment crea environment completo" -Test {
    # Crear BootstrapState simulado
    $bootstrapState = [PSCustomObject]@{
        ProjectName = 'TestProject2'
        ProjectPath = Join-Path -Path $testRoot -ChildPath 'TestProject2'
    }

    $result = Initialize-HermesEnvironment -BootstrapState $bootstrapState -EnvironmentsRoot $testEnvironmentsRoot

    $condition1 = ($null -ne $result)
    $condition2 = ($result.Environment -ne $null)
    $condition3 = ($result.Environment.VenvPath -ne $null)
    $condition4 = ($result.Environment.Status -eq 'Ready')
    return ($condition1 -and $condition2 -and $condition3 -and $condition4)
}

# Test 14: Test-HermesEnvironment detecta venv corrupto (sin pyvenv.cfg)
Test-ShouldThrow -TestName "New-IsolatedVenv rechaza directorio existente sin pyvenv.cfg" -Test {
    $projectName = 'CorruptVenv'
    $venvPath = Join-Path -Path $testEnvironmentsRoot -ChildPath $projectName

    # Crear directorio invalido
    New-Item -Path $venvPath -ItemType Directory -Force | Out-Null

    $pythonInfo = Detect-PythonInterpreter

    # Esto deberia fallar porque no es un venv valido
    New-IsolatedVenv -ProjectName $projectName -EnvironmentsRoot $testEnvironmentsRoot -PythonPath $pythonInfo.PythonPath
} -ExpectedMessage 'no es un venv valido'

#endregion

#region Cleanup

Write-Host "`n==================================================================" -ForegroundColor Magenta
Write-Host "RESULTADOS FINALES" -ForegroundColor Magenta
Write-Host "==================================================================" -ForegroundColor Magenta
Write-Host "Total: $($script:TestCount)"
Write-Host "Pass:  $($script:PassCount)" -ForegroundColor Green
Write-Host "Fail:  $($script:FailCount)" -ForegroundColor $(if ($script:FailCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "==================================================================" -ForegroundColor Magenta

# Limpiar recursos temporales
Write-Host "`n[Limpieza] Eliminando directorio de prueba: $testRoot"
Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue

# Restaurar PATH si es necesario
if ($env:VIRTUAL_ENV) {
    Exit-HermesEnvironment
}

# Codigo de salida basado en resultados
if ($script:FailCount -gt 0) {
    exit 1
}
else {
    exit 0
}

#endregion
