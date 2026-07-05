# CHANGELOG

Todas las notas de cambio relevantes de HERMES-ENTERPRISE se documentan en este archivo.

## [0.6.4] - 2026-07-05

### Agregado

- Fase 4.5: observabilidad y seguridad de logs del Azure Foundry Provider.
- `CorrelationId` por operación para trazabilidad end-to-end.
- Nuevo módulo `motor/providers/AzureFoundryTelemetry.ps1`.
- Registro de métricas: deployment, latencia, tokens de entrada/salida, costo estimado, modelo y estado.
- Sanitización de secretos en logs (api-key, token, authorization, password, secret, credential).
- Respuesta unificada del cliente REST: `{ Success, StatusCode, Data, LatenciaMs, Error, CorrelationId }`.
- Manejo centralizado de errores HTTP en `AzureFoundryRest.ps1`.
- `Write-HermesEnterpriseLogEvent` ahora acepta `CorrelationId` opcional manteniendo compatibilidad.
- Nueva prueba `Test-AzureFoundryProviderTelemetry.ps1` valida latencia, tokens, costo y secreto-safe logs.

### Compatibilidad

- No se modifican contratos públicos del Kernel, Plugin Framework ni Provider Framework.
- No se implementa Streaming, Responses API avanzada, Tool Calling, Agents, MCP ni Embeddings.

## [0.6.3] - 2026-07-05

### Agregado

- Fase 4.4: refactorización arquitectónica del Azure Foundry Provider.
- Nuevos módulos de seguridad:
  - `motor/security/AzureAdResolver.ps1`
  - `motor/security/KeyVaultResolver.ps1`
  - `motor/security/CredentialResolver.ps1`
- Nuevos módulos de provider:
  - `motor/providers/AzureFoundryRest.ps1`
  - `motor/providers/AzureFoundryHealth.ps1`
  - `motor/providers/AzureFoundryDeployment.ps1`
  - `motor/providers/AzureFoundryChat.ps1`
- `AzureFoundryProvider.ps1` ahora es exclusivamente un orquestador.
- Documentación: ADR-0012 en `ARCHITECTURE_DECISIONS.md` y nuevo `PROVIDER_FRAMEWORK.md`.

### Corregido

- Sin cambios funcionales; comportamiento observable idéntico.

### Compatibilidad

- No se modifican contratos públicos del Kernel, Plugin Framework ni Provider Framework.
- No se implementa Streaming, Responses API, Tool Calling, Agents, MCP ni Embeddings.

## [0.6.2] - 2026-07-05

### Agregado

- Fase 4.3: primer Chat real con Azure AI Foundry.
- `Invoke-AzureFoundryChat` envía mensaje a `ur-hermes-mini` y recibe respuesta del modelo `gpt-5-mini`.

### Corregido

- Parámetro de chat cambiado de `max_tokens` a `max_completion_tokens` para compatibilidad con modelos GPT-5.

### Compatibilidad

- No se implementa Streaming, Responses API, Tool Calling, Agents, MCP ni Embeddings.
- No se persisten credenciales en archivos.

## [0.6.1] - 2026-07-05

### Agregado

- Fase 4.2: integración segura con Azure AI Foundry mediante Azure AD y Azure Key Vault.
- Nueva prueba TDD `Test-AzureFoundryProviderConnection.ps1` para conexión real.
- `AzureFoundryProvider` ahora resuelve secretos únicamente desde Azure Key Vault durante la ejecución.
- Prioridad de autenticación: Azure AD (`az account get-access-token`) primero; si falla, API Key desde Key Vault.
- Fallback a Azure Management API para descubrimiento de deployments cuando el endpoint de datos requiere RBAC adicional.
- Deployments detectados en el recurso Modelo-IA-UR incluyen `ur-hermes-mini` y `ur-hermes-coder`.

### Compatibilidad

- No se escriben credenciales en `.env`, `config.yaml` ni archivos del proyecto.
- No se implementa Chat, Responses, Streaming, Tool Calling, Agents, MCP ni Embeddings.
- No se modifica comportamiento del Kernel ni del Plugin Framework.

## [0.6.0] - 2026-07-05

### Agregado

- Fase 4: primer provider real `AzureFoundryProvider` conectado al Provider Framework.
- Subfase 4.1: conexión, autenticación y descubrimiento automático de deployments.
  - Deployments conocidos: `ur-hermes-mini`, `ur-hermes-coder`, `ur-ep-gpt-5.5`.
  - Comandos públicos: `Connect-AzureFoundryProvider`, `Get-AzureFoundryDeployments`, `Get-AzureFoundryDeploymentDescription`.
- Subfase 4.2: health check real contra `/openai/models` mediante `Invoke-AzureFoundryHealth`.
  - Mapeo de códigos HTTP: 200 Healthy, 401 Invalid Key, 404 Deployment inexistente.
- Subfase 4.3: primer chat completion mediante `Invoke-AzureFoundryChat`.
- Modo simulado para pruebas offline cuando no existen credenciales reales.
- Prueba unitaria `Test-AzureFoundryProvider.ps1` que certifica las tres subfases sin salir de red.
- `Test-HermesEnterprise.ps1` ahora ejecuta además las pruebas del Provider Framework.

### Compatibilidad

- No se modifica comportamiento del Kernel ni del Plugin Framework.
- No se incorpora Model Router, streaming, tool calling, agents ni recovery automático.
- Las credenciales se leen únicamente de variables de entorno y nunca se almacenan en el contexto del provider.

