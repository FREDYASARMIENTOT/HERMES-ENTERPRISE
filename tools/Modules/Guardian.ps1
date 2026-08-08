function Test-GuardianRestrictions {
    <#
    .SYNOPSIS
        Validates that the Guardian restrictions are respected.
        This module reads RC73 protection rules and enforces them.
    .PARAMETER ConfigPath
        Path to Hermes.InfrastructureProtection.json.
    .OUTPUTS
        Hashtable with Guardian validation status.
    #>
    param(
        [Parameter(Mandatory)] [string] $ConfigPath
    )

    Write-Host "[Guardian] Validating infrastructure protection rules..."

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "[Guardian] WARNING: Infrastructure protection config not found at: $ConfigPath"
        return @{
            ConfigFound = $false
            RulesValidated = 0
            Allowed = $true
        }
    }

    $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $blockedOperations = @()
    $allowedOperations = @()

    if ($config.PSObject.Properties.Name -contains "BlockedOperations") {
        $blockedOperations = $config.BlockedOperations
    } elseif ($config.PSObject.Properties.Name -contains "blockedOperations") {
        $blockedOperations = $config.blockedOperations
    }

    if ($config.PSObject.Properties.Name -contains "AllowedOperations") {
        $allowedOperations = $config.AllowedOperations
    } elseif ($config.PSObject.Properties.Name -contains "allowedOperations") {
        $allowedOperations = $config.allowedOperations
    }

    $protectionRules = @{
        BlockedOperations = $blockedOperations
        AllowedOperations = $allowedOperations
        ConfigVersion = if ($config.PSObject.Properties.Name -contains "Version") { $config.Version } else { $config.version }
    }

    Write-Host "[Guardian] Protection rules loaded: $($blockedOperations.Count) blocked, $($allowedOperations.Count) allowed"

    return @{
        ConfigFound = $true
        RulesValidated = $blockedOperations.Count + $allowedOperations.Count
        ProtectionRules = $protectionRules
        Allowed = $true
    }
}

function Assert-ProyectoSafeToProceed {
    <#
    .SYNOPSIS
        Asserts that a given operation is allowed by Guardian rules.
    .PARAMETER Operation
        The operation to check (e.g., "CreateWebApp", "CreateResourceGroup").
    .PARAMETER GuardianState
        The current Guardian state from Test-GuardianRestrictions.
    .OUTPUTS
        Boolean indicating if the operation is allowed.
    #>
    param(
        [Parameter(Mandatory)] [string] $Operation,
        [Parameter(Mandatory)] [hashtable] $GuardianState
    )

    if (-not $GuardianState.Allowed) {
        throw "[Guardian] Guardian has blocked all operations. Cannot proceed."
    }

    $blocked = $GuardianState.ProtectionRules.BlockedOperations
    if ($Operation -in $blocked) {
        throw "[Guardian] Operation BLOCKED by Guardian rules: $Operation"
    }

    Write-Host "[Guardian] Operation allowed: $Operation"
    return $true
}

function Get-GuardianSummary {
    <#
    .SYNOPSIS
        Returns a summary of the Guardian state.
    .PARAMETER GuardianState
        The current Guardian state.
    .OUTPUTS
        Hashtable with summary.
    #>
    param(
        [Parameter(Mandatory)] [hashtable] $GuardianState
    )

    return @{
        Active = $GuardianState.Allowed
        ConfigFound = $GuardianState.ConfigFound
        RulesValidated = $GuardianState.RulesValidated
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
}

Export-ModuleMember -Function Test-GuardianRestrictions, Assert-ProyectoSafeToProceed, Get-GuardianSummary