<#
.SYNOPSIS
    ManifestBuilder - Genera CONTEXT_MANIFEST.json con orden de carga de archivos
.DESCRIPTION
    Crea un manifiesto que indica al Worker exactamente qué archivos cargar
    y en qué orden, eliminando ambigüedad y optimizando el consumo de tokens.
.BUDGET
    Maximo 200 lineas.
.INPUTS
    - ProjectRoot: Ruta raiz del proyecto
    - OutputPath: Ruta donde se generará el manifiesto
.OUTPUTS
    PSCustomObject con Path, Tokens, IsValid
.EXAMPLE
    $result = Build-Manifest -ProjectRoot "D:\HERMES-ENTERPRISE" -OutputPath "D:\HERMES-ENTERPRISE\.hermes\context"
#>

# Importar helpers centralizados
. "$PSScriptRoot\..\helpers\GitHelpers.ps1"
. "$PSScriptRoot\..\helpers\TokenHelpers.ps1"

function Build-Manifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    # Determinar archivos disponibles
    $priority = @()
    $optional = @()
    
    # Archivos de alta prioridad (siempre disponibles)
    $currentStatePath = Join-Path $OutputPath "CURRENT_STATE.md"
    if (Test-Path $currentStatePath) {
        $priority += [PSCustomObject]@{
            file = "CURRENT_STATE.md"
            reason = "Estado actual del proyecto, fase y paso"
            tokens = Estimate-Tokens -Content (Get-Content $currentStatePath -Raw)
        }
    }
    
    $nextTaskPath = Join-Path $OutputPath "NEXT_TASK.md"
    if (Test-Path $nextTaskPath) {
        $priority += [PSCustomObject]@{
            file = "NEXT_TASK.md"
            reason = "Siguiente tarea a ejecutar con criterios de aceptación"
            tokens = Estimate-Tokens -Content (Get-Content $nextTaskPath -Raw)
        }
    }
    
    $projectIndexPath = Join-Path $OutputPath "PROJECT_INDEX.json"
    if (Test-Path $projectIndexPath) {
        $priority += [PSCustomObject]@{
            file = "PROJECT_INDEX.json"
            reason = "Indice maestro de módulos, documentación y pruebas"
            tokens = Estimate-Tokens -Content (Get-Content $projectIndexPath -Raw)
        }
    }
    
    $workerContextPath = Join-Path $OutputPath "WORKER_CONTEXT.json"
    if (Test-Path $workerContextPath) {
        $priority += [PSCustomObject]@{
            file = "WORKER_CONTEXT.json"
            reason = "Contrato estructurado para ejecución del Worker"
            tokens = Estimate-Tokens -Content (Get-Content $workerContextPath -Raw)
        }
    }
    
    # Archivos opcionales (según necesidad)
    $summaryPath = Join-Path $OutputPath "SUMMARY.md"
    if (Test-Path $summaryPath) {
        $optional += [PSCustomObject]@{
            file = "SUMMARY.md"
            reason = "Resumen de ejecución anterior (útil para continuar trabajo)"
            tokens = Estimate-Tokens -Content (Get-Content $summaryPath -Raw)
            whenToLoad = "Cuando se necesita entender qué se hizo previamente"
        }
    }
    
    $memoryPath = Join-Path $OutputPath "PROJECT_MEMORY.md"
    if (Test-Path $memoryPath) {
        $optional += [PSCustomObject]@{
            file = "PROJECT_MEMORY.md"
            reason = "Memoria del proyecto: decisiones, ADR, convenciones"
            tokens = Estimate-Tokens -Content (Get-Content $memoryPath -Raw)
            whenToLoad = "Cuando se necesitan decisiones arquitectónicas o convenciones"
        }
    }
    
    # Calcular tokens totales
    $totalTokens = 0
    $priority | ForEach-Object { $totalTokens += $_.tokens }
    
    # Construir manifiesto
    $manifest = [PSCustomObject]@{
        schemaVersion = "1.0"
        generatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        generator = "ManifestBuilder"
        commit = Get-GitCommitHash -ProjectPath $ProjectRoot
        
        loadingStrategy = [PSCustomObject]@{
            mode = "progressive"
            description = "Cargar archivos priority primero, optional solo si es necesario"
        }
        
        priority = $priority
        
        optional = $optional
        
        estimatedContext = [PSCustomObject]@{
            priorityTokens = ($priority | Measure-Object -Property tokens -Sum).Sum
            optionalTokens = ($optional | Measure-Object -Property tokens -Sum).Sum
            totalEstimatedTokens = $totalTokens
            withinBudget = $totalTokens -le 500
        }
        
        workerInstructions = @(
            "1. Cargar TODOS los archivos en 'priority' en el orden listado"
            "2. Evaluar si necesitas archivos 'optional' según la tarea"
            "3. NO cargar archivos fuera de este manifiesto sin justificación"
            "4. Mantener el contexto dentro de 500 tokens si es posible"
        )
    }
    
    # Escribir JSON
    $manifestPath = Join-Path $OutputPath "CONTEXT_MANIFEST.json"
    $manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestPath -Encoding UTF8
    
    return [PSCustomObject]@{
        Path = $manifestPath
        Tokens = $totalTokens
        IsValid = (Test-Path $manifestPath)
    }
}
