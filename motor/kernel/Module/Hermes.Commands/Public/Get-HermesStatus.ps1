<#
.SYNOPSIS
    Muestra el estado del sistema Hermes.
.DESCRIPTION
    Verifica disponibilidad de Python, Git, SQLite, y la base de datos.
#>
function Get-HermesStatus {
    [CmdletBinding()]
    param()

    $status = [ordered]@{
        PythonAvailable = _Test-PythonAvailable
        GitAvailable    = _Test-GitAvailable
        SqliteAvailable = _Test-Sqlite3Available
        HermesDbExists  = _Test-HermesDb
    }

    if ($status.HermesDbExists) {
        $projects = _Get-AllProjectsFromDb
        $status.ProjectCount = $projects.Count
    } else {
        $status.ProjectCount = 0
    }

    if ($status.PythonAvailable) {
        $status.PythonVersion = _Get-PythonVersion
    }

    return [pscustomobject]$status
}