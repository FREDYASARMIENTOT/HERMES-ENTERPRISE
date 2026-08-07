<#
.SYNOPSIS
    Pester tests for AzureInfrastructureGuardian — RC73-B Hardening
.DESCRIPTION
    Validates the hardened Guardian with:
    - All resource types (RG, ASP, Storage, KeyVault, WebApp, AI Service, AppInsights, LogAnalytics, Database)
    - Standardized BLOCKED message
    - Environment tag protection (Environment=Production)
    - Protected tag protection (Protected=true)
    - CorrelationId, user, command logging
    - Protected RG containment
    - Untagged resource denial
    - Force bypass prevention for protected resources
    - Violation logging to JSONL
    ALL tests are UNIT tests — they NEVER call Azure.
#>

# Load the Guardian
$guardianPath = Join-Path $PSScriptRoot '..\..\motor\kernel\Security\AzureInfrastructureGuardian.ps1'
. $guardianPath

# Clear any cached policy
Clear-HermesInfrastructurePolicyCache

# ─────────────────────────────────────────────────────────────────────────────
# Policy loading
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Get-HermesInfrastructurePolicy — Policy Loading' {

    It 'Should load the policy from config file' {
        $policy = Get-HermesInfrastructurePolicy
        ($policy -ne $null) | Should Be $true
        $policy.Version | Should Be '1.1.0'
    }

    It 'Should have a valid version string' {
        $policy = Get-HermesInfrastructurePolicy
        $policy.Version | Should Match '^\d+\.\d+\.\d+$'
    }

    It 'Should have all protection lists defined' {
        $policy = Get-HermesInfrastructurePolicy
        ($policy.PSObject.Properties.Name -contains 'ProtectedResourceGroups') | Should Be $true
        ($policy.PSObject.Properties.Name -contains 'ProtectedAppServicePlans') | Should Be $true
        ($policy.PSObject.Properties.Name -contains 'ProtectedStorageAccounts') | Should Be $true
        ($policy.PSObject.Properties.Name -contains 'ProtectedKeyVaults') | Should Be $true
        ($policy.PSObject.Properties.Name -contains 'ProtectedWebApps') | Should Be $true
        ($policy.PSObject.Properties.Name -contains 'ProtectedAIServices') | Should Be $true
        ($policy.PSObject.Properties.Name -contains 'ProtectedApplicationInsights') | Should Be $true
        ($policy.PSObject.Properties.Name -contains 'ProtectedLogAnalytics') | Should Be $true
        ($policy.PSObject.Properties.Name -contains 'ProtectedDatabases') | Should Be $true
    }

    It 'Should have ValidationRules with deny rules enabled' {
        $policy = Get-HermesInfrastructurePolicy
        ($policy.ValidationRules -ne $null) | Should Be $true
        $policy.ValidationRules.DenyProtectedResourceGroupDeletion | Should Be $true
        $policy.ValidationRules.DenyProtectedAppServicePlanDeletion | Should Be $true
        $policy.ValidationRules.DenyProtectedStorageDeletion | Should Be $true
        $policy.ValidationRules.DenyProtectedKeyVaultDeletion | Should Be $true
        $policy.ValidationRules.DenyProtectedWebAppDeletion | Should Be $true
        $policy.ValidationRules.DenyProtectedAIServiceDeletion | Should Be $true
        $policy.ValidationRules.DenyProtectedApplicationInsightsDeletion | Should Be $true
        $policy.ValidationRules.DenyProtectedLogAnalyticsDeletion | Should Be $true
        $policy.ValidationRules.DenyProtectedDatabaseDeletion | Should Be $true
        $policy.ValidationRules.DenyEnvironmentProductionDeletion | Should Be $true
        $policy.ValidationRules.DenyProtectedTagDeletion | Should Be $true
        $policy.ValidationRules.DenyUntaggedResourceDeletion | Should Be $true
    }

    It 'Should have standardized BlockMessage defined' {
        $policy = Get-HermesInfrastructurePolicy
        ($policy.BlockMessage -ne $null) | Should Be $true
        $policy.BlockMessage | Should Match 'OPERACIÓN BLOQUEADA'
    }

    It 'Should have Audit configuration with user/command/CorrelationId logging' {
        $policy = Get-HermesInfrastructurePolicy
        ($policy.Audit -ne $null) | Should Be $true
        $policy.Audit.LogUser | Should Be $true
        $policy.Audit.LogCommand | Should Be $true
        $policy.Audit.LogCorrelationId | Should Be $true
        $policy.Audit.LogAllAttempts | Should Be $true
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Protected Resource Groups
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Protected Resource Groups — BLOCKED' {

    It 'RG-Hermes-Proyectos should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Hermes-Proyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'RG-Datamining-SII2.0-Dev should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Datamining-SII2.0-Dev' -ResourceGroupName 'RG-Datamining-SII2.0-Dev' -Force } | Should Throw 'PROTECTED'
    }

    It 'RG-Datamining-IA-UR should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Datamining-IA-UR' -ResourceGroupName 'RG-Datamining-IA-UR' -Force } | Should Throw 'PROTECTED'
    }

    It 'Non-protected RG should be ALLOWED when tagged' {
        $result = Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Test-Temp' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Protected App Service Plans
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Protected App Service Plans — BLOCKED' {

    It 'ASP-IAUR should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-IAUR' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'ASP-Hermes should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-Hermes' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'ASP-HermesEnterprise should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-HermesEnterprise' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Plan-Hermes-Proyectos should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'Plan-Hermes-Proyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Non-protected ASP should be ALLOWED when tagged' {
        $result = Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-Test-Temp' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Protected Storage Accounts
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Protected Storage Accounts — BLOCKED' {

    It 'saurhermesproyectos should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation StorageAccount -ResourceName 'saurhermesproyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Non-protected Storage should be ALLOWED when tagged' {
        $result = Invoke-InfrastructureGuardian -Operation StorageAccount -ResourceName 'hermesinfratest' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Protected Key Vaults
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Protected Key Vaults — BLOCKED' {

    It 'Protected KeyVault in protected RG should be BLOCKED (RG containment)' {
        { Invoke-InfrastructureGuardian -Operation KeyVault -ResourceName 'hermes-kv-test' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Non-protected KeyVault in non-protected RG should be ALLOWED when tagged' {
        $result = Invoke-InfrastructureGuardian -Operation KeyVault -ResourceName 'kv-test-temp' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Protected Web Apps
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Protected Web Apps — BLOCKED' {

    It 'AS-HermesEnterprise should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation WebApp -ResourceName 'AS-HermesEnterprise' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# AI Services
# ─────────────────────────────────────────────────────────────────────────────
Describe 'AI Services — BLOCKED' {

    It 'AI Service in protected RG should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation AIService -ResourceName 'ai-foundry-test' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Non-protected AI Service should be ALLOWED when tagged' {
        $result = Invoke-InfrastructureGuardian -Operation AIService -ResourceName 'ai-foundry-temp' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Application Insights
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Application Insights — BLOCKED' {

    It 'Application Insights in protected RG should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation ApplicationInsights -ResourceName 'test-insights' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Non-protected Application Insights should be ALLOWED when tagged' {
        $result = Invoke-InfrastructureGuardian -Operation ApplicationInsights -ResourceName 'test-insights-temp' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Log Analytics
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Log Analytics — BLOCKED' {

    It 'Log Analytics in protected RG should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation LogAnalytics -ResourceName 'test-logs' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Non-protected Log Analytics should be ALLOWED when tagged' {
        $result = Invoke-InfrastructureGuardian -Operation LogAnalytics -ResourceName 'test-logs-temp' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Databases
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Databases — BLOCKED' {

    It 'Database in protected RG should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation Database -ResourceName 'hermes-db-test' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Non-protected Database should be ALLOWED when tagged' {
        $result = Invoke-InfrastructureGuardian -Operation Database -ResourceName 'db-test-temp' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Environment Tag Protection (Environment=Production)
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Environment=Production Tag Protection — BLOCKED' {

    It 'Resource with Environment=Production should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-Prod' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'; Environment='Production'} -Force } | Should Throw 'BLOQUEADA'
    }

    It 'Resource with Environment=Production tag should show standardized block message' {
        try {
            Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-Prod' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'; Environment='Production'} -Force
        }
        catch {
            $_ | Should Match 'OPERACIÓN BLOQUEADA'
            $_ | Should Match 'Production'
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Protected=true Tag Protection
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Protected=true Tag Protection — BLOCKED' {

    It 'Resource with Protected=true should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation StorageAccount -ResourceName 'storage-protected' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'; Protected='true'} -Force } | Should Throw 'BLOQUEADA'
    }

    It 'Resource with Protected=true should show standardized block message' {
        try {
            Invoke-InfrastructureGuardian -Operation StorageAccount -ResourceName 'storage-protected' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'; Protected='true'} -Force
        }
        catch {
            $_ | Should Match 'OPERACIÓN BLOQUEADA'
            $_ | Should Match 'Protected=true'
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Untagged Resource Protection
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Untagged Resources — BLOCKED' {

    It 'Untagged Resource should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-Untagged' -ResourceGroupName 'RG-Test-Temp' -Force } | Should Throw 'HermesManaged'
    }

    It 'Resource with HermesManaged tag should be ALLOWED when not protected' {
        $result = Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-Tagged' -ResourceGroupName 'RG-Test-Temp' -Tags @{HermesManaged='true'} -Force
        $result | Should Be $true
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Force bypass prevention
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Force bypass prevention — BLOCKED' {

    It 'Should BLOCK even with -Force for protected resources' {
        { Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Hermes-Proyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Should BLOCK ASP with -Force' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'ASP-IAUR' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Should BLOCK WebApp with -Force' {
        { Invoke-InfrastructureGuardian -Operation WebApp -ResourceName 'AS-HermesEnterprise' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Standardized Block Message
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Standardized BLOCKED Message' {

    It 'Should include OPERACIÓN BLOQUEADA in block message' {
        try {
            Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Hermes-Proyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force
        }
        catch {
            $_ | Should Match 'OPERACIÓN BLOQUEADA'
            $_ | Should Match 'Azure Infrastructure Guardian'
            $_ | Should Match 'No está permitido eliminar'
        }
    }

    It 'Should include Detalle with specific reason' {
        try {
            Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Hermes-Proyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force
        }
        catch {
            $_ | Should Match 'Detalle:'
            $_ | Should Match 'RG-Hermes-Proyectos'
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Protected Resource Group containment
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Protected RG Containment — BLOCKED' {

    It 'Any resource in protected RG should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation AppServicePlan -ResourceName 'SomeRandomPlan' -ResourceGroupName 'RG-Hermes-Proyectos' -Force } | Should Throw 'PROTECTED'
    }

    It 'Any Storage in protected RG should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation StorageAccount -ResourceName 'RandomStorage' -ResourceGroupName 'RG-Datamining-SII2.0-Dev' -Force } | Should Throw 'PROTECTED'
    }

    It 'Any Database in protected RG should be BLOCKED' {
        { Invoke-InfrastructureGuardian -Operation Database -ResourceName 'RandomDB' -ResourceGroupName 'RG-Datamining-IA-UR' -Force } | Should Throw 'PROTECTED'
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CorrelationId tracking
# ─────────────────────────────────────────────────────────────────────────────
Describe 'CorrelationId Tracking' {

    It 'Should accept custom CorrelationId' {
        $testCid = 'test-cid-12345'
        try {
            Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Hermes-Proyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -CorrelationId $testCid -Force
        }
        catch {
            # Expected block
        }
        # Verification is done via JSONL log
        $logPath = Join-Path $PSScriptRoot '..\..\data\logs\guardian_violations.jsonl'
        if (Test-Path $logPath) {
            $logs = Get-Content $logPath -Raw
            $logs | Should Match $testCid
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Violation logging
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Violation Logging' {

    It 'Should log violations to guardian_violations.jsonl' {
        $logPath = Join-Path $PSScriptRoot '..\..\data\logs\guardian_violations.jsonl'
        # Ensure clean state for this test
        $exists = Test-Path $logPath

        try {
            Invoke-InfrastructureGuardian -Operation ResourceGroup -ResourceName 'RG-Hermes-Proyectos' -ResourceGroupName 'RG-Hermes-Proyectos' -Force
        }
        catch {
            # Expected
        }

        (Test-Path $logPath) | Should Be $true
        $logContent = Get-Content $logPath -Raw
        $logContent | Should Match 'RG-Hermes-Proyectos'
        $logContent | Should Match 'Timestamp'
        $logContent | Should Match 'CorrelationId'
        $logContent | Should Match 'Operation'
        $logContent | Should Match 'ResourceName'
        $logContent | Should Match 'ResourceGroup'
    }

    It 'Should log all blocked resource types' {
        $logPath = Join-Path $PSScriptRoot '..\..\data\logs\guardian_violations.jsonl'

        # Block multiple resource types
        @(
            @{op='ResourceGroup'; name='RG-Datamining-SII2.0-Dev'; rg='RG-Datamining-SII2.0-Dev'}
            @{op='AppServicePlan'; name='ASP-IAUR'; rg='RG-Hermes-Proyectos'}
            @{op='StorageAccount'; name='saurhermesproyectos'; rg='RG-Hermes-Proyectos'}
            @{op='WebApp'; name='AS-HermesEnterprise'; rg='RG-Hermes-Proyectos'}
        ) | ForEach-Object {
            try {
                Invoke-InfrastructureGuardian -Operation $_.op -ResourceName $_.name -ResourceGroupName $_.rg -Force
            }
            catch {
                # Expected
            }
        }

        $logContent = Get-Content $logPath -Raw
        $logContent | Should Match 'RG-Datamining-SII2.0-Dev'
        $logContent | Should Match 'ASP-IAUR'
        $logContent | Should Match 'saurhermesproyectos'
        $logContent | Should Match 'AS-HermesEnterprise'
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Cache
# ─────────────────────────────────────────────────────────────────────────────
Describe 'Clear-HermesInfrastructurePolicyCache' {

    It 'Should clear the cached policy' {
        $null = Get-HermesInfrastructurePolicy
        Clear-HermesInfrastructurePolicyCache
        $result = Get-HermesInfrastructurePolicy
        ($result -ne $null) | Should Be $true
    }
}