$RepoRoot = 'D:\HERMES-ENTERPRISE'
Describe 'Start-HermesProject basic' {
  It 'Start-HermesProject.ps1 shim exists and parses without error' {
    $shim = Join-Path $RepoRoot 'Start-HermesProject.ps1'
    (Test-Path $shim) | Should Be $true
    $errors = $null
    $parsed = [System.Management.Automation.Language.Parser]::ParseFile($shim, [ref]$null, [ref]$errors)
    ($parsed -ne $null) | Should Be $true
    $errors.Count | Should Be 0
  }
  It 'Bootstrap script exists' {
    $bootScript = Join-Path $RepoRoot 'motor\bootstrap\Start-HermesProject.ps1'
    (Test-Path $bootScript) | Should Be $true
  }
}
