# run_mission_bootstrap.ps1 - orchestrates components via KernelHost (MVK)
. 'D:/HERMES-ENTERPRISE/motor/kernel/Core/ServiceContainer.ps1'
. 'D:/HERMES-ENTERPRISE/motor/kernel/Core/EventBus.ps1'
. 'D:/HERMES-ENTERPRISE/motor/kernel/Core/ComponentRegistry.ps1'
. 'D:/HERMES-ENTERPRISE/motor/kernel/Contracts/IComponent.ps1'
. 'D:/HERMES-ENTERPRISE/motor/kernel/Core/KernelHost.ps1'

# Load component implementations
$workspaceComp = . 'D:/HERMES-ENTERPRISE/motor/kernel/Core/components/WorkspaceInspector.ps1'
$payloadComp = . 'D:/HERMES-ENTERPRISE/motor/kernel/Core/components/PayloadValidator.ps1'
$bootstrapComp = . 'D:/HERMES-ENTERPRISE/motor/kernel/Core/components/BootstrapOrchestrator.ps1'
$certComp = . 'D:/HERMES-ENTERPRISE/motor/kernel/Core/components/CertificationEngine.ps1'

# Setup container and eventbus via KernelHost responsibilities
$container = [ServiceContainer]::new()
$container.Register('EventBus',{ [EventBus]::new() })
$container.Register('Registry',{ [ComponentRegistry]::new() })

$kernelHostInstance = [KernelHost]::new($container)

# Components load plan (simple order respecting dependencies)
$components = @(
    @{ id='WorkspaceInspector'; factory={ $workspaceComp } },
    @{ id='PayloadValidator'; factory={ $payloadComp } },
    @{ id='BootstrapOrchestrator'; factory={ $bootstrapComp } },
    @{ id='CertificationEngine'; factory={ $certComp } }
)

Import-Module D:/HERMES-ENTERPRISE/motor/observability/ExecutionObservatory.ps1 -Force -ErrorAction SilentlyContinue
Start-Observatory
Write-Output '--- BOOTSTRAP MISSION START ---'
$start = Get-Date
$success = $true
try {
    $kernelHostInstance.RunStartup($components)
} catch {
    $success = $false
    $errorMsg = $_.Exception.Message
}
$end = Get-Date
$duration = ($end - $start).TotalSeconds
Write-Output '--- BOOTSTRAP MISSION END ---'
# Record facts for Sprint A
$exit_code = if ($success) { 0 } else { 1 }
$facts = @{ target='D:/HERMES-ENTERPRISE/motor/bootstrap/Start-HermesProject.ps1'; exit_code=$exit_code; stdout='(see logs)'; stderr=$errorMsg; duration=$duration }
$ledgerPath = 'D:/HERMES-ENTERPRISE/.verification/ledger.json'
if (-not (Test-Path (Split-Path $ledgerPath))) { New-Item -ItemType Directory -Path (Split-Path $ledgerPath) -Force | Out-Null }
$entry = @{ timestamp=(Get-Date).ToString('o'); component='BootstrapOrchestrator'; action='ExecuteScript'; evidence=@($facts) }
if (Test-Path $ledgerPath) { $arr = Get-Content $ledgerPath | ConvertFrom-Json } else { $arr = @() }
$arr += $entry
$arr | ConvertTo-Json -Depth 5 | Out-File -FilePath $ledgerPath -Encoding utf8

# Stop observatory and write telemetry
Stop-Observatory

# Print required five facts
Write-Output "TARGET: $($facts.target)"
Write-Output "EXIT_CODE: $($facts.exit_code)"
Write-Output "STDOUT: $($facts.stdout)"
Write-Output "STDERR: $($facts.stderr)"
Write-Output "DURATION: $($facts.duration)"
