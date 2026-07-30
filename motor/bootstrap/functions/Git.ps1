function Test-GitInstallation {
    try {
        git --version > $null
        return $true
    } catch {
        return $false
    }
}

function Get-GitStatusPorcelain {
    git status --porcelain
}

function Get-CurrentBranch {
    git rev-parse --abbrev-ref HEAD
}

function Get-LocalHead {
    git rev-parse HEAD
}

function Fetch-Origin {
    git fetch origin
}

function Get-RemoteHead {
    git rev-parse origin/main
}

function Get-AheadBehind {
    git rev-list --left-right --count HEAD...origin/main | ForEach-Object {
        $parts = $_ -split "\t"
        return @{behind=$parts[0]; ahead=$parts[1]}
    }
}
