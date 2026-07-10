# Context Engine - Motor de Optimización Contextual
# Fase 3.5 del Bootstrap Engine

<#
.SYNOPSIS
    Motor de optimización contextual para Workers automatizados
    
.DESCRIPTION
    Genera contexto mínimo necesario (200-500 tokens) para que Workers
    puedan operar sin historial conversacional completo.
    
    Genera:
    - PROJECT_INDEX.json (índice maestro)
    - CURRENT_STATE.md (estado actual)
    - NEXT_TASK.md (siguiente tarea)
    - WORKER_CONTEXT.json (contrato estructurado)
    - SUMMARY.md (resumen de ejecución)
    - PROJECT_MEMORY.md (memoria separada)

.INPUTS
    ContextPath: Ruta donde generar los archivos de contexto
    
.OUTPUTS
    PSObject con IsValid, GeneratedFiles, TotalTokens, Statistics

.EXAMPLE
    $result = Invoke-ContextEngine -ContextPath ".\.hermes\context"
#>

function Invoke-ContextEngine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ContextPath
    )
    
    try {
        # Cargar funciones auxiliares PRIMER
        . "$PSScriptRoot\builders\ContextHelpers.ps1"
        
        # Cargar builders
        . "$PSScriptRoot\builders\CurrentStateBuilder.ps1"
        . "$PSScriptRoot\builders\NextTaskBuilder.ps1"
        . "$PSScriptRoot\builders\ProjectIndexBuilder.ps1"
        . "$PSScriptRoot\builders\WorkerContextBuilder.ps1"
        . "$PSScriptRoot\builders\SummaryBuilder.ps1"
        
        # Cargar validador
        . "$PSScriptRoot\ContextValidator.ps1"
        
        # Crear directorio si no existe
        if (-not (Test-Path $ContextPath)) {
            New-Item -ItemType Directory -Path $ContextPath -Force | Out-Null
        }
        
        $generatedFiles = @()
        $totalTokens = 0
        
        # 1. PROJECT_INDEX.json
        Write-Verbose "Generando PROJECT_INDEX.json..."
        $projectIndex = Build-ProjectIndex -ContextPath $ContextPath
        if ($projectIndex.IsValid) {
            $generatedFiles += $projectIndex.Path
            $totalTokens += $projectIndex.Tokens
        }
        
        # 2. WORKER_CONTEXT.json
        Write-Verbose "Generando WORKER_CONTEXT.json..."
        $workerContext = Build-WorkerContext -ContextPath $ContextPath
        if ($workerContext.IsValid) {
            $generatedFiles += $workerContext.Path
            $totalTokens += $workerContext.Tokens
        }
        
        # 3. CURRENT_STATE.md
        Write-Verbose "Generando CURRENT_STATE.md..."
        $currentState = Build-CurrentState -ContextPath $ContextPath
        if ($currentState.IsValid) {
            $generatedFiles += $currentState.Path
            $totalTokens += $currentState.Tokens
        }
        
        # 4. NEXT_TASK.md
        Write-Verbose "Generando NEXT_TASK.md..."
        $nextTask = Build-NextTask -ContextPath $ContextPath
        if ($nextTask.IsValid) {
            $generatedFiles += $nextTask.Path
            $totalTokens += $nextTask.Tokens
        }
        
        # 5. SUMMARY.md
        Write-Verbose "Generando SUMMARY.md..."
        $summary = Build-WorkerSummary -ContextPath $ContextPath
        if ($summary.IsValid) {
            $generatedFiles += $summary.Path
            $totalTokens += $summary.Tokens
        }
        
        # 6. PROJECT_MEMORY.md
        Write-Verbose "Generando PROJECT_MEMORY.md..."
        $memory = Build-ProjectMemory -ContextPath $ContextPath
        if ($memory.IsValid) {
            $generatedFiles += $memory.Path
            $totalTokens += $memory.Tokens
        }
        
        # Validar coherencia
        Write-Verbose "Validando coherencia..."
        $validation = Invoke-ContextValidation -ContextPath $ContextPath
        
        return [PSCustomObject]@{
            IsValid = $validation.IsValid
            GeneratedFiles = $generatedFiles
            TotalTokens = $totalTokens
            Statistics = [PSCustomObject]@{
                FileCount = $generatedFiles.Count
                ValidationPassed = $validation.IsValid
                CoherenceCheck = $validation.IsCoherent
            }
        }
    }
    catch {
        Write-Error "Invoke-ContextEngine failed: $_"
        return [PSCustomObject]@{
            IsValid = $false
            GeneratedFiles = @()
            TotalTokens = 0
            Statistics = [PSCustomObject]@{
                FileCount = 0
                ValidationPassed = $false
                CoherenceCheck = $false
                Error = $_.Exception.Message
            }
        }
    }
}
