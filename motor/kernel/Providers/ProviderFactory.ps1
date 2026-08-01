<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderFactory.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Fábrica de proveedores del Kernel Enterprise.
    Centraliza la creación de instancias de proveedores con configuración predefinida.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-ProviderFactory {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Constructors = @{}
        CreatedCount = 0
    }
}

function Register-ProviderFactoryConstructor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Factory,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderName,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_ -is [scriptblock] })]
        [scriptblock]$Constructor
    )

    $Factory.Constructors[$ProviderName] = $Constructor
}

function New-ProviderFromFactory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Factory,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderType,

        [Parameter(Mandatory = $false)]
        [hashtable]$ProviderConfig = @{}
    )

    if (-not $Factory.Constructors.ContainsKey($ProviderName)) {
        throw "Provider constructor not registered: $ProviderName"
    }

    $constructor = $Factory.Constructors[$ProviderName]
    $provider = & $constructor -Id $Id -Name $ProviderName -Version $Version -ProviderType $ProviderType -ProviderConfig $ProviderConfig
    $Factory.CreatedCount++

    return $provider
}

function Test-ProviderFactoryRegistered {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Factory,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderName
    )

    return $Factory.Constructors.ContainsKey($ProviderName)
}

function Get-ProviderFactoryRegisteredProviders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Factory
    )

    return $Factory.Constructors.Keys | Sort-Object
}

Export-ModuleMember -Function New-ProviderFactory, Register-ProviderFactoryConstructor, New-ProviderFromFactory, Test-ProviderFactoryRegistered, Get-ProviderFactoryRegisteredProviders