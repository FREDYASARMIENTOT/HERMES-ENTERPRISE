<#
.SYNOPSIS
    ContextContract - Define esquemas y validadores para artefactos de contexto
#>

function New-ContextContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("WorkerContext", "ProjectIndex", "ContextManifest")]
        [string]$ContractType
    )
    
    switch ($ContractType) {
        "WorkerContext" {
            return [PSCustomObject]@{
                Type = "WorkerContext"
                Version = "1.0"
                RequiredFields = @(
                    "project",
                    "completedModules",
                    "pendingModules",
                    "paths"
                )
                OptionalFields = @(
                    "dependencies",
                    "tests",
                    "constraints"
                )
            }
        }
        "ProjectIndex" {
            return [PSCustomObject]@{
                Type = "ProjectIndex"
                Version = "1.0"
                RequiredFields = @(
                    "project",
                    "modules",
                    "criticalComponents"
                )
                OptionalFields = @(
                    "tests"
                )
            }
        }
        "ContextManifest" {
            return [PSCustomObject]@{
                Type = "ContextManifest"
                Version = "1.0"
                RequiredFields = @(
                    "priority",
                    "optional",
                    "estimatedTokens"
                )
                OptionalFields = @()
            }
        }
    }
}

function Test-ContextContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$JsonPath,
        
        [Parameter(Mandatory)]
        [ValidateSet("WorkerContext", "ProjectIndex", "ContextManifest")]
        [string]$ContractType
    )
    
    try {
        $content = Get-Content $JsonPath -Raw | ConvertFrom-Json
        $contract = New-ContextContract -ContractType $ContractType
        
        # Verificar campos requeridos
        foreach ($field in $contract.RequiredFields) {
            if (-not ($content.PSObject.Properties.Name -contains $field)) {
                return [PSCustomObject]@{
                    IsValid = $false
                    Error = "Campo requerido faltante: $field"
                }
            }
        }
        
        return [PSCustomObject]@{
            IsValid = $true
            Error = $null
        }
        
    } catch {
        return [PSCustomObject]@{
            IsValid = $false
            Error = "Error al validar: $_"
        }
    }
}

Export-ModuleMember -Function New-ContextContract, Test-ContextContract
