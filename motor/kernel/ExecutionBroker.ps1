function Invoke-ExecutionBroker {
    param(
        [string]$ComponentName,
        [hashtable]$Payload
    )
    # The broker asks the CapabilityProvider to resolve
    . "$PSScriptRoot\CapabilityProvider.ps1"
    $resolution = Resolve-ExecutionRequest -ComponentName $ComponentName -Payload $Payload
    if ($resolution.status -ne 'READY') { return $resolution }

    # Determine launcher based on capability implementation
    $cap = $resolution.capability
    if ($cap.implementation -eq 'system') {
        # Build a system invocation descriptor but DO NOT execute here
        return @{ status='LAUNCHABLE'; launcher='system'; commandDescriptor=@{exe=$cap.path; args=$Payload} }
    } elseif ($cap.implementation -eq 'venv') {
        return @{ status='LAUNCHABLE'; launcher='venv'; descriptor=@{exe=$cap.path; args=$Payload} }
    } else {
        return @{ status='UNSUPPORTED'; detail=$cap }
    }
}

