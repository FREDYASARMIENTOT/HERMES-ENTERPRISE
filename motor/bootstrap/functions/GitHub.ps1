# functions/GitHub.ps1 - Implement gh-based provisioning helpers
function Test-GitHubAuthentication {
    try {
        $status = gh auth status 2>&1
        if ($status -match 'Logged in to github.com') {
            return $true
        }
    } catch { }
    return $false
}

function New-GitHubRepository {
    param($Name, $Private = $true)
    gh repo create $Name --private --confirm
}

function Connect-GitHubRemote {
    param($RepoUri)
    git remote add origin $RepoUri
}

function Publish-Repository {
    param($Branch='main')
    git push -u origin $Branch
}

function Verify-GitHubSynchronization {
    $local = git rev-parse HEAD
    $remote = gh api repos/$(git remote get-url origin | ForEach-Object { $_ -replace '\.git$','' -replace 'https://github.com/','' })/commits/main --jq '.sha' 2>$null
    return $local -eq $remote
}
