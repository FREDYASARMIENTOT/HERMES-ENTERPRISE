[psobject]ResolveWorkspace([string]$argWorkspace, [switch]$sandboxMode) {
    $candidate = $null
    $reason = $null
    $mode = $null
    $path = $null
    if ($this.Config -and $this.Config.WorkspaceRoot) { $candidate = $this.Config.WorkspaceRoot; $reason='Hermes.config.json' }
    if ($env:HERMES_WORKSPACE) { $candidate = $env:HERMES_WORKSPACE; $reason='Environment variable HERMES_WORKSPACE' }
    if ($argWorkspace) { $candidate = $argWorkspace; $reason='Argument' }
    if (-not $candidate) { $candidate = 'D:/Proyectos'; $reason='Default' }
    if ($sandboxMode.IsPresent) { $mode='Sandbox'; $path = $this.Config.SandboxRoot } else { $mode='Produccion'; $path = $candidate }
    return @{ Workspace=$path; Mode=$mode; Reason=$reason }
}
