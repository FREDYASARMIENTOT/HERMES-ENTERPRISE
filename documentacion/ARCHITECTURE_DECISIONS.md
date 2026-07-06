# Architecture Decisions HERMES-ENTERPRISE

| Campo | Valor |
|---|---|
| Proyecto | HERMES-ENTERPRISE |
| AutorPrincipal | Fredy Alejandro Sarmiento Torres |
| Estado | Registro vivo de decisiones arquitectónicas |

---

## ADR-0016: Session Framework como objeto raíz

### Estado

Aceptada.

### Contexto

Después de la Fase 5, HERMES Enterprise opera como asistente de desarrollo con múltiples managers y scripts. La Fase 6.0 requiere un objeto raíz que coordine el contexto del usuario sin modificar el Kernel ni los componentes maduros.

### Decisión

Introducir el Session Framework bajo `motor/session/`:

- `SessionDescriptor.ps1`: objeto raíz portátil.
- `SessionPersistence.ps1`: almacenamiento JSON en `.hermes/sessions/`.
- `SessionLoader.ps1`: detección de sesión existente.
- `SessionRecovery.ps1`: respaldos automáticos.
- `SessionTelemetry.ps1`: historial de eventos.
- `SessionWizard.ps1`: First Run Experience.
- `SessionManager.ps1`: orquestador del ciclo de vida.

Modificar `scripts/Start-HermesEnterprise.ps1` para que recupere la sesión existente o ejecute el Session Wizard.

### Consecuencias positivas

- Toda interacción opera dentro de un contexto de sesión explícito.
- Los managers existientes pueden consumir la sesión sin duplicar información.
- El punto de entrada del sistema es más simple para el usuario.

### Límites

- No se modifica Kernel, Bootstrap, Runtime, EventBus, Logger, Plugin Framework, Provider Framework, Azure Foundry Provider, Workspace Provider ni Git Provider.
- GitHub sigue en modo MOCK.
- Los comandos externos se preparan pero no se ejecutan automáticamente.

### Verificación

- `pruebas/unitarias/Test-SessionFramework.ps1`
- `pruebas/aceptacion/Test-DeveloperWorkspaceFlow.ps1`
- `scripts/Start-HermesEnterprise.ps1`
- `scripts/Test-HermesEnterprise.ps1`

---

## ADR-0015: HERMES Enterprise Developer Assistant

### Estado

Aceptada.

### Contexto

El Kernel, Plugin Framework y Provider Framework están maduros. La Fase 5 cambia el objetivo: dejar de construir infraestructura aislada y comenzar a usar HERMES como asistente de desarrollo operativo dentro de VS Code.

### Decisión

Refactorizar providers existentes y agregar scripts públicos para exponer un flujo de trabajo completo:

- Separar `WorkspaceProvider.ps1` en `ProjectManager.ps1`, `GitManager.ps1` y `VSCodeManager.ps1`.
- Completar `GitHubProvider.ps1` con `GitHubManagers.ps1` para Repository, Branch, Commit, Pull, Push, Clone y Workspace.
- Crear scripts en `scripts/` para sesión de desarrollo, proyectos, VS Code, pruebas, documentación y commits.
- Crear prueba de aceptación end-to-end en `pruebas/aceptacion/Test-DeveloperWorkspaceFlow.ps1`.

### Consecuencias positivas

- HERMES pasa de framework a herramienta operativa.
- Los comandos Git y VS Code quedan encapsulados y reutilizables.
- El flujo end-to-end es verificable.

### Límites

- GitHub sigue en modo MOCK.
- No se modifica Kernel, Runtime, Bootstrap, Logger, EventBus, Plugin Framework ni Azure Foundry.
- Los comandos externos se preparan pero no se ejecutan automáticamente.

### Verificación

- `pruebas/unitarias/Test-GitHubWorkspace.ps1`
- `pruebas/aceptacion/Test-DeveloperWorkspaceFlow.ps1`
- `scripts/Test-HermesEnterprise.ps1`

