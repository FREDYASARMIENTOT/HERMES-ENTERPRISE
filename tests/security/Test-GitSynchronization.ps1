Import-Module ..\..\motor\bootstrap\functions\Git.ps1 -Force

Describe "Git Synchronization Tests" {
    It "Fase A - Estado local" {
        $porcelain = Get-GitStatusPorcelain
        $porcelain | Should -BeNullOrEmpty
        $branch = Get-CurrentBranch
        $branch | Should -Not -BeNullOrEmpty
        $localHead = Get-LocalHead
        $localHead | Should -Match '^[0-9a-f]{7,40}$'
    }

    It "Fase B - Estado remoto" {
        Fetch-Origin | Out-Null
        $remoteHead = Get-RemoteHead
        $remoteHead | Should -Match '^[0-9a-f]{7,40}$'
    }

    It "Fase C - Comparación ahead/behind" {
        $counts = Get-AheadBehind
        $counts.ahead | Should -Not -BeNullOrEmpty
        $counts.behind | Should -Not -BeNullOrEmpty
    }

    It "Fase D - Auditoría GitHub (gh api)" {
        $localHead = Get-LocalHead
        $repo = (git remote get-url origin) -replace '\.git$','' -replace 'https://github.com/',''
        $resp = gh api repos/$repo/commits/main --jq '.sha' 2>$null
        $resp | Should -Match '^[0-9a-f]{7,40}$'
        $localHead | Should -BeString
    }
}
