function Show-ProvisioningReport {
    param([hashtable]$Data)
    "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" | Write-Output
    "HERMES ENTERPRISE PROVISIONING REPORT" | Write-Output
    "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" | Write-Output
    "Proyecto............. $($Data.Name)" | Write-Output
    "Ruta Local........... $($Data.Path)" | Write-Output
}
