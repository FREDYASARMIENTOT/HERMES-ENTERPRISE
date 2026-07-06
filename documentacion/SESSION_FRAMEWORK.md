# Session Framework

## Propósito

A partir de la Fase 7.0, el Session Framework es un **componente interno** administrado automáticamente por el Developer Context Framework. La sesión representa el estado de desarrollo persistente, pero **ya no es el objeto raíz** del sistema.

## Evolución arquitectónica

- **Fase 6**: la sesión era el objeto raíz y contenía el workspace.
- **Fase 7**: el `DeveloperContext` es el objeto raíz y contiene la sesión.

```text
DeveloperContext
└── Session
```

## Archivos

- `motor/session/SessionDescriptor.ps1`: representación de una sesión.
- `motor/session/SessionPersistence.ps1`: persistencia JSON.
- `motor/session/SessionLoader.ps1`: detección y carga de sesión.
- `motor/session/SessionRecovery.ps1`: respaldos y recuperación.
- `motor/session/SessionTelemetry.ps1`: registro de eventos en el historial.
- `motor/session/SessionManager.ps1`: orquestador del ciclo de vida. Recibe un `DeveloperContext`.

> **Nota**: `motor/session/SessionWizard.ps1` fue eliminado en la Fase 7. Sus responsabilidades se dividieron en `motor/wizards/FirstRunWizard.ps1` y `motor/wizards/ProjectWizard.ps1`.

## Session Descriptor

Campos mínimos:

- IdentificadorSesion
- NombreProyecto
- RutaWorkspace
- RepositorioGit
- BranchActual
- ProveedorIA
- ModeloIA
- PluginsInstalados
- ConfiguracionActiva
- FechaCreacion
- UltimaActividad
- VersionHermes
- EstadoSesion
- Usuario
- Historial
- Contexto

## Responsabilidades del SessionManager

- Crear sesión a partir de un `DeveloperContext`.
- Abrir sesión existente.
- Cerrar sesión.
- Guardar sesión.
- Recuperar sesión.
- Cambiar proyecto, workspace, modelo, provider y rama.
- Actualizar estado.

El SessionManager **no interactúa con el usuario**. Si existe una sesión, la recupera; si no, la crea automáticamente.

## Persistencia

Las sesiones se almacenan en `.hermes/sessions/<Identificador>.json`. Los respaldos se guardan en `.hermes/sessions/backup/`.

## Integración

El `DeveloperContextManager` consume el SessionManager para obtener o crear la sesión que contendrá el `DeveloperContext`. Los demás componentes (Workspace, Git, GitHub, VS Code, Azure Foundry, plugins, documentación, pruebas) consumen el `DeveloperContext`.

## Compatibilidad

- `scripts/Start-HermesEnterprise.ps1` construye el `DeveloperContext` y lo entrega al Kernel.
- `scripts/Test-HermesEnterprise.ps1` incluye `Test-SessionFramework.ps1` y las pruebas del Developer Context.
- Smoke Test Enterprise continúa operativo.
