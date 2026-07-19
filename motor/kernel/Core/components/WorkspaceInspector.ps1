class WorkspaceInspector : IComponent {
    WorkspaceInspector() : base('WorkspaceInspector','1.0',@(),@('Workspace')){}
    [void] Initialize([hashtable]$ctx){ Write-Output 'WorkspaceInspector: Initialize' }
    [void] Validate(){ Write-Output 'WorkspaceInspector: Validate' }
    [void] Start(){ Write-Output 'WorkspaceInspector: Start - verifying workspace'; $ok = Test-Path 'D:/HERMES-ENTERPRISE' ; if(-not $ok){ throw 'Workspace not found' } ; Write-Output 'WorkspaceInspector: Verified' }
    [void] Stop(){ Write-Output 'WorkspaceInspector: Stop' }
    [void] Dispose(){ Write-Output 'WorkspaceInspector: Dispose' }
}
return [WorkspaceInspector]::new()
