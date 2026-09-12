<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-Context.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida el módulo Context.ps1 del motor Hermes Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$global:HERMES_REPO_ROOT = "D:\HERMES-ENTERPRISE"

# ---------------------------------------------------------------------------
# Helper: Retorna la memoria serializada (simulación)
# ---------------------------------------------------------------------------
function Get-TestEnvironmentSerializedMemory {
    return @"
{
    "repos": [
        {
            "name": "HERMES-ENTERPRISE",
            "url": "https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE.git",
            "branch": "master",
            "root": "D:\\HERMES-ENTERPRISE"
        }
    ],
    "root": "D:\\HERMES-ENTERPRISE",
    "session": "PRUEBA-RC45-001"
}
"@
}

# ---------------------------------------------------------------------------
# Helper: Entorno simulado
# ---------------------------------------------------------------------------
function Get-TestEnvironment {
    return @{
        HERMES_REPO_ROOT = $global:HERMES_REPO_ROOT
        HERMES_ENVIRONMENT = "DEV"
        HERMES_SESSION_ID = "PRUEBA-RC45-001"
        HERMES_KERNEL_MODE = "test"
        USERPROFILE = [Environment]::GetFolderPath("UserProfile")
        TEMP = [System.IO.Path]::GetTempPath()
    }
}

# ---------------------------------------------------------------------------
# Context.ps1
# ---------------------------------------------------------------------------
Describe "Context" {

    It "New-HermesEnterpriseContext debe crear contexto con valores correctos" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        $env = Get-TestEnvironment
        $contexto = New-HermesEnterpriseContext -Environment $env
        $contexto.NombreProyecto | Should Be "HERMES-ENTERPRISE"
        $contexto.RootRepositorio | Should Be $global:HERMES_REPO_ROOT
        $contexto.IdentificadorSesion | Should Not BeNullOrEmpty
    }

    It "New-HermesEnterpriseContext dataset debe contener al menos un repositorio" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        $env = Get-TestEnvironment
        $contexto = New-HermesEnterpriseContext -Environment $env
        $contexto.Dataset.Repos | Should Not BeNullOrEmpty
        ($contexto.Dataset.Repos.Count) | Should BeGreaterThan 0
    }

    It "New-HermesEnterpriseContext debe incluir estado inicial en 0" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        $env = Get-TestEnvironment
        $contexto = New-HermesEnterpriseContext -Environment $env
        $contexto.Estado.DuracionSegundos | Should Be 0
        $contexto.Estado.ComponentesCargados | Should Be 0
        $contexto.Estado.EventosEmitidos | Should Be 0
    }

    It "New-HermesEnterpriseContext debe tener un identificador único de contexto" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        $env = Get-TestEnvironment
        $contexto = New-HermesEnterpriseContext -Environment $env
        $contexto.IdentificadorContexto | Should Not BeNullOrEmpty
    }

    It "New-HermesEnterpriseContext debe tener memoria serializable no nula" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        $env = Get-TestEnvironment
        $contexto = New-HermesEnterpriseContext -Environment $env
        $memoria = $contexto.SerializeMemory()
        $memoria | Should Not BeNullOrEmpty
    }

    It "DeserializeMemory debe restaurar estado de Context" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        $env = Get-TestEnvironment
        $contexto = New-HermesEnterpriseContext -Environment $env
        $jsonMemoria = Get-TestEnvironmentSerializedMemory
        $contexto.DeserializeMemory($jsonMemoria)
        $contexto.NombreProyecto | Should Be "HERMES-ENTERPRISE"
        $contexto.RootRepositorio | Should Be $global:HERMES_REPO_ROOT
    }

    It "Get-HermesEnvironmentVariables debe retornar variables relevantes" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        $env = Get-TestEnvironment
        $variables = Get-HermesEnvironmentVariables -Environment $env
        $variables | Should Not BeNullOrEmpty
    }

    It "Get-HermesEnvironmentVariables debe incluir HERMES_REPO_ROOT" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        $env = Get-TestEnvironment
        $variables = Get-HermesEnvironmentVariables -Environment $env
        $variables.HERMES_REPO_ROOT | Should Be $global:HERMES_REPO_ROOT
    }
}

# ---------------------------------------------------------------------------
# ContextValidator.ps1
# ---------------------------------------------------------------------------
Describe "ContextValidator" {

    It "Test-HermesRepositoryRoot existe y retorna true para directorio válido" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\ContextValidator.ps1")
        $resultado = Test-HermesRepositoryRoot -RutaRepositorio $global:HERMES_REPO_ROOT
        $resultado | Should Be $true
    }

    It "Test-HermesRepositoryRoot retorna false para directorio inexistente" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\ContextValidator.ps1")
        $resultado = Test-HermesRepositoryRoot -RutaRepositorio "Z:\NoExiste"
        $resultado | Should Be $false
    }

    It "Test-HermesRepositoryRoot retorna false para ruta vacía" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\ContextValidator.ps1")
        $resultado = Test-HermesRepositoryRoot -RutaRepositorio ""
        $resultado | Should Be $false
    }

    It "Get-HermesRepositorySize retorna tamano mayor a 0" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\ContextValidator.ps1")
        $tamano = Get-HermesRepositorySize -RutaRepositorio $global:HERMES_REPO_ROOT
        $tamano | Should BeGreaterThan 0
    }

    It "Get-HermesRepositorySize retorna 0 para ruta inexistente" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\ContextValidator.ps1")
        $tamano = Get-HermesRepositorySize -RutaRepositorio "Z:\NoExiste"
        $tamano | Should Be 0
    }

    It "Connect-TestRepository debe lanzar si no hay token" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\ContextValidator.ps1")
        { Connect-TestRepository } | Should Throw
    }
}

