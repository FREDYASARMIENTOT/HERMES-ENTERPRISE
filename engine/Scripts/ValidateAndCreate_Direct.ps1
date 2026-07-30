# ValidateAndCreate_Direct.ps1
param(
    [string]$ProjectName = 'ProyectoPrueba001'
)
$repo='D:/HERMES-ENTERPRISE'
$tools=Join-Path $repo 'tools'
$reports=Join-Path $repo 'reports'
if(-not (Test-Path $reports)) { New-Item -ItemType Directory -Path $reports | Out-Null }
# Atomic restore: if tmp exists, move to real
$tmp=Join-Path $tools 'WorkspaceResolver.psm1.tmp'
$real=Join-Path $tools 'WorkspaceResolver.psm1'
$backup=Join-Path $reports 'backups/WorkspaceResolver.psm1.bak'
if (Test-Path $tmp) {
    if (-not (Test-Path (Split-Path $backup))) { New-Item -ItemType Directory -Path (Split-Path $backup) | Out-Null }
    if (Test-Path $real) { Copy-Item -Path $real -Destination $backup -Force }
    Move-Item -Path $tmp -Destination $real -Force
}
# Import WorkspaceResolver
$log = @()
function Log($step,$cmd,$exit,$out,$err,$dur){ $log+=[ordered]@{Step=$step; Command=$cmd; ExitCode=$exit; Out=$out; Err=$err; Duration=$dur} }
# Step A: Import module workspaceresolver
$start=Get-Date
try{ Import-Module $real -Force -ErrorAction Stop; $end=Get-Date; Log 'Import-WorkspaceResolver' "Import-Module $real" 0 'OK' '' (($end-$start).TotalMilliseconds) } catch { $end=Get-Date; Log 'Import-WorkspaceResolver' "Import-Module $real" 1 '' $_.Exception.Message (($end-$start).TotalMilliseconds); $log|ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'ExecutionTrace.json'); $log|Format-Table | Out-String | Out-File (Join-Path $reports 'ExecutionTrace.md'); exit 1 }
# Step B: Resolve workspace
$start=Get-Date
try{ $w = [WorkspaceResolver]::new((Join-Path $repo 'Hermes.config.json')); $ctx = $w.ResolveWorkspace($null); $end=Get-Date; $ctx | ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'WorkspaceContext.json') -Encoding utf8; $log|Add-Member -NotePropertyName 'WorkspaceContext' -NotePropertyValue $ctx -Force; Log 'ResolveWorkspace' 'Invoke' 0 ($ctx|ConvertTo-Json -Depth 4) '' (($end-$start).TotalMilliseconds) } catch { $end=Get-Date; Log 'ResolveWorkspace' 'Invoke' 1 '' $_.Exception.Message (($end-$start).TotalMilliseconds); $log|ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'ExecutionTrace.json'); $log|Format-Table | Out-String | Out-File (Join-Path $reports 'ExecutionTrace.md'); exit 1 }
# Step C: Import ProjectFactory
$pf = Join-Path $tools 'ProjectFactoryV2.psm1'
$start=Get-Date
try{ Import-Module $pf -Force -ErrorAction Stop; $end=Get-Date; Log 'Import-ProjectFactory' "Import-Module $pf" 0 'OK' '' (($end-$start).TotalMilliseconds) } catch { $end=Get-Date; Log 'Import-ProjectFactory' "Import-Module $pf" 1 '' $_.Exception.Message (($end-$start).TotalMilliseconds); $log|ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'ExecutionTrace.json'); $log|Format-Table | Out-String | Out-File (Join-Path $reports 'ExecutionTrace.md'); exit 1 }
# Step D: Create project
$start=Get-Date
try{ $r = Create-Project -NombreProyecto $ProjectName -WorkspaceContext $ctx; $end=Get-Date; Log 'Create-Project' "Create-Project $ProjectName" (if($r.Success){0}else{1}) ($r | ConvertTo-Json -Depth 5) '' (($end-$start).TotalMilliseconds); if(-not $r.Success){ $log|ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'ExecutionTrace.json'); $log|Format-Table | Out-String | Out-File (Join-Path $reports 'ExecutionTrace.md'); exit 1 } } catch { $end=Get-Date; Log 'Create-Project' "Create-Project $ProjectName" 1 '' $_.Exception.Message (($end-$start).TotalMilliseconds); $log|ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'ExecutionTrace.json'); $log|Format-Table | Out-String | Out-File (Join-Path $reports 'ExecutionTrace.md'); exit 1 }
# Step E: Filesystem validation
$tp = Test-Path (Join-Path $ctx.Workspace $ProjectName)
$gci = Get-ChildItem -LiteralPath $ctx.Workspace | Out-String
Log 'Filesystem-TestPath' "Test-Path $($ctx.Workspace)\$ProjectName" (if($tp){0}else{1}) $tp '' 0
$log|ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'ExecutionTrace.json') -Encoding utf8
$log|Format-Table | Out-String | Out-File (Join-Path $reports 'ExecutionTrace.md') -Encoding utf8
# Save workspace context type
$ctx | Get-Member | Select-Object Name,MemberType | ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'WorkspaceContextType.json') -Encoding utf8
Write-Output 'Done'
