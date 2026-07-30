Set-Location 'D:/HERMES-ENTERPRISE'
$repo='D:/HERMES-ENTERPRISE'
$out = [ordered]@{}
$out.Toplevel = git rev-parse --show-toplevel 2>&1
$out.Status = git status --porcelain=2 -b 2>&1
$out.Branches = git branch -vv 2>&1
$out.Remotes = git remote -v 2>&1
$out.HEAD = git rev-parse HEAD 2>&1
$out | ConvertTo-Json -Depth 5 | Out-File "$repo/reports/GitRepository.json" -Encoding utf8
Write-Output 'Git info captured'
