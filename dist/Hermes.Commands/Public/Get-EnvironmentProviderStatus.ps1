<#
.SYNOPSIS
    Obtiene el estado del proveedor de entornos virtuales.
.DESCRIPTION
    Retorna el estado actual del provider de entorno en formato PSObject.
.PARAMETER Provider
    Objeto EnvironmentProvider.
#>
function Get-EnvironmentProviderStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    process {
        return [pscustomobject][ordered]@{
            Id              = $Provider.Id
            Name            = $Provider.Name
            Version         = $Provider.Version
            ProviderType    = $Provider.ProviderType
            Status          = $Provider.Status
            IsConnected     = $Provider.IsConnected
            PythonVersion   = $Provider.PythonVersion
            VenvPath        = $Provider.VenvPath
            CondaPath       = $Provider.CondaPath
            LastCreatedEnv  = $Provider.LastCreatedEnv
            ErrorCount      = $Provider.Errors.Count
            LastConnection  = $Provider.LastConnection
        }
    }
}

<#
.SYNOPSIS
    Copia un proyecto Hermes.
.DESCRIPTION
    Copia la carpeta del proyecto a una nueva ubicación.
.PARAMETER SourcePath
    Ruta origen.
.PARAMETER DestinationPath
    Ruta destino.
#>
function Copy-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Source not found: '{0}'")]
        [string]$SourcePath,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$DestinationPath
    )

    $SourcePath = (Resolve-Path $SourcePath).Path
    if ($PSCmdlet.ShouldProcess($DestinationPath, "Copy project from '$SourcePath'")) {
        try {
            _Copy-ProjectFolder -SourcePath $SourcePath -DestinationPath $DestinationPath
            Write-Host "[OK] Project copied to $DestinationPath" -ForegroundColor Green
        } catch {
            Write-Error "Failed to copy: $_"
        }
    }
}

<#
.SYNOPSIS
    Renombra un proyecto Hermes.
.DESCRIPTION
    Cambia el nombre de la carpeta y actualiza el marcador .hermes.
.PARAMETER ProjectPath
    Ruta actual del proyecto.
.PARAMETER NewName
    Nuevo nombre.
#>
function Rename-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$NewName
    )

    $ProjectPath = (Resolve-Path $ProjectPath).Path
    if ($PSCmdlet.ShouldProcess($ProjectPath, "Rename to '$NewName'")) {
        try {
            $newPath = _Rename-Project -ProjectPath $ProjectPath -NewName $NewName
            Write-Host "[OK] Project renamed to $newPath" -ForegroundColor Green
        } catch {
            Write-Error "Failed to rename: $_"
        }
    }
}