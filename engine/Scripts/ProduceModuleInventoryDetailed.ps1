$repo='D:/HERMES-ENTERPRISE'
$mods = Get-ChildItem -Path $repo -Recurse -Include *.psm1 -File
$scripts = Get-ChildItem -Path $repo -Recurse -Include *.ps1 -File
$out = @()
foreach ($m in $mods) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($m.FullName)
    $refs = @()
    foreach ($s in $scripts) {
        $txt = Get-Content -LiteralPath $s.FullName -Raw -ErrorAction SilentlyContinue
        if ($txt -match [regex]::Escape($name)) { $refs += $s.FullName }
    }
    $rel = $m.FullName.Substring($repo.Length+1).TrimStart('\')
    $isTracked = $false
    try { $isTracked = (git ls-files | Select-String -Pattern ([regex]::Escape($rel))) -ne $null } catch { $isTracked = $false }
    $out += [ordered]@{ Name = $name; Path = $m.FullName; Versioned = $isTracked; ReferencedBy = $refs }
}
$out | ConvertTo-Json -Depth 6 | Out-File (Join-Path $repo 'reports/ModuleInventoryDetailed.json') -Encoding utf8
Write-Output 'Module inventory done'
