function Get-SystemCapabilities {
    <#
    Returns an array of capability objects discovered on the host.
    Each object: @{ name=string; implementation=string; path=string; health=string }
    #>
    param()
    $caps = @()
    # PowerShell
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) { $caps += @{ name='PowerShell_7'; implementation='system'; path=$pwsh.Source; health='READY' } }
    else { $caps += @{ name='PowerShell_7'; implementation='system'; path=$null; health='MISSING' } }
    # Python
    $py = Get-Command python -ErrorAction SilentlyContinue
    if ($py) { $caps += @{ name='Python_3'; implementation='system'; path=$py.Source; health='READY' } }
    else { $caps += @{ name='Python_3'; implementation='system'; path=$null; health='MISSING' } }
    # Git
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) { $caps += @{ name='Git'; implementation='system'; path=$git.Source; health='READY' } }
    else { $caps += @{ name='Git'; implementation='system'; path=$null; health='MISSING' } }
    return $caps
}

function Write-CapabilitySnapshot {
    param(
        [string]$OutPath = "$PSScriptRoot\..\..\.verification\capabilities\discovery-$(Get-Date -Format yyyyMMddHHmmss).json"
    )
    $caps = Get-SystemCapabilities
    $caps | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutPath -Encoding utf8
    return $OutPath
}

Export-ModuleMember -Function Get-SystemCapabilities,Write-CapabilitySnapshot
