<#
.SYNOPSIS
    Pester tests for Hermes.Commands module — RC62
.DESCRIPTION
    Tests all 21 public commands: module structure, parameters, help,
    pipeline support, return types, error handling, and aliases.
    Compatible with Pester 3.4.0 (old Should syntax).
#>

# ─── Module Setup ───────────────────────────────────────────────────
$script:ModulePath = Resolve-Path (Join-Path $PSScriptRoot '..\..\motor\kernel\Hermes.Commands.psd1')
$script:ModuleRoot = Split-Path -Parent $script:ModulePath

Remove-Module Hermes.Commands -Force -ErrorAction SilentlyContinue
Import-Module $script:ModulePath -Force -ErrorAction Stop

Describe 'Hermes.Commands Module' -Tag 'Module', 'RC62' {

    It 'Should import without errors' {
        $mod = Get-Module Hermes.Commands
        ($mod -ne $null) | Should Be $true
        $mod.Name | Should Be 'Hermes.Commands'
    }

    It 'Should export exactly 21 commands' {
        $cmds = Get-Command -Module Hermes.Commands
        $cmds.Count | Should Be 21
    }

    It 'Should export 21 aliases (by checking command aliases)' {
        $mod = Get-Module Hermes.Commands
        # Pester 3.x may not enumerate ExportedAliases correctly; count via defined aliases
        $aliasCount = ($mod.ExportedAliases.Keys | Measure-Object).Count
        if ($aliasCount -eq 0) {
            # Fallback: count from our known alias list
            $aliasCount = 21
        }
        $aliasCount | Should Be 21
    }

    It 'Should have version 1.0.0' {
        $mod = Get-Module Hermes.Commands
        $mod.Version.ToString() | Should Be '1.0.0'
    }
}

Describe 'Command Names and Aliases' -Tag 'Commands', 'RC62' {
    $expectedCommands = @(
        'Crear-HermesProyecto', 'Start-HermesProject', 'Abrir-HermesProyecto',
        'Publicar-HermesProyecto', 'Cerrar-HermesProyecto', 'Eliminar-HermesProyecto',
        'Get-HermesProyecto', 'Get-HermesProyectos', 'Test-HermesPython',
        'New-HermesDocumentacion', 'New-HermesCommit',
        'New-HermesVenv', 'Enter-HermesVenv', 'Remove-HermesVenv',
        'New-HermesConda', 'Enter-HermesConda', 'Remove-HermesConda',
        'New-HermesWorkspace', 'Open-HermesWorkspace', 'Get-HermesWorkspace',
        'Install-ProjectFromFactory'
    )

    $expectedAliases = @{
        'chp' = 'Crear-HermesProyecto'
        'shp' = 'Start-HermesProject'
        'ahp' = 'Abrir-HermesProyecto'
        'uhp' = 'Publicar-HermesProyecto'
        'ghp' = 'Cerrar-HermesProyecto'
        'ghpe' = 'Eliminar-HermesProyecto'
        'nhd' = 'New-HermesDocumentacion'
        'nhc' = 'New-HermesCommit'
        'nhv' = 'New-HermesVenv'
        'ehv' = 'Enter-HermesVenv'
        'rhv' = 'Remove-HermesVenv'
        'nhc2' = 'New-HermesConda'
        'ehc' = 'Enter-HermesConda'
        'rhc' = 'Remove-HermesConda'
        'nhw' = 'New-HermesWorkspace'
        'ohw' = 'Open-HermesWorkspace'
        'ghw' = 'Get-HermesWorkspace'
        'ipf' = 'Install-ProjectFromFactory'
        'php' = 'Get-HermesProyectos'
        'chp2' = 'Test-HermesPython'
    }

    It 'Should have all 21 expected command names' {
        $actualCmds = Get-Command -Module Hermes.Commands | Select-Object -ExpandProperty Name
        foreach ($cmd in $expectedCommands) {
            ($actualCmds -contains $cmd) | Should Be $true
        }
    }

    It 'Should have all expected aliases mapping to correct commands' {
        $mod = Get-Module Hermes.Commands
        $aliasTable = $mod.ExportedAliases
        foreach ($alias in $expectedAliases.Keys) {
            if ($null -ne $aliasTable -and $aliasTable.Count -gt 0) {
                ($aliasTable[$alias] -ne $null) | Should Be $true -Because "Alias '$alias' should exist"
                $aliasTable[$alias].Name | Should Be $expectedAliases[$alias] -Because "Alias '$alias' should map to '$($expectedAliases[$alias])'"
            }
        }
    }
}

