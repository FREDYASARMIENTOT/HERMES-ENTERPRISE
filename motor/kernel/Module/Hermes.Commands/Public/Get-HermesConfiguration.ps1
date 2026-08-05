<#
.SYNOPSIS
    Obtiene un valor de configuración del sistema Hermes.
.DESCRIPTION
    Lee un valor de la tabla Configuration en la base de datos.
.PARAMETER Key
    Clave de configuración.
.PARAMETER Default
    Valor por defecto si la clave no existe.
#>
function Get-HermesConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Key = '',

        [Parameter(Mandatory = $false)]
        [string]$Default = ''
    )

    if ($Key) {
        return _Get-ConfigValue -Key $Key -Default $Default
    }
    return _Get-AllConfigValues
}

<#
.SYNOPSIS
    Establece un valor de configuración del sistema Hermes.
.DESCRIPTION
    Guarda un valor en la tabla Configuration de la base de datos.
.PARAMETER Key
    Clave de configuración.
.PARAMETER Value
    Valor a guardar.
#>
function Set-HermesConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Key,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Value
    )

    _Set-ConfigValue -Key $Key -Value $Value
    Write-Host "[OK] Configuration '$Key' = '$Value'" -ForegroundColor Green
}

<#
.SYNOPSIS
    Repara la instalación de Hermes.
.DESCRIPTION
    Verifica y repara la instalación: base de datos, módulos, proveedores.
.PARAMETER Force
    Recrea la base de datos sin preguntar.
#>
function Repair-HermesInstallation {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($PSCmdlet.ShouldProcess('Hermes installation', 'Repair')) {
        Write-Host "[..] Repairing Hermes installation..." -ForegroundColor Yellow

        # 1. Check prerequisites
        $prereqs = Test-HermesPrerequisites
        if (-not $prereqs) {
            Write-Warning "Prerequisites check failed."
        }

        # 2. Initialize database if missing or force
        $dbPath = Join-Path (_Get-HermesRootEnv) 'hermes.db'
        if (-not (Test-Path $dbPath) -or $Force) {
            Initialize-HermesDatabase -Force:$Force
        }

        # 3. Verify Providers/ files exist
        $providerFiles = @(
            'EnvironmentProvider.ps1',
            'ProviderBase.ps1',
            'GitHubProvider.ps1',
            'WorkspaceProvider.ps1'
        )
        $providersDir = Join-Path $PSScriptRoot '..' 'Providers'
        foreach ($file in $providerFiles) {
            $fp = Join-Path $providersDir $file
            if (Test-Path $fp) {
                Write-Host "  [OK] Provider: $file" -ForegroundColor Green
            } else {
                Write-Warning "  [MISS] Provider: $file"
            }
        }

        # 4. Verify Private module files
        $privateFiles = @(
            'HermesHelpers.ps1',
            'DatabaseOperations.ps1',
            'PathResolver.ps1',
            'Validation.ps1'
        )
        $privateDir = Join-Path $PSScriptRoot '..' 'Private'
        foreach ($file in $privateFiles) {
            $fp = Join-Path $privateDir $file
            if (Test-Path $fp) {
                Write-Host "  [OK] Private: $file" -ForegroundColor Green
            } else {
                Write-Warning "  [MISS] Private: $file"
            }
        }

        Write-Host "[OK] Installation repair completed." -ForegroundColor Green
    }
}