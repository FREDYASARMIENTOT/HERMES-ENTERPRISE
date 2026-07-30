$RepoRoot = (Get-Item -Path ".\" ).FullName
Describe 'Start-HermesProject basic' {
  It 'Imports Start-HermesProject module without errors' {
    $repoRoot = $RepoRoot
    . (Join-Path $repoRoot 'motor\bootstrap\Start-HermesProject.ps1')
    $true | Should -BeTrue
  }
  It 'Accepts parameters and writes BOOTSTRAP_CONTEXT.json' {
    $repoRoot = $RepoRoot
    $tmpName = "TestProj$(Get-Random)"
    $boot = Join-Path -Path $repoRoot -ChildPath ".hermes/BOOTSTRAP_CONTEXT.json"
    if (Test-Path $boot) { Copy-Item $boot "$boot.bak" -Force }
    & (Join-Path $repoRoot 'Start-HermesProject.ps1') -NombreProyecto $tmpName -ProvisionTarget Local -Modo Desarrollo
    Test-Path $boot | Should -BeTrue
    if (Test-Path "$boot.bak") { Move-Item -Path "$boot.bak" -Destination $boot -Force }
  }
}
