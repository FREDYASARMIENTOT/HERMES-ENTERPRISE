<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EngineResolver.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Resolvedor de Motores — registry lookup + lazy init + lifecycle validation.
    Satisface: capability.engine.resolve
====================================================================================================
#>

Set-StrictMode -Version Latest

$script:EngineRegistry = @{}

function Register-Engine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Engine
    )

    if (-not (Test-EngineContractValid $Engine)) {
        throw "Engine '$($Engine.Name)' does not satisfy IEngine contract"
    }

    if ([string]::IsNullOrEmpty($Engine.Id)) {
        $id = $Engine.Name
    } else {
        $id = $Engine.Id
    }
    $script:EngineRegistry[$id] = $Engine
}

function Resolve-Engine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineIdOrName
    )

    # 1. Direct lookup by key (Id)
    if ($script:EngineRegistry.ContainsKey($EngineIdOrName)) {
        return $script:EngineRegistry[$EngineIdOrName]
    }

    # 2. Scan by Name, Id, or EngineType (use cases reference EngineType)
    foreach ($key in $script:EngineRegistry.Keys) {
        $e = $script:EngineRegistry[$key]
        if ($e.Name -eq $EngineIdOrName -or
            $e.Id -eq $EngineIdOrName -or
            $e.EngineType -eq $EngineIdOrName) {
            return $e
        }
    }

    return $null
}

function Get-AllEngines {
    [CmdletBinding()]
    param()

    return $script:EngineRegistry.Values
}

function Clear-EngineRegistry {
    [CmdletBinding()]
    param()

    $script:EngineRegistry.Clear()
}

function Test-EngineContractValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Engine
    )

    return $Engine.PSObject.Properties.Name -contains 'Id' -and
           $Engine.PSObject.Properties.Name -contains 'Name' -and
           $Engine.PSObject.Properties.Name -contains 'Capabilities' -and
           $Engine.PSObject.Properties.Name -contains 'Status' -and
           $Engine.PSObject.Properties.Name -contains 'EngineType'
}