# ---------------------------------------------------------------------------
# SummaryBuilder.ps1
# ---------------------------------------------------------------------------
Describe "SummaryBuilder" {

    It "New-HermesContextSummary debe generar resumen con nombre del proyecto" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\builders\SummaryBuilder.ps1")
        $resumen = New-HermesContextSummary -ProjectName "HERMES-ENTERPRISE" -RootPath $global:HERMES_REPO_ROOT
        $resumen.ProjectName | Should Be "HERMES-ENTERPRISE"
    }

    It "New-HermesContextSummary debe incluir RootPath" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\builders\SummaryBuilder.ps1")
        $resumen = New-HermesContextSummary -ProjectName "HERMES-ENTERPRISE" -RootPath $global:HERMES_REPO_ROOT
        $resumen.RootPath | Should Be $global:HERMES_REPO_ROOT
    }

    It "New-HermesContextSummary debe incluir fecha y hora" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\builders\SummaryBuilder.ps1")
        $resumen = New-HermesContextSummary -ProjectName "HERMES-ENTERPRISE" -RootPath $global:HERMES_REPO_ROOT
        $resumen.Timestamp | Should Not BeNullOrEmpty
    }

    It "New-HermesContextSummary debe incluir contador de archivos (mayor a 0)" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\builders\SummaryBuilder.ps1")
        $resumen = New-HermesContextSummary -ProjectName "HERMES-ENTERPRISE" -RootPath $global:HERMES_REPO_ROOT
        $resumen.FileCount | Should BeGreaterThan 0
    }

    It "Test de integración: Context + SummaryBuilder deben funcionar juntos" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\builders\SummaryBuilder.ps1")
        $env = Get-TestEnvironment
        $contexto = New-HermesEnterpriseContext -Environment $env
        $resumen = New-HermesContextSummary -ProjectName $contexto.NombreProyecto -RootPath $contexto.RootRepositorio
        $resumen.ProjectName | Should Be "HERMES-ENTERPRISE"
        $resumen.RootPath | Should Be $contexto.RootRepositorio
    }

    It "New-HermesContextSummary debe aceptar parámetro -IncludeMemory para integrar memoria" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\builders\SummaryBuilder.ps1")
        $env = Get-TestEnvironment
        $contexto = New-HermesEnterpriseContext -Environment $env
        $resumen = New-HermesContextSummary -ProjectName $contexto.NombreProyecto -RootPath $contexto.RootRepositorio -IncludeMemory
        $resumen.MemorySerializada | Should Not BeNullOrEmpty
    }

    It "Get-HermesEnvironmentSummary debe retornar tabla con columnas clave" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\builders\SummaryBuilder.ps1")
        $env = Get-TestEnvironment
        $contexto = New-HermesEnterpriseContext -Environment $env
        $tabla = Get-HermesEnvironmentSummary -Context $contexto
        $tabla | Should Not BeNullOrEmpty
    }

    It "New-HermesContextSummary debe incluir plataforma y runtime" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\builders\SummaryBuilder.ps1")
        $resumen = New-HermesContextSummary -ProjectName "HERMES-ENTERPRISE" -RootPath $global:HERMES_REPO_ROOT
        $resumen.Plataforma | Should Not BeNullOrEmpty
        $resumen.Runtime | Should Not BeNullOrEmpty
    }
}

