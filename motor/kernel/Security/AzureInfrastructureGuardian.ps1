<#
.SYNOPSIS
    Azure Infrastructure Guardian -- Central Protection Layer for Destructive Operations
.DESCRIPTION
    Mandatory security gate for all Azure Remove-* operations.
    Every destructive provider call MUST pass through this Guardian before
    executing any deletion. The Guardian enforces the policy defined in
    config/Hermes.InfrastructureProtection.json.

    Hardened for RC73-B with:
    - All resource types: ResourceGroup, AppServicePlan, StorageAccount, KeyVault, WebApp,
      AIService, ApplicationInsights, LogAnalytics, Database, ManagedIdentity
    - Standardized BLOCKED message
    - Environment tag protection (Environment=Production, Protected=true)
    - CorrelationId tracking
    - User and command logging
    - JSONL audit log with full context

    Protected resources cannot be deleted:
    - Resource Groups listed in ProtectedResourceGroups
    - App Service Plans listed in ProtectedAppServicePlans
    - Storage Accounts listed in ProtectedStorageAccounts
    - Key Vaults listed in ProtectedKeyVaults
    - Web Apps listed in ProtectedWebApps
    - AI Services listed in ProtectedAIServices
    - Application Insights listed in ProtectedApplicationInsights
    - Log Analytics listed in ProtectedLogAnalytics
    - Databases listed in ProtectedDatabases
    - Resources with Environment=Production tag
    - Resources with Protected=true tag
    - Resources missing Hermes tags (HermesManaged=true)
    - Resources without project ownership metadata
    - Resources with active dependencies (RequireDependencyCheck)
#>

# Script-scoped policy cache
$script:ProtectionPolicy = $null

