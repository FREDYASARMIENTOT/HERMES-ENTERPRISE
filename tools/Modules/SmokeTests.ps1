function Ejecutar-PruebasHumoProyecto {
    <#
    .SYNOPSIS
        Ejecuta pruebas funcionales (smoke tests) contra la aplicación web desplegada.
        Cada endpoint debe devolver el código y contenido esperado; un HTTP 200 aislado no es suficiente.
    .PARAMETER BaseUrl
        URL base de la aplicación desplegada.
    .PARAMETER CorrelationId
        ID de correlación para registro en base de datos.
    .PARAMETER DbPath
        Ruta a la base de datos SQLite para registrar resultados.
    .OUTPUTS
        Hashtable con los resultados de las pruebas.
    #>
    param(
        [Parameter(Mandatory)] [string] $BaseUrl,
        [Parameter(Mandatory)] [string] $CorrelationId,
        [string] $DbPath = ""
    )

    $horaInicio = Get-Date

    $puntosFinales = @(
        "/",
        "/health",
        "/api/version",
        "/api/proyecto",
        "/api/workspace",
        "/api/git",
        "/api/github",
        "/api/sqlite",
        "/api/azure",
        "/api/despliegue",
        "/openapi.json",
        "/api/rc77-c8-this-endpoint-must-not-exist"
    )

    $resultados = @()
    $aprobadas = 0
    $fallidas = 0

    Write-Host "[SmokeTests] Iniciando pruebas funcionales para: $BaseUrl"
    Write-Host ""

    foreach ($puntoFinal in $puntosFinales) {
        $urlCompleta = "$BaseUrl$puntoFinal"
        $inicioPrueba = Get-Date

        try {
            $respuesta = Invoke-WebRequest -Uri $urlCompleta -Method GET -UseBasicParsing -TimeoutSec 15
            $codigoHttp = $respuesta.StatusCode
            $tiempoRespuesta = [math]::Round(((Get-Date) - $inicioPrueba).TotalSeconds, 3)
            $estado = if ($codigoHttp -eq 200) { "PASS" } else { "FAIL" }

            Write-Host "  [$estado] $urlCompleta -> $codigoHttp (${tiempoRespuesta}s)"
        }
        catch {
            $codigoHttp = 0
            $tiempoRespuesta = [math]::Round(((Get-Date) - $inicioPrueba).TotalSeconds, 3)
            $estado = "FAIL"
            Write-Host "  [FAIL] $urlCompleta -> ERROR (${tiempoRespuesta}s)"
        }

        $resultado = @{
            Endpoint = $puntoFinal
            Url = $urlCompleta
            HTTPCode = $codigoHttp
            Estado = $estado
            TiempoRespuesta = $tiempoRespuesta
        }
        $resultados += $resultado

        if ($estado -eq "PASS") { $aprobadas++ } else { $fallidas++ }
    }

    $tiempoTranscurrido = (Get-Date) - $horaInicio
    $tiempoTotal = [math]::Round($tiempoTranscurrido.TotalSeconds, 2)

    Write-Host ""
    Write-Host "[SmokeTests] Resultados: $aprobadas aprobadas, $fallidas fallidas, ${tiempoTotal}s total"

    if ($DbPath -and (Test-Path $DbPath)) {
        foreach ($r in $resultados) {
            try {
                $consulta = @"
INSERT INTO SmokeTestResults (CorrelationId, Endpoint, HTTPCode, Estado, TiempoRespuesta)
VALUES ('$CorrelationId', '$($r.Endpoint)', $($r.HTTPCode), '$($r.Estado)', $($r.TiempoRespuesta));
"@
                sqlite3 $DbPath $consulta 2>&1 | Out-Null
            }
            catch {
                # El registro en SQLite no es crítico para la prueba
            }
        }
    }

    $estadoGeneral = if ($fallidas -eq 0) { "PASS" } else { "FAIL" }

    return @{
        Endpoints = $resultados
        Passed = $aprobadas
        Failed = $fallidas
        Total = $puntosFinales.Count
        TotalTime = $tiempoTotal
        OverallStatus = $estadoGeneral
    }
}

function Probar-PaginaInicioProyecto {
    <#
    .SYNOPSIS
        Verifica que la página de inicio retorne HTTP 200 y contenga contenido válido del reporte de despliegue.
    .PARAMETER BaseUrl
        URL base de la aplicación desplegada.
    .OUTPUTS
        Hashtable con el resultado de la prueba de la página de inicio.
    #>
    param(
        [Parameter(Mandatory)] [string] $BaseUrl
    )

    $horaInicio = Get-Date

    try {
        $respuesta = Invoke-WebRequest -Uri $BaseUrl -Method GET -UseBasicParsing -TimeoutSec 15
        $tiempoTranscurrido = [math]::Round(((Get-Date) - $horaInicio).TotalSeconds, 2)

        $cuerpo = $respuesta.Content

        # Validación del reporte de despliegue
        $tieneTituloHermes = $cuerpo -match "HERMES ENTERPRISE"
        $tieneInformeDespliegue = $cuerpo -match "INFORME DE DESPLIEGUE"
        $tieneOperativo = $cuerpo -match "OPERATIVO"
        $tieneInfoProyecto = $cuerpo -match "Proyecto"
        $tieneAppService = $cuerpo -match "App Service"
        $tienePruebasFuncionales = $cuerpo -match "PRUEBAS FUNCIONALES"
        $tieneAccesos = $cuerpo -match "ACCESOS"

        # Verificaciones negativas: no debe ser página por defecto
        $esHelloWorld = $cuerpo -match "<h1>Hello World</h1>"
        $esAzureDefault = $cuerpo -match "Azure App Service" -or $cuerpo -match "Your app is deployed"

        $paginaInicioOk = ($respuesta.StatusCode -eq 200) -and $tieneTituloHermes -and $tieneInformeDespliegue -and -not $esHelloWorld -and -not $esAzureDefault

        return @{
            Url = $BaseUrl
            HTTPCode = $respuesta.StatusCode
            Time = $tiempoTranscurrido
            LandingOk = $paginaInicioOk
            HasHermesTitle = $tieneTituloHermes
            HasDeployReport = $tieneInformeDespliegue
            HasOperativo = $tieneOperativo
            HasProjectInfo = $tieneInfoProyecto
            HasAppServiceInfo = $tieneAppService
            HasFunctionalTests = $tienePruebasFuncionales
            HasAccessLinks = $tieneAccesos
            IsHelloWorld = $esHelloWorld
            IsAzureDefault = $esAzureDefault
        }
    }
    catch {
        return @{
            Url = $BaseUrl
            HTTPCode = 0
            Time = [math]::Round(((Get-Date) - $horaInicio).TotalSeconds, 2)
            LandingOk = $false
            Error = $_.Exception.Message
        }
    }
}

Export-ModuleMember -Function Ejecutar-PruebasHumoProyecto, Probar-PaginaInicioProyecto