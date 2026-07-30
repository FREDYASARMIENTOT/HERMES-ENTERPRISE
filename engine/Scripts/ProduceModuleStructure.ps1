$mods = Get-ChildItem -Path 'D:/HERMES-ENTERPRISE' -Recurse -Include *.psm1 -File
$out = @()
foreach ($m in $mods) {
    $content = Get-Content -LiteralPath $m.FullName -Raw
    $lines = $content -split "`n"
    $count = $lines.Length
    $hasClass = $content -match '\bclass\b'
    $hasFunction = $content -match '\bfunction\b'
    $hasExport = $content -match 'Export-ModuleMember'
    $entry = [ordered]@{ File = $m.FullName; Lines = $count; HasClass = $hasClass; HasFunction = $hasFunction; HasExport = $hasExport }
    $out += $entry
}
$out | ConvertTo-Json -Depth 5 | Out-File 'D:/HERMES-ENTERPRISE/reports/ModuleStructure.json' -Encoding utf8
$out | Format-Table | Out-String | Out-File 'D:/HERMES-ENTERPRISE/reports/ModuleStructure.md' -Encoding utf8
Write-Output 'Module structure produced'