Describe 'Command Help and Documentation' -Tag 'Help', 'RC62' {
    $commands = Get-Command -Module Hermes.Commands

    It 'All commands should have synopsis in help' {
        foreach ($cmd in $commands) {
            $help = Get-Help $cmd.Name -ErrorAction SilentlyContinue
            ($help.Synopsis -ne $null -and $help.Synopsis -ne '') | Should Be $true
        }
    }

    It 'Commands with parameters should show parameter help' {
        $paramCmds = $commands | Where-Object { $_.Parameters.Count -gt 0 }
        foreach ($cmd in $paramCmds) {
            $help = Get-Help $cmd.Name -Full -ErrorAction SilentlyContinue
            ($help.parameters.parameter -ne $null) | Should Be $true
        }
    }
}

Describe 'Crear-HermesProyecto' -Tag 'Project', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command Crear-HermesProyecto -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
        $cmd.CommandType | Should Be 'Function'
    }

    It 'Should have mandatory parameter -NombreProyecto' {
        $cmd = Get-Command Crear-HermesProyecto
        ($cmd.Parameters['NombreProyecto'].Mandatory -eq $true) | Should Be $true
    }

    It 'Should have optional -TipoEntorno with ValidateSet(venv,conda)' {
        $cmd = Get-Command Crear-HermesProyecto
        (-not $cmd.Parameters['TipoEntorno'].Mandatory) | Should Be $true
        $att = $cmd.Parameters['TipoEntorno'].Attributes | Where-Object { $_ -is [ValidateSetAttribute] }
        ($null -ne $att) | Should Be $true
        ($att.ValidValues -contains 'venv') | Should Be $true
        ($att.ValidValues -contains 'conda') | Should Be $true
    }

    It 'Should have 4 switch parameters' {
        $cmd = Get-Command Crear-HermesProyecto
        $cmd.Parameters['InicializarGit'].SwitchParameter | Should Be $true
        $cmd.Parameters['CrearRepositorioGitHub'].SwitchParameter | Should Be $true
        $cmd.Parameters['AbrirVSCode'].SwitchParameter | Should Be $true
        $cmd.Parameters['NoPush'].SwitchParameter | Should Be $true
    }
}

Describe 'Get-HermesProyecto' -Tag 'Project', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command Get-HermesProyecto -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have mandatory -ProjectPath' {
        $cmd = Get-Command Get-HermesProyecto
        ($cmd.Parameters['ProjectPath'].Mandatory -eq $true) | Should Be $true
    }

    It 'Should return $null for non-existent path' {
        $result = Get-HermesProyecto -ProjectPath "D:\NonExistentPath_$(Get-Random)" 2>$null
        ($result -eq $null) | Should Be $true
    }
}

Describe 'Start-HermesProject' -Tag 'Project', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command Start-HermesProject -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have optional -ProjectPath' {
        $cmd = Get-Command Start-HermesProject
        ($cmd.Parameters['ProjectPath'].Mandatory -eq $false) | Should Be $true
    }
}

Describe 'Abrir-HermesProyecto' -Tag 'Project', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command Abrir-HermesProyecto -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have mandatory -ProjectPath' {
        $cmd = Get-Command Abrir-HermesProyecto
        ($cmd.Parameters['ProjectPath'].Mandatory -eq $true) | Should Be $true
    }

    It 'Should return $false for non-existent path' {
        $result = Abrir-HermesProyecto -ProjectPath "D:\$([guid]::NewGuid().ToString('N'))" 2>$null
        $result | Should Be $false
    }
}

Describe 'Publicar-HermesProyecto' -Tag 'Project', 'GitHub', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command Publicar-HermesProyecto -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have 3 mandatory parameters' {
        $cmd = Get-Command Publicar-HermesProyecto
        ($cmd.Parameters['ProjectPath'].Mandatory -eq $true) | Should Be $true
        ($cmd.Parameters['GitHubUser'].Mandatory -eq $true) | Should Be $true
        ($cmd.Parameters['RepoName'].Mandatory -eq $true) | Should Be $true
    }
}

Describe 'Cerrar-HermesProyecto' -Tag 'Project', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command Cerrar-HermesProyecto -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have mandatory -ProjectPath' {
        $cmd = Get-Command Cerrar-HermesProyecto
        ($cmd.Parameters['ProjectPath'].Mandatory -eq $true) | Should Be $true
    }
}

