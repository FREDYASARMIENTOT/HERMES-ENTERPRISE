$file='D:/HERMES-ENTERPRISE/tools/WorkspaceResolver.psm1'
$abs = (Get-Item -LiteralPath $file).FullName
$exists = Test-Path -LiteralPath $file
$itm = Get-Item -LiteralPath $file | Select-Object FullName,Length,LastWriteTime
$hash = Get-FileHash -Path $file -Algorithm SHA256
$content = Get-Content -LiteralPath $file -Raw -Encoding UTF8
$len = $content.Length
$lines = $content -split "`n"
$first = $lines[0..([Math]::Min(19,$lines.Length-1))] -join "`n"
$last = $lines[([Math]::Max(0,$lines.Length-20))..($lines.Length-1)] -join "`n"
$out = [ordered]@{
    RequestedPath = $file
    AbsolutePath = $abs
    Exists = $exists
    Item = $itm
    SHA256 = $hash.Hash
    Encoding = 'UTF8'
    FileLength = $len
    First20 = $first
    Last20 = $last
}
$out | ConvertTo-Json -Depth 5 | Out-File D:/HERMES-ENTERPRISE/reports/ImportForensics.json -Encoding utf8
$out | Format-List | Out-String | Out-File D:/HERMES-ENTERPRISE/reports/ImportForensics.md -Encoding utf8
Write-Output 'Forensics written'