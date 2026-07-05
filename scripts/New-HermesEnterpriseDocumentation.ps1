<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : New-HermesEnterpriseDocumentation.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Orquesta el Motor Generador de Documentación Enterprise para construir documentos Markdown
    desde plantillas reutilizables, metadatos centralizados y especificaciones declarativas.

Alcance de Fase 0.2:
    - Crear infraestructura del motor documental.
    - Demostrar generación controlada de documentos base mínimos.
    - No generar todavía documentación extensa ni las 300 páginas definitivas.

Características:
    - Idempotente.
    - Sin dependencias externas.
    - Compatible con PowerShell 7.
    - Arquitectura modular basada en builders y plantillas.
====================================================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$VersionProyecto = "1.0.0",

    [Parameter(Mandatory = $false)]
    [switch]$SoloValidar
)

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------------------
# Resolver la raíz del repositorio desde la ubicación del script.
# Esta estrategia permite ejecutar el generador desde cualquier directorio de trabajo.
# -----------------------------------------------------------------------------------------

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScripts

# -----------------------------------------------------------------------------------------
# Importar el constructor documental central.
# El script falla explícitamente si el builder no existe, evitando ejecuciones parciales.
# -----------------------------------------------------------------------------------------

$RutaDocumentBuilder = Join-Path -Path $RutaRaizRepositorio -ChildPath "builders\DocumentBuilder.ps1"

if (-not (Test-Path -Path $RutaDocumentBuilder)) {
    throw "No se encontró el constructor documental requerido: $RutaDocumentBuilder"
}

. $RutaDocumentBuilder

# -----------------------------------------------------------------------------------------
# Declarar rutas requeridas por el motor documental.
# Todas las rutas son relativas al repositorio para evitar acoplamiento con una máquina.
# -----------------------------------------------------------------------------------------

$RutasRequeridasMotorDocumental = @(
    "documentacion",
    "plantillas",
    "builders",
    "scripts",
    "plantillas\DocumentoBase.md.tpl",
    "plantillas\BootstrapEnterprise.md.tpl",
    "plantillas\IndiceDocumentacion.md.tpl",
    "builders\DocumentBuilder.ps1",
    "builders\MarkdownUtilities.ps1",
    "builders\DocumentMetadata.ps1"
)

foreach ($RutaRequeridaMotorDocumental in $RutasRequeridasMotorDocumental) {
    $RutaCompletaRequeridaMotorDocumental = Join-Path -Path $RutaRaizRepositorio -ChildPath $RutaRequeridaMotorDocumental

    if (-not (Test-Path -Path $RutaCompletaRequeridaMotorDocumental)) {
        throw "Falta un componente requerido del motor documental: $RutaRequeridaMotorDocumental"
    }
}

# -----------------------------------------------------------------------------------------
# Definir contenido reutilizable común para evitar duplicación textual entre documentos.
# En fases futuras estos valores podrán venir de configuración centralizada o manifestos.
# -----------------------------------------------------------------------------------------

$DescripcionBibliotecaDocumental = @"
La biblioteca documental de HERMES-ENTERPRISE será generada desde plantillas reutilizables,
metadatos centralizados y especificaciones declarativas. Esta fase crea únicamente la
infraestructura del generador; el contenido extenso se incorporará de forma controlada en fases
posteriores.
"@

$ReferenciasCruzadasBase = @"
- README principal: README.md
- Project Charter: documentacion/PROJECT_CHARTER.md
- Visión: documentacion/VISION.md
- SRS: documentacion/SRS_HERMES_ENTERPRISE.md
- Motor documental: builders/DocumentBuilder.ps1
"@

# -----------------------------------------------------------------------------------------
# Construir especificaciones declarativas de documentos mínimos.
# Cada documento se genera a partir de plantilla y tokens; no se duplica estructura Markdown.
# -----------------------------------------------------------------------------------------

