# BootstrapContext factory - returns an immutable PSCustomObject
param(
    [Parameter(Mandatory=$true)][psobject]$Config
)
function New-BootstrapContext {
    param([psobject]$Config)
    $ctx = [PSCustomObject]@{
        ProjectName = $Config.project.name
        GitHubCreate = $Config.github.create
        GitHubVisibility = $Config.github.visibility
        PythonCreateVenv = $Config.python.create_venv
        PythonInstallReqs = $Config.python.install_requirements
        VSCodeOpen = $Config.vscode.open
        RunTests = $Config.tests.run
        Timestamp = (Get-Date).ToString('o')
    }
    # make properties read-only by creating a new [pscustomobject] via reflection (shallow immutability)
    $ro = [System.Management.Automation.LanguagePrimitives]::ConvertTo([psobject]$ctx, [psobject])
    return $ctx
}
