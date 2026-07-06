# Session Framework

## Propósito

A partir de la Fase 6.0, HERMES Enterprise se organiza alrededor del concepto de "Developer Session". La sesión es el objeto raíz del sistema y todos los componentes (Workspace, Git, GitHub, VS Code, Azure Foundry, plugins, documentación, pruebas) consumen su contexto.

## Archivos

- `motor/session/SessionDescriptor.ps1`: representación de una sesión.
- `motor/session/SessionPersistence.ps1`: persistencia JSON.
- `motor/session/SessionLoader.ps1`: detección y carga de sesión.
- `motor/session/SessionRecovery.ps1`: respaldos y recuperación.
- `motor/session/SessionTelemetry.ps1`: registro de eventos en el historial.
- `motor/session/SessionWizard.ps1`: First Run Experience.
- `motor/session/SessionManager.ps1`: orquestador del ciclo de vida.

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

- Crear sesión.
- Abrir sesión.
- Cerrar sesión.
- Guardar sesión.
- Recuperar sesión.
- Cambiar proyecto, workspace, modelo, provider y rama.
- Actualizar estado.

## Persistencia

Las sesiones se almacenan en `.hermes/sessions/<Identificador>.json`. Los respaldos se guardan en `.hermes/sessions/backup/`.

## Integración

Workspace Manager, Git Manager, GitHub Manager, VS Code Manager, Azure Foundry Provider, Plugin Manager, Documentation Manager y Testing Manager consumen la sesión como contexto. No se almacena información duplicada.

## Compatibilidad

- `scripts/Start-HermesEnterprise.ps1` recupera la sesión existente o ejecuta el Session Wizard.
- `scripts/Test-HermesEnterprise.ps1` incluye `Test-SessionFramework.ps1`.
- Smoke Test Enterprise continúa operativo.
