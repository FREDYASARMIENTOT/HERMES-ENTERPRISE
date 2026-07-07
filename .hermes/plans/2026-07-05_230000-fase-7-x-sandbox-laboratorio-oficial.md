# Fase 7.X — Development Workspace Sandbox (Laboratorio Oficial)

> **For Hermes:** Ejecutar con TDD estricto, commits pequeños y validación continua.

**Goal:** Convertir el Sandbox en el Laboratorio Oficial de Validación de HERMES Enterprise: escenarios reales de usuario, guías integradas, reportes auditables y manejo de errores sin reintentos automáticos.

**Architecture:** Cada Sandbox es un escenario autodescriptivo bajo `D:\Sandbox\TestNNN-<Escenario>`. Contiene `HermesEnterprise/`, `Workspace/`, `Reports/`, `Snapshots/`, `Logs/`, `Sessions/`, `Artifacts/`, `UserGuide.md`, `SandboxInstructions.ps1` y `sandbox.json`. El ciclo de vida se divide en scripts de responsabilidad única.

**Tech Stack:** PowerShell 7+, sin dependencias externas, sin Azure, sin GitHub real, sin providers reales.

---

## Scripts a crear/modificar

### New-HermesEnterpriseSandbox.ps1
- Crea estructura del Sandbox con nombre autodescriptivo.
- Soporta parámetro `-Escenario`.
- Genera `sandbox.json` con metadatos.

### Initialize-HermesEnterpriseSandbox.ps1
- Prepara el escenario dentro del Sandbox:
  - EmptyFolder: nada.
  - ExistingProject: crea proyecto.
  - ProjectWithoutGit: proyecto sin .git.
  - GitWithoutRemote: proyecto con git init.
  - GitHubRepository: git con remote MOCK.
  - NewProject: estructura lista para nuevo proyecto.
  - ResumeSession: crea una sesión previa.
  - MultipleSessions: crea múltiples sesiones.

### Invoke-HermesEnterpriseScenario.ps1
- Ejecuta HERMES Enterprise dentro del Sandbox.
- Recolecta DeveloperContext.
- No reintenta automáticamente; registra errores.

### Test-HermesEnterpriseSandbox.ps1
- Ejecuta Smoke Test dentro del Sandbox.
- Genera reportes.

### Export-HermesEnterpriseSandboxReport.ps1
- Genera reportes JSON:
  - InstallationReport.json
  - ValidationReport.json
  - SmokeTestReport.json
  - AcceptanceReport.json
  - DeveloperContext.json
  - Workspace.json

### New-HermesEnterpriseSandboxUserGuide.ps1
- Genera `UserGuide.md` con instrucciones específicas del escenario.

### New-HermesEnterpriseSandboxInstructions.ps1
- Genera `SandboxInstructions.ps1` con ayuda interactiva.

### Remove-HermesEnterpriseSandbox.ps1
- Elimina un Sandbox específico.
- Valida que el nombre comience con Test\d{3}-.

### Get-HermesEnterpriseSandbox.ps1
- Lista Sandboxes con metadatos.

### SandboxWizard.ps1
- Pregunta ruta base y escenario.

### Invoke-HermesEnterpriseSandbox.ps1
- Orquestador del flujo completo.
- Llama secuencialmente a New, Initialize, Invoke Scenario, Test, Export Reports, Generate Guides.
- Si falla: registra error, marca FAILED, detiene.

### Test-SandboxWorkflow.ps1
- Valida matriz de escenarios.

---

## Escenarios

| Escenario         | Descripción                 |
| ----------------- | --------------------------- |
| NoWorkspace       | VS Code sin carpeta abierta |
| EmptyFolder       | Carpeta vacía              |
| ExistingProject   | Proyecto existente          |
| ProjectWithoutGit | Proyecto sin Git            |
| GitWithoutRemote  | Git sin remoto              |
| GitHubRepository  | Git con remoto              |
| ResumeSession     | Reabrir sesión             |
| NewProject        | Crear proyecto nuevo        |
| CloneProject      | Clonar proyecto             |
| MultipleSessions  | Cambiar entre sesiones      |

---

## Manejo de errores

1. Registrar error en Logs/
2. Guardar ValidationReport.json con estado FAILED
3. Marcar sandbox.json estado = FAILED
4. Detener ejecución
5. No reintentar automáticamente

---

## Validación final

1. Ejecutar Test-SandboxWorkflow.ps1
2. Verificar que al menos 3 escenarios pasen
3. Verificar UserGuide.md y SandboxInstructions.ps1 generados
4. Verificar reportes JSON
5. Ejecutar Smoke Test Enterprise sin regresiones

