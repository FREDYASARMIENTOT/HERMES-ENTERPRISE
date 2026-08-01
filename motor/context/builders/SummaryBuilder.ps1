<#
.SYNOPSIS
    SummaryBuilder - Genera SUMMARY.md con resumen de ejecución de Worker
.DESCRIPTION
    Crea un documento que resume lo que hizo un Worker: archivos modificados,
    tests ejecutados, resultado, commit realizado, problemas encontrados y
    próximo paso recomendado.
.BUDGET
    Maximo 150 lineas.
.INPUTS
    - ExecutionData: Datos de ejecución del Worker
    - OutputPath: Ruta donde se generará SUMMARY.md
.OUTPUTS
    PSCustomObject con Path, Tokens, IsValid
.EXAMPLE
    $execData = @{
        WorkerName = "BootstrapWizardWorker"
        StartTime = "2026-01-08T15:30:00"
        EndTime = "2026-01-08T16:45:00"
        FilesCreated = @("motor\bootstrap\engine\BootstrapWizard.ps1")
        FilesModified = @()
        FilesDeleted = @()
        TestsPassed = 15
        TestsFailed = 0
        TestCoverage = 95
        ExitCode = 0
        CommitHash = "abc123def456"
        CommitMessage = "feat: Bootstrap Wizard implementation"
        IssuesFound = @()
        NextStep = "Implementar Environment Manager"
    }
    $result = Build-WorkerSummary -ExecutionData $execData -OutputPath "D:\HERMES-ENTERPRISE\.hermes\context"
#>

# Importar helpers centralizados
. "$PSScriptRoot\..\helpers\DurationHelpers.ps1"
. "$PSScriptRoot\..\helpers\TokenHelpers.ps1"

function Build-WorkerSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExecutionData,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    # Validar ExecutionData
    if (-not $ExecutionData.WorkerName) {
        throw "ExecutionData debe contener WorkerName"
    }
    
    # Construir contenido de SUMMARY.md
    $content = @"
---
contextVersion: 1
generatedAt: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
generator: SummaryBuilder
commit: $($ExecutionData.CommitHash)
---

# Resumen de Ejecución

## Información General
- **Worker:** $($ExecutionData.WorkerName)
- **Inicio:** $($ExecutionData.StartTime)
- **Fin:** $($ExecutionData.EndTime)
- **Duración:** $(Calculate-Duration -Start $ExecutionData.StartTime -End $ExecutionData.EndTime)
- **Código de Salida:** $($ExecutionData.ExitCode)
- **Estado:** $(if ($ExecutionData.ExitCode -eq 0) { "SUCCESS" } else { "FAILED" })

## Archivos Modificados
"@

    # Agregar archivos creados
    if ($ExecutionData.FilesCreated.Count -gt 0) {
        $content += "`n`n### Creados"
        $ExecutionData.FilesCreated | ForEach-Object {
            $content += "`n- ``$_``"
        }
    }
    
    # Agregar archivos modificados
    if ($ExecutionData.FilesModified.Count -gt 0) {
        $content += "`n`n### Modificados"
        $ExecutionData.FilesModified | ForEach-Object {
            $content += "`n- ``$_``"
        }
    }
    
    # Agregar archivos eliminados
    if ($ExecutionData.FilesDeleted.Count -gt 0) {
        $content += "`n`n### Eliminados"
        $ExecutionData.FilesDeleted | ForEach-Object {
            $content += "`n- ``$_``"
        }
    }
    
    if (($ExecutionData.FilesCreated.Count + $ExecutionData.FilesModified.Count + $ExecutionData.FilesDeleted.Count) -eq 0) {
        $content += "`n- (Ningún archivo modificado)"
    }
    
    $content += @"


## Pruebas Ejecutadas
- **Tests Pasados:** $($ExecutionData.TestsPassed)
- **Tests Fallidos:** $($ExecutionData.TestsFailed)
- **Cobertura:** $($ExecutionData.TestCoverage)%
- **Estado:** $(if ($ExecutionData.TestsFailed -eq 0) { "PASS - Todos los tests pasan" } else { "FAIL - Algunos tests fallaron" })

## Commit Realizado
- **Hash:** ``$($ExecutionData.CommitHash | Select-Object -First 7)``
- **Mensaje:** $($ExecutionData.CommitMessage)

## Problemas Encontrados
"@

    if ($ExecutionData.IssuesFound.Count -gt 0) {
        $ExecutionData.IssuesFound | ForEach-Object {
            $content += "`n- $_"
        }
    } else {
        $content += "`n- (Ningún problema encontrado)"
    }
    
    $content += @"


## Próximo Paso Recomendado
$($ExecutionData.NextStep)

---
*Generado automáticamente por SummaryBuilder*
"@
    
    # Escribir archivo con encabezado YAML
    $filePath = Join-Path $OutputPath "SUMMARY.md"
    
    # Asegurar que el directorio existe
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $content | Set-Content -Path $filePath -Encoding UTF8
    
    # Calcular tokens estimados
    $tokens = Estimate-Tokens -Content (Get-Content -Path $filePath -Raw)
    
    return [PSCustomObject]@{
        Path = $filePath
        Tokens = $tokens
        IsValid = (Test-Path $filePath)
    }
}
