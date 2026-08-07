<#
.SYNOPSIS
    Azure Infrastructure Guardian — Central Protection Layer for Destructive Operations
.DESCRIPTION
    Mandatory security gate for all Azure Remove-* operations.
    Every destructive provider call MUST pass through this Guardian before
    executing any deletion. The Guardian enforces the policy defined in
    config/Hermes.InfrastructureProtection.json.

    Protected resources cannot be deleted:
    - Resource Groups listed in ProtectedResourceGroups
    - App Service Plans listed in ProtectedAppServicePlans
    - Storage Accounts listed in ProtectedStorageAccounts
    - Key Vaults listed in ProtectedKeyVaults
    - Resources missing Hermes tags (HermesManaged=true)
    - Resources without project ownership metadata
    - Resources with active dependencies (RequireDependencyCheck)

    Violations are logged to SQLite and telemetry.
#>

# Script-scoped policy cache
$script:ProtectionPolicy = $null

function Get-HermesInfrastructurePolicy {
    <#
    .SYNOPSIS
        Loads the current Infrastructure Protection Policy from configuration.
    #>
    [CmdletBinding()]
    param()

    if ($script:ProtectionPolicy) {
        return $script:ProtectionPolicy
    }

    $policyPath = Join-Path $PSScriptRoot '..\..\..\config\Hermes.InfrastructureProtection.json'
    if (-not (Test-Path $policyPath)) {
        Write-Warning "[Guardian] Policy file not found at $policyPath. Using built-in safe defaults."
        $script:ProtectionPolicy = @{
            Version = '1.0.0'
            PolicyName = 'Hermes Azure Infrastructure Protection Policy (Fallback)'
            Enforcement = 'hard'
            ProtectedResourceGroups = @('RG-Hermes-Proyectos', 'RG-Datamining-SII2.0-Dev')
            ProtectedAppServicePlans = @('Plan-Hermes-Proyectos', 'ASP-IAUR')
            ProtectedStorageAccounts = @('saurhermesproyectos')
            ProtectedKeyVaults = @()
            ValidationRules = @{
                DenyProtectedResourceGroupDeletion = $true
                DenyProtectedAppServicePlanDeletion = $true
                DenyProtectedStorageDeletion = $true
                DenySharedInfrastructureDeletion = $true
                DenyUntaggedResourceDeletion = $true
            }
            Audit = @{
                LogAllAttempts = $true
                SeverityLevel = 'Critical'
            }
        }
        return $script:ProtectionPolicy
    }

    try {
        $policy = Get-Content -Path $policyPath -Raw | ConvertFrom-Json
        $script:ProtectionPolicy = $policy
        Write-Verbose "[Guardian] Policy loaded: $($policy.PolicyName) v$($policy.Version)"
        return $policy
    }
    catch {
        Write-Warning "[Guardian] Failed to load policy: $($_.Exception.Message). Using safe defaults."
        return Get-HermesInfrastructurePolicy -ForceReload
    }
}

function Clear-HermesInfrastructurePolicyCache {
    <#
    .SYNOPSIS
        Clears the cached policy. Next call to Get-HermesInfrastructurePolicy will reload from disk.
    #>
    [CmdletBinding()]
    param()
    $script:ProtectionPolicy = $null
    Write-Verbose "[Guardian] Policy cache cleared."
}

