<#
.SYNOPSIS
    Ejecuta las pruebas del sistema Hermes Enterprise.
.DESCRIPTION
    Corre Pester tests de integración y unitarias.
.PARAMETER Path
    Ruta de la prueba (archivo o carpeta).
.PARAMETER PassThru
    Retorna resultados en lugar de mostrarlos.
#>
function Invoke-HermesEnterpriseTests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = 'pruebas',

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    Write-Host "[..] Running Hermes Enterprise tests..." -ForegroundColor Yellow

    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Error "Pester module not installed. Run: Install-Module Pester -Force -SkipPublisherCheck"
        return
    }

    $config = New-PesterConfiguration
    $config.Run.Path = $Path
    $config.Run.PassThru = $PassThru
    $config.Output.Verbosity = 'Detailed'

    $result = Invoke-Pester -Configuration $config

    if ($PassThru) {
        return $result
    }
}

<#
.SYNOPSIS
    Muestra ayuda detallada de un comando Hermes.
.DESCRIPTION
    Muestra la ayuda del comando si existe el archivo about_*.help.txt.
.PARAMETER CommandName
    Nombre del comando.
#>
function Get-HermesHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$CommandName
    )

    $helpDir = Join-Path $PSScriptRoot '..' 'es-ES'
    $helpFile = Join-Path $helpDir "about_$CommandName.help.txt"
    if (Test-Path $helpFile) {
        Get-Content $helpFile -Raw
    } else {
        Get-Help $CommandName -Full
    }
}

<#
.SYNOPSIS
    Inicializa la base de datos Hermes.
.DESCRIPTION
    Crea las tablas necesarias en la base de datos SQLite.
.PARAMETER Force
    Recrea las tablas si ya existen.
#>
function Initialize-HermesDatabase {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($PSCmdlet.ShouldProcess('Hermes database', 'Initialize tables')) {
        _Initialize-Database -Force:$Force
        Write-Host "[OK] Hermes database initialized." -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Exporta proyectos Hermes a un archivo JSON.
.DESCRIPTION
    Exporta los proyectos registrados a JSON.
.PARAMETER OutputPath
    Ruta del archivo JSON de salida.
#>
function Export-HermesProjects {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $projects = _Get-AllProjectsFromDb
    $projects | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "[OK] Exported $($projects.Count) projects to $OutputPath" -ForegroundColor Green
}

<#
.SYNOPSIS
    Importa proyectos Hermes desde un archivo JSON.
.DESCRIPTION
    Importa proyectos registrados desde un archivo JSON de exportación.
.PARAMETER InputPath
    Ruta del archivo JSON de entrada.
#>
function Import-HermesProjects {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "File not found: '{0}'")]
        [string]$InputPath
    )

    $data = Get-Content $InputPath -Raw | ConvertFrom-Json
    $count = 0
    foreach ($project in $data) {
        _Register-ProjectInDb -ProjectPath $project.ProjectPath -ProjectName $project.ProjectName
        $count++
    }
    Write-Host "[OK] Imported $count projects." -ForegroundColor Green
}