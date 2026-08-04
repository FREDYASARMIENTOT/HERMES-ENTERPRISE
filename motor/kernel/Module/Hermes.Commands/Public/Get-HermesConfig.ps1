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
function Get-HermesConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [string]$Default = ''
    )

    return _Get-ConfigValue -Key $Key -Default $Default
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
function Set-HermesConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Key,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Value
    )

    _Set-ConfigValue -Key $Key -Value $Value
    Write-Host "[OK] Config '$Key' = '$Value'" -ForegroundColor Green
}

<#
.SYNOPSIS
    Verifica los prerequisitos del sistema Hermes.
.DESCRIPTION
    Comprueba que Python, Git, SQLite y la base de datos estén disponibles.
#>
function Test-HermesPrerequisites {
    [CmdletBinding()]
    param()

    $checks = [ordered]@{
        PythonAvailable = _Test-PythonAvailable
        GitAvailable    = _Test-GitAvailable
        SqliteAvailable = _Test-Sqlite3Available
        HermesDbExists  = _Test-HermesDb
    }

    $allOk = $true
    foreach ($key in $checks.Keys) {
        $status = if ($checks[$key]) { '[OK]' } else { '[FAIL]' }
        $color = if ($checks[$key]) { 'Green' } else { 'Red' }
        if (-not $checks[$key]) { $allOk = $false }
        Write-Host "  $status $key" -ForegroundColor $color
    }

    if ($checks.PythonAvailable) {
        $v = _Get-PythonVersion
        Write-Host "  [..] Python version: $v" -ForegroundColor Cyan
    }

    return $allOk
}