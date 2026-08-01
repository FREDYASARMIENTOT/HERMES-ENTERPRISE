# GitHub module (esqueleto)
function Create-GitHubRepo {
    param($Name, $Private = $true)
    Write-Output "Create-GitHubRepo $Name"
}
function Connect-Remote {
    param($Repo)
    Write-Output "Connect-Remote $Repo"
}
function Publish-Repo {
    param($Path)
    Write-Output "Publish-Repo $Path"
}
function Create-Release {
    param($Tag, $Notes)
    Write-Output "Create-Release $Tag"
}
function Setup-BranchProtection {
    param($Rules)
    Write-Output "Setup-BranchProtection"
}