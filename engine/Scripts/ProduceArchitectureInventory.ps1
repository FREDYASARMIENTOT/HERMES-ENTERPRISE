Set-StrictMode -Version Latest
$repo='D:/HERMES-ENTERPRISE'
Set-Location $repo
$tracked = git ls-files | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
$status = git status --porcelain=2 | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
$ignored = @()
try { $ignored = (git check-ignore -v * 2>$null) -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } } catch { $ignored = @() }
$all = Get-ChildItem -Path $repo -Recurse -File | ForEach-Object { $_.FullName.Substring($repo.Length+1).TrimStart('\\') }
$untracked = @()
foreach ($f in $all) { if ($tracked -notcontains $f) { $untracked += $f } }
$groups = [ordered]@{ TrackedModified = @(); TrackedDeleted = @(); Untracked = @(); Ignored = @() }
foreach ($s in $status) {
    if ($s -match '^1\s+(\S)') { $flag = $matches[1]; $parts = $s -split '\s+'; $file = $parts[-1];
        if ($flag -eq 'M') { $groups.TrackedModified += $file }
        elseif ($flag -eq 'D') { $groups.TrackedDeleted += $file }
    }
}
$groups.Untracked = $untracked
$groups.Ignored = $ignored
$groups | ConvertTo-Json -Depth 5 | Out-File (Join-Path $repo 'reports/ArchitectureInventory.json') -Encoding utf8
Write-Output 'Architecture inventory written'