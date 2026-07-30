function Invoke-EnterprisePipeline {
    param(
        [psobject]$Context
    )
    # Minimal orchestration implementing local golden path steps
    Write-Output "[Invoke-EnterprisePipeline] Starting orchestration"

    $repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $root = Resolve-Path (Join-Path $repoRoot '..')
    $hermesDir = Join-Path $root '.hermes'
    if (-not (Test-Path $hermesDir)) { New-Item -ItemType Directory -Path $hermesDir | Out-Null }

    # Persist BOOTSTRAP_CONTEXT.json if not present
    $bootstrapPath = Join-Path $hermesDir 'BOOTSTRAP_CONTEXT.json'
    if (-not (Test-Path $bootstrapPath)) {
        $ctx = @{ Sprint='Builder++++++'; Status='IN_PROGRESS'; GoldenPath= @{ }; CurrentBlocker='None'; NextTask='Orchestrating' }
        $ctx | ConvertTo-Json | Out-File -FilePath $bootstrapPath -Encoding utf8
        Write-Output "[Invoke-EnterprisePipeline] BOOTSTRAP_CONTEXT.json created"
    }

    # Persist LAST_INVOCATION.json
    $lastPath = Join-Path $hermesDir 'LAST_INVOCATION.json'
    $Context | ConvertTo-Json | Out-File -FilePath $lastPath -Encoding utf8

    # Initialize Git repo locally
    $projDir = Join-Path $root $Context.NombreProyecto
    if (-not (Test-Path $projDir)) { New-Item -ItemType Directory -Path $projDir | Out-Null; Write-Output "[Invoke-EnterprisePipeline] Project directory created: $projDir" }
    if (-not (Test-Path (Join-Path $projDir '.git'))) {
        & git -C $projDir init
        Write-Output "[Invoke-EnterprisePipeline] Git initialized in $projDir"
    }

    # Provision remote if requested (mock: do not call GH without token)
    if ($Context.ProvisionTarget -eq 'GitHub') {
        Write-Output "[Invoke-EnterprisePipeline] ProvisionTarget=GitHub -> remote creation mocked. (No network call in this run)"
        # create remote stub file
        $remoteStub = Join-Path $projDir 'REMOTE_STUB.txt'
        "remote: github.com/${Context.GitHubUser}/${Context.NombreProyecto}" | Out-File -FilePath $remoteStub -Encoding utf8
    }

    # Create environment (virtualenv mock)
    $envDir = Join-Path $projDir 'env'
    if (-not (Test-Path $envDir)) { New-Item -ItemType Directory -Path $envDir | Out-Null; Write-Output "[Invoke-EnterprisePipeline] Environment created at $envDir" }

    # Persist EstadoEjecucion.json
    $statusPath = Join-Path -Path (Join-Path $root 'tools') -ChildPath 'reports/EstadoEjecucion.json'
    if (-not (Test-Path (Split-Path $statusPath))) { New-Item -ItemType Directory -Path (Split-Path $statusPath) -Force | Out-Null }
    $status = @{ timestamp=(Get-Date).ToString('o'); paso='Invoke-EnterprisePipeline'; evento='COMPLETED'; detalle='Local orchestration done' }
    $status | ConvertTo-Json | Out-File -FilePath $statusPath -Encoding utf8

    Write-Output "[Invoke-EnterprisePipeline] Orchestration completed"
    return 0
}

# Export function for callers
Export-ModuleMember -Function Invoke-EnterprisePipeline
