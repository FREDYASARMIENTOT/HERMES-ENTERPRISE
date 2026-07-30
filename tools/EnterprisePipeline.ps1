<#
EnterprisePipeline adapter - lightweight, safe, and documented
Behavior: loads Invoke-EnterprisePipeline from tools if present or returns error code
#>
param(
    [Parameter(Mandatory=$false)][psobject]$Contexto
)

$adapterRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$schedulerPath = Join-Path -Path $adapterRoot -ChildPath 'Scheduler.ps1'
$alt = Join-Path -Path (Join-Path $adapterRoot '..') -ChildPath 'motor\bootstrap\engine\BootstrapOrchestrator.ps1'

# Prefer local Invoke-EnterprisePipeline implementation
$invokePath = Join-Path -Path $adapterRoot -ChildPath 'Invoke-EnterprisePipeline.ps1'
if (Test-Path $invokePath) { . $invokePath }

# Logging helper
function Write-HermesLog {
    param([string]$Message)
    $logPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'hermes.log'
    Add-Content -Path $logPath -Value ("$(Get-Date -Format o) | $Message")
}

# Try to load scheduler or orchestrator
if (Test-Path $schedulerPath) {
    . $schedulerPath
    Write-HermesLog "Adapter: Loaded Scheduler at $schedulerPath"
} elseif (Test-Path $alt) {
    . $alt
    Write-HermesLog "Adapter: Loaded BootstrapOrchestrator at $alt"
} else {
    Write-HermesLog "Adapter: Scheduler not found at $schedulerPath and orchestrator not found at $alt"
    Write-Output "[Adapter] Scheduler not found at $schedulerPath and orchestrator not found at $alt"
    return 1
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
