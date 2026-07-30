Param(
    [Parameter(Mandatory=$true)][string]$ProjectName
)
$repoRoot = 'D:/HERMES-ENTERPRISE'
$tools = Join-Path $repoRoot 'tools'
$reports = Join-Path $repoRoot 'reports'
$cfg = Join-Path $repoRoot 'Hermes.config.json'

$wr = Join-Path $tools 'WorkspaceResolver.psm1'
$pf = Join-Path $tools 'ProjectFactoryV2.psm1'
$val = Join-Path $tools 'Validation.psm1'
$reg = Join-Path $tools 'Registry.psm1'

if (-not (Test-Path $wr)) { Write-Output "MISSING:$wr"; exit 2 }
if (-not (Test-Path $pf)) { Write-Output "MISSING:$pf"; exit 2 }
if (-not (Test-Path $val)) { Write-Output "MISSING:$val"; exit 2 }
if (-not (Test-Path $reg)) { Write-Output "MISSING:$reg"; exit 2 }

Import-Module $wr -Force -ErrorAction Stop
Import-Module $pf -Force -ErrorAction Stop
Import-Module $val -Force -ErrorAction Stop
Import-Module $reg -Force -ErrorAction Stop

$w = [WorkspaceResolver]::new($cfg)
$ctx = $w.ResolveWorkspace($null)
$start = Get-Date
$r = Create-Project -NombreProyecto $ProjectName -WorkspaceContext $ctx
$end = Get-Date
$elapsed = ($end - $start).TotalSeconds
$result = @{ ExitCode = (if ($r.Success) {0} else {1}); Workspace=$ctx.Workspace; Path=$r.Path; Time=$elapsed; Error=$r.Error }
$jf = Join-Path $reports 'CreateProjectResult.json'
$result | ConvertTo-Json | Out-File -FilePath $jf -Encoding utf8
if ($r.Success) { exit 0 } else { exit 1 }