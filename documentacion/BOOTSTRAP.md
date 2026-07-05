# Bootstrap Enterprise

| Campo | Valor |
|---|---|
| NombreDocumento | Bootstrap Enterprise |
| Proyecto | HERMES-ENTERPRISE |
| Version | 1.0.0 |
| AutorPrincipal | Fredy Alejandro Sarmiento Torres |
| Licencia | MIT |
| RepositorioOficial | https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE |
| ArquitecturaBase | Hermes Agent + Azure AI Foundry + MCP + A2A |
| FechaGeneracion | 2026-07-05 |
| GeneradoPor | New-HermesEnterpriseDocumentation.ps1 |

## Tabla de contenido

- [Propósito](#proposito)
- [Alcance](#alcance)
- [Secuencia de inicialización](#secuencia-de-inicializacion)
- [Contratos de Bootstrap](#contratos-de-bootstrap)
- [Estados del ciclo de arranque](#estados-del-ciclo-de-arranque)
- [Eventos publicados](#eventos-publicados)
- [Métricas y telemetría](#metricas-y-telemetria)
- [Recuperación ante fallos](#recuperacion-ante-fallos)
- [Contenido inicial](#contenido-inicial)
- [Referencias cruzadas](#referencias-cruzadas)

---

## Navegación

- [Índice de documentación](README.md)

---

## Propósito

Definir Bootstrap Enterprise como la fase del ciclo de vida mediante la cual nace HERMES-ENTERPRISE. Bootstrap no ejecuta inteligencia artificial, no conversa con proveedores externos y no opera agentes; prepara de forma ordenada el universo mínimo donde Kernel, Runtime, Plugin Manager y componentes posteriores podrán vivir.

## Alcance

Incluye creación de contexto, carga de configuración, creación de registro de módulos, contenedor de dependencias, service locator, logger, event bus, runtime y plugin manager. Excluye todavía ejecución de Azure AI Foundry, MCP, LLMs, workflows productivos y agentes inteligentes.

## Secuencia de inicialización

```text
Usuario
↓
scripts/Start-HermesEnterprise.ps1
↓
motor/bootstrap/Bootstrap.ps1
↓
New-HermesEnterpriseKernelContext
↓
New-HermesEnterpriseKernel
↓
Start-HermesEnterpriseKernel
↓
ConfigurationManager
↓
ModuleRegistry
↓
DependencyContainer
↓
ServiceLocator
↓
Logger
↓
EventBus
↓
Runtime
↓
PluginManager
↓
Initialize-HermesEnterprisePlugins
↓
Start-HermesEnterpriseRuntime
↓
Kernel.Iniciado
↓
Sistema listo
```

Orden normativo:

1. Resolver la raíz del repositorio desde el script de entrada.
2. Importar Bootstrap y validadores mínimos.
3. Construir KernelContext con rutas, entorno, versión e identificador de correlación.
4. Construir el objeto Kernel en estado Creado.
5. Cargar configuración local del Kernel.
6. Crear registro de módulos y mecanismos de dependencias.
7. Crear Logger antes de registrar eventos operativos persistentes.
8. Crear EventBus antes de iniciar Runtime o publicar eventos.
9. Crear Runtime en estado Creado.
10. Crear PluginManager para preparar discovery, contratos, lifecycle y provider registry.
11. Registrar servicios base en el contenedor de dependencias.
12. Registrar el módulo Kernel en ModuleRegistry.
13. Descubrir, ordenar, validar, cargar e inicializar plugins.
14. Iniciar Runtime.
15. Registrar log de arranque exitoso.
16. Publicar evento Kernel.Iniciado.
17. Marcar Kernel como Iniciado.

## Contratos de Bootstrap

| Etapa | Precondición | Postcondición | Regla de bloqueo |
|---|---|---|---|
| Entrada | Ruta raíz recibida y no vacía | Ruta raíz normalizada | No continuar si la ruta no puede resolverse. |
| Contexto | Ruta raíz válida | Contexto con rutas de motor, configuración y logs | No crear Kernel sin ContextoKernel. |
| Configuración | Contexto disponible | ConfigurationManager y Configuracion cargados | No iniciar Runtime sin configuración. |
| Registro | Kernel creado | ModuleRegistry disponible | No declarar módulos si el registro no existe. |
| Dependencias | Registro disponible | DependencyContainer y ServiceLocator creados | No registrar servicios sin contenedor. |
| Logger | Ruta de logs disponible | Logger JSONL operativo | No declarar arranque exitoso sin Logger. |
| EventBus | Logger y dependencias base creadas | EventBus en memoria operativo | No iniciar Runtime sin EventBus. |
| Runtime | EventBus operativo | Runtime en estado Creado | No iniciar plugins que dependan del Runtime si no existe. |
| PluginManager | Ruta de plugins y versión Kernel disponibles | Manager con ProviderRegistry disponible | No descubrir plugins sin ruta raíz y versión Kernel. |
| Plugins | Manager operativo | Plugins compatibles inicializados o falla controlada | No registrar proveedores de plugins inválidos. |
| Inicio Runtime | Plugins inicializados | Runtime en estado EnEjecucion | No publicar Kernel.Iniciado si Runtime no inició. |
| Ready | Runtime iniciado y evento publicado | Kernel en estado Iniciado | No considerar listo un Kernel parcialmente inicializado. |

Todo contrato debe ser verificable por pruebas unitarias o validadores de fase. En versiones posteriores, estas reglas podrán convertirse en aserciones ejecutables del propio Bootstrap.

## Estados del ciclo de arranque

```text
BOOTING
↓
CONTEXT_CREATED
↓
CONFIGURATION_LOADED
↓
SERVICES_REGISTERED
↓
PLUGIN_MANAGER_CREATED
↓
PLUGINS_DISCOVERED
↓
PLUGINS_INITIALIZED
↓
RUNTIME_STARTED
↓
READY
```

Mapeo actual de implementación:

| Estado arquitectónico | Evidencia actual |
|---|---|
| BOOTING | Invocación de Start-HermesEnterpriseBootstrap. |
| CONTEXT_CREATED | Objeto retornado por New-HermesEnterpriseKernelContext. |
| CONFIGURATION_LOADED | Propiedad Configuracion del Kernel poblada. |
| SERVICES_REGISTERED | Servicios base registrados en DependencyContainer. |
| PLUGIN_MANAGER_CREATED | Propiedad PluginManager del Kernel poblada. |
| PLUGINS_DISCOVERED | Find-HermesEnterprisePlugins ejecutado por PluginManager. |
| PLUGINS_INITIALIZED | PluginsCargados actualizado por Initialize-HermesEnterprisePlugins. |
| RUNTIME_STARTED | Runtime.EstadoRuntime igual a EnEjecucion. |
| READY | Kernel.EstadoKernel igual a Iniciado. |

## Eventos publicados

Eventos implementados actualmente:

| Evento | Publicador | Momento |
|---|---|---|
| Runtime.Iniciado | Runtime | Cuando Runtime cambia a EnEjecucion. |
| Runtime.Detenido | Runtime | Cuando Runtime cambia a Detenido. |
| Kernel.Iniciado | Kernel | Después de iniciar Runtime y escribir log de inicio. |

Eventos normativos propuestos para completar la telemetría de Bootstrap:

| Evento | Propósito |
|---|---|
| Bootstrap.Starting | Marcar inicio del proceso de nacimiento del sistema. |
| Bootstrap.ContextCreated | Confirmar creación de KernelContext. |
| Bootstrap.ConfigurationLoaded | Confirmar carga de configuración. |
| Bootstrap.LoggerCreated | Confirmar disponibilidad de logging. |
| Bootstrap.EventBusReady | Confirmar disponibilidad del bus de eventos. |
| Bootstrap.RuntimeReady | Confirmar creación del Runtime antes de iniciarlo. |
| Bootstrap.PluginDiscoveryStarted | Medir inicio de discovery de plugins. |
| Bootstrap.PluginDiscoveryFinished | Registrar conteo y duración de discovery. |
| Bootstrap.Completed | Marcar transición a Ready. |
| Bootstrap.Failed | Registrar etapa, excepción y decisión de recuperación. |

## Métricas y telemetría

La fase Bootstrap debe producir telemetría mínima para que el arranque sea observable y comparable entre versiones.

| Métrica | Unidad | Objetivo inicial | Uso |
|---|---:|---:|---|
| bootstrap.context.duration | ms | 5 | Detectar problemas de resolución de rutas o entorno. |
| bootstrap.configuration.duration | ms | 8 | Detectar configuración pesada o corrupta. |
| bootstrap.logger.duration | ms | 2 | Confirmar creación rápida de infraestructura de logs. |
| bootstrap.eventbus.duration | ms | 2 | Confirmar disponibilidad de eventos en memoria. |
| bootstrap.plugin.discovery.duration | ms | 40 | Medir crecimiento del ecosistema de plugins. |
| bootstrap.plugin.initialization.duration | ms | 100 | Detectar plugins lentos o bloqueantes. |
| bootstrap.runtime.start.duration | ms | 15 | Controlar costo de transición a EnEjecucion. |
| bootstrap.total.duration | ms | 250 | Medir el tiempo total hasta Ready. |

Dimensiones recomendadas:

- VersionKernel.
- NombreEntorno.
- IdentificadorContexto.
- NombreEtapaBootstrap.
- Resultado: Success, Degraded o Failed.
- CantidadPluginsDescubiertos.
- CantidadPluginsInicializados.

## Recuperación ante fallos

| Punto de fallo | Acción normativa | Resultado esperado |
|---|---|---|
| Ruta raíz inválida | Abort | No crear contexto parcial. |
| Configuración ausente | Degrade/CreateDefault cuando el ConfigurationManager lo permita | Continuar con configuración local mínima. |
| Configuración corrupta | Abort | Evitar iniciar Kernel con parámetros ambiguos. |
| Logger no puede crear archivo | Abort | No operar sin trazabilidad mínima. |
| EventBus no disponible | Abort | No iniciar Runtime ni plugins sin eventos. |
| Plugin incompatible con versión Kernel | Abort en fase actual | Evitar cargar extensiones fuera de contrato. |
| Plugin no cumple contrato | Abort en fase actual | Evitar estados semiválidos. |
| Plugin opcional falla | Degrade en fase futura | Continuar sin la capacidad opcional y publicar Bootstrap.Failed/Degraded. |
| Provider externo no disponible | Defer en fase futura | No bloquear Bootstrap; el provider se valida al activarse. |
| Runtime no inicia | Abort | No publicar Kernel.Iniciado ni marcar Ready. |

La regla general es: si falla infraestructura base, el arranque se aborta; si falla una capacidad opcional futura, el sistema puede degradarse siempre que quede documentado por eventos, logs y estado explícito.

## Contenido inicial

La implementación ejecutable vive en motor/bootstrap/Bootstrap.ps1 y se expone mediante scripts/Start-HermesEnterprise.ps1. El script de entrada no contiene la arquitectura de arranque; delega en Bootstrap, que a su vez crea Contexto y Kernel. El algoritmo concreto de inicialización se ejecuta principalmente en Start-HermesEnterpriseKernel dentro de motor/kernel/Kernel.ps1.

## Referencias cruzadas

- Kernel: documentacion/KERNEL.md
- Configuration: documentacion/CONFIGURATION.md
- Runtime: documentacion/RUNTIME.md
- Logger: documentacion/LOGGER.md
- EventBus: documentacion/EVENT_BUS.md
- Module Registry: documentacion/MODULE_REGISTRY.md
- Plugin Manager: documentacion/PLUGIN_MANAGER.md
- Provider Registry: documentacion/PROVIDER_REGISTRY.md

---

> Documento generado automáticamente por el Motor Generador de Documentación Enterprise.
> No editar manualmente contenido generado; modificar plantillas o especificaciones.

