<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : SessionWizard.ps1
Propósito:
    First Run Experience. Detecta herramientas, configura workspace, proyecto, Git y VS Code.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioSessionWizard = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioSessionWizard "SessionDescriptor.ps1")
. (Join-Path $RutaDirectorioSessionWizard "SessionPersistence.ps1")
. (Join-Path $RutaDirectorioSessionWizard "SessionTelemetry.ps1")
. (Join-Path $RutaDirectorioSessionWizard "..\providers\WorkspaceProvider.ps1")

function Get-HermesEnterpriseInstalledTools {
    [CmdletBinding()][OutputType([pscustomobject])]
    param()
    function Test-Command { param([string]$Name) return ($null -ne (Get-Command $Name -ErrorAction SilentlyContinue)) }
    return [pscustomobject][ordered]@{
        PowerShell = $true
        Git = Test-Command -Name "git"
        VSCode = Test-Command -Name "code"
        AzureCLI = Test-Command -Name "az"
        GitHubCLI = Test-Command -Name "gh"
        Python = Test-Command -Name "python"
        Docker = Test-Command -Name "docker"
        Node = Test-Command -Name "node"
    }
}

function Start-HermesEnterpriseSessionWizard {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory=$false)][string]$NombreProyecto = "HermesProject",
        [Parameter(Mandatory=$false)][string]$RutaBase = ".",
        [Parameter(Mandatory=$false)][string]$ModeloIA = "ur-hermes-mini",
        [Parameter(Mandatory=$false)][string]$ProveedorIA = "AzureFoundryProvider"
    )
    Write-Host "Bienvenido a HERMES Enterprise. Configurando primera sesión..." -ForegroundColor Cyan

    $Herramientas = Get-HermesEnterpriseInstalledTools
    Write-Host "Herramientas detectadas: $($Herramientas | ConvertTo-Json -Compress)" -ForegroundColor DarkGray

    $Proyecto = New-HermesEnterpriseProject -NombreProyecto $NombreProyecto -RutaBase $RutaBase -LenguajePrincipal "PowerShell" -TipoProyecto "HermesSession"
    $Workspace = New-HermesEnterpriseVSCodeWorkspaceFile -Ruta $Proyecto.RutaLocal -NombreWorkspace $NombreProyecto
    $GitInit = Initialize-HermesEnterpriseProjectRepository -Ruta $Proyecto.RutaLocal
    $Readme = New-HermesEnterpriseProjectReadme -Ruta $Proyecto.RutaLocal -NombreProyecto $NombreProyecto -Descripcion "Sesión creada automáticamente por HERMES Enterprise."
    $Readme.Contenido | Out-File -FilePath $Readme.RutaArchivo -Encoding utf8 -NoNewline

    $IdentificadorSesion = [guid]::NewGuid().ToString("N").Substring(0, 12)
    $Sesion = New-HermesEnterpriseSessionDescriptor `
        -IdentificadorSesion $IdentificadorSesion `
        -NombreProyecto $NombreProyecto `
        -RutaWorkspace $Proyecto.RutaLocal `
        -RepositorioGit (Test-HermesEnterpriseGitRepository -Ruta $Proyecto.RutaLocal) `
        -BranchActual "main" `
        -ProveedorIA $ProveedorIA `
        -ModeloIA $ModeloIA `
        -PluginsInstalados @() `
        -ConfiguracionActiva @{ HerramientasDetectadas = $Herramientas; WorkspaceCreado = $true } `
        -EstadoSesion "Active"

    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $Sesion -Operacion "WizardCompleted" -Mensaje "Primera sesión configurada correctamente." -Metadatos @{ Herramientas = $Herramientas }
    $null = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $Sesion

    Write-Host "Sesión $($Sesion.IdentificadorSesion) creada y guardada." -ForegroundColor Green
    return $Sesion
}
