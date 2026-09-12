<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-UseCases.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Tests Pester (v3 compatible) para la capa completa de Use Cases:
    - FASE 3: Auto-registration integration test (Initialize-UseCaseOrchestrator)
    - FASE 5: Per-use case tests (Happy Path + Validation Error + Engine Error)
====================================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Load the entire orchestrator (which dot-sources all dependencies) ──
. "$PSScriptRoot\..\..\motor\kernel\Capabilities\UseCaseOrchestrator.ps1"

#=============================================================================
# FASE 3: Auto-registration integration test
#=============================================================================
Describe 'FASE 3: Auto-registration Integration' {

    It 'Should initialize successfully' {
        Clear-UseCaseRegistry
        $r = Initialize-UseCaseOrchestrator
        $r.Status | Should Be 'Initialized'
    }

    It 'Should register exactly 9 use cases' {
        Clear-UseCaseRegistry
        $r = Initialize-UseCaseOrchestrator
        $r.UseCasesRegistered | Should Be 9
    }

    It 'Should register exactly 7 engines' {
        Clear-UseCaseRegistry
        $r = Initialize-UseCaseOrchestrator
        $r.EnginesRegistered | Should Be 7
    }

    It 'Should map exactly 9 capabilities' {
        Clear-UseCaseRegistry
        $r = Initialize-UseCaseOrchestrator
        $r.CapabilitiesMapped | Should Be 9
    }

    It 'Should resolve all 9 use cases by ID' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null
        $ids = @('uc-bootstrap','uc-workspace-discovery','uc-capability-discovery','uc-config-load','uc-config-validate','uc-dependency-resolve','uc-provider-resolve','uc-runtime-startup','uc-kernel-startup')
        foreach ($ucId in $ids) {
            $uc = Resolve-UseCase -UseCaseIdOrName $ucId
            $uc | Should Not BeNullOrEmpty
            $uc.Id | Should Be $ucId
        }
    }

    It 'Should resolve all 9 use cases by Name' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null
        $names = @('BootstrapUseCase','WorkspaceDiscoveryUseCase','CapabilityDiscoveryUseCase','ConfigurationLoadUseCase','ConfigurationValidateUseCase','DependencyResolveUseCase','ProviderResolveUseCase','RuntimeStartupUseCase','KernelStartupUseCase')
        foreach ($ucName in $names) {
            $uc = Resolve-UseCase -UseCaseIdOrName $ucName
            $uc | Should Not BeNullOrEmpty
            $uc.Name | Should Be $ucName
        }
    }

    It 'Should return null for non-existent use case' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null
        $uc = Resolve-UseCase -UseCaseIdOrName 'nonexistent-uc'
        $uc | Should BeNullOrEmpty
    }

    It 'Each use case should have valid contract properties' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null
        $all = Get-AllUseCases
        foreach ($uc in $all) {
            $uc.Id           | Should Not BeNullOrEmpty
            $uc.Name         | Should Not BeNullOrEmpty
            $uc.Capability   | Should Not BeNullOrEmpty
            $uc.EngineType   | Should Not BeNullOrEmpty
            $uc.ProviderType | Should Not BeNullOrEmpty
            $uc.Status       | Should Be 'Registered'
        }
    }

    It 'Get-AllUseCases should return all 9' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null
        $all = Get-AllUseCases
        @($all).Count | Should Be 9
    }
}

#=============================================================================
# FASE 5: Per-Use Case Execution Tests
#=============================================================================

Describe 'FASE 5: Use Case Execution - BootstrapUseCase [uc-bootstrap]' {

    It 'Happy Path: Should execute successfully with valid parameters' {
        Clear-UseCaseRegistry
        Clear-EngineRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-bootstrap' -InputParameters @{
            WorkspaceName  = 'test-workspace'
            RepositoryRoot = 'D:\'
        }

        $result.Status  | Should Be 'Completed'
        $result.Engine  | Should Be 'BootstrapEngine'
        $result.WorkspacePath | Should Not BeNullOrEmpty
    }

    It 'Validation Error: Should fail when WorkspaceName missing' {
        Clear-UseCaseRegistry
        Clear-EngineRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-bootstrap' -InputParameters @{
            RepositoryRoot = 'D:\'
        }

        $result.Status  | Should Be 'Faulted'
        $result.Error   | Should Not BeNullOrEmpty
    }

    It 'Validation Error: Should fail when RepositoryRoot missing' {
        Clear-UseCaseRegistry
        Clear-EngineRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-bootstrap' -InputParameters @{
            WorkspaceName = 'test'
        }

        $result.Status  | Should Be 'Faulted'
        $result.Error   | Should Not BeNullOrEmpty
    }

    It 'Engine Resolution Error: Should fail for non-existent engine type' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        Register-UseCase -UseCase ([pscustomobject]@{
            Id           = 'uc-bogus-engine'
            Name         = 'BogusUseCase'
            Capability   = 'capability.bogus'
            EngineType   = 'NonExistentEngine'
            ProviderType = 'FileSystem'
            Status       = 'Registered'
        })
        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-bogus-engine' -InputParameters @{ Dummy = $true }
        $result.Success | Should Be $false
        $result.Step    | Should Be 'ResolveEngine'
    }
}

