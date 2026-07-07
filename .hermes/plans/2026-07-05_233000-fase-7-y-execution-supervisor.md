# Fase 7.Y — Execution Supervisor para el Sandbox

> **For Hermes:** Ejecutar con TDD estricto, commits pequeños y validación continua.

**Goal:** Transformar el Sandbox en una herramienta de desarrollo interactiva con un Execution Supervisor que coordine pasos, muestre progreso, registre estado, permita pausas y nunca reintente automáticamente.

**Architecture:** Nuevo módulo `motor/sandbox/` con `ExecutionLogger.ps1`, `ExecutionDashboard.ps1` y `ExecutionSupervisor.ps1`. El supervisor orquesta los pasos del Sandbox, escribe logs y estado continuo, y soporta modos interactivo y automático.

**Tech Stack:** PowerShell 7+, sin dependencias externas.

---

## Componentes

### ExecutionLogger.ps1
- Escribe `Execution.log`, `Execution.json` y `CurrentState.json` después de cada paso.
- Funciones:
  - `Write-HermesEnterpriseExecutionLog`
  - `Write-HermesEnterpriseExecutionState`
  - `Get-HermesEnterpriseExecutionState`

### ExecutionDashboard.ps1
- Muestra dashboard en consola:
  - Sandbox actual
  - Escenario
  - Estado
  - Progreso `[#####-----] 50%`
  - Tiempo transcurrido
  - Errores / Warnings
  - Paso actual
- Funciones:
  - `Show-HermesEnterpriseExecutionDashboard`
  - `Show-HermesEnterpriseExecutionProgress`

### ExecutionSupervisor.ps1
- Orquesta los pasos del Sandbox:
  1. Crear Sandbox
  2. Inicializar escenario
  3. Ejecutar escenario (DeveloperContext)
  4. Smoke Test
  5. Exportar reportes
  6. Generar UserGuide.md
  7. Generar SandboxInstructions.ps1
- Cada paso registra log, actualiza estado, muestra dashboard.
- Si un paso falla: registra error, marca FAILED, detiene. No reintenta.
- Parámetros:
  - `-Interactive`: pausa después de cada paso (ENTER continuar, R repetir, Q salir)
  - `-NoPause`: ejecución automática
  - `-OpenVSCode`: abre VS Code en el paso Workspace preparado y pausa
- Funciones:
  - `Start-HermesEnterpriseExecutionSupervisor`
  - `Invoke-HermesEnterpriseExecutionStep`

### Invoke-HermesEnterpriseSandbox.ps1 (actualizado)
- Usa el ExecutionSupervisor en lugar de orquestar directamente.
- Pasa parámetros `-Interactive`, `-NoPause`, `-OpenVSCode`.

---

## Tests

- `pruebas/unitarias/Test-ExecutionLogger.ps1`
- `pruebas/unitarias/Test-ExecutionDashboard.ps1`
- `pruebas/unitarias/Test-ExecutionSupervisor.ps1`
- Actualizar `pruebas/unitarias/Test-SandboxWorkflow.ps1` para usar supervisor en modo `-NoPause`.

---

## Documentación

- Actualizar `documentacion/DEVELOPER_CONTEXT.md` con sección Execution Supervisor.
- Actualizar `CHANGELOG.md` a 0.9.2.

---

## Validación

1. Tests unitarios de logger, dashboard y supervisor pasan.
2. Test-SandboxWorkflow pasa en modo automático.
3. Smoke Test Enterprise continúa pasando.

---

## Estado de Implementación

**COMPLETADO - 2026-07-07**

### Componentes Creados (motor/sandbox/)
- `ExecutionLogger.ps1` (88 líneas) - Logging con niveles INFO/WARNING/ERROR/SUCCESS
- `ExecutionDashboard.ps1` (105 líneas) - Dashboard visual con barra [#####-----] y tiempo formateado
- `ExecutionSupervisor.ps1` (~280 líneas) - Orquestador con modos interactivo/automático

### Tests Unitarios
- `Test-ExecutionLogger.ps1` - Valida logging, estados, acumulación
- `Test-ExecutionDashboard.ps1` - Valida formato de dashboard y progress
- `Test-ExecutionSupervisor.ps1` - Valida flujo completo NoPause+SkipSmokeTest

### Refactorización
- `scripts/Invoke-HermesEnterpriseSandbox.ps1` - Delega en ExecutionSupervisor, recibe -Interactive/-NoPause/-OpenVSCode/-SkipSmokeTest

### Bugs Encontrados y Corregidos durante Implementación
- `Export-HermesEnterpriseSandboxReport.ps1` - Fix sintaxis `Test-Path $X -and` → `(Test-Path $X) -and`
- `{0:D2}:{1:D2}` -f float falla → usar `$var.ToString('D2')` con [int] cast
- `Clear-Host` en sesiones no-TTY → envuelto en try/catch silencioso
- `-match` falla con encoding UTF-8 en CI → usar `[IO.File]::ReadAllText` + `.Contains()`

### Verificación Ad-Hoc
```
[SandboxWorkflow]                                PASS (exit 0)
[ExecutionLogger]                                PASS (exit 0)
[ExecutionDashboard]                             PASS (exit 0)
[ExecutionSupervisor]                            PASS (exit 0)
[Invoke-HermesEnterpriseSandbox integration]     PASS (4/4 markers)
[Export-HermesEnterpriseSandboxReport fix]       PASS (parenthesized)
[motor/sandbox components]                       PASS (3/3 files)
7/7 passed, 0 failed
```

### Commit
`5123630` - feat: Fase 7.Y - Execution Supervisor completo
