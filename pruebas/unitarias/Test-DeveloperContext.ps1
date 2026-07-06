<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-DeveloperContext.ps1
Propósito:
    Valida el objeto raíz DeveloperContext y su orquestación mediante ContextBuilder.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition {
    param([bool]$CondicionEvaluada, [string]$MensajeError)
    if (-not $CondicionEvaluada) { throw $MensajeError }
}

. (Join-Path $RutaRaizRepositorio "motor\context\DeveloperContext.ps1")
. (Join-Path $RutaRaizRepositorio "motor\context\ContextBuilder.ps1")

$ContextoVacio = New-HermesEnterpriseDeveloperContext
Assert-HermesEnterpriseCondition ($null -ne $ContextoVacio) "DeveloperContext no fue creado."
Assert-HermesEnterpriseCondition ($ContextoVacio.PSObject.Properties.Name -contains "Workspace") "DeveloperContext no tiene Workspace."
Assert-HermesEnterpriseCondition ($ContextoVacio.PSObject.Properties.Name -contains "Proyecto") "DeveloperContext no tiene Proyecto."
Assert-HermesEnterpriseCondition ($ContextoVacio.PSObject.Properties.Name -contains "Git") "DeveloperContext no tiene Git."
Assert-HermesEnterpriseCondition ($ContextoVacio.PSObject.Properties.Name -contains "GitHub") "DeveloperContext no tiene GitHub."
Assert-HermesEnterpriseCondition ($ContextoVacio.PSObject.Properties.Name -contains "Provider") "DeveloperContext no tiene Provider."
Assert-HermesEnterpriseCondition ($ContextoVacio.PSObject.Properties.Name -contains "Modelo") "DeveloperContext no tiene Modelo."
Assert-HermesEnterpriseCondition ($ContextoVacio.PSObject.Properties.Name -contains "Plugins") "DeveloperContext no tiene Plugins."
Assert-HermesEnterpriseCondition ($ContextoVacio.PSObject.Properties.Name -contains "Session") "DeveloperContext no tiene Session."
Assert-HermesEnterpriseCondition ($ContextoVacio.PSObject.Properties.Name -contains "Preferencias") "DeveloperContext no tiene Preferencias."
Assert-HermesEnterpriseCondition ($ContextoVacio.PSObject.Properties.Name -contains "VariablesEntorno") "DeveloperContext no tiene VariablesEntorno."
Assert-HermesEnterpriseCondition ($ContextoVacio.PSObject.Properties.Name -contains "EstadoKernel") "DeveloperContext no tiene EstadoKernel."

$RutaTemporal = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP "HermesDeveloperContextTest_$(Get-Random)"))
New-Item -ItemType Directory -Path $RutaTemporal -Force | Out-Null

try {
    $Contexto = Build-HermesEnterpriseDeveloperContext -RutaWorkspace $RutaTemporal -NombreProyecto "TestProject"
    Assert-HermesEnterpriseCondition ($Contexto.Workspace.Existe -eq $true) "ContextBuilder no incluyó workspace."
    Assert-HermesEnterpriseCondition ($Contexto.Proyecto.NombreProyecto -eq "TestProject") "ContextBuilder no incluyó proyecto."
    Assert-HermesEnterpriseCondition ($Contexto.Git.TieneGit -eq $false) "ContextBuilder no reportó Git inexistente."
    Assert-HermesEnterpriseCondition ($Contexto.GitHub.Modo -eq "MOCK") "ContextBuilder no incluyó GitHub MOCK."
    Assert-HermesEnterpriseCondition ($Contexto.Provider -eq "AzureFoundryProvider") "ContextBuilder no usó provider por defecto."
    Assert-HermesEnterpriseCondition ($Contexto.Modelo -eq "ur-hermes-mini") "ContextBuilder no usó modelo por defecto."
}
finally {
    Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Test-DeveloperContext completado correctamente." -ForegroundColor Green
