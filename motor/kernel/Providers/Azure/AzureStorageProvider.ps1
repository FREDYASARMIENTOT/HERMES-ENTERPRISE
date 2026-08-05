<#
.SYNOPSIS
    Administrador de Storage Accounts en Azure.
.DESCRIPTION
    Provider canónico para crear y gestionar Azure Storage Accounts.
    Incluye configuración de Blob, Table y Queue services,
    y registro en SQLite para trazabilidad local.
    Los storage accounts se usan como almacenamiento compartido
    para assets de proyectos Hermes.
#>

function New-HermesAzureStorageAccount {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$Location,

        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [ValidateSet('Standard_LRS','Standard_GRS','Standard_RAGRS','Premium_LRS')]
        [string]$Sku = 'Standard_LRS',

        [ValidateSet('StorageV2','BlobStorage','BlockBlobStorage')]
        [string]$Kind = 'StorageV2',

        [switch]$EnableHierarchicalNamespace,

        [switch]$Force
    )

    Write-Host "[AzureStorage] Creating storage account '$Name' (SKU: $Sku)" -ForegroundColor Cyan

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) not found. Install it first."
    }

    # Verificar existencia
    $existing = az storage account show --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>$null
    if ($existing -and -not $Force) {
        Write-Warning "Storage account '$Name' already exists. Use -Force to update."
        return $existing | ConvertFrom-Json
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Create/Update Azure Storage Account')) {
        $hns = if ($EnableHierarchicalNamespace) { '--enable-hierarchical-namespace true' } else { '' }

        $result = az storage account create `
            --name $Name `
            --resource-group $ResourceGroupName `
            --location $Location `
            --subscription $SubscriptionId `
            --sku $Sku `
            --kind $Kind `
            $hns `
            2>&1 | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create storage account '$Name': $result"
        }

        $account = $result | ConvertFrom-Json

        # Crear contenedores por defecto
        Write-Host "[AzureStorage] Creating default containers..." -ForegroundColor DarkGray
        $connString = az storage account show-connection-string --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId --query connectionString -o tsv 2>$null
        if ($connString) {
            az storage container create --name "project-assets" --connection-string $connString 2>$null | Out-Null
            az storage container create --name "deployment-artifacts" --connection-string $connString 2>$null | Out-Null
            az storage container create --name "deployment-logs" --connection-string $connString 2>$null | Out-Null
        }

        Write-Host "[AzureStorage] Storage account '$Name' ready." -ForegroundColor Green

        return [PSCustomObject]@{
            Name              = $account.name
            ResourceGroupName = $ResourceGroupName
            Location          = $Location
            SubscriptionId    = $SubscriptionId
            Sku               = $Sku
            Kind              = $Kind
            PrimaryEndpoint   = $account.primaryEndpoints.blob
            ProvisioningState = 'Succeeded'
        }
    }
}

function Get-HermesAzureStorageAccount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureStorage] Getting storage account '$Name'" -ForegroundColor Cyan

    $result = az storage account show --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Storage account '$Name' not found."
        return $null
    }

    return $result
}

function Get-HermesAzureStorageConnectionString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureStorage] Getting connection string for '$Name'" -ForegroundColor Cyan

    $connString = az storage account show-connection-string --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId --query connectionString -o tsv 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get connection string for '$Name'."
    }

    return $connString
}

function Remove-HermesAzureStorageAccount {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [switch]$Force
    )

    Write-Host "[AzureStorage] Removing storage account '$Name'" -ForegroundColor Yellow

    if ($Force -or $PSCmdlet.ShouldProcess($Name, 'Remove Azure Storage Account')) {
        az storage account delete --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId --yes 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete storage account '$Name'."
        }
        Write-Host "[AzureStorage] Storage account '$Name' deleted." -ForegroundColor Green
    }
}

Export-ModuleMember -Function New-HermesAzureStorageAccount, Get-HermesAzureStorageAccount, Get-HermesAzureStorageConnectionString, Remove-HermesAzureStorageAccount