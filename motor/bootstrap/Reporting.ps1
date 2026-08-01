# Reporting module (esqueleto)
function Show-ProvisioningReport { param($Data) Write-Output "Provisioning Report:"; $Data | Format-List }
function Write-Report-MD { param($Path,$Content) Set-Content -Path $Path -Value $Content -Force }
function Write-Report-JSON { param($Path,$Object) $Object | ConvertTo-Json | Set-Content -Path $Path -Force }
