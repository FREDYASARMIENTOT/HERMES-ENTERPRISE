Param(
    [Parameter(Mandatory=$true)][string]$ProjectName
)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Import-Module (Join-Path $scriptDir '..\..\tools\WorkspaceResolver.psm1')
Import-Module (Join-Path $scriptDir '..\..\tools\ProjectFactoryV2.psm1')
Import-Module (Join-Path $scriptDir '..\..\tools\Validation.psm1')
Import-Module (Join-Path $scriptDir '..\..\tools\Registry.psm1')

$w = [WorkspaceResolver]::new((Join-Path $scriptDir '..\..\Hermes.config.json'))
$ctx = $w.ResolveWorkspace($null)
$start = Get-Date
$r = Create-Project -NombreProyecto $ProjectName -WorkspaceContext $ctx
$end = Get-Date
$elapsed = ($end - $start).TotalSeconds
$result = @{ ExitCode = (if ($r.Success) {0} else {1}); Workspace=$ctx.Workspace; Path=$r.Path; Time=$elapsed; Error=$r.Error }
$result | ConvertTo-Json | Out-File -FilePath (Join-Path $scriptDir '..\..\reports\CreateProjectResult.json') -Encoding utf8
if ($r.Success) { exit 0 } else { exit 1 }
