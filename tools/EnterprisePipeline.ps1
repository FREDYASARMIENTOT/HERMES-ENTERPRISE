param(
    [Parameter(Mandatory=$false)][psobject]$Contexto
)

# Adapter: delegate to Scheduler's Invoke-EnterprisePipeline
$adapterRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
# Scheduler expected under tools\Scheduler.ps1 (observed location)
$schedulerPath = Join-Path -Path $adapterRoot -ChildPath 'Scheduler.ps1'
Write-HermesLog "Adapter: Loading Scheduler from $schedulerPath"
if (-not (Test-Path $schedulerPath)) {
    # Also try relative to repo motor path
    $alt = Join-Path -Path (Join-Path $adapterRoot '..') -ChildPath 'motor\bootstrap\engine\BootstrapOrchestrator.ps1'
    Write-HermesLog "Adapter: Scheduler not found at $schedulerPath, trying $alt"
    if (Test-Path $alt) {
        # If orchestrator exists, just load it (best-effort)
        . $alt
        Write-HermesLog "Adapter: Loaded BootstrapOrchestrator at $alt"
    } else {
        Write-HermesLog "Adapter: Scheduler not found at $schedulerPath and orchestrator not found at $alt"
        Write-Output "[Adapter] Scheduler not found at $schedulerPath and orchestrator not found at $alt"
        return 1
    }
} else {
    . $schedulerPath
    Write-HermesLog "Adapter: Loaded Scheduler at $schedulerPath"
}

# Delegate call
if (Get-Command Invoke-EnterprisePipeline -ErrorAction SilentlyContinue) {
    Write-HermesLog "Adapter: Calling Invoke-EnterprisePipeline..."
    if ($null -ne $Contexto) {
        $rc = Invoke-EnterprisePipeline -Context $Contexto
    } else {
        $rc = Invoke-EnterprisePipeline @PSBoundParameters
    }
    Write-HermesLog "Adapter: Invoke-EnterprisePipeline returned with code $rc"
    return $rc
} else {
    Write-HermesLog "Adapter: Invoke-EnterprisePipeline not found after loading scheduler"
    Write-Output "[Adapter] Invoke-EnterprisePipeline not found after loading scheduler"
    return 2
}