---

## ADR-0014: GitHub Workspace Provider Fase 5.0

### Estado

Aceptada.

### Contexto

HERMES-ENTERPRISE requiere una línea evolutiva para automatizar el ciclo de vida del desarrollo de software sin romper la arquitectura existente.

### Decisión

Agregar providers independientes bajo `motor/providers/`:

- `GitHubProvider.ps1`: orquestador con contrato Enterprise y operaciones MOCK.
- `WorkspaceProvider.ps1`: gestión local de proyectos, Git y VS Code.
- `ProjectDescriptor.ps1`: descriptor portable sin dependencias externas.

Las operaciones Git y VS Code se preparan mediante wrappers pero no se ejecutan automáticamente.

### Límites

- No se usa GitHub API, CLI ni credenciales reales.
- No se crean repositorios reales en GitHub.
- No se modifica Kernel, Runtime, Bootstrap, Logger, EventBus, Plugin Framework ni Azure Foundry.

### Verificación

- `pruebas/unitarias/Test-GitHubWorkspace.ps1`
- `scripts/Test-HermesEnterprise.ps1`

---

## ADR-0013: Observabilidad y seguridad de logs del Azure Foundry Provider

### Estado

Aceptada.

### Contexto

El Azure Foundry Provider ya se conecta a Azure AI Foundry, ejecuta health checks, descubre deployments y envía chat completions. Antes de agregar capacidades avanzadas, la Fase 4.5 requiere hacer el provider observable y operable: trazabilidad de peticiones, métricas de latencia/tokens/costo, manejo centralizado de errores HTTP y garantía de que los logs nunca contengan secretos.

### Decisión

Agregar `motor/providers/AzureFoundryTelemetry.ps1` con:

- Generación de `CorrelationId` por operación.
- Sanitización de datos antes de escribir en logs (redacción de api-key, token, authorization, secret, password, credential).
- Estimación de costo por modelo basada en tokens de entrada/salida.
- Registro unificado de: deployment, latencia, tokens, costo, modelo, estado y error.

Modificar `AzureFoundryRest.ps1` para devolver respuestas unificadas `{ Success, StatusCode, Data, LatenciaMs, Error, CorrelationId }` y centralizar el manejo de errores HTTP.

Integrar telemetría en `AzureFoundryHealth`, `AzureFoundryDeployment` y `AzureFoundryChat`.

Extender `Write-HermesEnterpriseLogEvent` para aceptar `CorrelationId` opcional manteniendo compatibilidad.

Crear `pruebas/unitarias/Test-AzureFoundryProviderTelemetry.ps1` para validar sanitización, métricas y secreto-safe logs.

### Consecuencias positivas

- Trazabilidad end-to-end de cada petición.
- Logs listos para auditoría y debugging sin exponer credenciales.
- Base sólida para Streaming, Tool Calling y MCP.

### Límites

- No se implementa Streaming ni Responses API avanzada.
- No se implementa Tool Calling, Agents, MCP ni Embeddings.
- El costo es una estimación simplificada; no reemplaza la facturación de Azure.

### Verificación

- `pruebas/unitarias/Test-AzureFoundryProviderTelemetry.ps1`
- `pruebas/unitarias/Test-AzureFoundryProviderConnection.ps1`
- `scripts/Test-HermesEnterprise.ps1`

---

## ADR-0012: Refactorización arquitectónica del Azure Foundry Provider

### Estado

Aceptada.

### Contexto

El AzureFoundryProvider creció acumulando responsabilidades: autenticación, resolución de credenciales, llamadas REST, health check, deployments, chat, fallback a Azure AD y Key Vault. La Fase 4.4 requiere separar esas responsabilidades sin cambiar el comportamiento observable.

### Decisión

Convertir `AzureFoundryProvider.ps1` en un orquestador puro y mover responsabilidades a módulos especializados:

