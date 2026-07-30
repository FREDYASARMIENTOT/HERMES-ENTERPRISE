function Validate-Project {
    param(
        [Parameter(Mandatory=$true)][string]$ProjectPath
    )
    $checks = @{}
    $checks.Exists = Test-Path $ProjectPath
    $checks.Readme = Test-Path (Join-Path $ProjectPath 'README.md')
    $checks.PyProject = Test-Path (Join-Path $ProjectPath 'pyproject.toml')
    $checks.Src = Test-Path (Join-Path $ProjectPath 'src')
    $checks.Tests = Test-Path (Join-Path $ProjectPath 'tests')
    $checks.Docs = Test-Path (Join-Path $ProjectPath 'docs')
    $checks.Venv = Test-Path (Join-Path $ProjectPath '.venv')
    $checks.Git = Test-Path (Join-Path $ProjectPath '.git')
    return $checks
}
Export-ModuleMember -Function Validate-Project
