function Resolve-Capability {
    param(
        [string]$Name
    )
    $capsDir = Join-Path $PSScriptRoot '..\..\.verification\capabilities'
    $files = Get-ChildItem -Path $capsDir -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    foreach ($f in $files) {
        $data = Get-Content $f.FullName | ConvertFrom-Json
        foreach ($c in $data.capabilities) {
            if ($c.component -eq $Name) { return $c }
        }
    }
    return $null
}

function Resolve-ExecutionRequest {
    param(
        [string]$ComponentName,
        [hashtable]$Payload
    )
    # Simple resolution: check capability snapshot
    $cap = Resolve-Capability -Name $ComponentName
    if (-not $cap) { return @{ status='UNAVAILABLE'; reason='capability_not_found' } }
    if ($cap.health -ne 'READY') { return @{ status='UNAVAILABLE'; reason='capability_not_ready'; detail=$cap } }
    return @{ status='READY'; capability=$cap; payload=$Payload }
}

Export-ModuleMember -Function Resolve-Capability,Resolve-ExecutionRequest