Describe 'FASE 5: Use Case Execution - WorkspaceDiscoveryUseCase [uc-workspace-discovery]' {

    It 'Happy Path: Should execute with valid SearchRoot' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-workspace-discovery' -InputParameters @{
            SearchRoot = 'D:\'
        }
        $result.Success | Should Be $true
        $result.Status  | Should Be 'Completed'
        $result.Engine  | Should Be 'DiscoveryEngine'
    }

    It 'Should handle empty SearchRoot gracefully' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-workspace-discovery' -InputParameters @{}
        $result.Success | Should Be $true
        $result.Status  | Should Be 'Completed'
        $result.Engine  | Should Be 'DiscoveryEngine'
    }
}

Describe 'FASE 5: Use Case Execution - CapabilityDiscoveryUseCase [uc-capability-discovery]' {

    It 'Happy Path: Should execute without required input parameters' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-capability-discovery' -InputParameters @{}
        $result.Success | Should Be $true
        $result.Status  | Should Be 'Completed'
        $result.Engine  | Should Be 'DiscoveryEngine'
    }
}

Describe 'FASE 5: Use Case Execution - ConfigurationLoadUseCase [uc-config-load]' {

    It 'Happy Path: Should execute with valid ConfigPath' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-config-load' -InputParameters @{
            ConfigPath = 'D:\HERMES-ENTERPRISE\Hermes.config.json'
        }
        $result.Success | Should Be $true
        $result.Status  | Should Be 'Completed'
        $result.Engine  | Should Be 'ConfigEngine'
    }

    It 'Validation Error: Should fail when ConfigPath missing' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-config-load' -InputParameters @{}
        $result.Success | Should Be $false
        $result.Status  | Should Match 'Faulted|Failed'
    }
}

Describe 'FASE 5: Use Case Execution - ConfigurationValidateUseCase [uc-config-validate]' {

    It 'Happy Path: Should execute with valid ConfigPath' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-config-validate' -InputParameters @{
            ConfigPath = 'D:\HERMES-ENTERPRISE\Hermes.config.json'
        }
        $result.Success | Should Be $true
        $result.Status  | Should Be 'Completed'
        $result.Engine  | Should Be 'ConfigEngine'
    }

    It 'Validation Error: Should fail when ConfigPath missing' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-config-validate' -InputParameters @{}
        $result.Success | Should Be $false
        $result.Status  | Should Match 'Faulted|Failed'
    }
}

Describe 'FASE 5: Use Case Execution - DependencyResolveUseCase [uc-dependency-resolve]' {

    It 'Happy Path: Should execute with valid ModuleName' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-dependency-resolve' -InputParameters @{
            ModuleName = 'Kernel'
        }
        $result.Success | Should Be $true
        $result.Status  | Should Be 'Completed'
        $result.Engine  | Should Be 'DependencyEngine'
    }

    It 'Validation Error: Should fail when ModuleName missing' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-dependency-resolve' -InputParameters @{}
        $result.Success | Should Be $false
        $result.Status  | Should Match 'Faulted|Failed'
    }
}

Describe 'FASE 5: Use Case Execution - ProviderResolveUseCase [uc-provider-resolve]' {

    It 'Happy Path: Should execute with valid ProviderType' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-provider-resolve' -InputParameters @{
            ProviderType = 'GitHub'
        }
        $result.Success | Should Be $true
        $result.Status  | Should Be 'Completed'
        $result.Engine  | Should Be 'ProviderEngine'
    }

    It 'Validation Error: Should fail when ProviderType missing' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-provider-resolve' -InputParameters @{}
        $result.Success | Should Be $false
        $result.Status  | Should Match 'Faulted|Failed'
    }
}

Describe 'FASE 5: Use Case Execution - RuntimeStartupUseCase [uc-runtime-startup]' {

    It 'Happy Path: Should execute without required input' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-runtime-startup' -InputParameters @{}
        $result.Success | Should Be $true
        $result.Status  | Should Be 'Completed'
        $result.Engine  | Should Be 'RuntimeEngine'
    }
}

Describe 'FASE 5: Use Case Execution - KernelStartupUseCase [uc-kernel-startup]' {

    It 'Happy Path: Should execute without required input' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-kernel-startup' -InputParameters @{}
        $result.Success | Should Be $true
        $result.Status  | Should Be 'Completed'
        $result.Engine  | Should Be 'KernelEngine'
    }
}

#=============================================================================
# FASE 5: Cross-cutting error scenarios
#=============================================================================
Describe 'FASE 5: Cross-cutting Error Scenarios' {

    It 'Should fail gracefully when use case does not exist' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        $result = Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-nonexistent' -InputParameters @{}
        $result.Success | Should Be $false
        $result.Step    | Should Be 'ResolveUseCase'
    }

    It 'Should throw on null/empty use case ID' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        { Invoke-UseCaseOrchestrator -UseCaseIdOrName '' -InputParameters @{} } | Should Throw
    }

    It 'Should throw on null input parameters' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null

        { Invoke-UseCaseOrchestrator -UseCaseIdOrName 'uc-bootstrap' -InputParameters $null } | Should Throw
    }

    It 'Should be idempotent across multiple initializations' {
        Clear-UseCaseRegistry
        $r1 = Initialize-UseCaseOrchestrator
        $r2 = Initialize-UseCaseOrchestrator
        $r1.Status | Should Be 'Initialized'
        $r2.Status | Should Be 'Initialized'
        $r1.UseCasesRegistered | Should Be 9
        $r2.UseCasesRegistered | Should Be 9
    }

    It 'Should clear and re-register on re-initialization' {
        Clear-UseCaseRegistry
        Initialize-UseCaseOrchestrator | Out-Null
        $all = Get-AllUseCases
        @($all).Count | Should Be 9
    }
}