- `motor/security/AzureAdResolver.ps1`: token de Azure AD.
- `motor/security/KeyVaultResolver.ps1`: lectura de secretos de Azure Key Vault.
- `motor/security/CredentialResolver.ps1`: decisión de origen de credenciales y prueba de autenticación.
- `motor/providers/AzureFoundryRest.ps1`: cliente REST (URI, GET, POST, JSON).
- `motor/providers/AzureFoundryHealth.ps1`: health check e interpretación de códigos HTTP.
- `motor/providers/AzureFoundryDeployment.ps1`: descubrimiento y descripción de deployments.
- `motor/providers/AzureFoundryChat.ps1`: envío de conversaciones.

Los nombres de funciones públicas del provider se mantienen sin cambios.

### Consecuencias positivas

- Cada módulo tiene una única responsabilidad.
- Facilita agregar Streaming, Tool Calling, MCP y Agentes en fases posteriores.
- El orquestador no depende directamente de `az` ni de Key Vault.

### Límites

- No se agrega funcionalidad nueva.
- No se modifica comportamiento observable.
- No se cambian contratos públicos del Provider Framework ni del Kernel.

### Verificación

- `pruebas/unitarias/Test-AzureFoundryProvider.ps1`
- `pruebas/unitarias/Test-AzureFoundryProviderConnection.ps1`
- `scripts/Test-HermesEnterprise.ps1`

---

## ADR-0011: Reporte consolidado de madurez del Plugin Framework

### Estado

Aceptada.

### Contexto

Después de incorporar observabilidad, política de fallas, Sandbox v1, SemVer, manifiestos y ciclo de vida, la Fase 2.6 requiere cerrar la madurez del Plugin Framework antes de incorporar proveedores reales.

### Decisión

Agregar `Get-HermesEnterprisePluginFrameworkMaturityReport` en `PluginManager` para consolidar:

- estado de madurez del framework;
- versión del Kernel evaluada;
- totales de plugins cargados, `Faulted` y deshabilitados;
- política de falla aplicada;
- capacidades implementadas;
- límites explícitos no implementados;
- pruebas recomendadas;
- próxima fase recomendada.

El reporte es de solo lectura y usa la observabilidad ya existente.

### Límites

- No modifica comportamiento del Kernel.
- No integra proveedores reales.
- No incorpora Azure Foundry, IA ni MCP.
- No incorpora recovery automático ni retry.
- No cambia `plugin.json`.

### Verificación

- `pruebas/unitarias/Test-PluginFrameworkMaturity.ps1`
- `pruebas/unitarias/Test-PluginObservability.ps1`
- `scripts/Test-HermesEnterprise.ps1`

---

## ADR-0010: Observabilidad mínima del Plugin Framework

### Estado

Aceptada.

### Contexto

El Plugin Framework ya cuenta con discovery, manifiestos, SemVer, ciclo de vida, Sandbox v1 y política explícita de fallas. Antes de integrar proveedores reales, la Fase 2.5 requiere que un desarrollador pueda consultar el estado operativo de plugins sin modificar el Kernel.

### Decisión

Agregar observabilidad local al Plugin Framework mediante:

- `HoraInicio`, `HoraFin` y `DuracionMilisegundos` en el contexto de ciclo de vida del plugin.
- Consulta `Get-HermesEnterprisePluginObservability` en `PluginManager`.
- Reporte de totales de plugins cargados, `Faulted`, deshabilitados y acción de política aplicada.
- Detalle por plugin con estado, sandbox, política, tiempos y cantidad de errores.

### Límites

- No se modifica comportamiento del Kernel.
- No se agrega recuperación automática.
- No se agrega retry.
- No se integran proveedores reales, IA, Azure Foundry ni MCP.
- No se cambia `plugin.json`.

### Verificación

- `pruebas/unitarias/Test-PluginObservability.ps1`
- `pruebas/unitarias/Test-PluginFaultPolicy.ps1`
- `pruebas/unitarias/Test-PluginManager.ps1`

---