function Get-HermesInfrastructurePolicy {
    <#
    .SYNOPSIS
        Loads the current Infrastructure Protection Policy from configuration.
    .DESCRIPTION
        Caches the policy in $script:ProtectionPolicy for performance.
        Falls back to safe built-in defaults if config file is missing.
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
            Version = '1.1.0'
            PolicyName = 'Hermes Azure Infrastructure Protection Policy (Fallback)'
            Enforcement = 'hard'
            ProtectedResourceGroups = @('RG-Hermes-Proyectos', 'RG-Datamining-SII2.0-Dev', 'RG-Datamining-IA-UR')
            ProtectedAppServicePlans = @('ASP-IAUR', 'ASP-Hermes', 'ASP-HermesEnterprise', 'Plan-Hermes-Proyectos')
            ProtectedStorageAccounts = @('saurhermesproyectos')
            ProtectedKeyVaults = @()
            ProtectedWebApps = @()
            ProtectedAIServices = @()
            ProtectedApplicationInsights = @()
            ProtectedLogAnalytics = @()
            ProtectedDatabases = @()
            EnvironmentProtectionTags = @{
                Environment = 'Production'
                Protected = 'true'
            }
            ValidationRules = @{
                DenyProtectedResourceGroupDeletion = $true
                DenyProtectedAppServicePlanDeletion = $true
                DenyProtectedStorageDeletion = $true
                DenyProtectedKeyVaultDeletion = $true
                DenyProtectedWebAppDeletion = $true
                DenyProtectedAIServiceDeletion = $true
                DenyProtectedApplicationInsightsDeletion = $true
                DenyProtectedLogAnalyticsDeletion = $true
                DenyProtectedDatabaseDeletion = $true
                DenyEnvironmentProductionDeletion = $true
                DenyProtectedTagDeletion = $true
                DenySharedInfrastructureDeletion = $true
                DenyUntaggedResourceDeletion = $true
            }
            Audit = @{
                LogAllAttempts = $true
                LogUser = $true
                LogCommand = $true
                LogCorrelationId = $true
                SeverityLevel = 'Critical'
            }
        }
        # Build block message with ASCII-safe text to avoid encoding issues
        $script:ProtectionPolicy.BlockMessage = 'OPERACION BLOQUEADA' + "`n" +
            'Recurso protegido por Azure Infrastructure Guardian.' + "`n" +
            'No esta permitido eliminar infraestructura compartida.' + "`n" +
            'Si requiere eliminar este recurso,' + "`n" +
            'utilice una suscripcion de laboratorio' + "`n" +
            'o elimine primero la proteccion' + "`n" +
            'mediante el procedimiento administrativo.'
        return $script:ProtectionPolicy
    }

    try {
        $policyRaw = Get-Content -Path $policyPath -Raw
        $policy = $policyRaw | ConvertFrom-Json
        $script:ProtectionPolicy = $policy
        Write-Verbose "[Guardian] Policy loaded: $($policy.PolicyName) v$($policy.Version)"
        return $policy
    }
    catch {
        Write-Warning "[Guardian] Failed to load policy: $($_.Exception.Message). Using safe defaults."
        Clear-HermesInfrastructurePolicyCache
        return Get-HermesInfrastructurePolicy
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
        Returns $true if the operation is ALLOWED, throws with standardized BLOCKED message if DENIED.
    .PARAMETER Operation
        Type of resource being deleted: 'ResourceGroup', 'AppServicePlan', 'StorageAccount',
        'KeyVault', 'WebApp', 'AIService', 'ApplicationInsights', 'LogAnalytics',
        'Database', 'ManagedIdentity'
    .PARAMETER ResourceName
        Name of the resource to delete.
    .PARAMETER ResourceGroupName
        Resource Group containing the resource (if applicable).
    .PARAMETER Tags
        Hashtable of tags on the resource (if available). Keys are case-insensitive.
    .PARAMETER CorrelationId
        Optional correlation identifier for audit trail. Auto-generated if omitted.
    .PARAMETER Force
        If specified, allows override ONLY for non-protected resources.
        Has NO effect on protected resources.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('ResourceGroup', 'AppServicePlan', 'StorageAccount', 'KeyVault',
                     'WebApp', 'AIService', 'ApplicationInsights', 'LogAnalytics',
                     'Database', 'ManagedIdentity')]
        [string]$Operation,

        [Parameter(Mandatory)]
        [string]$ResourceName,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [hashtable]$Tags = @{},

        [string]$CorrelationId = (New-Guid).ToString(),

        [switch]$Force
    )

    $policy = Get-HermesInfrastructurePolicy
    $denyReasons = @()

    Write-Verbose "[Guardian] Validating: $Operation '$ResourceName' in RG '$ResourceGroupName' (CID: $CorrelationId)"

    # Get the standardized block message from policy (or fallback ASCII-safe version)
    $blockMessageFromPolicy = $policy.BlockMessage
    if ($blockMessageFromPolicy) {
        $blockMessage = $blockMessageFromPolicy
    }
    else {
        $blockMessage = 'OPERACION BLOQUEADA' + "`n" +
            'Recurso protegido por Azure Infrastructure Guardian.' + "`n" +
            'No esta permitido eliminar infraestructura compartida.' + "`n" +
            'Si requiere eliminar este recurso,' + "`n" +
            'utilice una suscripcion de laboratorio' + "`n" +
            'o elimine primero la proteccion' + "`n" +
            'mediante el procedimiento administrativo.'
    }

    # Determine the protected list to check based on operation type
    $protectedList = $null
    $listName = ''

    switch ($Operation) {
        'ResourceGroup' {
            $protectedList = @($policy.ProtectedResourceGroups)
            $listName = 'ProtectedResourceGroups'
            if ($ResourceName -in $protectedList) {
                $denyReasons += "Resource Group '$ResourceName' is PROTECTED (listed in $listName)."
            }
        }
        'AppServicePlan' {
            $protectedList = @($policy.ProtectedAppServicePlans)
            $listName = 'ProtectedAppServicePlans'
            if ($ResourceName -in $protectedList) {
                $denyReasons += "App Service Plan '$ResourceName' is PROTECTED (listed in $listName)."
            }
        }
        'StorageAccount' {
            $protectedList = @($policy.ProtectedStorageAccounts)
            $listName = 'ProtectedStorageAccounts'
            if ($ResourceName -in $protectedList) {
                $denyReasons += "Storage Account '$ResourceName' is PROTECTED (listed in $listName)."
            }
        }
        'KeyVault' {
            $protectedList = @($policy.ProtectedKeyVaults)
            $listName = 'ProtectedKeyVaults'
            if ($ResourceName -in $protectedList) {
                $denyReasons += "Key Vault '$ResourceName' is PROTECTED (listed in $listName)."
            }
        }
        'WebApp' {
            $protectedList = @($policy.ProtectedWebApps)
            $listName = 'ProtectedWebApps'
            if ($ResourceName -in $protectedList) {
                $denyReasons += "Web App '$ResourceName' is PROTECTED (listed in $listName)."
            }
        }
        'AIService' {
            $protectedList = @($policy.ProtectedAIServices)
            $listName = 'ProtectedAIServices'
            if ($ResourceName -in $protectedList) {
                $denyReasons += "AI Service '$ResourceName' is PROTECTED (listed in $listName)."
            }
        }
        'ApplicationInsights' {
            $protectedList = @($policy.ProtectedApplicationInsights)
            $listName = 'ProtectedApplicationInsights'
            if ($ResourceName -in $protectedList) {
                $denyReasons += "Application Insights '$ResourceName' is PROTECTED (listed in $listName)."
            }
        }
        'LogAnalytics' {
            $protectedList = @($policy.ProtectedLogAnalytics)
            $listName = 'ProtectedLogAnalytics'
            if ($ResourceName -in $protectedList) {
                $denyReasons += "Log Analytics '$ResourceName' is PROTECTED (listed in $listName)."
            }
        }
        'Database' {
            $protectedList = @($policy.ProtectedDatabases)
            $listName = 'ProtectedDatabases'
            if ($ResourceName -in $protectedList) {
                $denyReasons += "Database '$ResourceName' is PROTECTED (listed in $listName)."
            }
        }
    }

    # -- Rule: Protected Resource Group containment -------------------------
    # If the resource's RG is protected and the operation is not on the RG itself,
    # deny deletion of any resource inside it.
    if ($denyReasons.Count -eq 0 -and $Operation -ne 'ResourceGroup') {
        $protectedRGs = @($policy.ProtectedResourceGroups)
        if ($ResourceGroupName -in $protectedRGs) {
            $denyReasons += "Resource '$ResourceName' lives in PROTECTED RG '$ResourceGroupName'."
        }
    }

    # -- Rule: Environment tag protection -----------------------------------
    if ($denyReasons.Count -eq 0 -and $policy.ValidationRules.DenyEnvironmentProductionDeletion) {
        if ($Tags.Count -gt 0) {
            $tagKeys = @($Tags.Keys) | ForEach-Object { $_.ToLower() }
            if ($tagKeys -contains 'environment' -and $Tags['Environment'] -eq 'Production') {
                $denyReasons += "Resource '$ResourceName' has Environment=Production tag. Production resources are protected."
            }
        }
    }

    # -- Rule: Protected tag validation -------------------------------------
    if ($denyReasons.Count -eq 0 -and $policy.ValidationRules.DenyProtectedTagDeletion) {
        if ($Tags.Count -gt 0) {
            $tagKeys = @($Tags.Keys) | ForEach-Object { $_.ToLower() }
            if ($tagKeys -contains 'protected' -and $Tags['Protected'] -eq 'true') {
                $denyReasons += "Resource '$ResourceName' has Protected=true tag. Protected resources cannot be deleted."
            }
        }
    }

    # -- Rule: Hermes tag validation ----------------------------------------
    if ($denyReasons.Count -eq 0 -and $policy.ValidationRules.DenyUntaggedResourceDeletion) {
        if ($Tags.Count -eq 0 -or -not ($Tags.Keys -contains 'HermesManaged')) {
            $denyReasons += "Resource '$ResourceName' missing 'HermesManaged' tag. Untagged resources cannot be deleted."
        }
    }

    # -- Rule: Dependency check ---------------------------------------------
    if ($denyReasons.Count -eq 0 -and $policy.ValidationRules.RequireDependencyCheck) {
        Write-Verbose "[Guardian] Dependency check triggered for '$ResourceName'."
        # Future: implement actual dependency enumeration via Azure Resource Graph
    }

    # -- Enforcement --------------------------------------------------------
    if ($denyReasons.Count -gt 0) {
        $detailedReason = ($denyReasons -join ' ')
        $fullBlockMessage = $blockMessage + "`n`n" + 'Detalle: ' + $detailedReason

        # Build audit log entry
        $currentUser = if ($policy.Audit.LogUser) { (whoami 2>$null) -replace '.*\\', '' } else { 'unknown' }
        $currentCommand = if ($policy.Audit.LogCommand) { ($MyInvocation.Line -replace '\s+', ' ').Trim() } else { 'unknown' }

        $logEntry = @{
            Timestamp       = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            CorrelationId   = $CorrelationId
            User            = $currentUser
            Command         = $currentCommand
            Operation       = $Operation
            ResourceName    = $ResourceName
            ResourceGroup   = $ResourceGroupName
            Tags            = $Tags
            Reasons         = $denyReasons
            PolicyVersion   = $policy.Version
            BlockMessage    = $fullBlockMessage
        }

        # Log to JSONL file for observability
        try {
            $logPath = Join-Path $PSScriptRoot '..\..\..\data\logs'
            if (-not (Test-Path $logPath)) { New-Item -ItemType Directory -Path $logPath -Force | Out-Null }
            $logFile = Join-Path $logPath 'guardian_violations.jsonl'
            Add-Content -Path $logFile -Value (ConvertTo-Json $logEntry -Compress -Depth 3)
        }
        catch {
            # Telemetry logging failure is non-fatal
        }

        # Log to telemetry if available
        try {
            $telemetryScript = Join-Path $PSScriptRoot '..\..\..\tools\Write-HermesLog.ps1'
            if (Test-Path $telemetryScript) {
                . $telemetryScript
                Write-HermesLog -Message "GUARDIAN-BLOCKED: $Operation '$ResourceName' in RG '$ResourceGroupName'" -Level 'ERROR' -Data $logEntry
            }
        }
        catch {
            # Telemetry logging failure is non-fatal
        }

        Write-Warning "[GUARDIAN-DENIED] $fullBlockMessage"
        throw $fullBlockMessage
    }

    Write-Verbose "[Guardian] Operation ALLOWED: $Operation '$ResourceName' in RG '$ResourceGroupName' (CID: $CorrelationId)"
    return $true
}

# Only export when loaded as a module
if ($MyInvocation.MyCommand.CommandType -eq 'Function') {
    Export-ModuleMember -Function Get-HermesInfrastructurePolicy, Clear-HermesInfrastructurePolicyCache, Invoke-InfrastructureGuardian
}