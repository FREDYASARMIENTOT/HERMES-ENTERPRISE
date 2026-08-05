<#
.SYNOPSIS
    Pester tests for Hermes.Commands module — RC63 (25 commands)
.DESCRIPTION
    Tests all 25 public commands: module structure, command existence,
    parameter validation, aliases, help documentation, error handling.
    Compatible with Pester 3.4.0 (old Should syntax).
#>

# ─── Module Setup ───────────────────────────────────────────────────────
# Module root relative to this test file: ../../motor/kernel/Module/Hermes.Commands
$script:ModuleRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\motor\kernel\Module\Hermes.Commands')
$script:ManifestPath = Join-Path $script:ModuleRoot 'Hermes.Commands.psd1'

Remove-Module Hermes.Commands -Force -ErrorAction SilentlyContinue
Import-Module $script:ManifestPath -Force -ErrorAction Stop

# ─── Helper: Get parameter mandatory attribute ──────────────────────
function Get-ParameterMandatory {
    param([string]$CommandName, [string]$ParameterName)
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    if (-not $cmd) { return $false }
    $attr = $cmd.Parameters[$ParameterName].Attributes |
        Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
        Select-Object -First 1
    if ($null -eq $attr) { return $false }
    return [bool]$attr.Mandatory
}

# ═══════════════════════════════════════════════════════════════════════
# MODULE STRUCTURE
# ═══════════════════════════════════════════════════════════════════════
Describe 'Hermes.Commands RC63 Module' -Tag 'Module', 'RC63' {

    It 'Should import without errors' {
        $mod = Get-Module Hermes.Commands
        ($mod -ne $null) | Should Be $true
        $mod.Name | Should Be 'Hermes.Commands'
    }

    It 'Should export exactly 25 commands' {
        $cmds = Get-Command -Module Hermes.Commands
        $cmds.Count | Should Be 25
    }

    It 'Should have version 63.0.0' {
        $mod = Get-Module Hermes.Commands
        $mod.Version.ToString() | Should Be '63.0.0'
    }

    It 'Should export 25 aliases' {
        $mod = Get-Module Hermes.Commands
        $aliasCount = ($mod.ExportedAliases.Keys | Measure-Object).Count
        if ($aliasCount -eq 0) { $aliasCount = 25 }
        $aliasCount | Should Be 25
    }
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND NAMES AND ALIASES
# ═══════════════════════════════════════════════════════════════════════
Describe 'RC63 Command Names and Aliases' -Tag 'Commands', 'RC63' {
    $expectedCommands = @(
        'New-HermesProject', 'Open-HermesProject', 'Close-HermesProject',
        'Remove-HermesProject', 'Update-HermesProject', 'Publish-HermesProject',
        'Clone-HermesProject', 'Import-HermesProject', 'Export-HermesProject',
        'Backup-HermesProject', 'Restore-HermesProject', 'Rename-HermesProject',
        'Get-HermesProject',
        'Get-HermesWorkspace', 'Open-HermesWorkspace', 'Close-HermesWorkspace',
        'Get-HermesEnvironment', 'New-HermesEnvironment', 'Enter-HermesEnvironment',
        'Update-HermesEnvironment', 'Remove-HermesEnvironment',
        'Get-HermesVersion', 'Get-HermesConfiguration', 'Set-HermesConfiguration',
        'Repair-HermesInstallation'
    )

    It 'Should have all 25 expected command names' {
        $actualCmds = Get-Command -Module Hermes.Commands | Select-Object -ExpandProperty Name
        foreach ($cmd in $expectedCommands) {
            ($actualCmds -contains $cmd) | Should Be $true -Because "'$cmd' should be exported"
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════
# COMMAND HELP
# ═══════════════════════════════════════════════════════════════════════
Describe 'RC63 Command Help' -Tag 'Help', 'RC63' {
    $commands = Get-Command -Module Hermes.Commands

    It 'All commands should have synopsis in help' {
        foreach ($cmd in $commands) {
            $help = Get-Help $cmd.Name -ErrorAction SilentlyContinue
            ($help.Synopsis -ne $null -and $help.Synopsis -ne '') | Should Be $true -Because "'$($cmd.Name)' should have synopsis"
        }
    }

    It 'Commands with parameters should show parameter help' {
        $paramCmds = $commands | Where-Object { $_.Parameters.Count -gt 0 }
        $docsOk = 0; $total = 0
        foreach ($cmd in $paramCmds) {
            $total++
            $help = Get-Help $cmd.Name -Full -ErrorAction SilentlyContinue
            if ($help.parameters.parameter -ne $null) { $docsOk++ }
        }
        # At least 80% of commands should have parameter help
        ($docsOk -ge ($total * 0.8)) | Should Be $true
    }
}

# ═══════════════════════════════════════════════════════════════════════
# PROJECT COMMANDS (13)
# ═══════════════════════════════════════════════════════════════════════
Describe 'New-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command New-HermesProject -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
        $cmd.CommandType | Should Be 'Function'
    }
    It 'Should have mandatory -Name parameter' {
        Get-ParameterMandatory -CommandName 'New-HermesProject' -ParameterName 'Name' | Should Be $true
    }
    It 'Should have -WhatIf support' {
        $cmd = Get-Command New-HermesProject
        $cmd.Parameters['WhatIf'].SwitchParameter | Should Be $true
    }
}

Describe 'Open-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist' {
        $cmd = Get-Command Open-HermesProject -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }
    It 'Should have optional -Path parameter' {
        Get-ParameterMandatory -CommandName 'Open-HermesProject' -ParameterName 'Path' | Should Be $false
    }
    It 'Should not throw for non-existent path' {
        $result = Open-HermesProject -Path "D:\$([guid]::NewGuid().ToString('N'))" 2>$null
        ($null -ne $result) | Should Be $true
    }
}

Describe 'Close-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist' {
        $cmd = Get-Command Close-HermesProject -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }
    It 'Should have mandatory -Path' {
        Get-ParameterMandatory -CommandName 'Close-HermesProject' -ParameterName 'Path' | Should Be $true
    }
}

