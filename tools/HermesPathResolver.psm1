<#
.SYNOPSIS
    HermesPathResolver - resolve framework/workspace/sandbox roots from Hermes.config.json
.DESCRIPTION
    Provides HermesPathResolver class and also exported functions for reliable
    path resolution across all PowerShell execution contexts.
.EXAMPLE
    # Using class (in-session):
    $resolver = [HermesPathResolver]::new("Hermes.config.json")
    $ws = $resolver.GetWorkspaceRoot()

    # Using functions:
    $paths = Get-HermesPaths -ConfigPath "Hermes.config.json"
    $ws = $paths.WorkspaceRoot
#>

# ───────────────────────────────────────────────────────────────────
# Helper: internal config loader
# ───────────────────────────────────────────────────────────────────
function _LoadHermesConfig {
    param([string]$ConfigPath)
    if (-not (Test-Path $ConfigPath)) {
        throw "Hermes config not found: $ConfigPath"
    }
    return Get-Content $ConfigPath -Raw | ConvertFrom-Json
}

# ───────────────────────────────────────────────────────────────────
# Exported function: Get-HermesPaths
# Returns a hashtable with all resolved paths
# ───────────────────────────────────────────────────────────────────
function Get-HermesPaths {
    param(
        [Parameter(Mandatory=$true)][string]$ConfigPath
    )
    $config = _LoadHermesConfig -ConfigPath $ConfigPath
    return @{
        ConfigPath = $ConfigPath
        FrameworkRoot = $config.FrameworkRoot
        WorkspaceRoot = $config.WorkspaceRoot
        SandboxRoot = $config.SandboxRoot
        TemplatesRoot = $config.TemplatesRoot
        SkillsRoot = $config.SkillsRoot
        TestsRoot = $config.TestsRoot
        LogsRoot = $config.LogsRoot
        ReportsRoot = $config.ReportsRoot
        DefaultProvisionTarget = $config.DefaultProvisionTarget
    }
}

# ───────────────────────────────────────────────────────────────────
# Exported function: Resolve-HermesWorkspaceRoot
# Returns just the workspace root path
# ───────────────────────────────────────────────────────────────────
function Resolve-HermesWorkspaceRoot {
    param(
        [Parameter(Mandatory=$true)][string]$ConfigPath
    )
    $paths = Get-HermesPaths -ConfigPath $ConfigPath
    return $paths.WorkspaceRoot
}

# ───────────────────────────────────────────────────────────────────
# Exported function: Resolve-HermesProjectRoot
# Returns the full path for a given project name
# ───────────────────────────────────────────────────────────────────
function Resolve-HermesProjectRoot {
    param(
        [Parameter(Mandatory=$true)][string]$ConfigPath,
        [Parameter(Mandatory=$true)][string]$ProjectName
    )
    $paths = Get-HermesPaths -ConfigPath $ConfigPath
    return Join-Path -Path $paths.WorkspaceRoot -ChildPath $ProjectName
}

# ───────────────────────────────────────────────────────────────────
# Backward-compatibility class (works when module is loaded in-session
# via Import-Module in an interactive PowerShell window)
# ───────────────────────────────────────────────────────────────────
class HermesPathResolver {
    [string]$ConfigPath
    [string]$FrameworkRoot
    [string]$WorkspaceRoot
    [string]$SandboxRoot
    [string]$TemplatesRoot
    [string]$SkillsRoot
    [string]$TestsRoot
    [string]$LogsRoot
    [string]$ReportsRoot
    [string]$DefaultProvisionTarget

    HermesPathResolver([string]$configPath) {
        $this.ConfigPath = $configPath
        $this.LoadConfig()
    }

    [void]LoadConfig() {
        $config = _LoadHermesConfig -ConfigPath $this.ConfigPath
        $this.FrameworkRoot = $config.FrameworkRoot
        $this.WorkspaceRoot = $config.WorkspaceRoot
        $this.SandboxRoot = $config.SandboxRoot
        $this.TemplatesRoot = $config.TemplatesRoot
        $this.SkillsRoot = $config.SkillsRoot
        $this.TestsRoot = $config.TestsRoot
        $this.LogsRoot = $config.LogsRoot
        $this.ReportsRoot = $config.ReportsRoot
        $this.DefaultProvisionTarget = $config.DefaultProvisionTarget
    }

    [string]GetFrameworkRoot() { return $this.FrameworkRoot }
    [string]GetWorkspaceRoot() { return $this.WorkspaceRoot }
    [string]GetSandboxRoot() { return $this.SandboxRoot }
    [string]GetTemplatesRoot() { return $this.TemplatesRoot }
    [string]GetSkillsRoot() { return $this.SkillsRoot }
    [string]GetTestsRoot() { return $this.TestsRoot }
    [string]GetLogsRoot() { return $this.LogsRoot }
    [string]GetReportsRoot() { return $this.ReportsRoot }

    [string]GetProjectRoot([string]$projectName) {
        return (Join-Path -Path $this.WorkspaceRoot -ChildPath $projectName)
    }
}

# Export all functions
Export-ModuleMember -Function Get-HermesPaths, Resolve-HermesWorkspaceRoot, Resolve-HermesProjectRoot