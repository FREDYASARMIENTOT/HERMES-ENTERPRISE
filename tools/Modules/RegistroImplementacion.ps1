# RegistroImplementacion.ps1 — Registro de implementación PowerShell
# Proporciona funciones para crear y actualizar el registro de
# implementación (tablas Implementacion + PasoImplementacion) desde
# la Factory (PowerShell).

Set-StrictMode -Version Latest

function Iniciar-RegistroImplementacion {
    param(
        [Parameter(Mandatory)] [string] $DbPath,
        [Parameter(Mandatory)] [string] $CorrelationId,
        [Parameter(Mandatory)] [string] $NombreProyecto,
        [string] $Repositorio = "",
        [string] $CommitSolicitado = "",
        [string] $DeploymentId = ""
    )

    $DeploymentId = if ($DeploymentId) { $DeploymentId } else { [System.Guid]::NewGuid().ToString("N").Substring(0,12).ToUpper() }
    $Ahora = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    $registro = @{
        DbPath = $DbPath
        Implementacion = @{
            correlation_id = $CorrelationId
            nombre_proyecto = $NombreProyecto
            repositorio = $Repositorio
            commit_solicitado = $CommitSolicitado
            commit_desplegado = ""
            deployment_id = $DeploymentId
            estado_general = "EN_PROCESO"
            fecha_inicio = $Ahora
            fecha_fin = ""
            duracion_total_segundos = 0
            pasos_completados = 0
            pasos_fallidos = 0
            pasos_totales = 13
        }
        Pasos = @()
    }

    $pasosCanonicos = @(
        @{Numero=1;Nombre="SOLICITUD";Subpasos=@(@{Codigo="01.01";Nombre="nombre del proyecto"},@{Codigo="01.02";Nombre="repositorio"},@{Codigo="01.03";Nombre="parámetros"})}
        @{Numero=2;Nombre="FACTORY";Subpasos=@(@{Codigo="02.01";Nombre="crear workspace"},@{Codigo="02.02";Nombre="crear estructura"},@{Codigo="02.03";Nombre="renderizar templates"},@{Codigo="02.04";Nombre="validar placeholders"},@{Codigo="02.05";Nombre="inicializar SQLite"},@{Codigo="02.06";Nombre="registrar metadatos"},@{Codigo="02.07";Nombre="inicializar Git"})}
        @{Numero=3;Nombre="GITHUB";Subpasos=@(@{Codigo="03.01";Nombre="crear repositorio"},@{Codigo="03.02";Nombre="configurar repositorio"},@{Codigo="03.03";Nombre="publicar código"},@{Codigo="03.04";Nombre="verificar branch"},@{Codigo="03.05";Nombre="verificar SHA"})}
        @{Numero=4;Nombre="CI CHILD";Subpasos=@(@{Codigo="04.01";Nombre="checkout"},@{Codigo="04.02";Nombre="dependencias"},@{Codigo="04.03";Nombre="validación"},@{Codigo="04.04";Nombre="resultado"})}
        @{Numero=5;Nombre="CONTROL PLANE";Subpasos=@(@{Codigo="05.01";Nombre="recibir parámetros"},@{Codigo="05.02";Nombre="validar identidad"},@{Codigo="05.03";Nombre="checkout Child"},@{Codigo="05.04";Nombre="validar infraestructura"})}
        @{Numero=6;Nombre="AUTENTICACIÓN";Subpasos=@(@{Codigo="06.01";Nombre="GitHub OIDC"},@{Codigo="06.02";Nombre="Azure login"},@{Codigo="06.03";Nombre="comprobar resultado"})}
        @{Numero=7;Nombre="AZURE";Subpasos=@(@{Codigo="07.01";Nombre="localizar ASP-IAUR"},@{Codigo="07.02";Nombre="comprobar reutilización"},@{Codigo="07.03";Nombre="crear/reutilizar Web App"},@{Codigo="07.04";Nombre="configurar runtime"},@{Codigo="07.05";Nombre="configurar startup"})}
        @{Numero=8;Nombre="DEPLOY";Subpasos=@(@{Codigo="08.01";Nombre="construir ZIP"},@{Codigo="08.02";Nombre="validar contenido ZIP"},@{Codigo="08.03";Nombre="ZIP Deploy"},@{Codigo="08.04";Nombre="reinicio"},@{Codigo="08.05";Nombre="verificar SHA desplegado"})}
        @{Numero=9;Nombre="READINESS";Subpasos=@(@{Codigo="09.01";Nombre="comprobar disponibilidad"},@{Codigo="09.02";Nombre="comprobar HTTP"},@{Codigo="09.03";Nombre="comprobar health"},@{Codigo="09.04";Nombre="comprobar identidad"})}
        @{Numero=10;Nombre="PRUEBAS FUNCIONALES";Subpasos=@(@{Codigo="10.01";Nombre="/"};@{Codigo="10.02";Nombre="/health"};@{Codigo="10.03";Nombre="/api/version"};@{Codigo="10.04";Nombre="/api/proyecto"};@{Codigo="10.05";Nombre="/openapi.json"};@{Codigo="10.06";Nombre="/swagger"};@{Codigo="10.07";Nombre="/redoc"};@{Codigo="10.08";Nombre="endpoint inexistente → 404"})}
        @{Numero=11;Nombre="EVIDENCIA";Subpasos=@(@{Codigo="11.01";Nombre="requested SHA"},@{Codigo="11.02";Nombre="deployed SHA"},@{Codigo="11.03";Nombre="OIDC"},@{Codigo="11.04";Nombre="deployment"},@{Codigo="11.05";Nombre="readiness"},@{Codigo="11.06";Nombre="functional tests"},@{Codigo="11.07";Nombre="identidad"},@{Codigo="11.08";Nombre="infraestructura"})}
        @{Numero=12;Nombre="PUBLICACIÓN";Subpasos=@(@{Codigo="12.01";Nombre="landing page"},@{Codigo="12.02";Nombre="log de implementación"},@{Codigo="12.03";Nombre="accesos"},@{Codigo="12.04";Nombre="estado final"})}
        @{Numero=13;Nombre="NAVEGADOR";Subpasos=@(@{Codigo="13.01";Nombre="abrir /"},@{Codigo="13.02";Nombre="abrir /health"},@{Codigo="13.03";Nombre="abrir /api/version"},@{Codigo="13.04";Nombre="abrir /api/proyecto"},@{Codigo="13.05";Nombre="abrir /openapi.json"},@{Codigo="13.06";Nombre="abrir /swagger"},@{Codigo="13.07";Nombre="abrir /redoc"})}
    )

    foreach ($pc in $pasosCanonicos) {
        $paso = @{
            numero_paso = $pc.Numero; nombre_paso = $pc.Nombre
            estado = "PENDIENTE"; fecha_inicio = ""; fecha_fin = ""
            duracion_segundos = 0; detalle = ""; evidencia = ""; resultado = ""
function Iniciar-PasoImplementacion {
    param(
        [Parameter(Mandatory)] [hashtable] $Registro,
        [Parameter(Mandatory)] [int] $NumeroPaso,
        [string] $Detalle = ""
    )
    $paso = $Registro.Pasos | Where-Object { $_.numero_paso -eq $NumeroPaso }
    if (-not $paso) { Write-Warning "Paso $NumeroPaso no encontrado"; return }
    $Ahora = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $paso.estado = "EN_PROCESO"; $paso.fecha_inicio = $Ahora; $paso.detalle = $Detalle
    Write-Host "[RegistroImplementacion] Paso $NumeroPaso ($($paso.nombre_paso)): EN_PROCESO"
}

function Finalizar-PasoImplementacion {
    param(
        [Parameter(Mandatory)] [hashtable] $Registro,
        [Parameter(Mandatory)] [int] $NumeroPaso,
        [string] $Estado = "COMPLETADO", [string] $Detalle = "",
        [string] $Evidencia = "", [string] $Resultado = ""
    )
    $paso = $Registro.Pasos | Where-Object { $_.numero_paso -eq $NumeroPaso }
    if (-not $paso) { Write-Warning "Paso $NumeroPaso no encontrado"; return }
    $Ahora = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $paso.estado = $Estado; $paso.fecha_fin = $Ahora
    if ($Detalle) { $paso.detalle = $Detalle }
    if ($Evidencia) { $paso.evidencia = $Evidencia }
    $paso.resultado = if ($Resultado) { $Resultado } elseif ($Estado -eq "COMPLETADO") { "PASS" } else { "FAIL" }
    if ($paso.fecha_inicio) {
        try {
            $i = [datetime]::ParseExact($paso.fecha_inicio.TrimEnd('Z'),"yyyy-MM-ddTHH:mm:ss",$null)
            $f = [datetime]::ParseExact($Ahora.TrimEnd('Z'),"yyyy-MM-ddTHH:mm:ss",$null)
            $paso.duracion_segundos = ($f - $i).TotalSeconds
        } catch { $paso.duracion_segundos = 0 }
    }
    if ($Estado -eq "COMPLETADO") { $Registro.Implementacion.pasos_completados++ }
    elseif ($Estado -eq "FALLIDO") { $Registro.Implementacion.pasos_fallidos++ }
    Write-Host "[RegistroImplementacion] Paso $NumeroPaso ($($paso.nombre_paso)): $Estado ($($paso.duracion_segundos.ToString('0.0'))s)"
}

function Iniciar-SubpasoImplementacion {
    param(
        [Parameter(Mandatory)] [hashtable] $Registro,
        [Parameter(Mandatory)] [int] $NumeroPaso,
        [Parameter(Mandatory)] [string] $NumeroSubpaso,
        [string] $Detalle = ""
    )
    $paso = $Registro.Pasos | Where-Object { $_.numero_paso -eq $NumeroPaso }
    if (-not $paso) { return }
    $sp = $paso.subpasos | Where-Object { $_.numero_subpaso -eq $NumeroSubpaso }
    if (-not $sp) { return }
    $Ahora = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $sp.estado = "EN_PROCESO"; $sp.fecha_inicio = $Ahora; $sp.detalle = $Detalle
}

function Finalizar-SubpasoImplementacion {
    param(
        [Parameter(Mandatory)] [hashtable] $Registro,
        [Parameter(Mandatory)] [int] $NumeroPaso,
        [Parameter(Mandatory)] [string] $NumeroSubpaso,
        [string] $Estado = "COMPLETADO", [string] $Detalle = "",
        [string] $Evidencia = "", [string] $Resultado = ""
    )
    $paso = $Registro.Pasos | Where-Object { $_.numero_paso -eq $NumeroPaso }
    if (-not $paso) { return }
    $sp = $paso.subpasos | Where-Object { $_.numero_subpaso -eq $NumeroSubpaso }
    if (-not $sp) { return }
    $Ahora = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $sp.estado = $Estado; $sp.fecha_fin = $Ahora
    if ($Detalle) { $sp.detalle = $Detalle }
    if ($Evidencia) { $sp.evidencia = $Evidencia }
    $sp.resultado = if ($Resultado) { $Resultado } elseif ($Estado -eq "COMPLETADO") { "PASS" } else { "FAIL" }
    if ($sp.fecha_inicio) {
        try {
            $i = [datetime]::ParseExact($sp.fecha_inicio.TrimEnd('Z'),"yyyy-MM-ddTHH:mm:ss",$null)
            $f = [datetime]::ParseExact($Ahora.TrimEnd('Z'),"yyyy-MM-ddTHH:mm:ss",$null)
            $sp.duracion_segundos = ($f - $i).TotalSeconds
        } catch { $sp.duracion_segundos = 0 }
    }
}
            subpasos = @()
        }
        foreach ($sp in $pc.Subpasos) {
            $paso.subpasos += @{
function Finalizar-RegistroImplementacion {
    param(
        [Parameter(Mandatory)] [hashtable] $Registro,
        [string] $Estado = "COMPLETADO", [string] $Detalle = ""
    )
    $Ahora = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $Registro.Implementacion.fecha_fin = $Ahora
    $Registro.Implementacion.estado_general = $Estado
    if ($Registro.Implementacion.fecha_inicio) {
        try {
            $i = [datetime]::ParseExact($Registro.Implementacion.fecha_inicio.TrimEnd('Z'),"yyyy-MM-ddTHH:mm:ss",$null)
            $f = [datetime]::ParseExact($Ahora.TrimEnd('Z'),"yyyy-MM-ddTHH:mm:ss",$null)
            $Registro.Implementacion.duracion_total_segundos = ($f - $i).TotalSeconds
        } catch { }
    }
    if ($Detalle) { $Registro.Implementacion.detalle_final = $Detalle }
}

function Persistir-RegistroImplementacion {
    param([Parameter(Mandatory)] [hashtable] $Registro)
    $db = $Registro.DbPath; $imp = $Registro.Implementacion; $corrId = $imp.correlation_id
    if (-not (Test-Path $db)) { Write-Warning "[RegistroImplementacion] DB no encontrada: $db"; return $false }
    function esc($v) { return ($v -replace "'", "''") }
    $sql1 = @"
INSERT INTO Implementacion (CorrelationId, NombreProyecto, Repositorio,
    CommitSolicitado, CommitDesplegado, DeploymentId, EstadoGeneral,
    PasosCompletados, PasosFallidos, PasosTotales, DuracionTotalSegundos,
    FechaInicio, FechaFin)
VALUES ('$(esc $corrId)', '$(esc $imp.nombre_proyecto)', '$(esc $imp.repositorio)',
    '$(esc $imp.commit_solicitado)', '$(esc $imp.commit_desplegado)', '$(esc $imp.deployment_id)',
    '$(esc $imp.estado_general)', $($imp.pasos_completados), $($imp.pasos_fallidos),
    $($imp.pasos_totales), $($imp.duracion_total_segundos),
    '$(esc $imp.fecha_inicio)', '$(esc $imp.fecha_fin)')
ON CONFLICT(CorrelationId) DO UPDATE SET
    EstadoGeneral=excluded.EstadoGeneral, PasosCompletados=excluded.PasosCompletados,
    PasosFallidos=excluded.PasosFallidos, DuracionTotalSegundos=excluded.DuracionTotalSegundos,
    FechaFin=excluded.FechaFin,
    CommitDesplegado=CASE WHEN excluded.CommitDesplegado!='' THEN excluded.CommitDesplegado ELSE CommitDesplegado END;
"@
    sqlite3 $db $sql1 2>&1 | Out-Null
    sqlite3 $db "DELETE FROM PasoImplementacion WHERE CorrelationId='$(esc $corrId)';" 2>&1 | Out-Null
    foreach ($paso in $Registro.Pasos) {
        $subpJson = $paso.subpasos | ConvertTo-Json -Compress -Depth 3
        $subpJson = $subpJson -replace "'", "''"
        $sql2 = @"
INSERT INTO PasoImplementacion (CorrelationId, NumeroPaso, NombrePaso,
    NumeroSubpaso, NombreSubpaso, Estado, FechaInicio, FechaFin,
    DuracionSegundos, Detalle, Evidencia, Resultado)
VALUES ('$(esc $corrId)', $($paso.numero_paso), '$(esc $paso.nombre_paso)',
    '', '', '$(esc $paso.estado)', '$(esc $paso.fecha_inicio)', '$(esc $paso.fecha_fin)',
    $($paso.duracion_segundos), '$(esc $subpJson)', '$(esc $paso.evidencia)', '$(esc $paso.resultado)');
"@
        sqlite3 $db $sql2 2>&1 | Out-Null
    }
    Write-Host "[RegistroImplementacion] Persistido en SQLite: $db"
    return $true
}

Export-ModuleMember -Function Iniciar-RegistroImplementacion, Iniciar-PasoImplementacion, Finalizar-PasoImplementacion, Iniciar-SubpasoImplementacion, Finalizar-SubpasoImplementacion, Finalizar-RegistroImplementacion, Persistir-RegistroImplementacion
                numero_subpaso = $sp.Codigo; nombre_subpaso = $sp.Nombre
                estado = "PENDIENTE"; fecha_inicio = ""; fecha_fin = ""
                duracion_segundos = 0; detalle = ""; evidencia = ""; resultado = ""
            }
        }
        $registro.Pasos += $paso
    }
    Write-Host "[RegistroImplementacion] Iniciado: $NombreProyecto (CID: $CorrelationId, DEP: $DeploymentId)"
    return $registro
}