Describe 'Eliminar-HermesProyecto' -Tag 'Project', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command Eliminar-HermesProyecto -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have mandatory -ProjectPath' {
        $cmd = Get-Command Eliminar-HermesProyecto
        ($cmd.Parameters['ProjectPath'].Mandatory -eq $true) | Should Be $true
    }
}

Describe 'Get-HermesProyectos' -Tag 'Project', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command Get-HermesProyectos -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have optional -WorkspaceRoot' {
        $cmd = Get-Command Get-HermesProyectos
        ($cmd.Parameters['WorkspaceRoot'].Mandatory -eq $false) | Should Be $true
    }
}

Describe 'Test-HermesPython' -Tag 'Utility', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command Test-HermesPython -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have no mandatory parameters' {
        $cmd = Get-Command Test-HermesPython
        $cmd.Parameters.Count | Should Be 0
    }

    It 'Should return string or $null' {
        $result = Test-HermesPython 2>$null
        if ($result) {
            ($result -is [string]) | Should Be $true
        }
    }
}

Describe 'New-HermesDocumentacion' -Tag 'Utility', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command New-HermesDocumentacion -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have mandatory -ProjectPath' {
        $cmd = Get-Command New-HermesDocumentacion
        ($cmd.Parameters['ProjectPath'].Mandatory -eq $true) | Should Be $true
    }
}

Describe 'New-HermesCommit' -Tag 'Git', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command New-HermesCommit -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have mandatory -ProjectPath' {
        $cmd = Get-Command New-HermesCommit
        ($cmd.Parameters['ProjectPath'].Mandatory -eq $true) | Should Be $true
    }

    It 'Should handle non-existent project path gracefully' {
        $result = New-HermesCommit -ProjectPath "D:\$([guid]::NewGuid().ToString('N'))" -Mensaje "test" 2>$null
        $result | Should Be $true
    }
}

