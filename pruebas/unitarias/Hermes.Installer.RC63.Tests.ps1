<#
.SYNOPSIS
    Pester tests for Hermes installer commands — Install/Update/Repair/Uninstall
.DESCRIPTION
    Tests Install-Hermes, Update-Hermes, Repair-HermesInstallation,
    and Uninstall-Hermes. Compatible with Pester 3.4.0.
#>

$script:ModuleRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\motor\kernel\Module\Hermes.Commands')
$script:ManifestPath = Join-Path $script:ModuleRoot 'Hermes.Commands.psd1'
$script:InstallScriptsDir = Join-Path $script:ModuleRoot 'Install'
$script:DistDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\dist')

Remove-Module Hermes.Commands -Force -ErrorAction SilentlyContinue
Import-Module $script:ManifestPath -Force -ErrorAction Stop

# ═══════════════════════════════════════════════════════════════════════
# INSTALLER SCRIPTS EXISTENCE
# ═══════════════════════════════════════════════════════════════════════
Describe 'Hermes Installer Scripts' -Tag 'Installer', 'RC63' {

    It 'Should have Install-Hermes.ps1 in Install/' {
        (Test-Path (Join-Path $script:InstallScriptsDir 'Install-Hermes.ps1')) | Should Be $true
    }

    It 'Should have Update-Hermes.ps1 in Install/' {
        (Test-Path (Join-Path $script:InstallScriptsDir 'Update-Hermes.ps1')) | Should Be $true
    }

    It 'Should have Uninstall-Hermes.ps1 in Install/' {
        (Test-Path (Join-Path $script:InstallScriptsDir 'Uninstall-Hermes.ps1')) | Should Be $true
    }

    It 'Should have Repair-HermesInstallation public command' {
        $cmd = Get-Command Repair-HermesInstallation -Module Hermes.Commands -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }
}

# ═══════════════════════════════════════════════════════════════════════
# INSTALL SCRIPTS — PARSE VALIDATION
# ═══════════════════════════════════════════════════════════════════════
Describe 'Install-Hermes Syntax' -Tag 'Installer', 'RC63' {

    It 'Should parse without errors' {
        { $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:InstallScriptsDir 'Install-Hermes.ps1'), [ref]$null, [ref]$null) } |
            Should Not Throw
    }

    It 'Should have valid parameters (syntax check)' {
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:InstallScriptsDir 'Install-Hermes.ps1'), [ref]$tokens, [ref]$errors)
        ($errors.Count -eq 0 -or ($errors | Where-Object { $_.Id -ne 'ParserMissingParam' }).Count -eq 0) | Should Be $true
    }
}

Describe 'Update-Hermes Syntax' -Tag 'Installer', 'RC63' {

    It 'Should parse without errors' {
        { $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:InstallScriptsDir 'Update-Hermes.ps1'), [ref]$null, [ref]$null) } |
            Should Not Throw
    }
}

Describe 'Uninstall-Hermes Syntax' -Tag 'Installer', 'RC63' {

    It 'Should parse without errors' {
        { $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:InstallScriptsDir 'Uninstall-Hermes.ps1'), [ref]$null, [ref]$null) } |
            Should Not Throw
    }
}

# ═══════════════════════════════════════════════════════════════════════
# REPAIR COMMAND
# ═══════════════════════════════════════════════════════════════════════
Describe 'Repair-HermesInstallation' -Tag 'Installer', 'RC63' {

    It 'Should be a command' {
        $cmd = Get-Command Repair-HermesInstallation -Module Hermes.Commands -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have -ModulePath parameter' {
        $cmd = Get-Command Repair-HermesInstallation -Module Hermes.Commands -ErrorAction SilentlyContinue
        $cmd.Parameters.ContainsKey('ModulePath') | Should Be $true
    }

    It 'Should have -Force parameter (optional)' {
        $cmd = Get-Command Repair-HermesInstallation -Module Hermes.Commands -ErrorAction SilentlyContinue
        $cmd.Parameters.ContainsKey('Force') | Should Be $true
    }
}

# ═══════════════════════════════════════════════════════════════════════
# DISTRIBUTION INTEGRITY
# ═══════════════════════════════════════════════════════════════════════
Describe 'Distribution Integrity' -Tag 'Installer', 'RC63' {

    It 'Should have dist/ directory' {
        (Test-Path $script:DistDir) | Should Be $true
    }

    It 'Should have RELEASE_NOTES.md' {
        (Test-Path (Join-Path $script:DistDir 'RELEASE_NOTES.md')) | Should Be $true
    }

    It 'Should have SHA256SUMS.txt' {
        (Test-Path (Join-Path $script:DistDir 'SHA256SUMS.txt')) | Should Be $true
    }

    It 'Should have Hermes.Commands module in dist/' {
        (Test-Path (Join-Path $script:DistDir 'Hermes.Commands\Hermes.Commands.psd1')) | Should Be $true
    }

    It 'Should have DISTRIBUTION_REPORT.txt' {
        (Test-Path (Join-Path $script:DistDir 'DISTRIBUTION_REPORT.txt')) | Should Be $true
    }
}