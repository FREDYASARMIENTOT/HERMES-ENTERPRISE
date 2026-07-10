<#
.SYNOPSIS
    ContextValidator - Valida integridad y coherencia de artefactos de contexto
.DESCRIPTION
    Valida que los archivos de contexto generados sean:
    - Completos (existen y tienen contenido)
    - Coherentes entre sí (mismo commit, versión, rama)
    - Dentro del presupuesto de tokens
    - Parseables correctamente (JSON válido)
.BUDGET
    Maximo 250 lineas.
.INPUTS
    - ContextPath: Ruta donde se encuentran los artefactos de contexto
.OUTPUTS
    PSCustomObject con IsValid, Errors, Warnings, Statistics
.EXAMPLE
    $result = Invoke-ContextValidation -ContextPath "D:\HERMES-ENTERPRISE\.hermes\context"
    if (-not $result.IsValid) {
        Write-Error "Contexto inválido: $($result.Errors -join ', ')"
    }
#>
function Invoke-ContextValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ContextPath
    )
    
    $errors = @()
    $warnings = @()
    $statistics = @{
        TotalFiles = 0
        TotalTokens = 0
        FilesValidated = 0
    }
    
    # Archivos requeridos (prioridad)
    $requiredFiles = @(
        "CURRENT_STATE.md",
        "NEXT_TASK.md",
        "WORKER_CONTEXT.json",
        "PROJECT_INDEX.json",
        "CONTEXT_MANIFEST.json"
    )
    
    # Archivos opcionales
    $optionalFiles = @(
        "SUMMARY.md",
        "PROJECT_MEMORY.md"
    )
    
    # Validar archivos requeridos existen
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $ContextPath $file
        $statistics.TotalFiles++
        
        if (-not (Test-Path $filePath)) {
            $errors += "Archivo requerido faltante: $file"
            continue
        }
        
        $fileSize = (Get-Item $filePath).Length
        if ($fileSize -eq 0) {
            $errors += "Archivo requerido vacío: $file"
            continue
        }
        
        $statistics.FilesValidated++
        $statistics.TotalTokens += Estimate-Tokens -FilePath $filePath
    }
    
    # Validar archivos opcionales
    foreach ($file in $optionalFiles) {
        $filePath = Join-Path $ContextPath $file
        $statistics.TotalFiles++
        
        if (Test-Path $filePath) {
            $fileSize = (Get-Item $filePath).Length
            if ($fileSize -eq 0) {
                $warnings += "Archivo opcional vacío: $file"
                continue
            }
            $statistics.FilesValidated++
            $statistics.TotalTokens += Estimate-Tokens -FilePath $filePath
        }
    }
    
    # Validar JSON files
    $jsonFiles = @("WORKER_CONTEXT.json", "PROJECT_INDEX.json", "CONTEXT_MANIFEST.json")
    foreach ($jsonFile in $jsonFiles) {
        $jsonPath = Join-Path $ContextPath $jsonFile
        if (Test-Path $jsonPath) {
            try {
                $content = Get-Content $jsonPath -Raw | ConvertFrom-Json
                $statistics.FilesValidated++
            } catch {
                $errors += "JSON inválido en: $jsonFile"
            }
        }
    }
    
    # Validar coherencia de commits
    $commits = @()
    
    # Extraer commit de CURRENT_STATE.md
    $currentStatePath = Join-Path $ContextPath "CURRENT_STATE.md"
    if (Test-Path $currentStatePath) {
        $content = Get-Content $currentStatePath -Raw
        if ($content -match "^commit:\s*(.+)$" -or $content -match "commit:\s*([^`n]+)") {
            $commits += $matches[1].Trim()
        }
    }
    
    # Extraer commit de WORKER_CONTEXT.json
    $workerContextPath = Join-Path $ContextPath "WORKER_CONTEXT.json"
    if (Test-Path $workerContextPath) {
        try {
            $json = Get-Content $workerContextPath -Raw | ConvertFrom-Json
            if ($json.project.commit) {
                $commits += $json.project.commit
            }
        } catch {}
    }
    
    # Extraer commit de MANIFEST.json
    $manifestPath = Join-Path $ContextPath "CONTEXT_MANIFEST.json"
    if (Test-Path $manifestPath) {
        try {
            $json = Get-Content $manifestPath -Raw | ConvertFrom-Json
            if ($json.commit) {
                $commits += $json.commit
            }
        } catch {}
    }
    
    # Validar coherencia
    if ($commits.Count -gt 1) {
        $uniqueCommits = $commits | Select-Object -Unique
        if ($uniqueCommits.Count -gt 1) {
            $errors += "Incoherencia de commits: se encontraron $($uniqueCommits.Count) commits diferentes"
        }
    }
    
    # Validar presupuesto de tokens
    if ($statistics.TotalTokens -gt 500) {
        $warnings += "Tokens totales ($($statistics.TotalTokens)) excede presupuesto recomendado de 500"
    }
    
    # Retornar resultado
    return [PSCustomObject]@{
        IsValid = ($errors.Count -eq 0)
        Errors = $errors
        Warnings = $warnings
        Statistics = $statistics
    }
}

function Estimate-Tokens {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw
    # Estimación: 1 token ~= 4 caracteres (aproximación conservadora)
    return [math]::Ceiling($content.Length / 4)
}


