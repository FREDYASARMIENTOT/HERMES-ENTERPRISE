function Initialize-ProyectoDatabase {
    <#
    .SYNOPSIS
        Initializes the SQLite database for a project.
    .PARAMETER DbPath
        Full path to the SQLite database file.
    .PARAMETER CorrelationId
        Unique correlation identifier.
    .PARAMETER SchemaPath
        Path to the SQL schema template file (optional).
    #>
    param(
        [Parameter(Mandatory)] [string] $DbPath,
        [Parameter(Mandatory)] [string] $CorrelationId,
        [string] $SchemaPath = ""
    )

    $dbDir = Split-Path $DbPath -Parent
    if (-not (Test-Path $dbDir)) {
        New-Item -Path $dbDir -ItemType Directory -Force | Out-Null
    }

    if ($SchemaPath -and (Test-Path $SchemaPath)) {
        Write-Host "[SQLite] Applying schema from: $SchemaPath"
        $schema = Get-Content -Path $SchemaPath -Raw -Encoding UTF8
        $schema | sqlite3 $DbPath 2>&1 | Out-Null
    }

    Write-Host "[SQLite] Database initialized: $DbPath"
}

function Register-ProyectoEvent {
    <#
    .SYNOPSIS
        Registers an event in the BitacoraEventos table.
    #>
    param(
        [Parameter(Mandatory)] [string] $DbPath,
        [Parameter(Mandatory)] [string] $CorrelationId,
        [Parameter(Mandatory)] [string] $Paso,
        [Parameter(Mandatory)] [string] $Estado,
        [string] $Usuario = "system",
        [double] $Duracion = 0,
        [string] $Mensaje = "",
        [string] $Resultado = ""
    )

    $sql = @"
INSERT INTO BitacoraEventos (CorrelationId, Usuario, Paso, Estado, Duracion, Mensaje, Resultado)
VALUES ('$CorrelationId', '$Usuario', '$Paso', '$Estado', $Duracion, '$(Escape-SqlString $Mensaje)', '$(Escape-SqlString $Resultado)');
"@

    sqlite3 $DbPath $sql 2>&1 | Out-Null
}

function Register-TimelineEvent {
    <#
    .SYNOPSIS
        Registers an event in the Timeline table.
    #>
    param(
        [Parameter(Mandatory)] [string] $DbPath,
        [Parameter(Mandatory)] [string] $CorrelationId,
        [Parameter(Mandatory)] [string] $Evento,
        [Parameter(Mandatory)] [string] $Estado,
        [string] $Detalle = "",
        [double] $Duracion = 0
    )

    $sql = @"
INSERT INTO Timeline (CorrelationId, Evento, Estado, Detalle, Duracion)
VALUES ('$CorrelationId', '$(Escape-SqlString $Evento)', '$Estado', '$(Escape-SqlString $Detalle)', $Duracion);
"@

    sqlite3 $DbPath $sql 2>&1 | Out-Null
}

function Set-ProyectoInfo {
    <#
    .SYNOPSIS
        Updates or inserts project information.
    #>
    param(
        [Parameter(Mandatory)] [string] $DbPath,
        [Parameter(Mandatory)] [string] $CorrelationId,
        [Parameter(Mandatory)] [hashtable] $Properties
    )

    $existing = (sqlite3 $DbPath "SELECT COUNT(*) FROM Proyecto WHERE CorrelationId='$CorrelationId'" 2>&1)
    if ([string]::IsNullOrEmpty($existing)) { $existing = "0" }

    if ($existing -eq "0") {
        $nom = Escape-SqlString $Properties["Nombre"]
        $desc = Escape-SqlString $Properties["Descripcion"]
        $version = $Properties["Version"]
        $sql = @"
INSERT INTO Proyecto (Nombre, Descripcion, Version, CorrelationId, Estado)
VALUES ('$nom', '$desc', '$version', '$CorrelationId', 'CREADO');
"@
    }
    else {
        $sets = @()
        foreach ($k in $Properties.Keys) {
            $v = $Properties[$k]
            $ev = Escape-SqlString $v
            $sets += "$k='$ev'"
        }
        $setClause = $sets -join ", "
        $sql = "UPDATE Proyecto SET $setClause, FechaActualizacion=datetime('now','localtime') WHERE CorrelationId='$CorrelationId';"
    }

    sqlite3 $DbPath $sql 2>&1 | Out-Null
}

function Get-ProyectoInfo {
    <#
    .SYNOPSIS
        Retrieves project information from SQLite.
    #>
    param(
        [Parameter(Mandatory)] [string] $DbPath,
        [Parameter(Mandatory)] [string] $CorrelationId
    )

    $result = sqlite3 $DbPath -header -column "SELECT * FROM Proyecto WHERE CorrelationId='$CorrelationId'" 2>&1
    return $result
}

function Register-SmokeTestResult {
    <#
    .SYNOPSIS
        Registers a smoke test result.
    #>
    param(
        [Parameter(Mandatory)] [string] $DbPath,
        [Parameter(Mandatory)] [string] $CorrelationId,
        [Parameter(Mandatory)] [string] $Endpoint,
        [int] $HTTPCode = 0,
        [string] $Estado = "PENDIENTE",
        [double] $TiempoRespuesta = 0,
        [string] $Detalle = ""
    )

    $sql = @"
INSERT INTO SmokeTestResults (CorrelationId, Endpoint, HTTPCode, Estado, TiempoRespuesta, Detalle)
VALUES ('$CorrelationId', '$(Escape-SqlString $Endpoint)', $HTTPCode, '$Estado', $TiempoRespuesta, '$(Escape-SqlString $Detalle)');
"@

    sqlite3 $DbPath $sql 2>&1 | Out-Null
}

function Test-SQLiteConnection {
    <#
    .SYNOPSIS
        Tests if SQLite is accessible.
    #>
    param(
        [Parameter(Mandatory)] [string] $DbPath
    )

    try {
        $null = sqlite3 $DbPath "SELECT 1" 2>&1
        return $true
    }
    catch {
        return $false
    }
}

function Escape-SqlString {
    param([string] $Value)
    return $Value -replace "'", "''"
}

Export-ModuleMember -Function Initialize-ProyectoDatabase, Register-ProyectoEvent, Register-TimelineEvent, Set-ProyectoInfo, Get-ProyectoInfo, Register-SmokeTestResult, Test-SQLiteConnection