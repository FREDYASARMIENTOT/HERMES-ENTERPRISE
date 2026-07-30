Param()
Import-Module "..\..\tools\WorkspaceResolver.psm1"
$w = [WorkspaceResolver]::new((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..\..\Hermes.config.json'))
$ctx = $w.ResolveWorkspace($null)
$ctx | ConvertTo-Json | Out-File -FilePath (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..\..\reports\ResolveWorkspace.json') -Encoding utf8
Write-Output $ctx.Workspace