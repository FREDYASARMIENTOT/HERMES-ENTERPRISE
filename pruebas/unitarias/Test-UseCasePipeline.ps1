<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-UseCasePipeline.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Tests Pester para el Pipeline Use Case Driven (CapabilitySystem, Discovery,
    PipelineOrchestrator, ProviderLifecycleManager).
    Compatible con Pester 3.x (BeforeAll no está disponible a nivel de script).
====================================================================================================
#>

# ============================================================================
# Helpers compartidos (definidos inline, fuera de Describe en Pester 3.x
# son accesibles globalmente en el script scope)
# ============================================================================

function New-UseCaseContext {
    param(
        [string]$UseCaseName,
        [string[]]$RequiredCapabilities,
        [hashtable]$InputParameters,
        [hashtable]$Metadata
    )

    return [pscustomobject][ordered]@{
        UseCaseId          = [guid]::NewGuid().ToString()
        UseCaseName        = $UseCaseName
        Status             = 'Pending'
        RequiredCapabilities = $RequiredCapabilities
        InputParameters    = $InputParameters
        Metadata           = $Metadata
        PipelineStack      = [System.Collections.ArrayList]@()
        Errors             = [System.Collections.ArrayList]@()
        StartedAt          = $null
        CompletedAt        = $null
        ExecutionTimeMs    = 0
        OutputResults      = $null
    }
}

function New-CapabilityRegistry {
    param()
    return [pscustomobject][ordered]@{
        Capabilities = @{}
        TotalRegistered = 0
    }
}

function Register-Capability {
    param(
        [psobject]$CapabilityRegistry,
        [string]$CapabilityName,
        [scriptblock]$EngineResolver
    )
    $CapabilityRegistry.Capabilities[$CapabilityName] = @{
        EngineResolver  = $EngineResolver
        ProviderResolvers = @()
        RegisteredAt   = (Get-Date).ToString('o')
    }
    $CapabilityRegistry.TotalRegistered++
    return $true
}

function Get-CapabilityRegistrySummary {
    param([psobject]$CapabilityRegistry)
    return [pscustomobject][ordered]@{
        RegisteredCapabilities = $CapabilityRegistry.TotalRegistered
        Capabilities           = $CapabilityRegistry.Capabilities.Keys
    }
}

function New-PipelineOrchestrator {
    param([psobject]$CapabilityRegistry, [psobject]$DependencyContainer)
    return [pscustomobject][ordered]@{
        CapabilityRegistry = $CapabilityRegistry
        Container          = $DependencyContainer
        ExecutionHistory   = [System.Collections.ArrayList]@()
        TotalExecutions    = 0
        TotalSuccesses     = 0
        TotalFailures      = 0
        AverageExecutionMs = 0
    }
}

