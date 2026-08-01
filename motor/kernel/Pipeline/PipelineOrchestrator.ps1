<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : PipelineOrchestrator.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Orquestador del pipeline de ejecución Use Case Driven.
    Coordina: validación de contexto -> resolución de capacidades -> invocación de resolvers -> 
    recolección de resultados -> finalización.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea un nuevo PipelineOrchestrator que coordina la ejecución de Use Cases.
.DESCRIPTION
    Inicializa el orquestador con el registro de capacidades y el contenedor de dependencias.
.PARAMETER CapabilityRegistry
    El registro de capacidades que resuelve capacidades a engines/providers.
.PARAMETER DependencyContainer
    El contenedor de dependencias del sistema.
#>
function New-PipelineOrchestrator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$CapabilityRegistry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$DependencyContainer
    )

    return [pscustomobject][ordered]@{
        CapabilityRegistry  = $CapabilityRegistry
        Container           = $DependencyContainer
        ExecutionHistory    = [System.Collections.ArrayList]@()
        TotalExecutions     = 0
        TotalSuccesses      = 0
        TotalFailures       = 0
        AverageExecutionMs  = 0
    }
}

<#
.SYNOPSIS
    Ejecuta un Use Case de principio a fin.
.DESCRIPTION
    Toma un UseCaseContext, valida, resuelve capacidades, ejecuta los resolvers
    y recolecta los resultados en el contexto.
.PARAMETER PipelineOrchestrator
    El orquestador del pipeline.
.PARAMETER UseCaseContext
    El contexto del Use Case a ejecutar.
#>
function Invoke-UseCasePipeline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$PipelineOrchestrator,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext
    )

    $startTime = [datetime]::UtcNow

    try {
        # 1. Validar contexto
        $UseCaseContext.Status = 'Validated'

        $valid = $UseCaseContext | Test-UseCaseContextValid
        if (-not $valid) {
            $UseCaseContext.Status = 'Failed'
            $null = $UseCaseContext.Errors.Add('UseCase context validation failed')
            return $UseCaseContext
        }

        # 2. Resolver capacidades
        $resolved = Resolve-Capabilities -CapabilityRegistry $PipelineOrchestrator.CapabilityRegistry `
                                         -RequiredCapabilities $UseCaseContext.RequiredCapabilities

        # 3. Ejecutar resolvers de Engine
        $UseCaseContext.Status = 'Executing'

        foreach ($engineResolver in $resolved.EngineResolvers) {
            try {
                $engineResult = & $engineResolver -UseCaseContext $UseCaseContext -Container $PipelineOrchestrator.Container
                $null = $UseCaseContext.PipelineStack.Add("Engine: $($engineResult | Out-String)")

                if ($null -ne $engineResult -and $engineResult.PSObject.Properties.Name -contains 'Output') {
                    $UseCaseContext.OutputResults = $engineResult.Output
                }
            }
            catch {
                $null = $UseCaseContext.Errors.Add("Engine resolver error: $_")
                throw
            }
        }

        # 4. Ejecutar resolvers de Provider
        foreach ($providerResolver in $resolved.ProviderResolvers) {
            try {
                $providerResult = & $providerResolver -UseCaseContext $UseCaseContext -Container $PipelineOrchestrator.Container
                $null = $UseCaseContext.PipelineStack.Add("Provider: $($providerResult | Out-String)")

                if ($null -ne $providerResult -and $providerResult.PSObject.Properties.Name -contains 'Output') {
                    $UseCaseContext.OutputResults = $providerResult.Output
                }
            }
            catch {
                $null = $UseCaseContext.Errors.Add("Provider resolver error: $_")
                throw
            }
        }

        # 5. Finalizar con éxito
        $UseCaseContext.Status = 'Completed'
        $PipelineOrchestrator.TotalSuccesses++
    }
    catch {
        $UseCaseContext.Status = 'Failed'
        $null = $UseCaseContext.Errors.Add("Pipeline execution failed: $_")
        $PipelineOrchestrator.TotalFailures++
    }
    finally {
        # Registrar métricas
        $endTime = [datetime]::UtcNow
        $executionTime = [math]::Round(($endTime - $startTime).TotalMilliseconds, 2)

        $UseCaseContext.StartedAt = $startTime.ToString('o')
        $UseCaseContext.CompletedAt = $endTime.ToString('o')
        $UseCaseContext.ExecutionTimeMs = $executionTime

        # Guardar historial
        $historyEntry = [pscustomobject][ordered]@{
            UseCaseName     = $UseCaseContext.UseCaseName
            UseCaseId       = $UseCaseContext.UseCaseId
            Status          = $UseCaseContext.Status
            ExecutionTimeMs = $executionTime
            Timestamp       = $endTime.ToString('o')
        }
        $null = $PipelineOrchestrator.ExecutionHistory.Add($historyEntry)
        $PipelineOrchestrator.TotalExecutions++

        # Recalcular promedio
        $totalTimes = ($PipelineOrchestrator.ExecutionHistory | ForEach-Object { $_.ExecutionTimeMs } | Measure-Object -Average)
        if ($totalTimes.Count -gt 0) {
            $PipelineOrchestrator.AverageExecutionMs = [math]::Round($totalTimes.Average, 2)
        }
    }

    return $UseCaseContext
}

<#
.SYNOPSIS
    Obtiene un resumen del PipelineOrchestrator.
#>
function Get-PipelineOrchestratorSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$PipelineOrchestrator
    )

    return [pscustomobject][ordered]@{
        TotalExecutions    = $PipelineOrchestrator.TotalExecutions
        TotalSuccesses     = $PipelineOrchestrator.TotalSuccesses
        TotalFailures      = $PipelineOrchestrator.TotalFailures
        AverageExecutionMs = $PipelineOrchestrator.AverageExecutionMs
        SuccessRate        = if ($PipelineOrchestrator.TotalExecutions -gt 0) {
            [math]::Round(($PipelineOrchestrator.TotalSuccesses / $PipelineOrchestrator.TotalExecutions) * 100, 2)
        } else { 0 }
        LastExecution      = if ($PipelineOrchestrator.ExecutionHistory.Count -gt 0) {
            $PipelineOrchestrator.ExecutionHistory[-1]
        } else { $null }
    }
}

Export-ModuleMember -Function New-PipelineOrchestrator, Invoke-UseCasePipeline, Get-PipelineOrchestratorSummary