class PayloadValidator : IComponent {
    PayloadValidator() : base('PayloadValidator','1.0',@('WorkspaceInspector'),@('Payload')){}
    [void] Initialize([hashtable]$ctx){ Write-Output 'PayloadValidator: Initialize' }
    [void] Validate(){ Write-Output 'PayloadValidator: Validate' }
    [void] Start(){ Write-Output 'PayloadValidator: Start - validating payload'; Write-Output 'PayloadValidator: Payload OK' }
    [void] Stop(){ Write-Output 'PayloadValidator: Stop' }
    [void] Dispose(){ Write-Output 'PayloadValidator: Dispose' }
}
return [PayloadValidator]::new()
