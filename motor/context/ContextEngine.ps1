<#
.SYNOPSIS
    Context Optimization Engine - Motor principal de optimización de contexto

.DESCRIPTION
    Orquestador principal que coordina la generación de todos los artefactos
    de contexto para permitir que Workers operen con mínima información.
    
    Genera automáticamente:
    - PROJECT_INDEX.json (índice maestro)
    - CURRENT_STATE.md (estado actual del proyecto)
    - NEXT_TASK.md (siguiente tarea a ejecutar)
    - WORKER_CONTEXT.json (contrato estructurado para Workers)
    - CONTEXT_MANIFEST.json (orden de carga de archivos)
    - SUMMARY.md (resumen de ejecución de Worker, opcional)
    
    Cada Worker puede iniciar leyendo solo los archivos de prioridad del
    CONTEXT_MANIFEST.json y cargar progresivamente los opcionales según
    necesidad, manteniendo el contexto total en 200-500 tokens efectivos.

.INPUTS
    BootstrapState [PSObject]
        Objeto con el estado actual del Bootstrap Engine
    
    OutputPath [string]
        Ruta donde se generarán los archivos de contexto
    
    ExecutionData [PSObject]
        Datos de ejecución del Worker (opcional, para generar SUMMARY.md)

.OUTPUTS
    PSObject con:
        - Success: Boolean indicando éxito de la operación
        - TotalTokens: Tokens totales estimados
        - Validation: Resultado de la validación de integridad
        - GeneratedFiles: Lista de archivos generados

.EXAMPLE
    $state = Get-Content ".hermes\bootstrap\BOOTSTRAP_STATE.json" | ConvertFrom-Json
    $result = Invoke-ContextEngine -BootstrapState $state -OutputPath ".hermes\context"
    
.NOTES
    Author: Hermes Agent
    Version: 1.0.0
    Requires: PowerShell 7.0+
#>

function Invoke-ContextEngine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$BootstrapState,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [PSObject]$ExecutionData
    )
    
    begin {
        Write-Verbose "ContextEngine: Iniciando generación de contexto..."
        
        # Asegurar que OutputPath existe
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        # Cargar builders
        $buildersPath = Join-Path $PSScriptRoot "builders"
        . (Join-Path $buildersPath "ProjectIndexBuilder.ps1")
        . (Join-Path $buildersPath "CurrentStateBuilder.ps1")
        . (Join-Path $buildersPath "NextTaskBuilder.ps1")
        . (Join-Path $buildersPath "WorkerContextBuilder.ps1")
        . (Join-Path $buildersPath "SummaryBuilder.ps1")
        . (Join-Path $buildersPath "MemoryBuilder.ps1")
        . (Join-Path $buildersPath "ManifestBuilder.ps1")
        
        # Cargar validador
        . (Join-Path $PSScriptRoot "ContextValidator.ps1")
        
        $generatedFiles = @()
        $totalTokens = 0
    }
    
    process {
        try {
            # 1. Generar PROJECT_INDEX.json
            Write-Verbose "ContextEngine: Generando PROJECT_INDEX.json..."
            $indexResult = Build-ProjectIndex -BootstrapState $BootstrapState -OutputPath $OutputPath
            if ($indexResult.IsValid) {
                $generatedFiles += $indexResult.Path
                $totalTokens += $indexResult.Tokens
                Write-Verbose "  ✓ PROJECT_INDEX.json generado ($($indexResult.Tokens) tokens)"
            }
            
            # 2. Generar CURRENT_STATE.md
            Write-Verbose "ContextEngine: Generando CURRENT_STATE.md..."
            $stateResult = Build-CurrentState -BootstrapState $BootstrapState -OutputPath $OutputPath
            if ($stateResult.IsValid) {
                $generatedFiles += $stateResult.Path
                $totalTokens += $stateResult.Tokens
                Write-Verbose "  ✓ CURRENT_STATE.md generado ($($stateResult.Tokens) tokens)"
            }
            
            # 3. Generar NEXT_TASK.md
            Write-Verbose "ContextEngine: Generando NEXT_TASK.md..."
            $taskResult = Build-NextTask -BootstrapState $BootstrapState -OutputPath $OutputPath
            if ($taskResult.IsValid) {
                $generatedFiles += $taskResult.Path
                $totalTokens += $taskResult.Tokens
                Write-Verbose "  ✓ NEXT_TASK.md generado ($($taskResult.Tokens) tokens)"
            }
            
            # 4. Generar WORKER_CONTEXT.json
            Write-Verbose "ContextEngine: Generando WORKER_CONTEXT.json..."
            $contextResult = Build-WorkerContext -BootstrapState $BootstrapState -OutputPath $OutputPath
            if ($contextResult.IsValid) {
                $generatedFiles += $contextResult.Path
                $totalTokens += $contextResult.Tokens
                Write-Verbose "  ✓ WORKER_CONTEXT.json generado ($($contextResult.Tokens) tokens)"
            }
            
            # 5. Generar PROJECT_MEMORY.md
            Write-Verbose "ContextEngine: Generando PROJECT_MEMORY.md..."
            $memoryResult = Build-ProjectMemory -BootstrapState $BootstrapState -OutputPath $OutputPath
            if ($memoryResult.IsValid) {
                $generatedFiles += $memoryResult.Path
                $totalTokens += $memoryResult.Tokens
                Write-Verbose "  ✓ PROJECT_MEMORY.md generado ($($memoryResult.Tokens) tokens)"
            }
            
            # 6. Generar SUMMARY.md (si ExecutionData está presente)
            if ($ExecutionData) {
                Write-Verbose "ContextEngine: Generando SUMMARY.md..."
                $summaryResult = Build-WorkerSummary -ExecutionData $ExecutionData -OutputPath $OutputPath
                if ($summaryResult.IsValid) {
                    $generatedFiles += $summaryResult.Path
                    $totalTokens += $summaryResult.Tokens
                    Write-Verbose "  ✓ SUMMARY.md generado ($($summaryResult.Tokens) tokens)"
                }
            }
            
            # 7. Generar CONTEXT_MANIFEST.json (DEBE SER EL ÚLTIMO para conocer todos los archivos)
            Write-Verbose "ContextEngine: Generando CONTEXT_MANIFEST.json..."
            $manifestResult = Build-ContextManifest -BootstrapState $BootstrapState -OutputPath $OutputPath
            if ($manifestResult.IsValid) {
                $generatedFiles += $manifestResult.Path
                $totalTokens += $manifestResult.Tokens
                Write-Verbose "  ✓ CONTEXT_MANIFEST.json generado ($($manifestResult.Tokens) tokens)"
            }
            
            # 8. Validar integridad
            Write-Verbose "ContextEngine: Validando integridad del contexto..."
            $validationResult = Invoke-ContextValidator -BootstrapState $BootstrapState -OutputPath $OutputPath
            
            return [PSCustomObject]@{
                Success = $validationResult.IsValid
                TotalTokens = $totalTokens
                GeneratedFiles = $generatedFiles
                Validation = $validationResult
            }
            
        } catch {
            Write-Error "ContextEngine: Error durante la generación: $_"
            return [PSCustomObject]@{
                Success = $false
                TotalTokens = $totalTokens
                GeneratedFiles = $generatedFiles
                Validation = [PSCustomObject]@{
                    IsValid = $false
                    Errors = @($_.Exception.Message)
                }
            }
        }
    }
    
    end {
        Write-Verbose "ContextEngine: Generación completada. Total: $totalTokens tokens en $($generatedFiles.Count) archivos"
    }
}

Export-ModuleMember -Function Invoke-ContextEngine