$EspecificacionesDocumentos = @(
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-README" `
        -TituloDocumento "HERMES-ENTERPRISE" `
        -RutaRelativaSalida "README.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -RutaDocumentoSiguiente "documentacion/PROJECT_CHARTER.md" `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Presentar la plataforma empresarial de ingeniería para agentes inteligentes."
            AlcanceDocumento = "Este README es generado por el motor documental y será enriquecido progresivamente."
            ContenidoInicialDocumento = $DescripcionBibliotecaDocumental
            ReferenciasCruzadas = $ReferenciasCruzadasBase
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-INDEX" `
        -TituloDocumento "Índice de Documentación Enterprise" `
        -RutaRelativaSalida "documentacion\README.md" `
        -RutaRelativaPlantilla "plantillas\IndiceDocumentacion.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Biblioteca documental", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Servir como punto de entrada a la biblioteca técnica versionada del proyecto."
            ContenidoInicialDocumento = $DescripcionBibliotecaDocumental
            ReferenciasCruzadas = $ReferenciasCruzadasBase
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-KERNEL" `
        -TituloDocumento "Kernel Enterprise" `
        -RutaRelativaSalida "documentacion\KERNEL.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar el núcleo operativo que coordina configuración, módulos, dependencias, eventos, logging y runtime."
            AlcanceDocumento = "Infraestructura base del Kernel; no incluye todavía Azure Foundry, MCP, memoria, agentes ni herramientas externas."
            ContenidoInicialDocumento = "El Kernel Enterprise se implementa en motor/kernel y se inicia mediante scripts/Start-HermesEnterprise.ps1."
            ReferenciasCruzadas = "- Runtime: documentacion/RUNTIME.md`n- Configuración: documentacion/CONFIGURATION.md`n- Registro de módulos: documentacion/MODULE_REGISTRY.md`n- EventBus: documentacion/EVENT_BUS.md`n- Logger: documentacion/LOGGER.md`n- Bootstrap: documentacion/BOOTSTRAP.md"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-RUNTIME" `
        -TituloDocumento "Runtime Enterprise" `
        -RutaRelativaSalida "documentacion\RUNTIME.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar el ciclo de vida del Runtime del Kernel Enterprise."
            AlcanceDocumento = "Estados Creado, EnEjecucion y Detenido, con publicación de eventos de ciclo de vida."
            ContenidoInicialDocumento = "El Runtime se implementa en motor/runtime/Runtime.ps1 y se orquesta desde el Kernel."
            ReferenciasCruzadas = "- Kernel: documentacion/KERNEL.md`n- EventBus: documentacion/EVENT_BUS.md"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-CONFIGURATION" `
        -TituloDocumento "Configuration Manager" `
        -RutaRelativaSalida "documentacion\CONFIGURATION.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar la administración centralizada de configuración del Kernel Enterprise."
            AlcanceDocumento = "Configuración JSON local idempotente, sin secretos y preparada para evolución futura."
            ContenidoInicialDocumento = "El administrador se implementa en motor/configuracion/ConfigurationManager.ps1."
            ReferenciasCruzadas = "- Kernel: documentacion/KERNEL.md`n- Bootstrap: documentacion/BOOTSTRAP.md"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-MODULE-REGISTRY" `
        -TituloDocumento "Module Registry" `
        -RutaRelativaSalida "documentacion\MODULE_REGISTRY.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar el registro de módulos desacoplados del Kernel Enterprise."
            AlcanceDocumento = "Registro idempotente de nombre, versión, ruta, capacidades y estado de módulos."
            ContenidoInicialDocumento = "El registro se implementa en motor/registro/ModuleRegistry.ps1."
            ReferenciasCruzadas = "- Kernel: documentacion/KERNEL.md`n- Runtime: documentacion/RUNTIME.md"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-EVENT-BUS" `
        -TituloDocumento "Event Bus" `
        -RutaRelativaSalida "documentacion\EVENT_BUS.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar la comunicación desacoplada por eventos dentro del Kernel Enterprise."
            AlcanceDocumento = "Suscripción y publicación de eventos en memoria para infraestructura inicial."
            ContenidoInicialDocumento = "El bus de eventos se implementa en motor/eventos/EventBus.ps1."
            ReferenciasCruzadas = "- Kernel: documentacion/KERNEL.md`n- Runtime: documentacion/RUNTIME.md"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-LOGGER" `
        -TituloDocumento "Logger Enterprise" `
        -RutaRelativaSalida "documentacion\LOGGER.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar el logging estructurado JSONL del Kernel Enterprise."
            AlcanceDocumento = "Registro local de eventos con timestamp, componente, nivel, mensaje, correlationId y datos."
            ContenidoInicialDocumento = "El logger se implementa en motor/logging/Logger.ps1."
            ReferenciasCruzadas = "- Kernel: documentacion/KERNEL.md`n- Observabilidad futura: documentacion/README.md"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-BOOTSTRAP" `
        -TituloDocumento "Bootstrap Enterprise" `
        -RutaRelativaSalida "documentacion\BOOTSTRAP.md" `
        -RutaRelativaPlantilla "plantillas\BootstrapEnterprise.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Secuencia de inicialización", "Contratos de Bootstrap", "Estados del ciclo de arranque", "Eventos publicados", "Métricas y telemetría", "Recuperación ante fallos", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Definir Bootstrap Enterprise como la fase del ciclo de vida mediante la cual nace HERMES-ENTERPRISE. Bootstrap no ejecuta inteligencia artificial, no conversa con proveedores externos y no opera agentes; prepara de forma ordenada el universo mínimo donde Kernel, Runtime, Plugin Manager y componentes posteriores podrán vivir."
            AlcanceDocumento = "Incluye creación de contexto, carga de configuración, creación de registro de módulos, contenedor de dependencias, service locator, logger, event bus, runtime y plugin manager. Excluye todavía ejecución de Azure AI Foundry, MCP, LLMs, workflows productivos y agentes inteligentes."
            SecuenciaInicializacion = @'
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
'@
            ContratosBootstrap = @"
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
"@
            EstadosCicloArranque = @'
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
'@
            EventosPublicados = @"
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
"@
            MetricasTelemetria = @"
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
"@
            RecuperacionFallos = @"
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
"@
            ContenidoInicialDocumento = "La implementación ejecutable vive en motor/bootstrap/Bootstrap.ps1 y se expone mediante scripts/Start-HermesEnterprise.ps1. El script de entrada no contiene la arquitectura de arranque; delega en Bootstrap, que a su vez crea Contexto y Kernel. El algoritmo concreto de inicialización se ejecuta principalmente en Start-HermesEnterpriseKernel dentro de motor/kernel/Kernel.ps1."
            ReferenciasCruzadas = "- Kernel: documentacion/KERNEL.md`n- Configuration: documentacion/CONFIGURATION.md`n- Runtime: documentacion/RUNTIME.md`n- Logger: documentacion/LOGGER.md`n- EventBus: documentacion/EVENT_BUS.md`n- Module Registry: documentacion/MODULE_REGISTRY.md`n- Plugin Manager: documentacion/PLUGIN_MANAGER.md`n- Provider Registry: documentacion/PROVIDER_REGISTRY.md"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-PLUGIN-FRAMEWORK" `
        -TituloDocumento "Enterprise Plugin Framework" `
        -RutaRelativaSalida "documentacion\PLUGIN_FRAMEWORK.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar el marco de extensibilidad por plugins desacoplados del Kernel Enterprise."
            AlcanceDocumento = "Discovery, manifests, contratos, dependencias, ciclo de vida, provider registry y plugin de ejemplo."
            ContenidoInicialDocumento = "El framework se implementa en motor/plugins, motor/discovery, motor/manifest, motor/lifecycle, motor/contracts, motor/dependencygraph, motor/providers y motor/validation."
            ReferenciasCruzadas = "- Plugin Manifest: documentacion/PLUGIN_MANIFEST.md`n- Plugin Contracts: documentacion/PLUGIN_CONTRACTS.md`n- Plugin Lifecycle: documentacion/PLUGIN_LIFECYCLE.md`n- Plugin Discovery: documentacion/PLUGIN_DISCOVERY.md`n- Plugin Manager: documentacion/PLUGIN_MANAGER.md`n- Provider Registry: documentacion/PROVIDER_REGISTRY.md"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-PLUGIN-MANIFEST" `
        -TituloDocumento "Plugin Manifest" `
        -RutaRelativaSalida "documentacion\PLUGIN_MANIFEST.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar el contrato plugin.json usado por plugins Enterprise."
            AlcanceDocumento = "Nombre, versión, autor, Kernel mínimo, dependencias, eventos, servicios, configuración y permisos."
            ContenidoInicialDocumento = "La carga se implementa en motor/manifest/ManifestLoader.ps1 y se valida con HelloPlugin."
            ReferenciasCruzadas = "- Plugin Framework: documentacion/PLUGIN_FRAMEWORK.md`n- HelloPlugin: plugins/HelloPlugin/plugin.json"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-PLUGIN-CONTRACTS" `
        -TituloDocumento "Plugin Contracts" `
        -RutaRelativaSalida "documentacion\PLUGIN_CONTRACTS.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar contratos lógicos IPlugin, IProvider, ITool, IAgent e IExtension en PowerShell."
            AlcanceDocumento = "Validación basada en funciones requeridas porque PowerShell no define interfaces clásicas para scripts."
            ContenidoInicialDocumento = "El contrato IPlugin exige Install, Initialize, Start, Pause, Resume, Stop y Dispose por convención de nombres."
            ReferenciasCruzadas = "- Lifecycle: documentacion/PLUGIN_LIFECYCLE.md`n- Contracts: motor/contracts/PluginContracts.ps1"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-PLUGIN-LIFECYCLE" `
        -TituloDocumento "Plugin Lifecycle" `
        -RutaRelativaSalida "documentacion\PLUGIN_LIFECYCLE.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar el ciclo de vida estándar de plugins Enterprise."
            AlcanceDocumento = "Install, Initialize, Start, Pause, Resume, Stop y Dispose."
            ContenidoInicialDocumento = "El gestor se implementa en motor/lifecycle/LifecycleManager.ps1."
            ReferenciasCruzadas = "- Plugin Manager: documentacion/PLUGIN_MANAGER.md`n- HelloPlugin: plugins/HelloPlugin/HelloPlugin.ps1"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-PLUGIN-DISCOVERY" `
        -TituloDocumento "Plugin Discovery" `
        -RutaRelativaSalida "documentacion\PLUGIN_DISCOVERY.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar el descubrimiento automático de plugins por manifiestos plugin.json."
            AlcanceDocumento = "Búsqueda recursiva bajo plugins/ y creación de objetos PluginDescubierto."
            ContenidoInicialDocumento = "El discovery se implementa en motor/discovery/PluginDiscovery.ps1."
            ReferenciasCruzadas = "- Plugin Manifest: documentacion/PLUGIN_MANIFEST.md`n- Plugin Manager: documentacion/PLUGIN_MANAGER.md"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-PLUGIN-MANAGER" `
        -TituloDocumento "Plugin Manager" `
        -RutaRelativaSalida "documentacion\PLUGIN_MANAGER.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar el administrador que descubre, valida, ordena, carga e inicializa plugins."
            AlcanceDocumento = "Orquesta discovery, dependency graph, version validator, contracts, lifecycle y provider registry."
            ContenidoInicialDocumento = "El administrador se implementa en motor/plugins/PluginManager.ps1 y se integra al Kernel."
            ReferenciasCruzadas = "- Kernel: documentacion/KERNEL.md`n- Provider Registry: documentacion/PROVIDER_REGISTRY.md"
        }),
    (New-HermesEnterpriseDocumentSpecification `
        -IdentificadorDocumento "DOC-PROVIDER-REGISTRY" `
        -TituloDocumento "Provider Registry" `
        -RutaRelativaSalida "documentacion\PROVIDER_REGISTRY.md" `
        -RutaRelativaPlantilla "plantillas\DocumentoBase.md.tpl" `
        -NombresSeccionesDocumento @("Propósito", "Alcance", "Contenido inicial", "Referencias cruzadas") `
        -ValoresAdicionalesPlantilla @{
            PropositoDocumento = "Documentar el registro de proveedores aportados por plugins."
            AlcanceDocumento = "Registro inicial de proveedores en memoria para desacoplar futuros Azure, OpenAI, MCP, Ollama y otros."
            ContenidoInicialDocumento = "El registro se implementa en motor/providers/ProviderRegistry.ps1."
            ReferenciasCruzadas = "- Plugin Manager: documentacion/PLUGIN_MANAGER.md`n- HelloPlugin: plugins/HelloPlugin/README.md"
        })
)