## [0.5.6] - 2026-07-04

### Agregado

- Fase 2.6: reporte consolidado de madurez y compatibilidad del Plugin Framework.
- Nueva consulta `Get-HermesEnterprisePluginFrameworkMaturityReport` para certificar capacidades implementadas y límites explícitos.
- Prueba unitaria `Test-PluginFrameworkMaturity.ps1` para validar estado de madurez, capacidades, límites y próxima fase recomendada.

### Compatibilidad

- No se modifica comportamiento del Kernel.
- No se incorporan proveedores reales, Azure Foundry, IA, MCP, recovery automático ni retry.
- No se modifica el formato actual de `plugin.json`.

## [0.5.5] - 2026-07-04

### Agregado

- Fase 2.5: observabilidad mínima del Plugin Framework.
- Nueva consulta `Get-HermesEnterprisePluginObservability` para reportar plugins cargados, `Faulted`, deshabilitados y política aplicada.
- Registro de `HoraInicio`, `HoraFin` y `DuracionMilisegundos` por ciclo de vida de plugin.
- Prueba unitaria `Test-PluginObservability.ps1` para validar estado, política, errores y tiempos.

### Compatibilidad

- No se modifica comportamiento del Kernel.
- No se incorpora recovery automático, retry, proveedores reales, IA, Azure Foundry ni MCP.
- No se modifica el formato actual de `plugin.json`.

## [0.5.4] - 2026-07-04

### Agregado

- Fase 2.4: política explícita de manejo de plugins en estado `Faulted`.
- Nuevo componente `PluginFaultPolicy` con acciones permitidas `Continue`, `Disable` y `Abort`.
- Prueba unitaria `Test-PluginFaultPolicy.ps1` para validar las tres acciones sin recovery automático.

### Compatibilidad

- La acción predeterminada es `Continue`, conservando el comportamiento de Sandbox v1.
- No se incorpora retry, recovery automático, hot reload, auto restart, procesos, runspaces, jobs ni contenedores.
- No se modifica el formato actual de `plugin.json` ni contratos públicos del Kernel.

## [0.5.3] - 2026-07-04

### Agregado

- Fase 2.3: Sandbox v1 inicial para aislamiento lógico de errores de plugins.
- Estado `Faulted` y registro diagnóstico `ErroresSandbox` en el contexto de ciclo de vida del plugin.
- Prueba unitaria `Test-PluginSandbox.ps1` para validar que un plugin defectuoso no detiene la carga de otros plugins válidos.

### Compatibilidad

- No se incorpora aislamiento por procesos, runspaces, jobs, contenedores ni PowerShell separado.
- No se modifica el formato actual de `plugin.json`.
- No se modifica Bootstrap, Kernel público, Runtime, Logger, EventBus, Dependency Container ni Service Locator.

## [0.5.2] - 2026-07-04

### Agregado

- Fase 2.2: validación SemVer explícita para plugins.
- Validación `Major.Minor.Patch` mediante `[version]` y verificación previa de formato estricto.
- Errores descriptivos para versiones de plugin o Kernel mínimo con formato inválido.

### Compatibilidad

- Se mantiene el formato actual de `plugin.json`.
- No se modifican APIs públicas existentes del Kernel.
- No se incorpora sandbox, recovery, Azure Foundry, IA, MCP, providers ni agentes.

## [0.5.1] - 2026-07-04

### Agregado

- Fase 1.6: Smoke Test Enterprise del Kernel.
- Primera prueba de integración completa en `pruebas/integracion/Test-FullKernel.ps1`.
- Script público `scripts/Test-HermesEnterprise.ps1` para ejecutar la validación integral.
- Función auxiliar `Test-HermesEnterpriseKernelReady` para verificar servicios requeridos.
- Función auxiliar `Get-HermesEnterpriseKernelSummary` para resumir estado, servicios, plugins, eventos y métricas.

### Validación

- La integración valida Bootstrap, Kernel, Configuration, Dependency Injection, Service Locator, Logger, EventBus, Runtime, PluginManager, Health Monitor, Metrics, Documentation Engine y Shutdown.

### Compatibilidad

- No se incorporó Azure Foundry, MCP, A2A, IA ni proveedores externos.
- No se modificaron contratos públicos existentes.
- No se realizaron refactorizaciones masivas.

## [0.5.0] - 2026-07-04

### Agregado

- Fase 1: Observabilidad del Kernel Enterprise.
- Health Monitor del Kernel mediante `Get-HermesEnterpriseKernelHealth`.
- Métricas internas mínimas mediante `Write-HermesEnterpriseKernelMetric`.
- Registro automático de `KernelHealth` y `KernelMetrics` en el contenedor de dependencias del Kernel.
- Métrica automática `Kernel.Start` almacenada mediante Logger Enterprise como `MetricaKernel`.
- Pruebas unitarias focalizadas para Health Monitor y Kernel Metrics.

### Documentación

- Actualizado `documentacion/KERNEL.md` con Health Monitor, Kernel Metrics, registro automático y métrica inicial de arranque.
- Actualizado `documentacion/SRS_HERMES_ENTERPRISE.md` con requisitos RF/RNF de observabilidad del Kernel.
- Actualizado `documentacion/ARCHITECTURE_DECISIONS.md` con decisión arquitectónica ADR-0005.

### Compatibilidad

- No se eliminaron módulos existentes.
- No se renombraron directorios.
- No se modificaron contratos públicos existentes.
- No se incorporó IA, MCP distribuido, A2A ni proveedores externos.
