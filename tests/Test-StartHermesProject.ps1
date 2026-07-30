Describe 'Start-HermesProject basic' {
  It 'Imports Start-HermesProject module without errors' {
    $repoRoot = Split-Path -Parent (Resolve-Path -Path '..\Start-HermesProject.ps1' -ErrorAction SilentlyContinue)
    if (-not $repoRoot) { $repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
    . (Join-Path $repoRoot 'motor\bootstrap\Start-HermesProject.ps1')
    # If the script defines functions, ensure it's loadable
    $true | Should -BeTrue
  }
  It 'Accepts parameters and writes BOOTSTRAP_CONTEXT.json' {
    $repoRoot = Split-Path -Parent (Resolve-Path -Path '..\Start-HermesProject.ps1' -ErrorAction SilentlyContinue)
    if (-not $repoRoot) { $repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
    $tmpName = "TestProj$(Get-Random)"
    $boot = Join-Path -Path $repoRoot -ChildPath ".hermes/BOOTSTRAP_CONTEXT.json"
    # Backup
    if (Test-Path $boot) { Copy-Item $boot "$boot.bak" -Force }
    & (Join-Path $repoRoot 'Start-HermesProject.ps1') -NombreProyecto $tmpName -ProvisionTarget Local -Modo Desarrollo
    Test-Path $boot | Should -BeTrue
    # Restore
    if (Test-Path "$boot.bak") { Move-Item -Path "$boot.bak" -Destination $boot -Force }
  }
}