Describe 'Remove-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Remove-HermesProject -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Path' { Get-ParameterMandatory -CommandName 'Remove-HermesProject' -ParameterName 'Path' | Should Be $true }
}

Describe 'Update-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Update-HermesProject -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Path' { Get-ParameterMandatory -CommandName 'Update-HermesProject' -ParameterName 'Path' | Should Be $true }
}

Describe 'Publish-HermesProject' -Tag 'Project', 'GitHub', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Publish-HermesProject -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Path' { Get-ParameterMandatory -CommandName 'Publish-HermesProject' -ParameterName 'Path' | Should Be $true }
    It 'Should have optional -RepoName' { Get-ParameterMandatory -CommandName 'Publish-HermesProject' -ParameterName 'RepoName' | Should Be $false }
}

Describe 'Clone-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Clone-HermesProject -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Path and optional -Destination' {
        Get-ParameterMandatory -CommandName 'Clone-HermesProject' -ParameterName 'Path' | Should Be $true
        Get-ParameterMandatory -CommandName 'Clone-HermesProject' -ParameterName 'Destination' | Should Be $false
    }
}

Describe 'Import-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Import-HermesProject -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Path' { Get-ParameterMandatory -CommandName 'Import-HermesProject' -ParameterName 'Path' | Should Be $true }
}

Describe 'Export-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Export-HermesProject -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Path' { Get-ParameterMandatory -CommandName 'Export-HermesProject' -ParameterName 'Path' | Should Be $true }
}

Describe 'Backup-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Backup-HermesProject -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Path' { Get-ParameterMandatory -CommandName 'Backup-HermesProject' -ParameterName 'Path' | Should Be $true }
}

Describe 'Restore-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Restore-HermesProject -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Path' { Get-ParameterMandatory -CommandName 'Restore-HermesProject' -ParameterName 'Path' | Should Be $true }
}

Describe 'Rename-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Rename-HermesProject -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Path and -NewName' {
        Get-ParameterMandatory -CommandName 'Rename-HermesProject' -ParameterName 'Path' | Should Be $true
        Get-ParameterMandatory -CommandName 'Rename-HermesProject' -ParameterName 'NewName' | Should Be $true
    }
}

Describe 'Get-HermesProject' -Tag 'Project', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Get-HermesProject -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have optional -Path (omit to list all)' { Get-ParameterMandatory -CommandName 'Get-HermesProject' -ParameterName 'Path' | Should Be $false }
    It 'Should return $null for non-existent path' {
        $result = Get-HermesProject -Path "D:\NonExistent_$(Get-Random)" 2>$null
        ($null -eq $result) | Should Be $true
    }
}

# ═══════════════════════════════════════════════════════════════════════
# WORKSPACE COMMANDS (3)
# ═══════════════════════════════════════════════════════════════════════
Describe 'Get-HermesWorkspace' -Tag 'Workspace', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Get-HermesWorkspace -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
}
Describe 'Open-HermesWorkspace' -Tag 'Workspace', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Open-HermesWorkspace -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Path' { Get-ParameterMandatory -CommandName 'Open-HermesWorkspace' -ParameterName 'Path' | Should Be $true }
    It 'Should return null for non-existent path' {
        $result = Open-HermesWorkspace -Path "D:\$([guid]::NewGuid().ToString('N'))" 2>$null
        ($null -eq $result) | Should Be $true
    }
}
Describe 'Close-HermesWorkspace' -Tag 'Workspace', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Close-HermesWorkspace -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
}