function Invoke-UseCasePipeline {
    param(
        [psobject]$PipelineOrchestrator,
        [psobject]$UseCaseContext
    )

    $startTime = [datetime]::UtcNow
    $UseCaseContext.StartedAt = $startTime.ToString('o')

    try {
        $UseCaseContext.Status

        $resolved = Resolve-Capabilities -CapabilityRegistry $PipelineOrchestrator.CapabilityRegistry `
                                         -RequiredCapabilities $UseCaseContext.RequiredCapabilities

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

        $UseCaseContext.Status = 'Completed'
        $PipelineOrchestrator.TotalSuccesses++
    }
    catch {
        $UseCaseContext.Status = 'Failed'
        $null = $UseCaseContext.Errors.Add("Pipeline execution failed: $_")
        $PipelineOrchestrator.TotalFailures++
    }
    finally {
        $endTime = [datetime]::UtcNow
        $UseCaseContext.ExecutionTimeMs = [math]::Round(($endTime - $startTime).TotalMilliseconds, 2)

        $historyEntry = [pscustomobject][ordered]@{
            UseCaseName     = $UseCaseContext.UseCaseName
            UseCaseId       = $UseCaseContext.UseCaseId
            Status          = $UseCaseContext.Status
            ExecutionTimeMs = $UseCaseContext.ExecutionTimeMs
            Timestamp       = $endTime.ToString('o')
        }
        $null = $PipelineOrchestrator.ExecutionHistory.Add($historyEntry)
        $PipelineOrchestrator.TotalExecutions++
    }

    return $UseCaseContext
}

function Get-PipelineOrchestratorSummary {
    param([psobject]$PipelineOrchestrator)
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

function Resolve-Capabilities {
    param(
        [psobject]$CapabilityRegistry,
        [string[]]$RequiredCapabilities
    )

    $engineResolvers = [System.Collections.ArrayList]@()
    $providerResolvers = [System.Collections.ArrayList]@()
    $unresolved = [System.Collections.ArrayList]@()

    foreach ($cap in $RequiredCapabilities) {
        if ($CapabilityRegistry.Capabilities.ContainsKey($cap)) {
            $entry = $CapabilityRegistry.Capabilities[$cap]
            if ($null -ne $entry.EngineResolver) {
                $null = $engineResolvers.Add($entry.EngineResolver)
            }
        }
        else {
            $null = $unresolved.Add($cap)
        }
    }

    if ($unresolved.Count -gt 0) {
        throw "Unresolved capabilities: $($unresolved -join ', ')"
    }

    return [pscustomobject][ordered]@{
        EngineResolvers  = $engineResolvers
        ProviderResolvers = $providerResolvers
    }
}

function New-ProviderLifecycleManager {
    param(
        [psobject]$ProviderRegistry,
        [psobject]$DependencyContainer
    )
    return [pscustomobject][ordered]@{
        Registry           = $ProviderRegistry
        Container          = $DependencyContainer
        ActiveProviders    = [System.Collections.ArrayList]@()
        ProviderStates     = @{}
        ConnectionHistory  = [System.Collections.ArrayList]@()
        TotalConnections   = 0
        TotalDisconnections = 0
    }
}

function Connect-Provider {
    param(
        [psobject]$LifecycleManager,
        [string]$ProviderName
    )
    if (-not $LifecycleManager.Registry.Providers.ContainsKey($ProviderName)) {
        throw "Provider not found: $ProviderName"
    }
    $LifecycleManager.ProviderStates[$ProviderName] = 'Active'
    $null = $LifecycleManager.ActiveProviders.Add($ProviderName)

    $entry = [pscustomobject]@{ ProviderName = $ProviderName; Action = 'Connect'; Timestamp = [datetime]::UtcNow.ToString('o'); Status = 'Success' }
    $null = $LifecycleManager.ConnectionHistory.Add($entry)
    $LifecycleManager.TotalConnections++
    return $true
}

function Disconnect-Provider {
    param(
        [psobject]$LifecycleManager,
        [string]$ProviderName
    )
    if (-not $LifecycleManager.ProviderStates.ContainsKey($ProviderName)) {
        throw "Provider not tracked: $ProviderName"
    }
    $LifecycleManager.ProviderStates[$ProviderName] = 'Disconnected'
    $index = $LifecycleManager.ActiveProviders.IndexOf($ProviderName)
    if ($index -ge 0) { $LifecycleManager.ActiveProviders.RemoveAt($index) }
    $entry = [pscustomobject]@{ ProviderName = $ProviderName; Action = 'Disconnect'; Timestamp = [datetime]::UtcNow.ToString('o'); Status = 'Success' }
    $null = $LifecycleManager.ConnectionHistory.Add($entry)
    $LifecycleManager.TotalDisconnections++
    return $true
}

function Test-ProviderHealth {
    param(
        [psobject]$LifecycleManager,
        [string]$ProviderName
    )
    if (-not $LifecycleManager.ProviderStates.ContainsKey($ProviderName)) { return $false }
    return ($LifecycleManager.ProviderStates[$ProviderName] -eq 'Active')
}

function Disconnect-AllProviders {
    param([psobject]$LifecycleManager)
    $activeList = @($LifecycleManager.ActiveProviders | ForEach-Object { $_ })
    $results = [System.Collections.ArrayList]@()
    foreach ($p in $activeList) {
        try {
            $null = Disconnect-Provider -LifecycleManager $LifecycleManager -ProviderName $p
            $null = $results.Add([pscustomobject]@{ ProviderName = $p; Result = 'Disconnected' })
        } catch {
            $null = $results.Add([pscustomobject]@{ ProviderName = $p; Result = "Error: $_" })
        }
    }
    return $results
}

function Get-ProviderLifecycleStatus {
    param([psobject]$LifecycleManager)
    $statusList = [System.Collections.ArrayList]@()
    foreach ($pn in $LifecycleManager.ProviderStates.Keys) {
        $null = $statusList.Add([pscustomobject]@{
            ProviderName = $pn
            Status       = $LifecycleManager.ProviderStates[$pn]
            IsActive     = ($LifecycleManager.ProviderStates[$pn] -eq 'Active')
        })
    }
    return [pscustomobject][ordered]@{
        ActiveCount        = $LifecycleManager.ActiveProviders.Count
        TotalConnections   = $LifecycleManager.TotalConnections
        TotalDisconnections = $LifecycleManager.TotalDisconnections
        Providers          = $statusList
    }
}

# ============================================================================
# TESTS: UseCaseContext
# ============================================================================

Describe 'UseCaseContext Tests' {
    It 'Should create a context with Pending status' {
        $ctx = New-UseCaseContext -UseCaseName 'TestUseCase' -RequiredCapabilities @('cap.one') -InputParameters @{} -Metadata @{}
        $ctx.Status | Should Be 'Pending'
        $ctx.UseCaseName | Should Be 'TestUseCase'
        $ctx.UseCaseId | Should Not BeNullOrEmpty
    }

    It 'Should accept multiple capabilities' {
        $ctx = New-UseCaseContext -UseCaseName 'MultiCap' -RequiredCapabilities @('cap.one', 'cap.two', 'cap.three') -InputParameters @{ key = 'value' } -Metadata @{}
        $ctx.RequiredCapabilities.Count | Should Be 3
        $ctx.InputParameters['key'] | Should Be 'value'
    }

    It 'Should initialize empty error and pipeline stacks' {
        $ctx = New-UseCaseContext -UseCaseName 'EmptyTest' -RequiredCapabilities @() -InputParameters @{} -Metadata @{}
        $ctx.Errors.Count | Should Be 0
        $ctx.PipelineStack.Count | Should Be 0
    }
}

# ============================================================================
# TESTS: CapabilityRegistry
# ============================================================================

Describe 'CapabilityRegistry Tests' {
    It 'Should register and retrieve capabilities' {
        $reg = New-CapabilityRegistry
        $resolver = { param($UseCaseContext, $Container) return [pscustomobject]@{ Capability = 'test.cap'; Status = 'Completed' } }
        $result = Register-Capability -CapabilityRegistry $reg -CapabilityName 'test.cap' -EngineResolver $resolver
        $result | Should Be $true
        $reg.TotalRegistered | Should Be 1
        $reg.Capabilities.ContainsKey('test.cap') | Should Be $true
    }

    It 'Should return correct summary' {
        $reg = New-CapabilityRegistry
        $r1 = { param($ctx, $c) return $null }
        $r2 = { param($ctx, $c) return $null }
        $null = Register-Capability -CapabilityRegistry $reg -CapabilityName 'cap.a' -EngineResolver $r1
        $null = Register-Capability -CapabilityRegistry $reg -CapabilityName 'cap.b' -EngineResolver $r2
        $summary = Get-CapabilityRegistrySummary -CapabilityRegistry $reg
        $summary.RegisteredCapabilities | Should Be 2
        $summary.Capabilities.Count | Should Be 2
    }
}

# ============================================================================
# TESTS: PipelineOrchestrator
# ============================================================================

Describe 'PipelineOrchestrator Tests' {
    It 'Should execute a simple pipeline successfully' {
        $reg = New-CapabilityRegistry
        $resolver = {
            param($UseCaseContext, $Container)
            return [pscustomobject][ordered]@{
                Capability = 'sample.echo'
                Status     = 'Completed'
                Output     = @{ message = $UseCaseContext.InputParameters['message'] }
            }
        }
        $null = Register-Capability -CapabilityRegistry $reg -CapabilityName 'sample.echo' -EngineResolver $resolver

        $pipeline = New-PipelineOrchestrator -CapabilityRegistry $reg -DependencyContainer $null
        $ctx = New-UseCaseContext -UseCaseName 'EchoTest' -RequiredCapabilities @('sample.echo') -InputParameters @{ message = 'Hello Pipeline' } -Metadata @{}

        $result = Invoke-UseCasePipeline -PipelineOrchestrator $pipeline -UseCaseContext $ctx

        $result.Status | Should Be 'Completed'
        $result.OutputResults.message | Should Be 'Hello Pipeline'
        $pipeline.TotalExecutions | Should Be 1
        $pipeline.TotalSuccesses | Should Be 1
    }

    It 'Should fail on unresolved capabilities' {
        $reg = New-CapabilityRegistry
        $pipeline = New-PipelineOrchestrator -CapabilityRegistry $reg -DependencyContainer $null
        $ctx = New-UseCaseContext -UseCaseName 'FailTest' -RequiredCapabilities @('nonexistent.cap') -InputParameters @{} -Metadata @{}

        $result = Invoke-UseCasePipeline -PipelineOrchestrator $pipeline -UseCaseContext $ctx

        $result.Status | Should Be 'Failed'
        $result.Errors.Count | Should BeGreaterThan 0
        $pipeline.TotalExecutions | Should Be 1
        $pipeline.TotalFailures | Should Be 1
    }

    It 'Should return correct summary after multiple executions' {
        $reg = New-CapabilityRegistry
        $resolver = {
            param($UseCaseContext, $Container)
            return [pscustomobject][ordered]@{ Capability = 'ok'; Status = 'Completed'; Output = @{} }
        }
        $null = Register-Capability -CapabilityRegistry $reg -CapabilityName 'ok' -EngineResolver $resolver

        $pipeline = New-PipelineOrchestrator -CapabilityRegistry $reg -DependencyContainer $null

        # Ejecutar 3 exitosas
        1..3 | ForEach-Object {
            $ctx = New-UseCaseContext -UseCaseName "Success$_" -RequiredCapabilities @('ok') -InputParameters @{} -Metadata @{}
            $null = Invoke-UseCasePipeline -PipelineOrchestrator $pipeline -UseCaseContext $ctx
        }

        # Ejecutar 1 fallida
        $failCtx = New-UseCaseContext -UseCaseName 'Fail' -RequiredCapabilities @('nonexistent') -InputParameters @{} -Metadata @{}
        $null = Invoke-UseCasePipeline -PipelineOrchestrator $pipeline -UseCaseContext $failCtx

        $summary = Get-PipelineOrchestratorSummary -PipelineOrchestrator $pipeline
        $summary.TotalExecutions | Should Be 4
        $summary.TotalSuccesses | Should Be 3
        $summary.TotalFailures | Should Be 1
        $summary.SuccessRate | Should Be 75.0
    }

    It 'Should record execution time per use case' {
        $reg = New-CapabilityRegistry
        $resolver = {
            param($UseCaseContext, $Container)
            Start-Sleep -Milliseconds 10
            return [pscustomobject][ordered]@{ Capability = 'slow.cap'; Status = 'Completed'; Output = @{} }
        }
        $null = Register-Capability -CapabilityRegistry $reg -CapabilityName 'slow.cap' -EngineResolver $resolver

        $pipeline = New-PipelineOrchestrator -CapabilityRegistry $reg -DependencyContainer $null
        $ctx = New-UseCaseContext -UseCaseName 'SlowTest' -RequiredCapabilities @('slow.cap') -InputParameters @{} -Metadata @{}
        $result = Invoke-UseCasePipeline -PipelineOrchestrator $pipeline -UseCaseContext $ctx

        $result.ExecutionTimeMs | Should BeGreaterThan 0
        $result.StartedAt | Should Not BeNullOrEmpty
        $result.CompletedAt | Should Not BeNullOrEmpty
    }
}

# ============================================================================
# TESTS: ProviderLifecycleManager
# ============================================================================

Describe 'ProviderLifecycleManager Tests' {
    It 'Should initialize provider lifecycle manager' {
        $mockRegistry = [pscustomobject]@{ Providers = @{}; TotalCount = 0 }
        $lifecycle = New-ProviderLifecycleManager -ProviderRegistry $mockRegistry -DependencyContainer $null
        $lifecycle.TotalConnections | Should Be 0
        $lifecycle.TotalDisconnections | Should Be 0
        $lifecycle.ActiveProviders.Count | Should Be 0
    }

    It 'Should connect a provider successfully' {
        $mockRegistry = [pscustomobject]@{
            Providers = @{
                'TestProvider' = [pscustomobject]@{ Name = 'TestProvider'; Status = 'Initialized' }
            }
            TotalCount = 1
        }

        $lifecycle = New-ProviderLifecycleManager -ProviderRegistry $mockRegistry -DependencyContainer $null

        $result = Connect-Provider -LifecycleManager $lifecycle -ProviderName 'TestProvider'
        $result | Should Be $true
        $lifecycle.ActiveProviders.Count | Should Be 1
        $lifecycle.ActiveProviders[0] | Should Be 'TestProvider'
        $lifecycle.TotalConnections | Should Be 1
    }

    It 'Should disconnect a provider successfully' {
        $mockRegistry = [pscustomobject]@{
            Providers = @{
                'TestProvider' = [pscustomobject]@{ Name = 'TestProvider'; Status = 'Initialized' }
            }
            TotalCount = 1
        }

        $lifecycle = New-ProviderLifecycleManager -ProviderRegistry $mockRegistry -DependencyContainer $null
        $null = Connect-Provider -LifecycleManager $lifecycle -ProviderName 'TestProvider'

        $result = Disconnect-Provider -LifecycleManager $lifecycle -ProviderName 'TestProvider'
        $result | Should Be $true
        $lifecycle.ActiveProviders.Count | Should Be 0
        $lifecycle.TotalDisconnections | Should Be 1
    }

    It 'Should verify provider health' {
        $mockRegistry = [pscustomobject]@{
            Providers = @{
                'Healthy'   = [pscustomobject]@{ Name = 'Healthy'; Status = 'Initialized' }
                'Unhealthy' = [pscustomobject]@{ Name = 'Unhealthy'; Status = 'Initialized' }
            }
            TotalCount = 2
        }

        $lifecycle = New-ProviderLifecycleManager -ProviderRegistry $mockRegistry -DependencyContainer $null
        $null = Connect-Provider -LifecycleManager $lifecycle -ProviderName 'Healthy'

        Test-ProviderHealth -LifecycleManager $lifecycle -ProviderName 'Healthy' | Should Be $true
        Test-ProviderHealth -LifecycleManager $lifecycle -ProviderName 'Unhealthy' | Should Be $false
    }

    It 'Should disconnect all providers on bulk operation' {
        $mockRegistry = [pscustomobject]@{
            Providers = @{
                'P1' = [pscustomobject]@{ Name = 'P1'; Status = 'Initialized' }
                'P2' = [pscustomobject]@{ Name = 'P2'; Status = 'Initialized' }
                'P3' = [pscustomobject]@{ Name = 'P3'; Status = 'Initialized' }
            }
            TotalCount = 3
        }

        $lifecycle = New-ProviderLifecycleManager -ProviderRegistry $mockRegistry -DependencyContainer $null
        $null = Connect-Provider -LifecycleManager $lifecycle -ProviderName 'P1'
        $null = Connect-Provider -LifecycleManager $lifecycle -ProviderName 'P2'
        $null = Connect-Provider -LifecycleManager $lifecycle -ProviderName 'P3'

        $results = Disconnect-AllProviders -LifecycleManager $lifecycle
        $results.Count | Should Be 3
        $lifecycle.ActiveProviders.Count | Should Be 0
    }
}