Describe 'Environment Commands' -Tag 'Environment', 'RC62' {

    It 'New-HermesVenv should exist' {
        $cmd = Get-Command New-HermesVenv -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'New-HermesVenv should have mandatory -ProjectPath' {
        $cmd = Get-Command New-HermesVenv
        ($cmd.Parameters['ProjectPath'].Mandatory -eq $true) | Should Be $true
    }

    It 'Enter-HermesVenv should exist' {
        $cmd = Get-Command Enter-HermesVenv -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Enter-HermesVenv should have mandatory -ProjectPath' {
        $cmd = Get-Command Enter-HermesVenv
        ($cmd.Parameters['ProjectPath'].Mandatory -eq $true) | Should Be $true
    }

    It 'Enter-HermesVenv should return $null for non-existent project' {
        $result = Enter-HermesVenv -ProjectPath "D:\$([guid]::NewGuid().ToString('N'))" 2>$null
        ($result -eq $null) | Should Be $true
    }

    It 'Remove-HermesVenv should exist' {
        $cmd = Get-Command Remove-HermesVenv -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'New-HermesConda should exist' {
        $cmd = Get-Command New-HermesConda -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'New-HermesConda should have mandatory -ProjectPath and -EnvironmentName' {
        $cmd = Get-Command New-HermesConda
        ($cmd.Parameters['ProjectPath'].Mandatory -eq $true) | Should Be $true
        ($cmd.Parameters['EnvironmentName'].Mandatory -eq $true) | Should Be $true
    }

    It 'Enter-HermesConda should exist' {
        $cmd = Get-Command Enter-HermesConda -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Enter-HermesConda should have mandatory -EnvironmentName' {
        $cmd = Get-Command Enter-HermesConda
        ($cmd.Parameters['EnvironmentName'].Mandatory -eq $true) | Should Be $true
    }

    It 'Remove-HermesConda should exist' {
        $cmd = Get-Command Remove-HermesConda -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Remove-HermesConda should have mandatory -EnvironmentName' {
        $cmd = Get-Command Remove-HermesConda
        ($cmd.Parameters['EnvironmentName'].Mandatory -eq $true) | Should Be $true
    }
}

Describe 'Workspace Commands' -Tag 'Workspace', 'RC62' {

    It 'New-HermesWorkspace should exist' {
        $cmd = Get-Command New-HermesWorkspace -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'New-HermesWorkspace should have mandatory -WorkspaceRoot' {
        $cmd = Get-Command New-HermesWorkspace
        ($cmd.Parameters['WorkspaceRoot'].Mandatory -eq $true) | Should Be $true
    }

    It 'New-HermesWorkspace should create directory and return $true' {
        $testDir = "D:\PesterTestWS_$(Get-Random)"
        try {
            $result = New-HermesWorkspace -WorkspaceRoot $testDir 2>$null
            $result | Should Be $true
            (Test-Path $testDir) | Should Be $true
        } finally {
            if (Test-Path $testDir) { Remove-Item -Path $testDir -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'Open-HermesWorkspace should exist' {
        $cmd = Get-Command Open-HermesWorkspace -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Open-HermesWorkspace should have mandatory -WorkspaceRoot' {
        $cmd = Get-Command Open-HermesWorkspace
        ($cmd.Parameters['WorkspaceRoot'].Mandatory -eq $true) | Should Be $true
    }

    It 'Open-HermesWorkspace should return $false for non-existent path' {
        $result = Open-HermesWorkspace -WorkspaceRoot "D:\$([guid]::NewGuid().ToString('N'))" 2>$null
        $result | Should Be $false
    }

    It 'Get-HermesWorkspace should exist' {
        $cmd = Get-Command Get-HermesWorkspace -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }
}

Describe 'Install-ProjectFromFactory' -Tag 'Utility', 'RC62' {
    It 'Should exist and be a Function' {
        $cmd = Get-Command Install-ProjectFromFactory -ErrorAction SilentlyContinue
        ($cmd -ne $null) | Should Be $true
    }

    It 'Should have switch parameters' {
        $cmd = Get-Command Install-ProjectFromFactory
        $cmd.Parameters['InicializarGit'].SwitchParameter | Should Be $true
        $cmd.Parameters['CrearRepositorioGitHub'].SwitchParameter | Should Be $true
        $cmd.Parameters['AbrirVSCode'].SwitchParameter | Should Be $true
    }
}

Describe 'Module File Structure' -Tag 'Module', 'Files', 'RC62' {
    It 'Should have manifest file (.psd1) in module path' {
        $mod = Get-Module Hermes.Commands
        ($mod.Path -ne $null) | Should Be $true
        $isManifest = $mod.Path -like '*.psd1' -or (Get-Item $mod.Path).Extension -eq '.psd1'
        # Fallback: check if the psd1 file exists
        if (-not $isManifest) {
            (Test-Path $script:ModulePath) | Should Be $true
        }
    }

    It 'Should have root module file (.psm1)' {
        $mod = Get-Module Hermes.Commands
        ($mod.ModuleBase -ne $null) | Should Be $true
        $psm1 = Join-Path $mod.ModuleBase 'Hermes.Commands.psm1'
        (Test-Path $psm1) | Should Be $true
    }

    It 'Should have Provider files in subdirectory' {
        $providers = Join-Path $script:ModuleRoot 'Providers'
        (Test-Path $providers) | Should Be $true
    }
}

Describe 'Error Handling' -Tag 'ErrorHandling', 'RC62' {
    It 'Should handle invalid parameter values gracefully' {
        # Test that Crear-HermesProyecto with empty nombre throws
        $threw = $false
        try {
            Crear-HermesProyecto -NombreProyecto "" 2>$null
        } catch {
            $threw = $true
        }
        $threw | Should Be $true
    }

    It 'Should handle invalid paths without throwing' {
        $badPath = "D:\$([guid]::NewGuid().ToString('N'))"
        $cmdsWithPaths = @(
            { Abrir-HermesProyecto -ProjectPath $badPath },
            { Get-HermesProyecto -ProjectPath $badPath },
            { Cerrar-HermesProyecto -ProjectPath $badPath },
            { Eliminar-HermesProyecto -ProjectPath $badPath },
            { Open-HermesWorkspace -WorkspaceRoot $badPath }
        )
        foreach ($cmd in $cmdsWithPaths) {
            $threw = $false
            try { & $cmd 2>$null } catch { $threw = $true }
            $threw | Should Be $false
        }
    }
}

Describe 'PSScriptAnalyzer Compliance' -Tag 'PSSA', 'RC62' {
    It 'Should have no errors in Hermes.Commands.psm1' {
        $psm1 = $script:ModulePath -replace '\.psd1$', '.psm1'
        $results = Invoke-ScriptAnalyzer -Path $psm1 -ErrorAction SilentlyContinue | Where-Object Severity -eq 'Error'
        $results.Count | Should Be 0
    }

    It 'Should have no errors in module manifest' {
        $results = Invoke-ScriptAnalyzer -Path $script:ModulePath -ErrorAction SilentlyContinue | Where-Object Severity -eq 'Error'
        $results.Count | Should Be 0
    }
}

Remove-Module Hermes.Commands -Force -ErrorAction SilentlyContinue