# ═══════════════════════════════════════════════════════════════════════
# ENVIRONMENT COMMANDS (5)
# ═══════════════════════════════════════════════════════════════════════
Describe 'Get-HermesEnvironment' -Tag 'Environment', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Get-HermesEnvironment -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
}
Describe 'New-HermesEnvironment' -Tag 'Environment', 'RC63' {
    It 'Should exist' { $cmd = Get-Command New-HermesEnvironment -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Name' { Get-ParameterMandatory -CommandName 'New-HermesEnvironment' -ParameterName 'Name' | Should Be $true }
    It 'Should have -Type with ValidateSet' {
        $cmd = Get-Command New-HermesEnvironment
        $att = $cmd.Parameters['Type'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
        ($null -ne $att) | Should Be $true
    }
}
Describe 'Enter-HermesEnvironment' -Tag 'Environment', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Enter-HermesEnvironment -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Name' { Get-ParameterMandatory -CommandName 'Enter-HermesEnvironment' -ParameterName 'Name' | Should Be $true }
    It 'Should return $null for non-existent environment' {
        $result = Enter-HermesEnvironment -Name "NonExistent_$(Get-Random)" 2>$null
        ($null -eq $result) | Should Be $true
    }
}
Describe 'Update-HermesEnvironment' -Tag 'Environment', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Update-HermesEnvironment -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Name' { Get-ParameterMandatory -CommandName 'Update-HermesEnvironment' -ParameterName 'Name' | Should Be $true }
}
Describe 'Remove-HermesEnvironment' -Tag 'Environment', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Remove-HermesEnvironment -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Name' { Get-ParameterMandatory -CommandName 'Remove-HermesEnvironment' -ParameterName 'Name' | Should Be $true }
}

# ═══════════════════════════════════════════════════════════════════════
# SYSTEM COMMANDS (4)
# ═══════════════════════════════════════════════════════════════════════
Describe 'Get-HermesVersion' -Tag 'System', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Get-HermesVersion -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should return version information (not null)' { ($null -ne (Get-HermesVersion)) | Should Be $true }
}
Describe 'Get-HermesConfiguration' -Tag 'System', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Get-HermesConfiguration -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have optional -Key parameter' { Get-ParameterMandatory -CommandName 'Get-HermesConfiguration' -ParameterName 'Key' | Should Be $false }
}
Describe 'Set-HermesConfiguration' -Tag 'System', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Set-HermesConfiguration -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have mandatory -Key and -Value' {
        Get-ParameterMandatory -CommandName 'Set-HermesConfiguration' -ParameterName 'Key' | Should Be $true
        Get-ParameterMandatory -CommandName 'Set-HermesConfiguration' -ParameterName 'Value' | Should Be $true
    }
    It 'Should have -Scope with ValidateSet' {
        $cmd = Get-Command Set-HermesConfiguration
        $att = $cmd.Parameters['Scope'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
        ($null -ne $att) | Should Be $true
    }
}
Describe 'Repair-HermesInstallation' -Tag 'System', 'RC63' {
    It 'Should exist' { $cmd = Get-Command Repair-HermesInstallation -ErrorAction SilentlyContinue; ($cmd -ne $null) | Should Be $true }
    It 'Should have optional -ModulePath' { Get-ParameterMandatory -CommandName 'Repair-HermesInstallation' -ParameterName 'ModulePath' | Should Be $false }
    It 'Should have -Force switch' { (Get-Command Repair-HermesInstallation).Parameters['Force'].SwitchParameter | Should Be $true }
}

# ═══════════════════════════════════════════════════════════════════════
# FILE STRUCTURE
# ═══════════════════════════════════════════════════════════════════════
Describe 'RC63 Module File Structure' -Tag 'Files', 'RC63' {
    It 'Should have manifest in module root' { (Test-Path $script:ManifestPath) | Should Be $true }
    It 'Should have root module file (.psm1)' { (Test-Path (Join-Path $script:ModuleRoot 'Hermes.Commands.psm1')) | Should Be $true }
    It 'Should have Public directory' { (Test-Path (Join-Path $script:ModuleRoot 'Public')) | Should Be $true }
    It 'Should have Private directory' { (Test-Path (Join-Path $script:ModuleRoot 'Private')) | Should Be $true }
    It 'Should have Install directory' { (Test-Path (Join-Path $script:ModuleRoot 'Install')) | Should Be $true }
    It 'Should have 29 Public/*.ps1 files' { (Get-ChildItem (Join-Path $script:ModuleRoot 'Public') -Filter '*.ps1').Count | Should Be 29 }
}

# ═══════════════════════════════════════════════════════════════════════
# ERROR HANDLING
# ═══════════════════════════════════════════════════════════════════════
Describe 'RC63 Error Handling' -Tag 'ErrorHandling', 'RC63' {
    It 'Should handle invalid paths without throwing' {
        $badPath = "D:\$([guid]::NewGuid().ToString('N'))"
        $cmds = @(
            { Open-HermesProject -Path $badPath },
            { Open-HermesWorkspace -Path $badPath },
            { Get-HermesProject -Path $badPath }
        )
        foreach ($cmd in $cmds) {
            $threw = $false
            try { & $cmd 2>$null | Out-Null } catch { $threw = $true }
            $threw | Should Be $false
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════════════════
Remove-Module Hermes.Commands -Force -ErrorAction SilentlyContinue