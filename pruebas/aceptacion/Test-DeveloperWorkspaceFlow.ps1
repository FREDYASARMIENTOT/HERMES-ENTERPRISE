<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-DeveloperWorkspaceFlow.ps1
Propósito:
    Escenario de aceptación end-to-end del Developer Workspace:
    Crear proyecto -> Crear workspace -> Inicializar Git -> Crear README -> Ejecutar pruebas
    -> Abrir VS Code -> Preparar commit -> Generar documentación -> Mostrar resumen.
====================================================================================================
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasAceptacion = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasAceptacion)

function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada,[string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }

. (Join-Path $RutaRaizRepositorio "motor\providers\WorkspaceProvider.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\GitHubProvider.ps1")

$RutaBaseTemporal = Join-Path $env:TEMP "HermesDeveloperWorkspaceTest_$(Get-Random)"
$NombreProyecto = "MiProyectoHermes"

Write-Host "[1/9] Crear proyecto..." -ForegroundColor Cyan
$Proyecto = New-HermesEnterpriseProject -NombreProyecto $NombreProyecto -RutaBase $RutaBaseTemporal -LenguajePrincipal "PowerShell" -TipoProyecto "DeveloperWorkspace"
Assert-HermesEnterpriseCondition (Test-HermesEnterpriseWorkspaceFolderExists -Ruta $Proyecto.RutaLocal) "No se creó la carpeta del proyecto."

Write-Host "[2/9] Crear workspace VS Code..." -ForegroundColor Cyan
$Workspace = New-HermesEnterpriseVSCodeWorkspaceFile -Ruta $Proyecto.RutaLocal -NombreWorkspace $NombreProyecto
Assert-HermesEnterpriseCondition ($Workspace.RutaArchivo -like "*.code-workspace") "No se generó el archivo de workspace."

Write-Host "[3/9] Inicializar Git..." -ForegroundColor Cyan
$Repo = Initialize-HermesEnterpriseProjectRepository -Ruta $Proyecto.RutaLocal
Assert-HermesEnterpriseCondition ($Repo.GitInit.Operacion -eq "init") "No se preparó git init."

Write-Host "[4/9] Crear README..." -ForegroundColor Cyan
$Readme = New-HermesEnterpriseProjectReadme -Ruta $Proyecto.RutaLocal -NombreProyecto $NombreProyecto -Descripcion "Proyecto de prueba generado por HERMES."
$Readme.Contenido | Out-File -FilePath $Readme.RutaArchivo -Encoding utf8 -NoNewline
Assert-HermesEnterpriseCondition (Test-Path $Readme.RutaArchivo) "No se creó el README."

Write-Host "[5/9] Ejecutar pruebas HERMES..." -ForegroundColor Cyan
$RutaSmokeTest = Join-Path $RutaRaizRepositorio "scripts\Test-HermesEnterprise.ps1"
& $RutaSmokeTest

Write-Host "[6/9] Abrir VS Code (comando preparado)..." -ForegroundColor Cyan
$ComandoVSCode = Invoke-HermesEnterpriseVSCodeCommand -Operacion OpenFolder -Ruta $Proyecto.RutaLocal
Assert-HermesEnterpriseCondition ($ComandoVSCode.Operacion -eq "OpenFolder") "No se preparó el comando de VS Code."

Write-Host "[7/9] Preparar commit..." -ForegroundColor Cyan
$Commit = Submit-HermesEnterpriseGitCommit -Ruta $Proyecto.RutaLocal -Mensaje "feat: proyecto inicial"
Assert-HermesEnterpriseCondition ($Commit.Operacion -eq "commit") "No se preparó el commit."

Write-Host "[8/9] Generar documentación..." -ForegroundColor Cyan
$RutaGeneradorDoc = Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseDocumentation.ps1"
& $RutaGeneradorDoc -SoloValidar

Write-Host "[9/9] Mostrar resumen..." -ForegroundColor Cyan
$Resumen = Get-HermesEnterpriseWorkspaceSummary -Ruta $Proyecto.RutaLocal
Assert-HermesEnterpriseCondition ($Resumen.Proyecto.NombreProyecto -eq $NombreProyecto) "El resumen no contiene el proyecto."

Remove-Item -Path $RutaBaseTemporal -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Escenario Developer Workspace completado correctamente." -ForegroundColor Green
