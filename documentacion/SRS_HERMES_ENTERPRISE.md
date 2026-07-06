### RF-015: Integración con managers

Workspace Manager, Git Manager, GitHub Manager, VS Code Manager, Azure Foundry Provider, Plugin Manager, Documentation Manager y Testing Manager deben poder consumir el Session Descriptor como contexto.

Criterios de aceptación:

- No debe duplicarse información entre la sesión y los managers.
- Los managers existentes deben seguir operando sin modificaciones de su contrato público.

---

## 18. Trazabilidad Fase 6.0

| Requisito | Componente | Prueba | Documento |
|---|---|---|---|
| RF-012 | motor/session/SessionDescriptor.ps1, motor/session/SessionPersistence.ps1 | pruebas/unitarias/Test-SessionFramework.ps1 | documentacion/SESSION_FRAMEWORK.md |
| RF-013 | motor/session/SessionManager.ps1 | pruebas/unitarias/Test-SessionFramework.ps1 | documentacion/SESSION_FRAMEWORK.md |
| RF-014 | motor/session/SessionWizard.ps1, scripts/Start-HermesEnterprise.ps1 | pruebas/unitarias/Test-SessionFramework.ps1, scripts/Start-HermesEnterprise.ps1 | documentacion/FIRST_RUN_EXPERIENCE.md |
| RF-015 | motor/session/SessionManager.ps1 | pruebas/aceptacion/Test-DeveloperWorkspaceFlow.ps1 | documentacion/DEVELOPER_ASSISTANT.md |

---

## 19. Alcance Fase 7.0: Developer Context Framework

La Fase 7.0 reorganiza la arquitectura construida hasta la Fase 6 para convertir a HERMES Enterprise en un asistente de desarrollo cuyo punto de entrada sea el Developer Context, dejando la Session como un componente interno. No se agregan capacidades funcionales nuevas.

### RF-016: Developer Context

El sistema debe exponer un objeto raíz `DeveloperContext` que contenga: Workspace, Proyecto, Git, GitHub, Provider, Modelo, Plugins, Session, Preferencias, VariablesEntorno y EstadoKernel.

Criterios de aceptación:

- El contexto debe crearse mediante `New-HermesEnterpriseDeveloperContext`.
- El contexto debe construirse mediante `Build-HermesEnterpriseDeveloperContext`.
- El contexto debe administrarse mediante `New-HermesEnterpriseDeveloperContextManager`.
- El contexto no debe persistirse; siempre se reconstruye.
- El contexto no debe almacenar secretos ni credenciales.

### RF-017: Inspectores de contexto

El sistema debe exponer inspectores de solo lectura para descubrir workspace, proyecto, Git, GitHub y variables de entorno.

Criterios de aceptación:

- Cada inspector debe tener una única responsabilidad.
- Los inspectores no deben ejecutar operaciones destructivas.
- Los inspectores no deben modificar el sistema de archivos, el repositorio ni el Kernel.

### RF-018: First Run Wizard y Project Wizard

El sistema debe separar la experiencia de primera ejecución en dos asistentes independientes: `FirstRunWizard` para preferencias globales y `ProjectWizard` para resolver la ausencia de proyecto.

Criterios de aceptación:

- `FirstRunWizard` no debe crear proyectos.
- `ProjectWizard` debe permitir crear proyecto, abrir proyecto existente o clonar repositorio.
- El concepto de `Session Wizard` debe eliminarse.

### RF-019: Punto de entrada basado en DeveloperContext

Al ejecutar `Start-HermesEnterprise`, el sistema debe construir el `DeveloperContext` antes de iniciar el Kernel.

Criterios de aceptación:

- `scripts/Start-HermesEnterprise.ps1` debe construir el `DeveloperContext`.
- El `DeveloperContextManager` debe recuperar una Session existente o crearla automáticamente.
- El usuario nunca debe interactuar directamente con la Session.
- El Kernel debe recibir el `DeveloperContext` a través de `EstadoKernel`.

### RF-020: Compatibilidad del Kernel y componentes certificados

El Kernel, Bootstrap, Runtime, Logger, EventBus, Plugin Framework, Provider Framework, Azure Foundry Provider, Workspace Provider y Git Provider deben permanecer sin cambios en sus contratos públicos.

Criterios de aceptación:

- Los componentes certificados no deben modificarse.
- Las pruebas existentes deben continuar pasando.
- El Smoke Test Enterprise debe continuar funcionando sin regresiones.

---

## 20. Trazabilidad Fase 7.0

| Requisito | Componente | Prueba | Documento |
|---|---|---|---|
| RF-016 | motor/context/DeveloperContext.ps1, motor/context/ContextBuilder.ps1, motor/context/DeveloperContextManager.ps1 | pruebas/unitarias/Test-DeveloperContext.ps1, pruebas/unitarias/Test-DeveloperContextManager.ps1 | documentacion/DEVELOPER_CONTEXT.md |
| RF-017 | motor/context/WorkspaceInspector.ps1, motor/context/ProjectInspector.ps1, motor/context/GitInspector.ps1, motor/context/GitHubInspector.ps1, motor/context/EnvironmentInspector.ps1 | pruebas/unitarias/Test-WorkspaceInspector.ps1, pruebas/unitarias/Test-ProjectInspector.ps1, pruebas/unitarias/Test-GitInspector.ps1, pruebas/unitarias/Test-GitHubInspector.ps1, pruebas/unitarias/Test-EnvironmentInspector.ps1 | documentacion/DEVELOPER_CONTEXT.md |
| RF-018 | motor/wizards/FirstRunWizard.ps1, motor/wizards/ProjectWizard.ps1 | pruebas/unitarias/Test-FirstRunWizard.ps1, pruebas/unitarias/Test-ProjectWizard.ps1 | documentacion/FIRST_RUN_EXPERIENCE.md |
| RF-019 | scripts/Start-HermesEnterprise.ps1, motor/context/DeveloperContextManager.ps1 | pruebas/aceptacion/Test-DeveloperWorkspaceFlow.ps1, scripts/Start-HermesEnterprise.ps1 | documentacion/DEVELOPER_CONTEXT.md, documentacion/DEVELOPER_ASSISTANT.md |
| RF-020 | motor/kernel/Kernel.ps1, motor/bootstrap/Bootstrap.ps1, motor/runtime/Runtime.ps1, motor/logging/Logger.ps1, motor/eventos/EventBus.ps1, motor/plugins/PluginManager.ps1, motor/providers/* | scripts/Test-HermesEnterprise.ps1 | documentacion/ARCHITECTURE_DECISIONS.md |
