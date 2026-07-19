# Orchestrator
Get-ChildItem "$PSScriptRoot/functions/*.ps1" | ForEach-Object { . $_.FullName }

param(
    [string]$NombreDeProyecto,
    [ValidateSet('Local','GitHub','GitLab','AzureDevOps')][string]$ProvisionTarget = 'Local',
    [string]$GitHubUser
)

if (-not (Test-ProvisioningPrerequisites -Target $ProvisionTarget)) {
    Write-Error "Fallo en validaciones previas. Abortando."; exit 1
}

try {
    $ProjectPath = Create-LocalProject -Nombre $NombreDeProyecto
    $venvPath = Create-PythonEnvironment -ProjectPath $ProjectPath
    Initialize-Git -ProjectPath $ProjectPath
    Generate-Templates -ProjectPath $ProjectPath

    if ($ProvisionTarget -eq 'GitHub') {
        # Placeholders for GitHub actions
        Write-Host "[GitHub] Crear repo y push (no ejecutado en esta sesión)"
    }

    Show-ProvisioningReport -Data @{ Name = $NombreDeProyecto; Path = $ProjectPath }
} catch {
    Write-Error "Error fatal en el provisionamiento: $($_.Exception.Message)"; exit 1
}
