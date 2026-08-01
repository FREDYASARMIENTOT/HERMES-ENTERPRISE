<#
.SYNOPSIS
    Prueba ad-hoc para validar AzureProviderAuthentication.

.DESCRIPTION
    Valida que el componente AzureProviderAuthentication cumple con:
    - Estructura de código correcta
    - Función pública Connect-HermesAzure expuesta
    - Funciones privadas requeridas presentes
    - NO contiene referencias a Data Factory
    - NO contiene referencias a Storage
    - Scope lock respetado (solo autenticación)

.NOTES
    Tipo: Ad-hoc verification
    Autor: Hermes Enterprise
    Fecha: 2026-07-10
#>

$ErrorActionPreference = 'Stop'
$rootDir = 'D:\HERMES-ENTERPRISE'
$componentPath = Join-Path $rootDir 'motor\providers\azure\AzureProviderAuthentication.ps1'

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    if ($Passed) {
        Write-Host "OK: $TestName" -ForegroundColor Green
    }
    else {
        Write-Host "FALLO: $TestName - $Message" -ForegroundColor Red
    }
    return $Passed
}

# ═══════════════════════════════════════════════════════════════════════════
# PRUEBAS DE VALIDACIÓN
# ═══════════════════════════════════════════════════════════════════════════

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "TEST: AzureProviderAuthentication - Sprint 6.2" -ForegroundColor Cyan
Write-Host "======================================================================`n" -ForegroundColor Cyan

$testResults = @()

# T1: El archivo existe
$testResults += Write-TestResult -TestName "T1: Archivo AzureProviderAuthentication.ps1 existe" `
    -Passed (Test-Path $componentPath) `
    -Message "Archivo no encontrado en $componentPath"

if (-not (Test-Path $componentPath)) {
    Write-Host "`nFALLO: Pruebas no pueden continuar sin el archivo principal." -ForegroundColor Red
    exit 1
}

# T2: El archivo contiene la función pública Connect-HermesAzure
$content = Get-Content $componentPath -Raw
$hasConnectFunction = $content -match 'function\s+Connect-HermesAzure'
$testResults += Write-TestResult -TestName "T2: Función pública Connect-HermesAzure definida" `
    -Passed $hasConnectFunction `
    -Message "Función Connect-HermesAzure no encontrada"

# T3: Parámetros obligatorios presentes (regex permite líneas intermedias como [ValidateNotNullOrEmpty()])
$hasCorreoParam = $content -match 'Mandatory\s*=\s*\$true[\s\S]*?\[string\]\$CorreoElectronico'
$testResults += Write-TestResult -TestName "T3: Parámetro CorreoElectronico obligatorio" `
    -Passed $hasCorreoParam `
    -Message "Parámetro CorreoElectronico no encontrado o no es obligatorio"

# T4: Funciones privadas requeridas
$privateFunctions = @(
    'VerificarAzureCLI',
    'ObtenerSesionActual',
    'ObtenerSuscripcionesDisponibles',
    'SeleccionarSubscription',
    'SeleccionarSubscriptionInteractiva',
    'ConstruirAzureContext'
)

$missingFunctions = @()
foreach ($func in $privateFunctions) {
    if ($content -notmatch "function\s+$func") {
        $missingFunctions += $func
    }
}

$allFunctionsPresent = $missingFunctions.Count -eq 0
$testResults += Write-TestResult -TestName "T4: Funciones privadas requeridas presentes" `
    -Passed $allFunctionsPresent `
    -Message "Faltan: $($missingFunctions -join ', ')"

# T5: NO contiene referencias a Data Factory
$hasDataFactory = $content -imatch 'datafactory|adf|pipeline|data\s*factory'
$testResults += Write-TestResult -TestName "T5: Sin referencias a Data Factory" `
    -Passed (-not $hasDataFactory) `
    -Message "Se encontraron referencias a Data Factory (viola scope lock)"

# T6: NO contiene referencias a Storage
$hasStorage = $content -imatch 'storage|blob|container|adls'
$testResults += Write-TestResult -TestName "T6: Sin referencias a Storage" `
    -Passed (-not $hasStorage) `
    -Message "Se encontraron referencias a Storage (viola scope lock)"

# T7: Utiliza comandos az correctos
$usesAzLogin = $content -match 'az\s+login'
$usesAzAccountShow = $content -match 'az\s+account\s+show'
$usesAzAccountList = $content -match 'az\s+account\s+list'
$usesAzAccountSet = $content -match 'az\s+account\s+set'

$usesCorrectCommands = $usesAzLogin -and $usesAzAccountShow -and $usesAzAccountList -and $usesAzAccountSet
$testResults += Write-TestResult -TestName "T7: Comandos az correctos (login, account show/list/set)" `
    -Passed $usesCorrectCommands `
    -Message "Faltan comandos az requeridos"

# T8: Construye AzureContext con campos requeridos
$contextFields = @(
    'Usuario',
    'IdentificadorInquilino',
    'NombreInquilino',
    'IdentificadorSuscripcion',
    'NombreSuscripcion',
    'Entorno',
    'EstaAutenticado',
    'MetodoAutenticacion'
)

$missingFields = @()
foreach ($field in $contextFields) {
    if ($content -notmatch $field) {
        $missingFields += $field
    }
}

$allFieldsPresent = $missingFields.Count -eq 0
$testResults += Write-TestResult -TestName "T8: AzureContext contiene todos los campos requeridos" `
    -Passed $allFieldsPresent `
    -Message "Faltan campos: $($missingFields -join ', ')"

# T9: Nombres en español (verificación básica)
$spanishNames = $content -match 'CorreoElectronico|IdentificadorSuscripcion|EstaAutenticado|MetodoAutenticacion'
$testResults += Write-TestResult -TestName "T9: Nombres de variables/parámetros en español" `
    -Passed $spanishNames `
    -Message "Nombres no están completamente en español"

# T10: No modifica Bootstrap Engine
$modifiesBootstrap = $content -imatch 'bootstrap|start-hermesproject'
$testResults += Write-TestResult -TestName "T10: No modifica Bootstrap Engine" `
    -Passed (-not $modifiesBootstrap) `
    -Message "Se encontraron referencias a Bootstrap (viola restricciones)"

# T11: No modifica Context Engine
$modifiesContext = $content -imatch 'contextengine|current_state\.md'
$testResults += Write-TestResult -TestName "T11: No modifica Context Engine" `
    -Passed (-not $modifiesContext) `
    -Message "Se encontraron referencias a Context Engine (viola restricciones)"

# T12: No modifica Kernel
$modifiesKernel = $content -imatch 'kernel|motor\\kernel'
$testResults += Write-TestResult -TestName "T12: No modifica Kernel" `
    -Passed (-not $modifiesKernel) `
    -Message "Se encontraron referencias a Kernel (viola restricciones)"

# ═══════════════════════════════════════════════════════════════════════════
# RESULTADO FINAL
# ═══════════════════════════════════════════════════════════════════════════

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_ }).Count

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "RESULTADO: $passedTests/$totalTests pruebas pasaron" -ForegroundColor Cyan
Write-Host "======================================================================`n" -ForegroundColor Cyan

if ($passedTests -eq $totalTests) {
    Write-Host "OK: AzureProviderAuthentication cumple con todos los criterios de Sprint 6.2" -ForegroundColor Green
    exit 0
}
else {
    $failedCount = $totalTests - $passedTests
    Write-Host "FALLO: $failedCount prueba(s) fallaron. Revisar scope lock y estructura." -ForegroundColor Red
    exit 1
}