## ADR-0009: Política explícita de manejo de plugins Faulted

### Estado

Aceptada.

### Contexto

Sandbox v1 ya evita que un plugin defectuoso detenga la carga de otros plugins. La Fase 2.4 requiere hacer explícita la decisión operativa ante un plugin en estado `Faulted` sin implementar todavía recovery, retry ni aislamiento pesado.

### Decisión

Agregar `motor/lifecycle/PluginFaultPolicy.ps1` como componente pequeño con tres acciones permitidas:

- `Continue`: conservar el comportamiento actual y continuar con otros plugins.
- `Disable`: marcar el plugin defectuoso como deshabilitado para diagnóstico y operación posterior.
- `Abort`: detener explícitamente la inicialización ante una falla de plugin.

La política se conecta al `LifecycleManager` y al `PluginManager`. La acción predeterminada es `Continue` para mantener compatibilidad.

### Límites

- No se implementa retry.
- No se implementa recovery automático.
- No se implementa hot reload ni auto restart.
- No se agregan procesos, runspaces, jobs ni contenedores.
- No se cambia `plugin.json`.
- No se modifican contratos públicos del Kernel.

### Verificación

- `pruebas/unitarias/Test-PluginFaultPolicy.ps1`
- `pruebas/unitarias/Test-PluginSandbox.ps1`
- `pruebas/unitarias/Test-PluginManager.ps1`

---

## ADR-0008: Sandbox v1 de plugins por aislamiento lógico de errores

### Estado

Aceptada.

### Contexto

El Plugin Framework ya descubre, valida, ordena y ejecuta plugins. La Fase 2.3 requiere evitar que un plugin defectuoso detenga al PluginManager o al Kernel sin introducir todavía un sandbox pesado.

### Decisión

Agregar Sandbox v1 en `motor/lifecycle/LifecycleManager.ps1` mediante `try/catch` alrededor del ciclo de vida del plugin.

Cuando una etapa falla:

- El contexto del plugin queda con `EstadoActual = Faulted`.
- El contexto del plugin queda con `EstadoSandbox = Faulted`.
- El error se conserva en `ErroresSandbox` con etapa, tipo y mensaje.
- El PluginManager continúa con los demás plugins.

### Límites

- No se aíslan procesos.
- No se crean runspaces, jobs, AppDomains ni contenedores.
- No se ejecuta PowerShell separado.
- No se cambia `plugin.json`.
- No se modifican contratos públicos del Kernel.

### Verificación

- `pruebas/unitarias/Test-PluginSandbox.ps1`
- `pruebas/unitarias/Test-Lifecycle.ps1`
- `pruebas/unitarias/Test-PluginManager.ps1`

---

## ADR-0007: Validación SemVer estricta para plugins

### Estado

Aceptada.

### Contexto

El Enterprise Plugin Framework ya valida compatibilidad mínima contra el Kernel. La Fase 2.2 requiere hacer explícito que las versiones de plugins usan SemVer de tres segmentos sin cambiar el formato existente de `plugin.json`.

### Decisión

Agregar validación estricta `Major.Minor.Patch` en `motor/validation/VersionValidator.ps1` mediante una comprobación de formato previa y conversión tipada con `[version]`.

El `ManifestLoader` reutiliza la validación para los campos existentes:

- `Version`.
- `KernelMinimo`.

No se agrega ningún campo nuevo al manifiesto.

### Consecuencias positivas

- Los errores de versión son más descriptivos.
- Se evita aceptar versiones abreviadas ambiguas como `1.2`.
- Los manifiestos actuales siguen siendo compatibles.

### Límites

- No se implementa sandbox ni recovery en esta decisión.
- No se introduce proveedor externo ni IA.
- No se modifica el contrato público del Kernel.

### Verificación

- `pruebas/unitarias/Test-VersionValidator.ps1`
- `pruebas/unitarias/Test-Manifest.ps1`
- `pruebas/unitarias/Test-PluginManager.ps1`

---

