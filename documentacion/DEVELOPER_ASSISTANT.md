# HERMES Enterprise Developer Assistant

## Propósito

A partir de la Fase 5, HERMES Enterprise deja de construir únicamente infraestructura para convertirse en un asistente de desarrollo operativo dentro de VS Code.

El objetivo es que el usuario pueda trabajar desde VS Code utilizando únicamente comandos HERMES.

## Principios

- Priorizar integración sobre expansión.
- Reutilizar la infraestructura existente.
- No duplicar funcionalidades.
- Encapsular comandos Git y VS Code mediante wrappers HERMES.
- No ejecutar comandos externos automáticamente salvo que el usuario lo solicite.

## Flujo típico

```powershell
Start-HermesEnterprise
New-HermesEnterpriseProject MiProyecto -CrearReadme
Open-HermesEnterpriseProject MiProyecto
Invoke-HermesEnterpriseGitCommand status
Invoke-HermesEnterpriseVSCodeCommand OpenFolder
Invoke-HermesEnterpriseTests
Publish-HermesEnterpriseDocumentation
New-HermesEnterpriseCommit -Mensaje "feat: avance"
```

## Session Framework

A partir de la Fase 6, todas las interacciones operan dentro de una sesión gestionada por `motor/session/SessionManager.ps1`. Ver `documentacion/SESSION_FRAMEWORK.md` y `documentacion/FIRST_RUN_EXPERIENCE.md`.

## Scripts públicos

- `scripts/Start-HermesEnterpriseDevelopmentSession.ps1`: inicia sesión cargando Kernel y providers.
- `scripts/New-HermesEnterpriseProject.ps1`: crea proyecto local.
- `scripts/Open-HermesEnterpriseProject.ps1`: abre proyecto y prepara comando VS Code.
- `scripts/Invoke-HermesEnterpriseTests.ps1`: ejecuta smoke tests.
- `scripts/Publish-HermesEnterpriseDocumentation.ps1`: publica documentación.
- `scripts/New-HermesEnterpriseCommit.ps1`: prepara commit Git.

El punto de entrada principal es `scripts/Start-HermesEnterprise.ps1`, que recupera la sesión existente o ejecuta el Session Wizard.

## Managers

- `motor/providers/ProjectManager.ps1`: proyectos locales y descriptores.
- `motor/providers/GitManager.ps1`: wrappers Git.
- `motor/providers/VSCodeManager.ps1`: comandos VS Code.
- `motor/providers/GitHubManagers.ps1`: operaciones GitHub organizadas por área.
- `motor/providers/GitHubProvider.ps1`: orquestador con contrato Enterprise.
- `motor/providers/WorkspaceProvider.ps1`: orquestador del Developer Workspace.

## Prueba de aceptación

Ver `pruebas/aceptacion/Test-DeveloperWorkspaceFlow.ps1`.

## Límites

- GitHub sigue en modo MOCK.
- No se solicitan tokens ni se usa GitHub API/CLI.
- Los comandos Git y VS Code se preparan; su ejecución directa queda bajo control del usuario.
