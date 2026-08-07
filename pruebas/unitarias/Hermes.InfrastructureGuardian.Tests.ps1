<#
.SYNOPSIS
    Pester tests for AzureInfrastructureGuardian (v3 compatible)
.DESCRIPTION
    Validates that the Guardian correctly:
    - Loads policy from config file and fallback defaults
    - BLOCKS deletion of protected resources
    - ALLOWS deletion of non-protected resources
    - BLOCKS deletion of resources in protected RGs
    - BLOCKS deletion of untagged resources
    - Logs violations to the guardian_violations.jsonl log
#>

# Load the module by dot-sourcing (not as module)
$guardianPath = Join-Path $PSScriptRoot '..\..\motor\kernel\Security\AzureInfrastructureGuardian.ps1'
. $guardianPath

# Clear any cached policy
Clear-HermesInfrastructurePolicyCache

Describe 'Get-HermesInfrastructurePolicy' {

    It 'Should load the policy from config file' {
        $policy = Get-HermesInfrastructurePolicy
        ($policy -ne $null) | Should Be $true
        $policy.PolicyName | Should Match 'Hermes'
    }

    It 'Should have a valid version string' {
        $policy = Get-HermesInfrastructurePolicy
        $policy.Version | Should Match '^\d+\.\d+\.\d+$'
    }

    It 'Should have ProtectedResourceGroups defined' {
        $policy = Get-HermesInfrastructurePolicy
        ($policy.ProtectedResourceGroups -ne $null) | Should Be $true
    }

    It 'Should have ProtectedAppServicePlans defined' {
        $policy = Get-HermesInfrastructurePolicy
        ($policy.ProtectedAppServicePlans -ne $null) | Should Be $true
    }

    It 'Should have ProtectedStorageAccounts defined' {
        $policy = Get-HermesInfrastructurePolicy
        ($policy.ProtectedStorageAccounts -ne $null) | Should Be $true
    }

    It 'Should have ValidationRules defined' {
        $policy = Get-HermesInfrastructurePolicy
        ($policy.ValidationRules -ne $null) | Should Be $true
    }

    It 'Should return cached policy on subsequent calls' {
        Clear-HermesInfrastructurePolicyCache
        $first = Get-HermesInfrastructurePolicy
        $second = Get-HermesInfrastructurePolicy
        $first.PolicyName | Should Be $second.PolicyName
    }
}

Describe 'Clear-HermesInfrastructurePolicyCache' {

    It 'Should clear the cached policy' {
        $null = Get-HermesInfrastructurePolicy
        Clear-HermesInfrastructurePolicyCache
        $result = Get-HermesInfrastructurePolicy
        ($result -ne $null) | Should Be $true
    }
}

Describe 'Invoke-InfrastructureGuardian' {

    # ── Protected Resource Group ─────────────────────────────────────────
    It 'Should DENY deletion of a protected Resource Group' {
        { Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Hermes-Proyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Should DENY deletion of RG-Datamining-SII2.0-Dev' {
        { Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Datamining-SII2.0-Dev' -ResourceGroupName 'RG-Datamining-SII2.0-Dev' -Force } | Should Throw 'PROTECTED'
    }

    It 'Should ALLOW deletion of a non-protected Resource Group' {
        $result = Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Test-Temp' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }

    # ── Protected App Service Plan ───────────────────────────────────────
    It 'Should DENY deletion of a protected App Service Plan' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'Plan-Hermes-Proyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Should DENY deletion of ASP-IAUR' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-IAUR' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Should ALLOW deletion of a non-protected App Service Plan' {
        $result = Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-Test-Temp' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }

    # ── Protected Storage Account ────────────────────────────────────────
    It 'Should DENY deletion of a protected Storage Account' {
        { Invoke-InfrastructureGuardian -Operation StorageAccount -ResourceName 'saurhermesproyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Should ALLOW deletion of a non-protected Storage Account' {
        $result = Invoke-InfrastructureGuardian -Operation StorageAccount -ResourceName 'hermesinfratest' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }

    # ── Protected Resource Group containment ─────────────────────────────
    It 'Should DENY deletion of any resource in a protected RG' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'SomeRandomPlan' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    # ── Untagged Resources ───────────────────────────────────────────────
    It 'Should DENY deletion of an untagged resource' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-Untagged' -ResourceGroupName 'RG-Test-Temp' -Force } | Should Throw 'HermesManaged'
    }

    It 'Should ALLOW deletion of a resource with HermesManaged tag' {
        $result = Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-Tagged' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }

    # ── Known operations ─────────────────────────────────────────────────
    It 'Should accept ApplicationInsights operation' {
        $result = Invoke-InfrastructureGuardian -Operation ApplicationInsights -ResourceName 'test-insights' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }

    It 'Should accept LogAnalytics operation' {
        $result = Invoke-InfrastructureGuardian -Operation LogAnalytics -ResourceName 'test-logs' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }

    It 'Should accept ManagedIdentity operation' {
        $result = Invoke-InfrastructureGuardian -Operation ManagedIdentity -ResourceName 'test-identity' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }

    # ── Force bypass check ──────────────────────────────────────────────
    It 'Should BLOCK even with -Force for protected resources' {
        { Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Hermes-Proyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    # ── Violation logging ────────────────────────────────────────────────
    It 'Should log violations to guardian_violations.jsonl' {
        $logPath = Join-Path $PSScriptRoot '..\..\data\logs\guardian_violations.jsonl'
        if (Test-Path $logPath) { Remove-Item $logPath -Force }

        try {
            Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Hermes-Proyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force
        }
        catch {
            # Expected
        }

        (Test-Path $logPath) | Should Be $true
        $logContent = Get-Content $logPath -Raw
        $logContent | Should Match 'RG-Hermes-Proyectos'
    }

    # ── ApplicationInsights in protected RG ──────────────────────────────
    It 'Should DENY ApplicationInsights in protected RG' {
        { Invoke-InfrastructureGuardian -Operation ApplicationInsights -ResourceName 'test-insights' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }
}