## ADR-0006: Smoke Test Enterprise como certificado de madurez del Kernel

### Estado

Aceptada.

### Contexto

Después de consolidar Bootstrap, Kernel, Runtime, PluginManager, Logger, EventBus, Health Monitor y Metrics, HERMES-ENTERPRISE necesita demostrar que los componentes funcionan como sistema integrado antes de iniciar fases de robustez avanzada o proveedores de IA.

### Decisión

Crear una prueba de integración completa:

```powershell
pruebas/integracion/Test-FullKernel.ps1
```

Crear un script público de ejecución:

```powershell
scripts/Test-HermesEnterprise.ps1
```

Agregar funciones auxiliares no disruptivas en `motor/kernel/KernelValidator.ps1`:

```powershell
Test-HermesEnterpriseKernelReady
Get-HermesEnterpriseKernelSummary
```

La prueba integral valida arranque, servicios registrados, plugins, logger, eventos, health, métricas, documentación idempotente y shutdown.

### Consecuencias positivas

- HERMES-ENTERPRISE obtiene una línea base certificada del núcleo.
- Las fases futuras podrán detectar regresiones de integración rápidamente.
- Se mantiene la estrategia incremental sin introducir IA ni proveedores externos.

### Límites

- La prueba no reemplaza pruebas unitarias.
- La prueba no valida comportamiento de proveedores de IA.
- La prueba no agrega sandbox de plugins; eso queda para Fase 2.

### Verificación

- `pruebas/integracion/Test-FullKernel.ps1`
- `scripts/Test-HermesEnterprise.ps1`
- Suite completa en `pruebas/unitarias/Test-*.ps1`

---

## ADR-0005: Observabilidad interna incremental del Kernel

### Estado

Aceptada.

### Contexto

HERMES-ENTERPRISE requiere fortalecer el Kernel antes de incorporar inteligencia artificial, MCP distribuido, A2A o proveedores externos.

La línea base existente ya contiene Kernel, Runtime, Logger, EventBus, Configuration, Dependency Container, Service Locator y PluginManager. La evolución debe ser incremental y no debe romper compatibilidad.

### Decisión

Agregar observabilidad interna mínima al Kernel mediante dos componentes nuevos bajo `motor/kernel`:

- `KernelHealth.ps1`
- `KernelMetrics.ps1`

El Health Monitor expone:

```powershell
Get-HermesEnterpriseKernelHealth
```

Kernel Metrics expone:

```powershell
Write-HermesEnterpriseKernelMetric
```

Ambos componentes se cargan desde Bootstrap y se registran automáticamente en el contenedor de dependencias como servicios internos:

- KernelHealth.
- KernelMetrics.

Las métricas se almacenan mediante Logger Enterprise en formato JSONL, evitando introducir dependencias externas prematuras.

### Consecuencias positivas

- El Kernel gana introspección operativa sin rediseño.
- Se conserva compatibilidad con la arquitectura existente.
- Las métricas iniciales quedan disponibles para fases posteriores de telemetría.
- Las pruebas unitarias pueden validar observabilidad sin proveedores externos.

### Consecuencias y límites

- La observabilidad sigue siendo local y mínima.
- No existe todavía dashboard, exportador OpenTelemetry ni integración cloud.
- La memoria reportada corresponde a memoria administrada del proceso PowerShell mediante .NET GC.

### Alternativas descartadas

- Incorporar observabilidad externa desde esta fase: descartado por exceso de alcance.
- Modificar la estructura pública del Kernel para agregar propiedades nuevas permanentes: descartado para preservar compatibilidad.
- Registrar métricas en archivos separados: descartado porque Logger Enterprise ya es el contrato de persistencia local.

### Verificación

- `pruebas/unitarias/Test-KernelHealth.ps1`
- `pruebas/unitarias/Test-KernelMetrics.ps1`
- `pruebas/unitarias/Test-Kernel.ps1`
- `scripts/Start-HermesEnterprise.ps1`
