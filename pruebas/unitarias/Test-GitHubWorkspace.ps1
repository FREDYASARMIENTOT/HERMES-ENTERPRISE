<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-GitHubWorkspace.ps1
Propósito:
    Valida GitHubProvider, GitHubManagers, WorkspaceProvider, ProjectManager, GitManager,
    VSCodeManager, ProjectDescriptor y wrappers Git/VS Code.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada,[string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }

. (Join-Path $RutaRaizRepositorio "motor\providers\GitHubProvider.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\WorkspaceProvider.ps1")

# GitHubProvider contrato
$GitHubProvider = New-HermesEnterpriseGitHubProvider
Assert-HermesEnterpriseCondition ($GitHubProvider.Adapter.EstadoActual -eq "Created") "GitHubProvider no inicia en Created."
$GitHubProvider.ConfiguracionProvider = @{ UsuarioGitHub = "usuario-test" }
Assert-HermesEnterpriseCondition (ValidateConfiguration-GitHubProvider -ContextoProvider $GitHubProvider).EsValida "GitHubProvider rechazó configuración válida."
Connect-GitHubProvider -ContextoProvider $GitHubProvider | Out-Null
Assert-HermesEnterpriseCondition ($GitHubProvider.Adapter.EstadoActual -eq "Ready") "GitHubProvider no llegó a Ready."
Assert-HermesEnterpriseCondition ((Get-GitHubProviderHealth -ContextoProvider $GitHubProvider).Estado -eq "Healthy") "GitHubProvider no reportó Healthy."
$Summary = Get-GitHubProviderSummary -ContextoProvider $GitHubProvider
Assert-HermesEnterpriseCondition $Summary.DiagnosticsListoLocalmente "Summary no confirma readiness local."
Assert-HermesEnterpriseCondition (-not $Summary.LimitesIncluidos.HTTP) "GitHubProvider no debe declarar HTTP."
Disconnect-GitHubProvider -ContextoProvider $GitHubProvider | Out-Null
Assert-HermesEnterpriseCondition ($GitHubProvider.Adapter.EstadoActual -eq "Disposed") "GitHubProvider no finalizó en Disposed."

# GitHubManagers
Assert-HermesEnterpriseCondition ((New-HermesEnterpriseGitHubRepository -Nombre "test-repo").Estado -eq "MOCK-Repository-Create") "Repository Manager Create falló."
Assert-HermesEnterpriseCondition ((New-HermesEnterpriseGitHubBranch -Nombre "feature").Estado -eq "MOCK-Branch-Create") "Branch Manager Create falló."
Assert-HermesEnterpriseCondition ((New-HermesEnterpriseGitHubCommit -Mensaje "feat: test").Estado -eq "MOCK-Commit-Create") "Commit Manager Create falló."
Assert-HermesEnterpriseCondition ((New-HermesEnterpriseGitHubPullRequest -Titulo "PR" -RamaOrigen "feature" -RamaDestino "main").Estado -eq "MOCK-Pull-Create") "Pull Manager Create falló."
Assert-HermesEnterpriseCondition ((Publish-HermesEnterpriseGitHubBranch -Rama "feature").Estado -eq "MOCK-Push-Branch") "Push Manager falló."
Assert-HermesEnterpriseCondition ((Copy-HermesEnterpriseGitHubRepository -Url "https://github.local/repo" -RutaLocal "C:\\repo").Estado -eq "MOCK-Clone-Repository") "Clone Manager falló."
Assert-HermesEnterpriseCondition ((New-HermesEnterpriseGitHubWorkspace -Nombre "ws").Estado -eq "MOCK-Workspace-Create") "Workspace Manager falló."

# ProjectDescriptor
$Descriptor = New-HermesEnterpriseProjectDescriptor -NombreProyecto "ProyectoPrueba" -RutaLocal "C:\Proyectos\ProyectoPrueba" -LenguajePrincipal "PowerShell" -TipoProyecto "CLI"
Assert-HermesEnterpriseCondition ($Descriptor.NombreProyecto -eq "ProyectoPrueba") "ProjectDescriptor no conserva nombre."

# Workspace / Project / Git / VS Code
$RutaTemporal = Join-Path $env:TEMP "HermesWorkspaceTest_$(Get-Random)"
$RutaProyecto = New-HermesEnterpriseWorkspaceFolder -RutaBase $RutaTemporal -NombreCarpeta "ProyectoTest"
Assert-HermesEnterpriseCondition (Test-HermesEnterpriseWorkspaceFolderExists -Ruta $RutaProyecto) "WorkspaceProvider no creó carpeta."
$Proyecto = New-HermesEnterpriseProject -NombreProyecto "ProyectoTest" -RutaBase $RutaTemporal -LenguajePrincipal "PowerShell" -TipoProyecto "CLI"
Assert-HermesEnterpriseCondition ($Proyecto.NombreProyecto -eq "ProyectoTest") "New-HermesEnterpriseProject no devolvió descriptor."
$Abierto = Open-HermesEnterpriseProject -Ruta $RutaProyecto
Assert-HermesEnterpriseCondition ($Abierto.RepositorioGit -eq $false) "Open-HermesEnterpriseProject no detectó ausencia de Git."
$Repo = Initialize-HermesEnterpriseProjectRepository -Ruta $RutaProyecto
Assert-HermesEnterpriseCondition ($Repo.GitInit.Operacion -eq "init") "Initialize-HermesEnterpriseProjectRepository no preparó git init."
$GitStatus = Get-HermesEnterpriseGitStatus -Ruta $RutaProyecto
Assert-HermesEnterpriseCondition ($GitStatus.Operacion -eq "status") "Get-HermesEnterpriseGitStatus no preparó status."
$VSCodeOpen = Invoke-HermesEnterpriseVSCodeCommand -Operacion OpenFolder -Ruta $RutaProyecto
Assert-HermesEnterpriseCondition ($VSCodeOpen.Operacion -eq "OpenFolder") "Invoke-HermesEnterpriseVSCodeCommand no preparó OpenFolder."
$WorkspaceFile = New-HermesEnterpriseVSCodeWorkspaceFile -Ruta $RutaProyecto -NombreWorkspace "test"
Assert-HermesEnterpriseCondition ($WorkspaceFile.RutaArchivo -like "*.code-workspace") "New-HermesEnterpriseVSCodeWorkspaceFile no generó ruta."
$Readme = New-HermesEnterpriseProjectReadme -Ruta $RutaProyecto -NombreProyecto "ProyectoTest"
Assert-HermesEnterpriseCondition ($Readme.RutaArchivo -like "*README.md") "New-HermesEnterpriseProjectReadme no generó ruta."
$Estado = Get-HermesEnterpriseProjectState -Ruta $RutaProyecto
Assert-HermesEnterpriseCondition ($Estado.Descriptor -ne $null) "Get-HermesEnterpriseProjectState no devolvió descriptor."
Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Test-GitHubWorkspace completado correctamente." -ForegroundColor Green
