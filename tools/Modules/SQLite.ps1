function Inicializar-BaseDatosProyecto {
    <#
    .SYNOPSIS
        Inicializa la base de datos SQLite del proyecto.
    .PARAMETER DbPath
        Ruta completa al archivo de base de datos SQLite.
    .PARAMETER CorrelationId
        Identificador único de correlación.
    .PARAMETER SchemaPath
        Ruta al archivo de esquema SQL (opcional).
    #>
    param(
        [Parameter(Mandatory)] [string] $DbPath,
        [Parameter(Mandatory)] [string] $CorrelationId,
        [string] $SchemaPath = ""
    )

    # Crea el directorio de la base de datos si no existe
    $directorioDb = Split-Path $DbPath -Parent
    if (-not (Test-Path $directorioDb)) {
        New-Item -Path $directorioDb -ItemType Directory -Force | Out-Null
    }

    if ($SchemaPath -and (Test-Path $SchemaPath)) {
        Write-Host "[SQLite] Aplicando esquema desde: $SchemaPath"
        $esquema = Get-Content -Path $SchemaPath -Raw -Encoding UTF8
        $esquema | sqlite3 $DbPath 2>&1 | Out-Null
    }

    Write-Host "[SQLite] Base de datos inicializada: $DbPath"
}

function Registrar-EventoProyecto {
    <#
    .SYNOPSIS
        Registra un evento en la tabla BitacoraEventos.
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

    $consulta = @"
INSERT INTO BitacoraEventos (CorrelationId, Usuario, Paso, Estado, Duracion, Mensaje, Resultado)
VALUES ('$CorrelationId', '$Usuario', '$Paso', '$Estado', $Duracion, '$(Escapar-CadenaSQL $Mensaje)', '$(Escapar-CadenaSQL $Resultado)');
"@

    sqlite3 $DbPath $consulta 2>&1 | Out-Null
}

function Registrar-EventoLineaTiempo {
    <#
    .SYNOPSIS
        Registra un evento en la tabla Timeline (línea de tiempo del proyecto).
    #>
    param(
        [Parameter(Mandatory)] [string] $DbPath,
        [Parameter(Mandatory)] [string] $CorrelationId,
        [Parameter(Mandatory)] [string] $Evento,
        [Parameter(Mandatory)] [string] $Estado,
        [string] $Detalle = "",
        [double] $Duracion = 0
    )

    $consulta = @"
INSERT INTO Timeline (CorrelationId, Evento, Estado, Detalle, Duracion)
VALUES ('$CorrelationId', '$(Escapar-CadenaSQL $Evento)', '$Estado', '$(Escapar-CadenaSQL $Detalle)', $Duracion);
"@

    sqlite3 $DbPath $consulta 2>&1 | Out-Null
}

function Establecer-InformacionProyecto {
    <#
    .SYNOPSIS
        Inserta o actualiza la información del proyecto en la base de datos.
    #>
    param(
        [Parameter(Mandatory)] [string] $DbPath,
        [Parameter(Mandatory)] [string] $CorrelationId,
        [Parameter(Mandatory)] [hashtable] $Properties
    )

    $existente = (sqlite3 $DbPath "SELECT COUNT(*) FROM Proyecto WHERE CorrelationId='$CorrelationId'" 2>&1)
    if ([string]::IsNullOrEmpty($existente)) { $existente = "0" }

    if ($existente -eq "0") {
        $nom = Escapar-CadenaSQL $Properties["Nombre"]
        $desc = Escapar-CadenaSQL $Properties["Descripcion"]
        $version = Escapar-CadenaSQL $Properties["Version"]
        $cid = Escapar-CadenaSQL $CorrelationId
        $consulta = @"
INSERT INTO Proyecto (Nombre, Descripcion, Version, CorrelationId, Estado)
VALUES ('$nom', '$desc', '$version', '$cid', 'CREADO');
"@
    }
    else {
        $asignaciones = @()
        foreach ($k in $Properties.Keys) {
            $v = $Properties[$k]
            $ev = Escapar-CadenaSQL $v
            # Validar que el nombre de columna solo contenga caracteres permitidos
            if ($k -notmatch '^[a-zA-Z_][a-zA-Z0-9_]*$') {
                Write-Host "[SQLite] ADVERTENCIA: nombre de columna inválido omitido: $k" -ForegroundColor Yellow
                continue
            }
            $asignaciones += "$k='$ev'"
        }
        $clausulaAsignacion = $asignaciones -join ", "
        $cid = Escapar-CadenaSQL $CorrelationId
        $consulta = "UPDATE Proyecto SET $clausulaAsignacion, FechaActualizacion=datetime('now','localtime') WHERE CorrelationId='$cid';"
    }

    sqlite3 $DbPath $consulta 2>&1 | Out-Null
}

function Obtener-InformacionProyecto {
    <#
    .SYNOPSIS
        Obtiene la información del proyecto desde SQLite.
    .NOTES
        CorrelationId escapado contra SQL injection.
    #>
    param(
        [Parameter(Mandatory)] [string] $DbPath,
        [Parameter(Mandatory)] [string] $CorrelationId
    )

    $cidSeguro = Escapar-CadenaSQL $CorrelationId
    $resultado = sqlite3 $DbPath -header -column "SELECT * FROM Proyecto WHERE CorrelationId='$cidSeguro'" 2>&1
    return $resultado
}

function Registrar-ResultadoPruebaHumo {
    <#
    .SYNOPSIS
        Registra el resultado de una prueba de humo (smoke test).
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

    $consulta = @"
INSERT INTO SmokeTestResults (CorrelationId, Endpoint, HTTPCode, Estado, TiempoRespuesta, Detalle)
VALUES ('$CorrelationId', '$(Escapar-CadenaSQL $Endpoint)', $HTTPCode, '$Estado', $TiempoRespuesta, '$(Escapar-CadenaSQL $Detalle)');
"@

    sqlite3 $DbPath $consulta 2>&1 | Out-Null
}

function Probar-ConexionSQLite {
    <#
    .SYNOPSIS
        Verifica si SQLite es accesible.
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

function Escapar-CadenaSQL {
    <#
    .SYNOPSIS
        Escapa caracteres especiales para SQLite (comillas simples).
    .NOTES
        Seguridad: Previene SQL injection por interpolación en valores string.
        Limitación: Columna/key names no son escapados aquí — deben validarse por separado.
        Recomendación futura: Migrar a System.Data.SQLite con consultas parametrizadas reales.
    #>
    param([string] $Value)
    # En SQLite, el escape de comillas simples se hace duplicándolas: ' → ''
    return $Value -replace "'", "''"
}

Export-ModuleMember -Function Inicializar-BaseDatosProyecto, Registrar-EventoProyecto, Registrar-EventoLineaTiempo, Establecer-InformacionProyecto, Obtener-InformacionProyecto, Registrar-ResultadoPruebaHumo, Probar-ConexionSQLite