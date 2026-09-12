#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Despliega el Portal Hermes en AS-HermesPortal via ZipDeploy usando OIDC
.DESCRIPTION
    Crea un ZIP del directorio Hermes.Web y lo despliega usando az webapp deploy
#>
param()

$ErrorActionPreference = "Stop"

Write-Host "=============================================="
Write-Host "Deploy-Portal — Portal Hermes → AS-HermesPortal"
Write-Host "=============================================="
Write-Host ""

$ZIP_FILE = "$env:TEMP\portal-deploy.zip"

# 1. Crear ZIP
Write-Host "[1/5] Creando ZIP desde Hermes.Web..."
if (Test-Path $ZIP_FILE) { Remove-Item $ZIP_FILE -Force }
Compress-Archive -Path "Hermes.Web\*" -DestinationPath $ZIP_FILE -Force
$size = (Get-Item $ZIP_FILE).Length
Write-Host "  ZIP creado: $size bytes"

# 2. Iniciar deploy en background job
Write-Host "[2/5] Iniciando deploy en background..."
$scriptBlock = {
    param($zip, $name, $rg)
    az webapp deploy --name $name --resource-group $rg --src-path $zip --type zip 2>&1
}
$job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $ZIP_FILE, "AS-HermesPortal", "RG-Hermes-Proyectos"

# 3. Esperar con timeout de 180 segundos
Write-Host "[3/5] Esperando deploy (timeout: 180s)..."
$result = Wait-Job -Job $job -Timeout 180

if ($result -eq $null) {
    Write-Host "  TIMEOUT: Deploy no completo en 180s"
    Stop-Job $job
    Remove-Job $job -Force
    exit 1
}

$output = Receive-Job $job
Remove-Job $job -Force

# 4. Verificar resultado
Write-Host "[4/5] Verificando resultado..."
$output | ForEach-Object { Write-Host "  $_" }

if ($LASTEXITCODE -eq 0) {
    Write-Host "[5/5] DEPLOY EXITOSO"
    Write-Host ""
    Write-Host "URL: https://as-hermesportal.azurewebsites.net/"
    Write-Host "SCM: https://as-hermesportal.scm.azurewebsites.net/"
    exit 0
} else {
    Write-Host "[5/5] DEPLOY FALLIDO (exit code: $LASTEXITCODE)"
    exit 1
}