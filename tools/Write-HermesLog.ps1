function Write-HermesLog {
    param(
        [string]$Message
    )
    # Single standard: write to tools/hermes.log
    $logPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'hermes.log'
    Add-Content -Path $logPath -Value ("$(Get-Date -Format o) | $Message")
}

# NOTE: Escribir-ProgresoHermes existe; refactor later to a single interface. For now Write-HermesLog provides the basic expected function used by adapters.
