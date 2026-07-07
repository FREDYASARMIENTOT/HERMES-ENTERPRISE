<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ExecutionSupervisor.ps1
Propósito:
    Orquesta los pasos del Sandbox con progreso, logs y dashboard.
    Soporta modo interactivo (-Interactive) para pausar después de cada paso.
    Si un paso falla: registra error, marca FAILED, detiene. No reintenta.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Start-HermesEnterpriseExecutionSupervisor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RutaRaizSandbox,
        [Parameter(Mandatory = $false)][string]$Escenario = "EmptyFolder",
        [Parameter(Mandatory = $false)][string]$NombreProyecto = "HermesProject",
        [Parameter(Mandatory = $false)][switch]$Interactive,
        [Parameter(Mandatory = $false)][switch]$NoPause,
        [Parameter(Mandatory = $false)][switch]$OpenVSCode,
        [Parameter(Mandatory = $false)][switch]$SkipSmokeTest
    )

    $HoraInicio = Get-Date
    $Errores = @()
    $Warnings = @()
    $PasosCompletados = 0
    $TotalPasos = 7

    function Get-Porcentaje { return [math]::Floor(($PasosCompletados / $TotalPasos) * 100) }

    function Mostrar-Dashboard {
        param([string]$Estado, [string]$Paso)
        $Tiempo = [int]((Get-Date) - $HoraInicio).TotalSeconds
        Show-HermesEnterpriseExecutionDashboard -RutaSandbox $RutaRaizSandbox -Escenario $Escenario -Estado $Estado -Porcentaje (Get-Porcentaje) -TiempoTranscurridoSegundos $Tiempo -PasoActual $Paso -Errores $Errores -Warnings $Warnings -Quiet
    }

    function Pausa-Interactiva {
        if ($Interactive -and -not $NoPause) {
            Write-Host ""
            Write-Host "Presione ENTER para continuar, R para repetir este paso, Q para salir..." -ForegroundColor Yellow
            $Respuesta = Read-Host
            return $Respuesta.ToUpper()
        }
        return "CONTINUE"
    }

    # PASO 1: Crear Sandbox
    Mostrar-Dashboard -Estado "RUNNING" -Paso "1/$TotalPasos - Crear Sandbox"
    try {
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaRaizSandbox -Mensaje "Paso 1/$TotalPasos : Crear Sandbox" -Nivel INFO
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaRaizSandbox -Paso "CrearSandbox" -Estado "RUNNING" -Porcentaje (Get-Porcentaje)

        $RutaSandbox = New-HermesEnterpriseSandbox -RutaRaizSandbox $RutaRaizSandbox -Escenario $Escenario -NombreProyecto $NombreProyecto
        $PasosCompletados++

        # Migrar logs temporales del paso 1 al sandbox correcto
        $RutaLogsTemp = Join-Path $RutaRaizSandbox "Logs"
        $RutaLogsFinal = Join-Path $RutaSandbox "Logs"
        if ((Test-Path $RutaLogsTemp) -and ($RutaLogsTemp -ne $RutaLogsFinal)) {
            if (-not (Test-Path $RutaLogsFinal)) { New-Item -ItemType Directory -Path $RutaLogsFinal -Force | Out-Null }
            Get-ChildItem -Path $RutaLogsTemp -File -ErrorAction SilentlyContinue | ForEach-Object {
                Move-Item -Path $_.FullName -Destination (Join-Path $RutaLogsFinal $_.Name) -Force
            }
            if ((@() + (Get-ChildItem -Path $RutaLogsTemp -File -ErrorAction SilentlyContinue)).Count -eq 0) {
                Remove-Item -Path $RutaLogsTemp -Force -ErrorAction SilentlyContinue
            }
        }

        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "CrearSandbox" -Estado "COMPLETED" -Porcentaje (Get-Porcentaje)
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Sandbox creado: $RutaSandbox" -Nivel SUCCESS

        $Respuesta = Pausa-Interactiva
        if ($Respuesta -eq "Q") { throw "Ejecución cancelada por usuario" }
        if ($Respuesta -eq "R") { $PasosCompletados-- }
    }
    catch {
        $Error = $_.Exception.Message
        $Errores += $Error
        $RutaFallos = if ($RutaSandbox) { $RutaSandbox } else { $RutaRaizSandbox }
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaFallos -Paso "CrearSandbox" -Estado "FAILED" -Porcentaje (Get-Porcentaje) -Detalle $Error
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaRaizSandbox -Mensaje "FALLO en CrearSandbox: $Error" -Nivel ERROR
        Mostrar-Dashboard -Estado "FAILED" -Paso "Error en paso 1"
        return
    }

    # PASO 2: Inicializar escenario
    Mostrar-Dashboard -Estado "RUNNING" -Paso "2/$TotalPasos - Inicializar escenario ($Escenario)"
    try {
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Paso 2/$TotalPasos : Inicializar escenario" -Nivel INFO
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "InicializarEscenario" -Estado "RUNNING" -Porcentaje (Get-Porcentaje)

        $Inicializacion = Initialize-HermesEnterpriseSandbox -RutaSandbox $RutaSandbox
        $PasosCompletados++

        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "InicializarEscenario" -Estado "COMPLETED" -Porcentaje (Get-Porcentaje)
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Escenario inicializado. Acciones: $($Inicializacion.Acciones -join ', ')" -Nivel SUCCESS

        $Respuesta = Pausa-Interactiva
        if ($Respuesta -eq "Q") { throw "Ejecución cancelada por usuario" }
    }
    catch {
        $Error = $_.Exception.Message
        $Errores += $Error
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "InicializarEscenario" -Estado "FAILED" -Porcentaje (Get-Porcentaje) -Detalle $Error
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "FALLO en InicializarEscenario: $Error" -Nivel ERROR
        Mostrar-Dashboard -Estado "FAILED" -Paso "Error en paso 2"
        return
    }

    # PASO 3: Ejecutar escenario (DeveloperContext)
    Mostrar-Dashboard -Estado "RUNNING" -Paso "3/$TotalPasos - Ejecutar escenario"
    try {
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Paso 3/$TotalPasos : Ejecutar escenario y recolectar DeveloperContext" -Nivel INFO
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "EjecutarEscenario" -Estado "RUNNING" -Porcentaje (Get-Porcentaje)

        $EscenarioResultado = Invoke-HermesEnterpriseScenario -RutaSandbox $RutaSandbox
        $DeveloperContext = $EscenarioResultado.DeveloperContext
        $PasosCompletados++

        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "EjecutarEscenario" -Estado "COMPLETED" -Porcentaje (Get-Porcentaje)
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Escenario ejecutado. DeveloperContext generado." -Nivel SUCCESS

        $Respuesta = Pausa-Interactiva
        if ($Respuesta -eq "Q") { throw "Ejecución cancelada por usuario" }
    }
    catch {
        $Error = $_.Exception.Message
        $Errores += $Error
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "EjecutarEscenario" -Estado "FAILED" -Porcentaje (Get-Porcentaje) -Detalle $Error
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "FALLO en EjecutarEscenario: $Error" -Nivel ERROR
        Mostrar-Dashboard -Estado "FAILED" -Paso "Error en paso 3"
        return
    }

    # PASO 4: Smoke Test
    if (-not $SkipSmokeTest) {
        Mostrar-Dashboard -Estado "RUNNING" -Paso "4/$TotalPasos - Smoke Test Enterprise"
        try {
            Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Paso 4/$TotalPasos : Ejecutar Smoke Test" -Nivel INFO
            Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "SmokeTest" -Estado "RUNNING" -Porcentaje (Get-Porcentaje)

            $SmokeTestResult = Test-HermesEnterpriseSandbox -RutaSandbox $RutaSandbox
            $PasosCompletados++

            Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "SmokeTest" -Estado "COMPLETED" -Porcentaje (Get-Porcentaje)
            Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Smoke Test completado: $($SmokeTestResult.Estado)" -Nivel SUCCESS

            $Respuesta = Pausa-Interactiva
            if ($Respuesta -eq "Q") { throw "Ejecución cancelada por usuario" }
        }
        catch {
            $Error = $_.Exception.Message
            $Errores += $Error
            Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "SmokeTest" -Estado "FAILED" -Porcentaje (Get-Porcentaje) -Detalle $Error
            Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "FALLO en SmokeTest: $Error" -Nivel ERROR
            Mostrar-Dashboard -Estado "FAILED" -Paso "Error en paso 4"
            return
        }
    }
    else {
        $PasosCompletados++
        $SmokeTestResult = $null
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Paso 4/$TotalPasos : Smoke Test omitido" -Nivel WARNING
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "SmokeTest" -Estado "SKIPPED" -Porcentaje (Get-Porcentaje)
    }

    # PASO 5: Exportar reportes
    Mostrar-Dashboard -Estado "RUNNING" -Paso "5/$TotalPasos - Exportar reportes"
    try {
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Paso 5/$TotalPasos : Exportar reportes" -Nivel INFO
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "ExportarReportes" -Estado "RUNNING" -Porcentaje (Get-Porcentaje)

        $Reportes = Export-HermesEnterpriseSandboxReport -RutaSandbox $RutaSandbox -DeveloperContext $DeveloperContext -SmokeTestResult $SmokeTestResult
        $PasosCompletados++

        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "ExportarReportes" -Estado "COMPLETED" -Porcentaje (Get-Porcentaje)
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Reportes exportados en: $($Reportes.RutaReports)" -Nivel SUCCESS

        $Respuesta = Pausa-Interactiva
        if ($Respuesta -eq "Q") { throw "Ejecución cancelada por usuario" }
    }
    catch {
        $Error = $_.Exception.Message
        $Errores += $Error
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "ExportarReportes" -Estado "FAILED" -Porcentaje (Get-Porcentaje) -Detalle $Error
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "FALLO en ExportarReportes: $Error" -Nivel ERROR
        Mostrar-Dashboard -Estado "FAILED" -Paso "Error en paso 5"
        return
    }

    # PASO 6: Generar UserGuide.md
    Mostrar-Dashboard -Estado "RUNNING" -Paso "6/$TotalPasos - Generar UserGuide.md"
    try {
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Paso 6/$TotalPasos : Generar UserGuide.md" -Nivel INFO
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "GenerarUserGuide" -Estado "RUNNING" -Porcentaje (Get-Porcentaje)

        $UserGuide = New-HermesEnterpriseSandboxUserGuide -RutaSandbox $RutaSandbox
        $PasosCompletados++

        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "GenerarUserGuide" -Estado "COMPLETED" -Porcentaje (Get-Porcentaje)
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "UserGuide.md generado: $UserGuide" -Nivel SUCCESS

        $Respuesta = Pausa-Interactiva
        if ($Respuesta -eq "Q") { throw "Ejecución cancelada por usuario" }
    }
    catch {
        $Error = $_.Exception.Message
        $Errores += $Error
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "GenerarUserGuide" -Estado "FAILED" -Porcentaje (Get-Porcentaje) -Detalle $Error
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "FALLO en GenerarUserGuide: $Error" -Nivel ERROR
        Mostrar-Dashboard -Estado "FAILED" -Paso "Error en paso 6"
        return
    }

    # PASO 7: Generar SandboxInstructions.ps1
    Mostrar-Dashboard -Estado "RUNNING" -Paso "7/$TotalPasos - Generar SandboxInstructions.ps1"
    try {
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Paso 7/$TotalPasos : Generar SandboxInstructions.ps1" -Nivel INFO
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "GenerarInstructions" -Estado "RUNNING" -Porcentaje (Get-Porcentaje)

        $Instructions = New-HermesEnterpriseSandboxInstructions -RutaSandbox $RutaSandbox
        $PasosCompletados++

        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "GenerarInstructions" -Estado "COMPLETED" -Porcentaje 100
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "SandboxInstructions.ps1 generado: $Instructions" -Nivel SUCCESS

        # Abrir VS Code si se solicitó
        if ($OpenVSCode) {
            Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Abriendo VS Code..." -Nivel INFO
            $Workspace = Get-ChildItem -Path (Join-Path $RutaSandbox "Workspace") -Filter "*.code-workspace" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($Workspace) {
                Start-Process "code" -ArgumentList $Workspace.FullName
                Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "VS Code abierto. Presione ENTER para continuar..." -Nivel INFO
                Read-Host
            }
        }

        # Marcar como completado
        $Metadata = Get-Content -Path (Join-Path $RutaSandbox "sandbox.json") -Raw | ConvertFrom-Json
        $Metadata.Estado = "Completed"
        $Metadata.Resultado = "SUCCESS"
        $Metadata | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $RutaSandbox "sandbox.json") -Encoding UTF8

        Mostrar-Dashboard -Estado "COMPLETED" -Paso "Ejecución finalizada"
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "Ejecución completada exitosamente" -Nivel SUCCESS
    }
    catch {
        $Error = $_.Exception.Message
        $Errores += $Error
        Write-HermesEnterpriseExecutionState -RutaSandbox $RutaSandbox -Paso "GenerarInstructions" -Estado "FAILED" -Porcentaje (Get-Porcentaje) -Detalle $Error
        Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaSandbox -Mensaje "FALLO en GenerarInstructions: $Error" -Nivel ERROR
        Mostrar-Dashboard -Estado "FAILED" -Paso "Error en paso 7"
        return
    }

    # Resumen final
    $HoraFin = Get-Date
    $Duracion = $HoraFin - $HoraInicio

    Write-Host ""
    Write-Host "====================================================================================================" -ForegroundColor Green
    Write-Host "  EJECUCIÓN COMPLETADA EXITOSAMENTE" -ForegroundColor Green
    Write-Host "====================================================================================================" -ForegroundColor Green
    Write-Host "Ruta:           " -NoNewline -ForegroundColor White
    Write-Host "$RutaSandbox" -ForegroundColor Green
    Write-Host "Escenario:      " -NoNewline -ForegroundColor White
    Write-Host "$Escenario" -ForegroundColor Green
    Write-Host "Duración:       " -NoNewline -ForegroundColor White
    Write-Host "$($Duracion.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
    Write-Host "UserGuide:      " -NoNewline -ForegroundColor White
    Write-Host "$UserGuide" -ForegroundColor White
    Write-Host "Instructions:   " -NoNewline -ForegroundColor White
    Write-Host "$Instructions" -ForegroundColor White
    Write-Host "Reports:        " -NoNewline -ForegroundColor White
    Write-Host "$($Reportes.RutaReports)" -ForegroundColor White
    Write-Host "====================================================================================================" -ForegroundColor Green
    Write-Host ""
}
