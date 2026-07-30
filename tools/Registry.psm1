function Register-Project {
    param(
        [Parameter(Mandatory=$true)][psobject]$Entry
    )
    $regPath = 'D:/HERMES-ENTERPRISE/reports/ProjectRegistry.json'
    if (-not (Test-Path $regPath)) { @() | ConvertTo-Json | Out-File -FilePath $regPath -Encoding utf8 }
    $arr = @()
    try { $arr = Get-Content $regPath -Raw | ConvertFrom-Json } catch { $arr=@() }
    $arr += $Entry
    $arr | ConvertTo-Json | Out-File -FilePath $regPath -Encoding utf8
    return $true
}
Export-ModuleMember -Function Register-Project
