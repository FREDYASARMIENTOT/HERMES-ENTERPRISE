function Show-ProvisioningReport {
    param([hashtable]$Data)
    "═══════════════════════════════════════" | Write-Host
    "HERMES ENTERPRISE PROVISIONING REPORT" | Write-Host
    "═══════════════════════════════════════" | Write-Host
    "Proyecto............. $($Data.Name)" | Write-Host
    "Ruta Local........... $($Data.Path)" | Write-Host
}
