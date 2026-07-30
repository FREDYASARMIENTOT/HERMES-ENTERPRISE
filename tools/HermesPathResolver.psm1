<#
HermesPathResolver - resolve framework/workspace/sandbox roots from Hermes.config.json
Parameters: ConfigPath
#>
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
        if (-not (Test-Path $this.ConfigPath)) { throw "Hermes config not found: $($this.ConfigPath)" }
        $json = Get-Content $this.ConfigPath -Raw | ConvertFrom-Json
        $this.FrameworkRoot = $json.FrameworkRoot
        $this.WorkspaceRoot = $json.WorkspaceRoot
        $this.SandboxRoot = $json.SandboxRoot
        $this.TemplatesRoot = $json.TemplatesRoot
        $this.SkillsRoot = $json.SkillsRoot
        $this.TestsRoot = $json.TestsRoot
        $this.LogsRoot = $json.LogsRoot
        $this.ReportsRoot = $json.ReportsRoot
        $this.DefaultProvisionTarget = $json.DefaultProvisionTarget
    }

    [string]Get-FrameworkRoot() { return $this.FrameworkRoot }
    [string]Get-WorkspaceRoot() { return $this.WorkspaceRoot }
    [string]Get-SandboxRoot() { return $this.SandboxRoot }
    [string]Get-TemplatesRoot() { return $this.TemplatesRoot }
    [string]Get-SkillsRoot() { return $this.SkillsRoot }
    [string]Get-TestsRoot() { return $this.TestsRoot }
    [string]Get-LogsRoot() { return $this.LogsRoot }
    [string]Get-ReportsRoot() { return $this.ReportsRoot }

    [string]Get-ProjectRoot([string]$projectName) {
        return (Join-Path -Path $this.WorkspaceRoot -ChildPath $projectName)
    }
}

Export-ModuleMember -Class HermesPathResolver