# ---------------------------------------------------------------------------
# ExecutionObservatory.ps1
# ---------------------------------------------------------------------------
Describe "ExecutionObservatory" {

    It "Debe registrar y recuperar un evento" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("test.event", "INFO", "Prueba de evento")
        $historial = $obs.GetHistory()
        ($historial.Count) | Should Be 1
        $historial[0].Category | Should Be "test.event"
        $historial[0].Level | Should Be "INFO"
        $historial[0].Message | Should Be "Prueba de evento"
    }

    It "Debe registrar múltiples eventos" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("evt1", "INFO", "Primero")
        $obs.RegisterEvent("evt2", "WARN", "Segundo")
        $historial = $obs.GetHistory()
        ($historial.Count) | Should Be 2
        $historial[0].Message | Should Be "Primero"
        $historial[1].Message | Should Be "Segundo"
    }

    It "GetMetrics debe retornar resumen JSON" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("metic", "INFO", "Test")
        $metricas = $obs.GetMetrics()
        $metricas | Should Not BeNullOrEmpty
    }

    It "Start debe iniciar cronómetro interno" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.Start()
        Start-Sleep -Milliseconds 10
        $obs.ElapsedMs | Should BeGreaterThan 0
    }

    It "Stop debe detener cronómetro interno" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.Start()
        Start-Sleep -Milliseconds 10
        $obs.Stop()
        $elapsed = $obs.ElapsedMs
        Start-Sleep -Milliseconds 20
        $obs.ElapsedMs | Should Be $elapsed
    }

    It "Snapshot debe retornar estado actual del observatorio" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("snap", "INFO", "Snapshot test")
        $snap = $obs.Snapshot()
        $snap.eventCount | Should Be 1
        $snap.running | Should Be $false
    }

    It "Debe registrar eventos con timestamp válido" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("ts", "INFO", "Timestamp test")
        $historial = $obs.GetHistory()
        $historial[0].Timestamp | Should Not BeNullOrEmpty
    }

    It "GetHistory debe retornar copia, no referencia interna" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("copia", "INFO", "Original")
        $historial1 = $obs.GetHistory()
        $historial1[0].Message = "Modificado"
        $historial2 = $obs.GetHistory()
        $historial2[0].Message | Should Be "Original"
    }

    It "Clear debe vaciar historial" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("clear", "INFO", "A limpiar")
        $obs.Clear()
        $historial = $obs.GetHistory()
        ($historial.Count) | Should Be 0
    }

    It "Lap debe retornar tiempo transcurrido sin resetear" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.Start()
        Start-Sleep -Milliseconds 10
        $lapso = $obs.Lap()
        $lapso | Should BeGreaterThan 0
        $obs.ElapsedMs | Should BeGreaterThan 0
    }

    It "Checkpoint debe registrar un hito" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.Start()
        Start-Sleep -Milliseconds 5
        $obs.Checkpoint("hito1")
        $obs.Checkpoint("hito2")
        $historial = $obs.GetHistory()
        ($historial.Count) | Should Be 2
        $historial[0].Message | Should Be "hito1"
        $historial[1].Message | Should Be "hito2"
    }

    It "EventCount debe retornar número correcto" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("a", "INFO", "A")
        $obs.RegisterEvent("b", "INFO", "B")
        $obs.RegisterEvent("c", "INFO", "C")
        ($obs.GetHistory().Count) | Should Be 3
    }

    It "LevelCount debe contar eventos por nivel" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("x", "INFO", "Info 1")
        $obs.RegisterEvent("y", "WARN", "Warn 1")
        $obs.RegisterEvent("z", "ERROR", "Error 1")
        $conteo = $obs.LevelCount("INFO")
        $conteo | Should Be 1
    }

    It "Debe retornar 0 para nivel sin eventos" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("x", "INFO", "Solo info")
        $conteo = $obs.LevelCount("ERROR")
        $conteo | Should Be 0
    }

    It "LastEvent debe retornar el último evento registrado" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("primero", "INFO", "Primero")
        Start-Sleep -Milliseconds 2
        $obs.RegisterEvent("segundo", "INFO", "Segundo")
        $ultimo = $obs.LastEvent
        $ultimo.Message | Should Be "Segundo"
    }

    It "LastEvent debe ser null si no hay eventos" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.LastEvent | Should BeNullOrEmpty
    }

    It "Running debe retornar false tras Stop" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.Start()
        $obs.Stop()
        $obs.Running | Should Be $false
    }

    It "Running debe retornar true tras Start" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.Start()
        $obs.Running | Should Be $true
        $obs.Stop()
    }

    It "ToString debe retornar string representativo" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")
        $obs = [ExecutionObservatory]::new()
        $obs.RegisterEvent("tostr", "INFO", "Test")
        $str = $obs.ToString()
        $str | Should Not BeNullOrEmpty
    }
}

# ============================================================================
# Integration Tests
# ============================================================================
Describe "Context Integration" -Tag "Integration" {
    It "Context + Validator + SummaryBuilder + Observatory deben funcionar juntos" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\Context.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\ContextValidator.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\context\builders\SummaryBuilder.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\observability\ExecutionObservatory.ps1")

        $env = Get-TestEnvironment
        $contexto = New-HermesEnterpriseContext -Environment $env
        $valido = Test-HermesRepositoryRoot -RutaRepositorio $contexto.RootRepositorio
        $valido | Should Be $true
        $resumen = New-HermesContextSummary -ProjectName $contexto.NombreProyecto -RootPath $contexto.RootRepositorio
        $resumen.ProjectName | Should Be "HERMES-ENTERPRISE"
        $obs = [ExecutionObservatory]::new()
        $obs.Start()
        $obs.RegisterEvent("integracion.exitosa", "INFO", "Todo funciona en conjunto")
        $obs.Stop()
        ($obs.GetHistory().Count) | Should Be 1
    }
}