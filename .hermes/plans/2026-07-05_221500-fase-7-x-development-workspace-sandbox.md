# Fase 7.X — Development Workspace Sandbox

> **For Hermes:** Ejecutar con TDD estricto, commits pequeños y validación continua.

**Goal:** Implementar un laboratorio de pruebas aislado bajo `D:\Sandbox` donde todo flujo de aceptación de HERMES Enterprise se ejecute sin afectar proyectos reales.

**Architecture:** Cada ejecución crea un Sandbox consecutivo autodescriptivo (`Test001-Hermes-Workspace`), con estructura interna `HermesEnterprise/{Workspace,Projects,Logs,Sessions,Temp,Artifacts,Reports}` y un `sandbox.json` con metadatos. Los scripts `New-`, `Remove-`, `Get-` e `Invoke-HermesEnterpriseSandbox` gestionan el ciclo de vida. El `Invoke-HermesEnterpriseSandbox` orquesta el flujo completo de desarrollador nuevo.

**Tech Stack:** PowerShell 7+, sin dependencias externas, sin Azure, sin GitHub real, sin providers reales.

---

## Task 1: New-HermesEnterpriseSandbox.ps1

**Files:**
- Create: `scripts/New-HermesEnterpriseSandbox.ps1`
- Test: `pruebas/unitarias/Test-SandboxWorkflow.ps1`

**Behavior:**
- Raíz por defecto: `D:\Sandbox`
- Encontrar último `TestNNN-*`, calcular siguiente número consecutivo.
- Crear estructura completa.
- Crear `sandbox.json`.
- Devolver ruta completa.

**TDD:**
1. Test RED esperando `New-HermesEnterpriseSandbox`.
2. Implementar.
3. Test GREEN.
4. Commit.

---

## Task 2: Remove-HermesEnterpriseSandbox.ps1

**Files:**
- Create: `scripts/Remove-HermesEnterpriseSandbox.ps1`
- Test: `pruebas/unitarias/Test-SandboxWorkflow.ps1`

**Behavior:**
- Recibe ruta de Sandbox.
- Elimina solo ese Sandbox.
- Nunca elimina `D:\Sandbox` raíz.
- Nunca elimina otros Test.

---

## Task 3: Get-HermesEnterpriseSandbox.ps1

**Files:**
- Create: `scripts/Get-HermesEnterpriseSandbox.ps1`
- Test: `pruebas/unitarias/Test-SandboxWorkflow.ps1`

**Behavior:**
- Lista Sandboxes existentes.
- Muestra Número, Fecha, Proyecto, Estado, Resultado desde `sandbox.json`.

---

## Task 4: SandboxWizard.ps1

**Files:**
- Create: `motor/wizards/SandboxWizard.ps1`
- Test: `pruebas/unitarias/Test-SandboxWizard.ps1`

**Behavior:**
- Pregunta ¿dónde crear el Sandbox?
- Valor por defecto `D:\Sandbox`.
- Devuelve ruta base elegida.

---

## Task 5: Invoke-HermesEnterpriseSandbox.ps1

**Files:**
- Create: `scripts/Invoke-HermesEnterpriseSandbox.ps1`
- Test: `pruebas/unitarias/Test-SandboxWorkflow.ps1`

**Behavior:**
1. Crear Sandbox
2. Construir Workspace
3. Crear Proyecto
4. Inicializar Git
5. Crear README
6. Crear .gitignore
7. Crear estructura Hermes
8. Abrir VS Code (preparar comando)
9. Iniciar Hermes Enterprise (Start-HermesEnterprise con -DevolverContexto)
10. Ejecutar Smoke Test
11. Guardar Reportes
12. Esperar aprobación del usuario

**Reportes:**
- `Reports/InstallationReport.json`
- `Reports/ValidationReport.json`
- `Reports/SmokeTestReport.json`
- `Reports/AcceptanceReport.json`

---

## Task 6: Test-SandboxWorkflow.ps1

**Files:**
- Create: `pruebas/unitarias/Test-SandboxWorkflow.ps1`

**Validations:**
- Creación de Sandbox consecutivo.
- Numeración correcta.
- Estructura de carpetas.
- Existencia de sandbox.json.
- Proyecto creado dentro del Sandbox.
- Git inicializado.
- Workspace VS Code preparado.
- Session creada dentro del Sandbox.
- DeveloperContext construido.
- Smoke Test ejecutado.
- Eliminación limpia.

---

## Task 7: Integración con Smoke Test / Acceptance Test

**Files:**
- Modify: `pruebas/aceptacion/Test-DeveloperWorkspaceFlow.ps1`
- Modify: `scripts/Test-HermesEnterprise.ps1` (opcional, agregar Test-SandboxWorkflow)

**Behavior:**
- El flujo de aceptación debería ejecutarse dentro de un Sandbox.
- Para esta fase, alcanza con que Test-SandboxWorkflow demuestre que el flujo completo funciona dentro del Sandbox.

---

## Task 8: Documentación

**Files:**
- Modify: `documentacion/DEVELOPER_CONTEXT.md`
- Modify: `documentacion/DEVELOPER_ASSISTANT.md`
- Modify: `CHANGELOG.md`

**Behavior:**
- Agregar sección sobre Development Workspace Sandbox.
- Actualizar versión a 0.9.1 o similar.

---

## Validación final

1. Ejecutar `pruebas/unitarias/Test-SandboxWorkflow.ps1`.
2. Ejecutar `scripts/Test-HermesEnterprise.ps1`.
3. Verificar que `D:\Sandbox` no quede con basura tras las pruebas.
4. Revisar `git status`.