# -----------------------------------------------------------------------------------------
# Si se solicita solo validación, terminar después de verificar dependencias y especificaciones.
# -----------------------------------------------------------------------------------------

if ($SoloValidar.IsPresent) {
    Write-Host "Motor documental validado correctamente." -ForegroundColor Green
    Write-Host "Repositorio : $RutaRaizRepositorio"
    Write-Host "Documentos  : $($EspecificacionesDocumentos.Count)"
    return
}

# -----------------------------------------------------------------------------------------
# Ejecutar la generación de documentos mínimos.
# Cada documento se escribe de forma idempotente; archivos sin cambios no se reescriben.
# -----------------------------------------------------------------------------------------

$CantidadDocumentosActualizados = 0

foreach ($EspecificacionDocumento in $EspecificacionesDocumentos) {
    $DocumentoFueActualizado = Invoke-HermesEnterpriseDocumentBuild `
        -EspecificacionDocumento $EspecificacionDocumento `
        -RutaRaizRepositorio $RutaRaizRepositorio `
        -VersionProyecto $VersionProyecto

    if ($DocumentoFueActualizado) {
        $CantidadDocumentosActualizados++
    }
}

# -----------------------------------------------------------------------------------------
# Mostrar resumen final para uso local y automatización futura en CI.
# -----------------------------------------------------------------------------------------

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "Motor documental ejecutado correctamente." -ForegroundColor Green
Write-Host "Repositorio             : $RutaRaizRepositorio"
Write-Host "Documentos declarados   : $($EspecificacionesDocumentos.Count)"
Write-Host "Documentos actualizados : $CantidadDocumentosActualizados"
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
