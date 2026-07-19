function Generate-Templates {
    param([string]$ProjectPath)
    $templatesRoot = Join-Path $PSScriptRoot '..\templates' | Resolve-Path -ErrorAction SilentlyContinue
    if (-not $templatesRoot) { return }
    Copy-Item -Path (Join-Path $templatesRoot 'README.md') -Destination (Join-Path $ProjectPath 'README.md') -Force -ErrorAction SilentlyContinue
}
