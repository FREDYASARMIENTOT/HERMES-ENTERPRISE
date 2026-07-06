# GitHub Workspace Provider

## Propósito
Nueva línea evolutiva de HERMES-ENTERPRISE para automatizar el ciclo de vida del desarrollo respetando la arquitectura Enterprise existente.

## Alcance Fase 5.0
- Infraestructura local para proyectos, Git y VS Code.
- Provider GitHub en modo MOCK, sin REST ni credenciales.
- Sin modificar Kernel, Runtime, Bootstrap, Logger, EventBus, Plugin Framework ni Azure Foundry.

## Archivos agregados
- `motor/providers/GitHubProvider.ps1`
- `motor/providers/WorkspaceProvider.ps1`
- `motor/providers/ProjectDescriptor.ps1`
- `pruebas/unitarias/Test-GitHubWorkspace.ps1`

## Contratos públicos
GitHubProvider: `New-HermesEnterpriseGitHubProvider`, `ValidateConfiguration-GitHubProvider`, `Initialize-GitHubProvider`, `Connect-GitHubProvider`, `Disconnect-GitHubProvider`, `Get-GitHubProviderHealth`, `Get-GitHubProviderSummary`, `GetProviderInformation-GitHubProvider`.

WorkspaceProvider: selección/creación de carpetas, detección Git/VS Code, wrappers Git/VS Code, integración Hermes.

## Límites
- No se crean repositorios reales en GitHub, ni tokens, API ni CLI.
- Los comandos Git y VS Code se preparan pero no se ejecutan automáticamente.

## Próxima fase
Conectar el provider con la API real de GitHub.
