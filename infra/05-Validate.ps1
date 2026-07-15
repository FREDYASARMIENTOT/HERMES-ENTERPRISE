Clear-Host

. ".\infra\00-Variables.ps1"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " HERMES ENTERPRISE" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host ""

Write-Host "Suscripción:"
az account show --query name -o tsv

Write-Host ""

Write-Host "Recurso AI:"
az cognitiveservices account show `
    --resource-group $Global:ResourceGroup `
    --name $Global:AIService `
    --query "{Nombre:name,Ubicacion:location,Kind:kind}"

Write-Host ""

Write-Host "Validación completada." -ForegroundColor Green