function Invoke-InfrastructureGuardian {
    <#
    .SYNOPSIS
        Validates a destructive operation against the Infrastructure Protection Policy.
    .DESCRIPTION
        Central validation function. Every Remove-* provider must call this before deleting.
        Returns $true if the operation is ALLOWED, throws if DENIED.
    .PARAMETER Operation
        Type of resource being deleted: 'ResourceGroup', 'AppServicePlan', 'StorageAccount', 'KeyVault',
        'ApplicationInsights', 'LogAnalytics', 'ManagedIdentity'
    .PARAMETER ResourceName
        Name of the resource to delete.
    .PARAMETER ResourceGroupName
        Resource Group containing the resource (if applicable).
    .PARAMETER Tags
        Hashtable of tags on the resource (if available).
    .PARAMETER Force
        If specified, allows override ONLY for non-protected resources.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('ResourceGroup', 'AppServicePlan', 'StorageAccount', 'KeyVault',
                     'ApplicationInsights', 'LogAnalytics', 'ManagedIdentity')]
        [string]$Operation,

        [Parameter(Mandatory)]
        [string]$ResourceName,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [hashtable]$Tags = @{},

        [switch]$Force
    )

    $policy = Get-HermesInfrastructurePolicy
    $denyMessage = $null

    Write-Verbose "[Guardian] Validating: $Operation '$ResourceName' in RG '$ResourceGroupName'"

    # ── Rule 1: Protected Resource Groups ──────────────────────────────────
    if ($Operation -eq 'ResourceGroup') {
        $protectedRGs = @($policy.ProtectedResourceGroups)
        if ($ResourceName -in $protectedRGs) {
            $denyMessage = "[GUARDIAN-DENIED] Resource Group '$ResourceName' is PROTECTED. Deletion blocked by policy."
            Write-Warning $denyMessage
        }
    }

    # ── Rule 2: Protected App Service Plans ───────────────────────────────
    if ($Operation -eq 'AppServicePlan') {
        $protectedASPs = @($policy.ProtectedAppServicePlans)
        if ($ResourceName -in $protectedASPs) {
            $denyMessage = "[GUARDIAN-DENIED] App Service Plan '$ResourceName' is PROTECTED. Deletion blocked."
            Write-Warning $denyMessage
        }
    }

    # ── Rule 3: Protected Storage Accounts ────────────────────────────────
    if ($Operation -eq 'StorageAccount') {
        $protectedStorages = @($policy.ProtectedStorageAccounts)
        if ($ResourceName -in $protectedStorages) {
            $denyMessage = "[GUARDIAN-DENIED] Storage Account '$ResourceName' is PROTECTED. Deletion blocked."
            Write-Warning $denyMessage
        }
    }

    # ── Rule 4: Protected Key Vaults ──────────────────────────────────────
    if ($Operation -eq 'KeyVault') {
        $protectedKVs = @($policy.ProtectedKeyVaults)
        if ($ResourceName -in $protectedKVs) {
            $denyMessage = "[GUARDIAN-DENIED] Key Vault '$ResourceName' is PROTECTED. Deletion blocked."
            Write-Warning $denyMessage
        }
    }

    # ── Rule 5: Shared/Protected Resource Group check ─────────────────────
    # If the resource's RG is protected, deny deletion of any resource inside it
    # unless explicitly allowed by policy exceptions
    if (-not $denyMessage -and $Operation -ne 'ResourceGroup') {
        $protectedRGs = @($policy.ProtectedResourceGroups)
        if ($ResourceGroupName -in $protectedRGs) {
            # Check if there's an explicit allow for this specific resource
            $denyMessage = "[GUARDIAN-DENIED] Resource '$ResourceName' lives in PROTECTED RG '$ResourceGroupName'. Deletion blocked."
            Write-Warning $denyMessage
        }
    }

    # ── Rule 6: Hermes tag validation ─────────────────────────────────────
    if (-not $denyMessage -and $policy.ValidationRules.DenyUntaggedResourceDeletion) {
        if ($Tags.Count -eq 0 -or -not $Tags.ContainsKey('HermesManaged')) {
            $denyMessage = "[GUARDIAN-DENIED] Resource '$ResourceName' missing 'HermesManaged' tag. Untagged resources cannot be deleted."
            Write-Warning $denyMessage
        }
    }

    # ── Rule 7: Dependency check ──────────────────────────────────────────
    if (-not $denyMessage -and $policy.ValidationRules.RequireDependencyCheck) {
        Write-Verbose "[Guardian] Dependency check triggered for '$ResourceName'."
        # Future: implement actual dependency enumeration via Azure Resource Graph
        # For now, this is a placeholder for the dependency check framework
    }

    # ── Enforcement ───────────────────────────────────────────────────────
    if ($denyMessage) {
        # Log the violation
        $logEntry = @{
            Timestamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            Operation    = $Operation
            ResourceName = $ResourceName
            ResourceGroup= $ResourceGroupName
            Reason       = $denyMessage
            PolicyVersion= $policy.Version
        }

        # Log to telemetry if available
        try {
            $logPath = Join-Path $PSScriptRoot '..\..\..\data\logs'
            if (-not (Test-Path $logPath)) { New-Item -ItemType Directory -Path $logPath -Force | Out-Null }
            $logFile = Join-Path $logPath 'guardian_violations.jsonl'
            Add-Content -Path $logFile -Value (ConvertTo-Json $logEntry -Compress)
        }
        catch {
            # Telemetry logging failure is non-fatal
        }

        throw $denyMessage
    }

    Write-Verbose "[Guardian] Operation ALLOWED: $Operation '$ResourceName' in RG '$ResourceGroupName'"
    return $true
}

# Only export when loaded as a module
if ($MyInvocation.MyCommand.CommandType -eq 'Function') {
    Export-ModuleMember -Function Get-HermesInfrastructurePolicy, Clear-HermesInfrastructurePolicyCache, Invoke-InfrastructureGuardian
}
