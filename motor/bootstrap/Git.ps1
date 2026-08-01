# Git module (esqueleto)
function Initialize-Git { param($ProjectPath) Write-Output "Initialize-Git $ProjectPath" }
function Commit-All { param($Message) Write-Output "Commit-All: $Message" }
function Push-Origin { param() Write-Output "Push-Origin (placeholder)" }
function Fetch-Origin { git fetch origin }
function Get-GitStatusPorcelain { git status --porcelain }
function Get-CurrentBranch { git rev-parse --abbrev-ref HEAD }
function Get-LocalHead { git rev-parse HEAD }
function Get-RemoteHead { git rev-parse origin/main }
function Get-AheadBehind { git rev-list --left-right --count HEAD...origin/main }