---

## Estado de Implementación

**✅ COMPLETADO - 2026-07-07**

Todos los componentes de la Fase 7.X fueron implementados y validados:

### Scripts Creados (1,081 líneas totales)
- ✅ `New-HermesEnterpriseSandbox.ps1` - Creación con numeración consecutiva
- ✅ `Initialize-HermesEnterpriseSandbox.ps1` - Inicialización de 10 escenarios
- ✅ `Invoke-HermesEnterpriseScenario.ps1` - Ejecución de escenarios
- ✅ `Test-HermesEnterpriseSandbox.ps1` - Smoke testing
- ✅ `Export-HermesEnterpriseSandboxReport.ps1` - Generación de reportes JSON
- ✅ `New-HermesEnterpriseSandboxUserGuide.ps1` - Guías de usuario por escenario
- ✅ `New-HermesEnterpriseSandboxInstructions.ps1` - Instrucciones interactivas
- ✅ `Remove-HermesEnterpriseSandbox.ps1` - Eliminación segura
- ✅ `Get-HermesEnterpriseSandbox.ps1` - Listado y consultas
- ✅ `motor/wizards/SandboxWizard.ps1` - Wizard interactivo
- ✅ `Invoke-HermesEnterpriseSandbox.ps1` - Orquestador principal

### Escenarios Implementados
1. NoWorkspace - VS Code sin carpeta abierta
2. EmptyFolder - Carpeta vacía
3. ExistingProject - Proyecto existente con Git
4. ProjectWithoutGit - Proyecto sin control de versiones
5. GitWithoutRemote - Git local sin remoto
6. GitHubRepository - Git con remoto configurado
7. ResumeSession - Reanudación de sesión anterior
8. NewProject - Creación de proyecto nuevo
9. CloneProject - Clonación de repositorio
10. MultipleSessions - Múltiples sesiones activas

### Validación de Tests
- ✅ `Test-SandboxWorkflow.ps1` - Ciclo completo del sandbox
- ✅ `Test-SandboxEscenarios.ps1` - Matriz de escenarios
- ✅ `Test-SandboxReports.ps1` - Generación de reportes
- ✅ `Test-SandboxGuides.ps1` - Guías e instrucciones

### Bugs Corregidos
- ✅ Fix en `Export-HermesEnterpriseSandboxReport.ps1` (sintaxis `-and` con `Test-Path`)
- ✅ Ajuste en `Test-SandboxWorkflow.ps1` (expectativa de numeración)

### Resultados de Validación Ad-Hoc (2026-07-07)
```
[1/5] Test-SandboxWorkflow.ps1 ................. PASS (exit 0)
[2/5] Test-ExecutionLogger.ps1 ................. PASS (exit 0)
[3/5] Test-ExecutionDashboard.ps1 .............. PASS (exit 0)
[4/5] Test-ExecutionSupervisor.ps1 ............. PASS (exit 0)
[5/5] Invoke-HermesEnterpriseSandbox integration  PASS (contenido verificado)

5/5 pasados - TODA VERIFICACIÓN AD-HOC PASÓ
```

### Commits
- `5123630` feat: Implementar Fase 7.X - Sandbox como Laboratorio Oficial de Validación
- `7d0e5c8` fix: Corregir sintaxis -and en Export-HermesEnterpriseSandboxReport.ps1

### Uso
```powershell
# Ejecutar un escenario específico
pwsh scripts/Invoke-HermesEnterpriseSandbox.ps1 -Escenario ExistingProject

# Listar sandboxes existentes
pwsh scripts/Get-HermesEnterpriseSandbox.ps1

# Eliminar sandbox
pwsh scripts/Remove-HermesEnterpriseSandbox.ps1 -RutaSandbox "D:\Sandbox\Test001-EmptyFolder"

# Lanzar wizard interactivo
pwsh motor/wizards/SandboxWizard.ps1
```

### Arquitectura
- **Cada Sandbox** es un directorio aislado: `D:\Sandbox\TestNNN-<Escenario>\`
- **Estructura interna**: HermesEnterprise/, Workspace/, Reports/, Snapshots/, Logs/, Sessions/, Artifacts/
- **Metadata**: `sandbox.json` con estado y configuración
- **Documentación**: UserGuide.md + SandboxInstructions.ps1 por escenario
- **Reportes auditables**: InstallationReport.json, ValidationReport.json, AcceptanceReport.json, SmokeTestReport.json, DeveloperContext.json, Workspace.json
