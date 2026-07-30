# KERNEL CONTRACT SPECIFICATION

| Campo | Valor |
|---|---|
| Nombre | Hermes Enterprise — Kernel Contract Specification |
| Versión | RC14.0 |
| Estado | **CONGELADO** — Contract First |
| Principio | Ningún componente depende de implementaciones concretas |
| Vigencia | A partir de esta especificación, todo nuevo componente debe existir primero como contrato |

---

## Tabla de contenidos

1. [Principios del Contracto](#1-principios-del-contrato)
2. [Convenciones](#2-convenciones)
3. [Kernel](#3-kernel)
4. [Runtime](#4-runtime)
5. [Context](#5-context)
6. [Dependency Injection](#6-dependency-injection)
7. [EventBus](#7-eventbus)
8. [Configuration](#8-configuration)
9. [Logging](#9-logging)
10. [Observability](#10-observability)
11. [Metrics](#11-metrics)
12. [Health](#12-health)
13. [Registry](#13-registry)
14. [Security](#14-security)
15. [Identity](#15-identity)
16. [Session](#16-session)
17. [Pipeline](#17-pipeline)
18. [Engine](#18-engine)
19. [Provider](#19-provider)
20. [Bootstrap](#20-bootstrap)
21. [Workspace](#21-workspace)
22. [Environment](#22-environment)
23. [Template](#23-template)
24. [Validation](#24-validation)
25. [Documentation](#25-documentation)
26. [Reporting](#26-reporting)
27. [Testing](#27-testing)
28. [Recovery](#28-recovery)
29. [Publishing](#29-publishing)
30. [Deployment](#30-deployment)
31. [Cloud](#31-cloud)
32. [Azure](#32-azure)
33. [Git](#33-git)
34. [GitHub](#34-github)
35. [Storage](#35-storage)
36. [DataLake](#36-datalake)
37. [Blob](#37-blob)
38. [Database](#38-database)
39. [AI](#39-ai)
40. [Messaging](#40-messaging)
41. [Plugins](#41-plugins)
42. [Capabilities](#42-capabilities)
43. [Discovery](#43-discovery)
44. [Scheduler](#44-scheduler)
45. [Manifest](#45-manifest)
46. [Apéndice A: Mapa de dependencias entre contratos](#46-apéndice-a-mapa-de-dependencias-entre-contratos)
47. [Apéndice B: Matriz de compatibilidad de versiones](#47-apéndice-b-matriz-de-compatibilidad-de-versiones)
48. [Apéndice C: Glosario de términos](#48-apéndice-c-glosario-de-términos)

---

## 1. Principios del Contrato

### 1.1. Contract First

Todo componente nuevo en Hermes Enterprise **debe existir primero como contrato**. La implementación es siempre posterior y puede ser reemplazada sin cambiar el contrato.

### 1.2. Principios rectores

| # | Principio | Descripción |
|---|---|---|
| P1 | **Program to an interface, not an implementation** | Todo consumo se hace contra el contrato, nunca contra la clase concreta |
| P2 | **Single Responsibility** | Cada contrato define una única responsabilidad |
| P3 | **Interface Segregation** | Los contratos son pequeños y específicos; ningún consumidor depende de métodos que no usa |
| P4 | **Liskov Substitution** | Cualquier implementación de un contrato debe poder reemplazar a otra sin alterar el sistema |
| P5 | **Open/Closed** | Los contratos están abiertos a extensión (herencia) pero cerrados a modificación directa |
| P6 | **Dependency Inversion** | Los módulos de alto nivel no dependen de módulos de bajo nivel; ambos dependen de contratos |
| P7 | **Explicit Contracts** | Todo contrato declara explícitamente precondiciones, postcondiciones e invariantes |
| P8 | **Fail Fast** | Si una precondición no se cumple, el contrato falla inmediatamente con un error explícito |

### 1.3. Reglas de versionado

Los contratos usan versionado semántico estricto (`MAJOR.MINOR.PATCH`):

- **MAJOR**: Cambio incompatible (se elimina o modifica un método, se cambia una pre/postcondición)
- **MINOR**: Adición compatible hacia atrás (nuevo método, nuevo parámetro opcional)
- **PATCH**: Corrección de documentación, aclaración de pre/postcondiciones sin cambio de comportamiento

### 1.4. Reglas de implementación

| Regla | Descripción |
|---|---|
| R1 | Toda implementación debe declarar qué versión del contrato implementa |
| R2 | Una implementación puede implementar múltiples contratos |
| R3 | Una implementación nunca debe exponer métodos públicos adicionales no definidos en el contrato |
| R4 | Si una implementación no puede cumplir una postcondición, debe fallar con el error definido |
| R5 | Las implementaciones deben pasar la suite de pruebas del contrato |

### 1.5. Estructura de cada especificación de contrato

Cada contrato en este documento sigue esta estructura:

```
Nombre
    Identificador único del contrato
Responsabilidad
    Frase que resume qué hace
Propósito
    Párrafo que describe el problema que resuelve
Estado
    [Propuesto | Aprobado | Congelado | Deprecado]
Versión
    Versión semántica actual
Dependencias
    Lista de contratos que necesita
Interfaces relacionadas
    Contratos que extiende o de los que depende lógicamente
Métodos
    Nombre | Entrada | Salida | Descripción
Eventos publicados
    Nombre del evento | Cuándo se publica | Payload
Eventos consumidos
    Nombre del evento | Cuándo se consume | Acción
Errores
    Nombre | Código | Cuándo ocurre
Precondiciones
    Condiciones que deben cumplirse antes de invocar
Postcondiciones
    Estado del sistema después de la ejecución exitosa
Invariantes
    Propiedades que siempre se mantienen
Extensibilidad
    Cómo se puede extender este contrato
Compatibilidad
    Reglas de compatibilidad hacia atrás
Ejemplos de uso
    Pseudocódigo de consumo típico
```

---

## 2. Convenciones

### 2.1. Convención de nomenclatura

| Elemento | Convención | Ejemplo |
|---|---|---|
| Interface (contrato) | Prefijo `I` + PascalCase | `IEngine`, `IGitProvider` |
| Método de contrato | PascalCase | `Initialize()`, `Execute()` |
| Parámetro | PascalCase | `$ProjectName`, `$SourcePath` |
| Evento | `Dominio.Accion.Estado` | `Engine.Started`, `Pipeline.Failed` |
| Código de error | `ERR_DOMINIO_CODIGO` | `ERR_ENGINE_INIT_FAILED` |
| Versión de contrato | `X.Y.Z` | `1.0.0` |

### 2.2. Convención de tipos de datos

| Tipo | Descripción |
|---|---|
| `string` | Cadena de texto Unicode |
| `int` | Entero de 32 bits con signo |
| `long` | Entero de 64 bits con signo |
| `bool` | Valor booleano (`true`/`false`) |
| `datetime` | Fecha y hora en formato ISO 8601 |
| `guid` | Identificador único global |
| `hashtable` | Tabla hash (clave-valor) |
| `object[]` | Arreglo de objetos |
| `string[]` | Arreglo de cadenas |
| `ScriptBlock` | Bloque de código ejecutable |
| `hashtable` | Diccionario de propiedades |
| `psobject` | Objeto genérico de PowerShell |

### 2.3. Convención de errores

Todo error sigue esta estructura:

```
Código: ERR_DOMINIO_NOMBRE
Mensaje: Descripción legible
Causa: Condición que lo dispara
Recuperación: Acción recomendada
```

---

## 3. Kernel

### IKernel

```
Nombre
    IKernel
Responsabilidad
    Coordinar el ciclo de vida completo del sistema Hermes Enterprise
Propósito
    IKernel es el contrato raíz del sistema. Inicializa todos los subsistemas
    (configuración, logging, eventos, runtime, plugins) y expone el estado
    global del sistema. Ningún componente opera fuera del ciclo de vida del Kernel.
Estado
    Congelado
Versión
    1.0.0
Dependencias
    IContext, IConfigurationManager, IServiceContainer, IEventBus,
    ILogger, IRuntime, IRegistry
Interfaces relacionadas
    IComponent (herencia indirecta)
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Initialize()` | Ninguna | `void` | Prepara el Kernel: valida contexto, carga configuración, crea servicios base |
| `Start()` | Ninguna | `void` | Inicia todos los subsistemas registrados en orden de dependencias |
| `Stop()` | Ninguna | `void` | Detiene todos los subsistemas en orden inverso de dependencias |
| `Restart()` | Ninguna | `void` | Reinicia el ciclo completo (Stop + Start) |
| `Dispose()` | Ninguna | `void` | Libera todos los recursos del Kernel |
| `GetState()` | Ninguna | `KernelState` | Devuelve el estado actual del Kernel |
| `GetContext()` | Ninguna | `IContext` | Devuelve el contexto del Kernel |
| `GetServiceContainer()` | Ninguna | `IServiceContainer` | Devuelve el contenedor DI |
| `GetEventBus()` | Ninguna | `IEventBus` | Devuelve el bus de eventos |
| `GetLogger()` | Ninguna | `ILogger` | Devuelve el logger |
| `GetRuntime()` | Ninguna | `IRuntime` | Devuelve el runtime |
| `GetRegistry()` | Ninguna | `IRegistry` | Devuelve el registro de componentes |
| `HealthCheck()` | Ninguna | `HealthReport` | Ejecuta health check completo de todos los subsistemas |

#### KernelState (enum)

| Valor | Descripción |
|---|---|
| `Created` | Kernel instanciado pero no inicializado |
| `Initializing` | Kernel en proceso de inicialización |
| `Initialized` | Kernel inicializado, subsistemas listos |
| `Starting` | Kernel iniciando subsistemas |
| `Running` | Kernel operativo |
| `Stopping` | Kernel deteniendo subsistemas |
| `Stopped` | Kernel detenido |
| `Failed` | Kernel en estado de error crítico |
| `Disposed` | Kernel con recursos liberados |

#### Eventos publicados

| Evento | Cuándo | Payload |
|---|---|---|
| `Kernel.Created` | Después de instanciar | `{ Version, ContextId }` |
| `Kernel.Initialized` | Después de Initialize() | `{ Duration, ServicesCount }` |
| `Kernel.Starting` | Antes de Start() | `{ Timestamp }` |
| `Kernel.Started` | Después de Start() | `{ Duration, RuntimeState }` |
| `Kernel.Stopping` | Antes de Stop() | `{ Reason }` |
| `Kernel.Stopped` | Después de Stop() | `{ Duration }` |
| `Kernel.Failed` | En error crítico | `{ ErrorCode, Message, Stage }` |
| `Kernel.HealthChanged` | Cuando cambia el health status | `{ Previous, Current, Report }` |

#### Errores

| Error | Código | Causa |
|---|---|---|
| KernelInitFailed | `ERR_KERNEL_INIT_FAILED` | Error durante Initialize() |
| KernelStartFailed | `ERR_KERNEL_START_FAILED` | Error durante Start() |
| KernelStopFailed | `ERR_KERNEL_STOP_FAILED` | Error durante Stop() |
| KernelStateTransitionInvalid | `ERR_KERNEL_INVALID_TRANSITION` | Transición de estado no válida |

#### Precondiciones

- El contexto debe ser válido (IContext válido)
- La configuración base debe ser accesible
- El sistema operativo debe soportar las operaciones del Kernel

#### Postcondiciones

- Después de `Start()`: todos los subsistemas están operativos
- Después de `Stop()`: todos los subsistemas están detenidos ordenadamente
- Después de `Dispose()`: todos los recursos están liberados

#### Invariantes

- El Kernel siempre tiene un estado válido (nunca `null`)
- El Kernel nunca expone subsistemas no inicializados
- El ciclo de vida es monotónico: no se puede volver a un estado anterior sin `Restart()`

#### Extensibilidad

- El Kernel acepta proveedores de servicios externos mediante `IServiceContainer`
- Los subsistemas pueden registrarse dinámicamente mediante `IRegistry`
- El health check puede extenderse registrando nuevos health probes

#### Compatibilidad

- `IKernel` versión `1.x` es compatible con todos los subsistemas que implementen contratos `1.x`
- Cambios MAJOR en `IKernel` requieren migración de todos los subsistemas

#### Ejemplos de uso

```powershell
$kernel = New-HermesEnterpriseKernel -Context $context
$kernel.Initialize()
$kernel.Start()
$state = $kernel.GetState()  # Running
$kernel.Stop()
$kernel.Dispose()
```

---

## 4. Runtime

### IRuntime

```
Nombre
    IRuntime
Responsabilidad
    Gestionar la ejecución de todos los componentes activos del sistema
Propósito
    IRuntime orquesta el ciclo de vida operativo de Engines, Providers
    y cualquier componente registrado. Provee el contexto de ejecución,
    maneja pausas/reanudaciones y coordina la finalización ordenada.
Estado
    Congelado
Versión
    1.0.0
Dependencias
    IServiceContainer, IEventBus, ILogger
Interfaces relacionadas
    IComponent (herencia indirecta)
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Start()` | Ninguna | `void` | Inicia la ejecución del Runtime y todos sus componentes |
| `Stop()` | Ninguna | `void` | Detiene la ejecución ordenadamente |
| `Pause()` | Ninguna | `void` | Pausa la ejecución sin detener componentes |
| `Resume()` | Ninguna | `void` | Reanuda la ejecución después de una pausa |
| `GetState()` | Ninguna | `RuntimeState` | Devuelve el estado actual |
| `GetExecutionContext()` | Ninguna | `hashtable` | Devuelve el contexto de ejecución compartido |
| `ExecuteEngine(EngineName, Parameters)` | `string`, `hashtable` | `object` | Ejecuta un motor específico con parámetros |
| `Cancel(OperationId)` | `string` | `bool` | Cancela una operación en curso |
| `GetActiveOperations()` | Ninguna | `object[]` | Lista las operaciones activas |

#### RuntimeState (enum)

| Valor | Descripción |
|---|---|
| `Created` | Runtime instanciado |
| `Starting` | Iniciando componentes |
| `Running` | Ejecutando operaciones |
| `Paused` | Pausado (operaciones suspendidas) |
| `Stopping` | Deteniendo componentes |
| `Stopped` | Detenido |
| `Failed` | Error irrecuperable |

#### Eventos publicados

| Evento | Cuándo | Payload |
|---|---|---|
| `Runtime.Starting` | Antes de Start() | `{ Mode }` |
| `Runtime.Started` | Después de Start() | `{ Duration }` |
| `Runtime.Paused` | Después de Pause() | `{ ActiveOperations }` |
| `Runtime.Resumed` | Después de Resume() | `{ PausedDuration }` |
| `Runtime.Stopping` | Antes de Stop() | `{ Reason }` |
| `Runtime.Stopped` | Después de Stop() | `{ Duration }` |
| `Runtime.Failed` | En error | `{ ErrorCode, Message }` |
| `Runtime.EngineStarted` | Motor iniciado | `{ EngineName, Duration }` |
| `Runtime.EngineCompleted` | Motor completado | `{ EngineName, Result }` |
| `Runtime.EngineFailed` | Motor falló | `{ EngineName, Error }` |

#### Errores

| Error | Código |
|---|---|
| RuntimeStartFailed | `ERR_RUNTIME_START_FAILED` |
| RuntimeStopFailed | `ERR_RUNTIME_STOP_FAILED` |
| RuntimeEngineNotFound | `ERR_RUNTIME_ENGINE_NOT_FOUND` |
| RuntimeEngineExecutionFailed | `ERR_RUNTIME_ENGINE_EXECUTION_FAILED` |
| RuntimeInvalidStateTransition | `ERR_RUNTIME_INVALID_TRANSITION` |

#### Precondiciones

- Runtime no debe estar en estado `Running` o `Stopped` antes de `Start()`
- Todos los engines deben estar registrados en `IServiceContainer`

#### Postcondiciones

- Después de `Start()`: contexto de ejecución disponible
- Después de `Stop()`: todas las operaciones finalizadas o canceladas
- Después de `Pause()`: las operaciones se suspenden (no se cancelan)

#### Invariantes

- El estado del Runtime sigue una máquina de estados finita
- No se puede ejecutar `ExecuteEngine()` si el Runtime no está en `Running` o `Paused`

---

## 5. Context

### IContext

```
Nombre
    IContext
Responsabilidad
    Representar el contexto compartido de ejecución del Kernel
Propósito
    IContext concentra la información base del sistema: rutas, metadatos,
    entorno, versión, identificador de correlación. Es el primer objeto
    creado durante el arranque y el último en ser liberado.
Estado
    Congelado
Versión
    1.0.0
Dependencias
    Ninguna
Interfaces relacionadas
    Ninguna
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `GetProperty(Name)` | `string` | `object` | Obtiene una propiedad del contexto |
| `SetProperty(Name, Value)` | `string`, `object` | `void` | Establece una propiedad del contexto |
| `HasProperty(Name)` | `string` | `bool` | Verifica si una propiedad existe |
| `GetAllProperties()` | Ninguna | `hashtable` | Devuelve todas las propiedades |
| `GetContextId()` | Ninguna | `guid` | Devuelve el identificador único del contexto |
| `GetCreatedAt()` | Ninguna | `datetime` | Devuelve la fecha de creación |
| `GetVersion()` | Ninguna | `string` | Devuelve la versión del Kernel |
| `GetEnvironment()` | Ninguna | `string` | Devuelve el nombre del entorno |
| `GetRepositoryRoot()` | Ninguna | `string` | Devuelve la ruta raíz del repositorio |
| `GetMotorPath()` | Ninguna | `string` | Devuelve la ruta del directorio motor |
| `GetConfigurationPath()` | Ninguna | `string` | Devuelve la ruta de configuración |
| `GetLogsPath()` | Ninguna | `string` | Devuelve la ruta de logs |
| `Validate()` | Ninguna | `bool` | Valida que el contexto tenga todos los campos requeridos |

#### Propiedades predeterminadas

| Propiedad | Tipo | Descripción |
|---|---|---|
| `NombreProyecto` | `string` | Nombre del proyecto |
| `VersionKernel` | `string` | Versión del Kernel |
| `NombreEntorno` | `string` | Entorno (Desarrollo, Producción, Diagnóstico) |
| `RutaRaizRepositorio` | `string` | Ruta absoluta de la raíz |
| `RutaMotor` | `string` | Ruta a `motor/` |
| `RutaConfiguracion` | `string` | Ruta a `configuracion/` |
| `RutaLogs` | `string` | Ruta a `logs/` |
| `FechaCreacion` | `datetime` | Fecha ISO 8601 |
| `IdentificadorContexto` | `guid` | UUID de correlación |

#### Eventos publicados

| Evento | Cuándo | Payload |
|---|---|---|
| `Context.Created` | Contexto creado | `{ ContextId, Version }` |
| `Context.PropertyChanged` | Propiedad modificada | `{ PropertyName, OldValue, NewValue }` |
| `Context.Validated` | Validación completada | `{ IsValid, Errors }` |

#### Errores

| Error | Código |
|---|---|
| ContextPropertyNotFound | `ERR_CONTEXT_PROPERTY_NOT_FOUND` |
| ContextPropertyInvalid | `ERR_CONTEXT_PROPERTY_INVALID` |
| ContextValidationFailed | `ERR_CONTEXT_VALIDATION_FAILED` |

#### Precondiciones

- `RutaRaizRepositorio` debe ser una ruta absoluta válida
- `NombreProyecto` debe tener entre 3 y 64 caracteres alfanuméricos
- `VersionKernel` debe ser semántica (`X.Y.Z`)

#### Postcondiciones

- El contexto tiene un `IdentificadorContexto` único
- Todas las rutas son absolutas y normalizadas

#### Invariantes

- El `IdentificadorContexto` nunca cambia durante la vida del contexto
- Las rutas base (raíz, motor, configuración, logs) nunca son `null` o vacías
- El contexto mantiene su estado interno consistente después de múltiples operaciones

#### Extensibilidad

- El contexto permite propiedades adicionales mediante `SetProperty()` y `GetProperty()`
- Las propiedades adicionales se almacenan en un `hashtable` interno dinámico
- El `DrainEventQueue()` permite a los consumidores procesar eventos acumulados
- Se puede crear un nuevo contexto extendiendo la clase base y sobrescribiendo los métodos de acceso directo

#### Compatibilidad

- `IContext` versión `1.x` es compatible con implementaciones que proporcionen los 12 métodos del contrato
- Las implementaciones pueden añadir propiedades adicionales sin romper la compatibilidad
- El constructor de 4 parámetros (`ProjectName`, `RepositoryRoot`, `KernelVersion`, `EnvironmentName`) es la forma mínima de instanciación
- El constructor de 7 parámetros permite especificar todas las rutas explícitamente
- La implementación `Context` acepta tanto consultas mediante el contrato `IContext` como mediante acceso directo a propiedades (`pscustomobject`) para compatibilidad legacy con Kernel.ps1

#### Ejemplos de uso

```powershell
# Creación mínima (4 parámetros)
$ctx = [Context]::new("HermesEnterprise", "D:\proyecto", "1.0.0", "Desarrollo")

# Creación completa (7 parámetros)
$ctx = [Context]::new("HermesEnterprise", "D:\proyecto", "1.0.0", "Desarrollo",
    "D:\proyecto\motor", "D:\proyecto\configuracion", "D:\proyecto\logs")

# Uso de IContext
$ctx.GetRepositoryRoot()  # D:\proyecto
$ctx.GetVersion()         # 1.0.0
$ctx.GetConfigurationPath() # D:\proyecto\configuracion
$ctx.GetLogsPath()        # D:\proyecto\logs
$ctx.GetMotorPath()       # D:\proyecto\motor
$ctx.GetContextId()       # guid único
$ctx.GetCreatedAt()       # datetime UTC

# Propiedades dinámicas
$ctx.SetProperty("MiPropiedad", "valor")
$ctx.GetProperty("MiPropiedad")  # "valor"
$ctx.HasProperty("MiPropiedad")  # True

# Validación
$ctx.Validate()  # True si todos los campos requeridos son válidos

# Eventos
$ctx.DrainEventQueue()  # @{ Type = "Context.Created"; ... }
```

---

## 6. Dependency Injection

### IServiceContainer

```
Nombre
    IServiceContainer
Responsabilidad
    Gestionar el registro, resolución y ciclo de vida de servicios
Propósito
    IServiceContainer es el contenedor de inyección de dependencias del sistema.
    Permite registrar servicios como singletons o transient, resolverlos por nombre,
    reemplazarlos y verificar su existencia. Todos los componentes acceden a sus
    dependencias exclusivamente a través de este contenedor.
Estado
    Congelado
Versión
    1.0.0
Dependencias
    Ninguna
Interfaces relacionadas
    Ninguna
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Register(Name, Factory, Lifetime)` | `string`, `ScriptBlock`, `ServiceLifetime` | `void` | Registra un servicio con su fábrica y ciclo de vida |
| `RegisterInstance(Name, Instance)` | `string`, `object` | `void` | Registra una instancia ya creada como singleton |
| `Resolve(Name)` | `string` | `object` | Resuelve un servicio por nombre |
| `ResolveAll()` | Ninguna | `hashtable` | Resuelve todos los servicios registrados |
| `Has(Name)` | `string` | `bool` | Verifica si un servicio está registrado |
| `Remove(Name)` | `string` | `bool` | Elimina un servicio del contenedor |
| `Replace(Name, Factory, Lifetime)` | `string`, `ScriptBlock`, `ServiceLifetime` | `void` | Reemplaza un servicio existente |
| `GetLifetime(Name)` | `string` | `ServiceLifetime` | Devuelve el ciclo de vida de un servicio |
| `ListRegistered()` | Ninguna | `string[]` | Lista todos los nombres de servicios registrados |
| `Clear()` | Ninguna | `void` | Elimina todos los servicios |
| `Dispose()` | Ninguna | `void` | Libera recursos de todos los servicios registrados |

#### ServiceLifetime (enum)

| Valor | Descripción |
|---|---|
| `Singleton` | Una única instancia compartida |
| `Transient` | Nueva instancia en cada resolución |
| `Scoped` | Una instancia por ámbito de ejecución |

#### Eventos publicados

| Evento | Payload |
|---|---|
| `Container.ServiceRegistered` | `{ Name, Lifetime }` |
| `Container.ServiceResolved` | `{ Name }` |
| `Container.ServiceRemoved` | `{ Name }` |
| `Container.ServiceReplaced` | `{ Name }` |
| `Container.Disposed` | `{ ServicesCount }` |

#### Errores

| Error | Código |
|---|---|
| ServiceNotFound | `ERR_CONTAINER_SERVICE_NOT_FOUND` |
| ServiceAlreadyRegistered | `ERR_CONTAINER_ALREADY_REGISTERED` |
| ServiceFactoryFailed | `ERR_CONTAINER_FACTORY_FAILED` |
| ServiceDisposeFailed | `ERR_CONTAINER_DISPOSE_FAILED` |

#### Precondiciones

- El nombre del servicio no debe estar vacío
- La fábrica debe ser un `ScriptBlock` válido no `null`

#### Postcondiciones

- Después de `Register()`: el servicio está disponible para resolución
- Después de `Remove()`: el servicio ya no está disponible
- Después de `Dispose()`: todos los singletons son liberados

#### Invariantes

- No se pueden registrar dos servicios con el mismo nombre a menos que se use `Replace()`
- Un servicio registrado como singleton mantiene la misma instancia en todas las resoluciones

---

## 7. EventBus

### IEventBus

```
Nombre
    IEventBus
Responsabilidad
    Proporcionar un bus de eventos en memoria para comunicación desacoplada
Propósito
    IEventBus permite la publicación y suscripción de eventos entre componentes
    sin acoplamiento directo. Soporta correlación de eventos, persistencia opcional,
    replay de eventos históricos y filtrado por tipo. Es el mecanismo principal
    de comunicación entre Engines, Providers y el Kernel.
Estado
    Congelado
Versión
    1.0.0
Dependencias
    ILogger (opcional)
Interfaces relacionadas
    Ninguna
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Publish(EventName, Payload)` | `string`, `object` | `void` | Publica un evento en el bus |
| `PublishWithCorrelation(EventName, Payload, CorrelationId)` | `string`, `object`, `string` | `void` | Publica un evento con ID de correlación |
| `Subscribe(EventName, Handler)` | `string`, `ScriptBlock` | `string` | Suscribe un handler; devuelve ID de suscripción |
| `SubscribeWithFilter(EventName, Handler, Filter)` | `string`, `ScriptBlock`, `ScriptBlock` | `string` | Suscribe con filtro condicional |
| `Unsubscribe(SubscriptionId)` | `string` | `bool` | Cancela una suscripción |
| `UnsubscribeAll(EventName)` | `string` | `int` | Cancela todas las suscripciones de un evento |
| `GetSubscriptions(EventName)` | `string` | `object[]` | Lista suscripciones activas de un evento |
| `GetSubscribedEvents()` | Ninguna | `string[]` | Lista todos los eventos con suscripciones |
| `Clear()` | Ninguna | `void` | Elimina todas las suscripciones |
| `EnablePersistence(EventName)` | `string` | `void` | Habilita persistencia para un evento |
| `DisablePersistence(EventName)` | `string` | `void` | Deshabilita persistencia para un evento |
| `Replay(EventName, From, To)` | `string`, `datetime`, `datetime` | `object[]` | Replay de eventos persistidos en un rango |
| `ReplayByCorrelationId(CorrelationId)` | `string` | `object[]` | Replay de eventos por ID de correlación |
| `GetEventCount(EventName)` | `string` | `int` | Número de eventos publicados |
| `GetMetrics()` | Ninguna | `hashtable` | Métricas del bus (total, por evento, velocidad) |
| `Dispose()` | Ninguna | `void` | Libera recursos del bus |

#### Evento estándar (payload)

```json
{
  "id": "guid",
  "eventName": "Engine.Started",
  "timestamp": "2026-07-29T23:59:59Z",
  "correlationId": "guid (opcional)",
  "source": "NombreDelComponente",
  "payload": {}
}
```

#### Errores

| Error | Código |
|---|---|
| EventPublishFailed | `ERR_EVENTBUS_PUBLISH_FAILED` |
| EventSubscriptionNotFound | `ERR_EVENTBUS_SUBSCRIPTION_NOT_FOUND` |
| EventReplayFailed | `ERR_EVENTBUS_REPLAY_FAILED` |
| EventPersistenceFailed | `ERR_EVENTBUS_PERSISTENCE_FAILED` |

#### Precondiciones

- `EventName` no debe estar vacío
- `Handler` debe ser un `ScriptBlock` válido

#### Postcondiciones

- Después de `Publish()`: todos los handlers suscritos al evento son invocados
- Después de `Subscribe()`: el handler recibirá eventos futuros
- Después de `Replay()`: se devuelven eventos históricos en orden cronológico

#### Invariantes

- Los eventos se publican en orden FIFO por suscripción
- Un handler que falla no afecta la entrega a otros handlers
- El bus nunca lanza excepciones a publicadores por fallos en handlers

#### Extensibilidad

- Se pueden agregar middlewares (logging, métricas, auditoría) antes de la entrega
- Se pueden implementar transportes alternativos (Azure Event Grid, Service Bus)

---

## 8. Configuration

### IConfigurationManager

```
Nombre
    IConfigurationManager
Responsabilidad
    Gestionar la configuración del sistema desde múltiples fuentes
Propósito
    IConfigurationManager carga, fusiona y provee acceso a la configuración
    desde archivos (JSON, YAML), variables de entorno, Azure Key Vault y
    otras fuentes. Soporta cascada de configuraciones, recarga en caliente
    y validación de esquemas.
Estado
    Congelado
Versión
    1.0.0
Dependencias
    ILogger, IServiceContainer
Interfaces relacionadas
    IConfigurationSource
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Load()` | Ninguna | `void` | Carga configuración de todas las fuentes registradas |
| `Reload()` | Ninguna | `void` | Recarga configuración desde las fuentes |
| `GetValue(Key)` | `string` | `object` | Obtiene un valor por clave |
| `GetValueOrDefault(Key, Default)` | `string`, `object` | `object` | Obtiene valor con valor por defecto |
| `GetSection(Prefix)` | `string` | `hashtable` | Obtiene una sección completa |
| `GetAll()` | Ninguna | `hashtable` | Devuelve toda la configuración |
| `HasKey(Key)` | `string` | `bool` | Verifica si una clave existe |
| `AddSource(Source)` | `IConfigurationSource` | `void` | Agrega una fuente de configuración |
| `RemoveSource(SourceName)` | `string` | `bool` | Elimina una fuente |
| `ListSources()` | Ninguna | `string[]` | Lista las fuentes registradas |
| `ValidateSchema(Schema)` | `hashtable` | `bool` | Valida configuración contra un esquema |
| `GetState()` | Ninguna | `ConfigState` | Estado de la configuración |

#### ConfigState (enum)

| Valor | Descripción |
|---|---|
| `Unloaded` | No cargada |
| `Loaded` | Cargada exitosamente |
| `Partial` | Cargada parcialmente (algunas fuentes fallaron) |
| `Failed` | Error de carga |

#### Eventos publicados

| Evento | Payload |
|---|---|
| `Configuration.Loaded` | `{ SourcesCount }` |
| `Configuration.Reloaded` | `{ ChangesCount }` |
| `Configuration.SourceAdded` | `{ SourceName, SourceType }` |
| `Configuration.SourceRemoved` | `{ SourceName }` |
| `Configuration.Changed` | `{ ChangedKeys[] }` |
| `Configuration.ValidationFailed` | `{ Errors[] }` |

#### Errores

| Error | Código |
|---|---|
| ConfigKeyNotFound | `ERR_CONFIG_KEY_NOT_FOUND` |
| ConfigLoadFailed | `ERR_CONFIG_LOAD_FAILED` |
| ConfigSourceNotFound | `ERR_CONFIG_SOURCE_NOT_FOUND` |
| ConfigValidationFailed | `ERR_CONFIG_VALIDATION_FAILED` |

#### Precondiciones

- Debe haber al menos una fuente de configuración registrada antes de `Load()`
- La configuración no debe estar ya cargada (a menos que se llame `Reload()`)

#### Postcondiciones

- Después de `Load()`: todas las fuentes están consolidadas en una sola vista
- La cascada respeta: Key Vault > Environment > Archivo > Defaults

#### Invariantes

- Las fuentes de configuración nunca se modifican; solo se leen
- La configuración es inmutable durante la ejecución a menos que se llame `Reload()`

---

### IConfigurationSource

```
Nombre
    IConfigurationSource
Responsabilidad
    Representar una fuente de configuración externa
Propósito
    IConfigurationSource abstrae el origen de la configuración. Las implementaciones
    pueden leer de archivos (JSON, YAML), variables de entorno, Azure Key Vault,
    secrets locales, etc. Cada fuente retorna un hashtable plano con claves-valor.
Estado
    Congelado
Versión
    1.0.0
Dependencias
    Ninguna
Interfaces relacionadas
    IConfigurationManager
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Load()` | Ninguna | `hashtable` | Carga y devuelve la configuración de esta fuente |
| `GetName()` | Ninguna | `string` | Nombre de la fuente |
| `GetType()` | Ninguna | `string` | Tipo de fuente (File, Environment, KeyVault, etc.) |
| `GetPriority()` | Ninguna | `int` | Prioridad en la cascada (mayor = más prioridad) |
| `IsAvailable()` | Ninguna | `bool` | Verifica si la fuente está disponible |
| `HealthCheck()` | Ninguna | `bool` | Verifica que la fuente sea accesible |
| `Validate()` | Ninguna | `bool` | Valida la integridad de la fuente |

#### Tipos de fuente

| Tipo | Descripción | Prioridad |
|---|---|---|
| `File` | Archivo JSON o YAML | 10 |
| `Environment` | Variables de entorno | 20 |
| `KeyVault` | Azure Key Vault | 30 |
| `Secrets` | Secretos locales (`.env`) | 5 |
| `Defaults` | Valores por defecto | 1 |

---

## 9. Logging

### ILogger

```
Nombre
    ILogger
Responsabilidad
    Proveer logging estructurado y centralizado para todo el sistema
Propósito
    ILogger permite registrar eventos operativos con niveles de severidad,
    formato estructurado (JSONL), correlación por contexto y múltiples
    salidas (archivo, consola, Azure Monitor). Es el mecanismo único de
    registro del sistema.
Estado
    Congelado
Versión
    1.0.0
Dependencias
    IContext
Interfaces relacionadas
    Ninguna
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Log(Level, Message, Properties)` | `LogLevel`, `string`, `hashtable` | `void` | Registra un mensaje con nivel y propiedades |
| `LogDebug(Message, Properties)` | `string`, `hashtable` | `void` | Registra un mensaje de depuración |
| `LogInfo(Message, Properties)` | `string`, `hashtable` | `void` | Registra un mensaje informativo |
| `LogWarning(Message, Properties)` | `string`, `hashtable` | `void` | Registra una advertencia |
| `LogError(Message, Properties)` | `string`, `hashtable` | `void` | Registra un error |
| `LogCritical(Message, Properties)` | `string`, `hashtable` | `void` | Registra un error crítico |
| `LogException(Exception, Message, Properties)` | `Exception`, `string`, `hashtable` | `void` | Registra una excepción con detalles |
| `GetLogs(Filter)` | `hashtable` | `object[]` | Obtiene logs con filtro (nivel, rango, fuente) |
| `GetLogCount()` | Ninguna | `int` | Número total de entradas |
| `GetMetrics()` | Ninguna | `hashtable` | Métricas del logger |
| `SetLevel(Level)` | `LogLevel` | `void` | Cambia el nivel mínimo de logging |
| `AddOutput(Output)` | `string` | `void` | Agrega una salida (archivo, consola, etc.) |
| `Flush()` | Ninguna | `void` | Fuerza escritura de buffer |
| `Dispose()` | Ninguna | `void` | Libera recursos |

#### LogLevel (enum)

| Valor | Prioridad | Descripción |
|---|---|---|
| `Trace` | 0 | Información de diagnóstico detallada |
| `Debug` | 1 | Información de depuración |
| `Info` | 2 | Eventos operativos normales |
| `Warning` | 3 | Situaciones anómalas no críticas |
| `Error` | 4 | Errores recuperables |
| `Critical` | 5 | Errores irrecoverables |

#### Eventos publicados

| Evento | Payload |
|---|---|
| `Logger.LogEntryWritten` | `{ Level, Message, Timestamp }` |
| `Logger.LevelChanged` | `{ Previous, New }` |
| `Logger.OutputAdded` | `{ OutputType }` |

#### Errores

| Error | Código |
|---|---|
| LogWriteFailed | `ERR_LOGGER_WRITE_FAILED` |
| LogOutputNotFound | `ERR_LOGGER_OUTPUT_NOT_FOUND` |

#### Precondiciones

- El logger debe estar inicializado antes de cualquier operación de logging
- El nivel de logging debe ser válido

#### Postcondiciones

- Después de `Log()`: la entrada está registrada en todas las salidas activas
- Después de `Flush()`: todos los buffers están vaciados a persistencia

#### Invariantes

- Todas las entradas de log tienen timestamp ISO 8601
- Todas las entradas de log incluyen el `ContextId` del contexto activo
- El logger nunca lanza excepciones en operaciones de logging

---

## 10. Observability

### IObservabilityProvider

```
Nombre
    IObservabilityProvider
Responsabilidad
    Proveer una fachada unificada para observabilidad del sistema
Propósito
    IObservabilityProvider unifica el acceso a logging, métricas, tracing
    y health checks. Es el punto de entrada para que los componentes registren
    su estado operativo sin depender de implementaciones concretas de cada
    subsistema de observabilidad.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger, IMetricsCollector, IHealthMonitor, ITracer
Interfaces relacionadas
    Ninguna
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `TrackEvent(Name, Properties)` | `string`, `hashtable` | `void` | Registra un evento de observabilidad |
| `TrackMetric(Name, Value, Dimensions)` | `string`, `double`, `hashtable` | `void` | Registra una métrica |
| `TrackException(Exception, Properties)` | `Exception`, `hashtable` | `void` | Registra una excepción |
| `TrackDependency(Type, Target, Name, Duration, Success)` | `string`, `string`, `string`, `long`, `bool` | `void` | Registra una dependencia externa |
| `StartOperation(Name)` | `string` | `string` | Inicia una operación trazable; devuelve OperationId |
| `StopOperation(OperationId, Success)` | `string`, `bool` | `void` | Finaliza una operación |
| `GetDashboard()` | Ninguna | `hashtable` | Devuelve resumen de observabilidad |

#### Eventos publicados

| Evento | Payload |
|---|---|
| `Observability.EventTracked` | `{ Name, Properties }` |
| `Observability.MetricTracked` | `{ Name, Value, Dimensions }` |
| `Observability.OperationStarted` | `{ OperationId, Name }` |
| `Observability.OperationStopped` | `{ OperationId, Duration, Success }` |

---

## 11. Metrics

### IMetricsCollector

```
Nombre
    IMetricsCollector
Responsabilidad
    Recolectar y exponer métricas del sistema
Propósito
    IMetricsCollector permite registrar métricas de desempeño, conteo de
    operaciones, duraciones y uso de recursos. Las métricas pueden ser
    consultadas en tiempo real o exportadas a sistemas externos (Azure
    Monitor, Prometheus, etc.).
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IContext
Interfaces relacionadas
    IObservabilityProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `RecordCount(MetricName, Increment, Dimensions)` | `string`, `long`, `hashtable` | `void` | Incrementa un contador |
| `RecordGauge(MetricName, Value, Dimensions)` | `string`, `double`, `hashtable` | `void` | Establece un valor de gauge |
| `RecordHistogram(MetricName, Value, Dimensions)` | `string`, `double`, `hashtable` | `void` | Registra un valor en un histograma |
| `RecordDuration(MetricName, Duration, Dimensions)` | `string`, `long`, `hashtable` | `void` | Registra una duración en ms |
| `GetMetric(MetricName)` | `string` | `hashtable` | Devuelve métrica por nombre |
| `GetAllMetrics()` | Ninguna | `hashtable` | Devuelve todas las métricas |
| `ResetMetric(MetricName)` | `string` | `void` | Resetea una métrica |
| `ResetAll()` | Ninguna | `void` | Resetea todas las métricas |
| `Export(format)` | `string` | `string` | Exporta métricas en formato especificado |

#### Métricas del sistema

| Nombre | Tipo | Descripción |
|---|---|---|
| `kernel.start.duration` | Histogram | Duración de inicio del Kernel |
| `kernel.stop.duration` | Histogram | Duración de parada del Kernel |
| `engine.execute.duration` | Histogram | Duración de ejecución de motor |
| `engine.execute.count` | Counter | Conteo de ejecuciones por motor |
| `engine.execute.errors` | Counter | Conteo de errores por motor |
| `engine.execute.success` | Counter | Conteo de éxitos por motor |
| `provider.connect.duration` | Histogram | Duración de conexión de provider |
| `provider.operation.duration` | Histogram | Duración de operación de provider |
| `provider.operation.count` | Counter | Conteo de operaciones por provider |
| `pipeline.total.duration` | Histogram | Duración total del pipeline |
| `pipeline.engine.count` | Gauge | Número de motores en pipeline |
| `eventbus.publish.count` | Counter | Conteo de eventos publicados |
| `eventbus.subscribers.count` | Gauge | Número de suscriptores activos |
| `runtime.uptime` | Gauge | Tiempo de actividad del Runtime |
| `service.resolved.count` | Counter | Conteo de servicios resueltos |

---

## 12. Health

### IHealthMonitor

```
Nombre
    IHealthMonitor
Responsabilidad
    Monitorear la salud de todos los componentes del sistema
Propósito
    IHealthMonitor ejecuta chequeos periódicos de salud sobre Kernel,
    Runtime, Engines, Providers y cualquier componente registrado. Produce
    reportes de salud que incluyen estado individual, estado global,
    métricas y recomendaciones.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger, IMetricsCollector
Interfaces relacionadas
    IObservabilityProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `RegisterProbe(Name, Probe)` | `string`, `ScriptBlock` | `void` | Registra un health probe |
| `UnregisterProbe(Name)` | `string` | `bool` | Elimina un health probe |
| `RunAllChecks()` | Ninguna | `HealthReport` | Ejecuta todos los checks registrados |
| `RunCheck(Name)` | `string` | `HealthCheckResult` | Ejecuta un check específico |
| `GetLastReport()` | Ninguna | `HealthReport` | Último reporte generado |
| `GetHistory(Count)` | `int` | `HealthReport[]` | Historial de reportes |
| `EnablePeriodicCheck(Interval)` | `int` | `void` | Habilita checks periódicos |
| `DisablePeriodicCheck()` | Ninguna | `void` | Deshabilita checks periódicos |

#### HealthReport

| Campo | Tipo | Descripción |
|---|---|---|
| `Timestamp` | `datetime` | Cuándo se generó |
| `OverallStatus` | `HealthStatus` | Verde, Amarillo, Rojo |
| `Checks` | `HealthCheckResult[]` | Resultados individuales |
| `Summary` | `hashtable` | Resumen (passed, failed, warnings) |
| `Recommendations` | `string[]` | Recomendaciones |

#### HealthStatus (enum)

| Valor | Descripción |
|---|---|
| `Healthy` | Todos los checks pasan |
| `Degraded` | Algunos checks fallan pero el sistema opera |
| `Unhealthy` | Checks críticos fallan |

#### HealthCheckResult

| Campo | Tipo | Descripción |
|---|---|---|
| `Name` | `string` | Nombre del probe |
| `Status` | `HealthStatus` | Estado del check |
| `Duration` | `long` | Duración en ms |
| `Message` | `string` | Mensaje descriptivo |
| `Details` | `hashtable` | Detalles adicionales |

---

## 13. Registry

### IRegistry

```
Nombre
    IRegistry
Responsabilidad
    Mantener el registro central de todos los componentes del sistema
Propósito
    IRegistry almacena metadatos de todos los componentes registrados:
    Engines, Providers, Services, Plugins. Permite consultar componentes
    por tipo, nombre, versión, estado y capacidades. Es la fuente de verdad
    para descubrimiento de componentes.
Estado
    Congelado
Versión
    1.0.0
Dependencias
    Ninguna
Interfaces relacionadas
    IComponentRegistry (especialización), IModuleRegistry (legacy)
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `RegisterComponent(Name, Metadata)` | `string`, `hashtable` | `void` | Registra un componente con metadatos |
| `UnregisterComponent(Name)` | `string` | `bool` | Elimina un componente del registro |
| `GetComponent(Name)` | `string` | `hashtable` | Obtiene metadatos de un componente |
| `FindComponentsByType(Type)` | `string` | `hashtable[]` | Busca componentes por tipo |
| `FindComponentsByCapability(Capability)` | `string` | `hashtable[]` | Busca componentes por capacidad |
| `FindComponentsByState(State)` | `string` | `string[]` | Busca componentes por estado |
| `ListComponents()` | Ninguna | `string[]` | Lista todos los componentes registrados |
| `GetComponentCount()` | Ninguna | `int` | Número de componentes registrados |
| `GetComponentTypes()` | Ninguna | `string[]` | Tipos de componentes registrados |
| `ComponentExists(Name)` | `string` | `bool` | Verifica si un componente existe |

#### Metadatos estándar de componente

| Campo | Tipo | Descripción |
|---|---|---|
| `Name` | `string` | Nombre único del componente |
| `Type` | `string` | Tipo (Engine, Provider, Plugin, Service) |
| `Version` | `string` | Versión semántica |
| `State` | `string` | Estado actual (Registered, Initialized, Started, Failed) |
| `Capabilities` | `string[]` | Capacidades que expone |
| `Dependencies` | `string[]` | Dependencias |
| `Contracts` | `string[]` | Contratos que implementa |
| `RegisteredAt` | `datetime` | Fecha de registro |
| `Metadata` | `hashtable` | Metadatos adicionales |

#### Tipos de componente

| Tipo | Descripción |
|---|---|
| `Engine` | Motor de dominio |
| `Provider` | Proveedor de servicio externo |
| `Plugin` | Plugin cargado dinámicamente |
| `Service` | Servicio interno del Kernel |
| `Contract` | Definición de contrato |

#### Eventos publicados

| Evento | Payload |
|---|---|
| `Registry.ComponentRegistered` | `{ Name, Type, Version }` |
| `Registry.ComponentUnregistered` | `{ Name }` |
| `Registry.ComponentStateChanged` | `{ Name, PreviousState, NewState }` |

---

## 14. Security

### ISecurityProvider

```
Nombre
    ISecurityProvider
Responsabilidad
    Gestionar secretos, credenciales y políticas de seguridad
Propósito
    ISecurityProvider abstrae el almacenamiento y recuperación de secretos,
    certificados y credenciales. Las implementaciones pueden usar Azure Key
    Vault, almacenamiento local, secretos de GitHub Actions, etc.
    Ningún componente debe hardcodear secretos ni implementar su propia
    gestión de seguridad.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger
Interfaces relacionadas
    IIdentityProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `GetSecret(Name)` | `string` | `string` | Obtiene un secreto por nombre |
| `SetSecret(Name, Value)` | `string`, `string` | `void` | Almacena un secreto |
| `DeleteSecret(Name)` | `string` | `bool` | Elimina un secreto |
| `ListSecrets()` | Ninguna | `string[]` | Lista nombres de secretos |
| `SecretExists(Name)` | `string` | `bool` | Verifica si un secreto existe |
| `GetCertificate(Name)` | `string` | `object` | Obtiene un certificado |
| `ValidatePolicy(Policy)` | `hashtable` | `bool` | Valida una política de seguridad |
| `Encrypt(Plaintext, KeyName)` | `string`, `string` | `string` | Cifra un texto |
| `Decrypt(Ciphertext, KeyName)` | `string`, `string` | `string` | Descifra un texto |
| `RotateSecret(Name)` | `string` | `void` | Rota un secreto |
| `HealthCheck()` | Ninguna | `bool` | Verifica conectividad |
| `Dispose()` | Ninguna | `void` | Libera recursos |

#### Errores

| Error | Código |
|---|---|
| SecretNotFound | `ERR_SECURITY_SECRET_NOT_FOUND` |
| SecretSetFailed | `ERR_SECURITY_SET_FAILED` |
| SecretDeleteFailed | `ERR_SECURITY_DELETE_FAILED` |
| EncryptionFailed | `ERR_SECURITY_ENCRYPTION_FAILED` |
| DecryptionFailed | `ERR_SECURITY_DECRYPTION_FAILED` |
| CertificateNotFound | `ERR_SECURITY_CERTIFICATE_NOT_FOUND` |
| PolicyValidationFailed | `ERR_SECURITY_POLICY_FAILED` |

---

## 15. Identity

### IIdentityProvider

```
Nombre
    IIdentityProvider
Responsabilidad
    Gestionar autenticación y autorización contra servicios externos
Propósito
    IIdentityProvider abstrae la autenticación contra cualquier proveedor
    de identidad: Azure Entra ID, GitHub PAT, tokens de acceso, etc.
    Permite verificar sesiones activas, obtener tokens y gestionar
    credenciales de forma segura.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ISecurityProvider
Interfaces relacionadas
    ISession
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Login(Credentials)` | `hashtable` | `bool` | Autentica contra el proveedor |
| `Logout()` | Ninguna | `void` | Cierra la sesión activa |
| `IsAuthenticated()` | Ninguna | `bool` | Verifica si hay sesión activa |
| `GetToken(Resource)` | `string` | `string` | Obtiene token de acceso |
| `RefreshToken()` | Ninguna | `bool` | Renueva el token actual |
| `GetIdentity()` | Ninguna | `hashtable` | Devuelve información de identidad |
| `GetProviderType()` | Ninguna | `string` | Tipo de proveedor (AzureAD, GitHub, etc.) |
| `ValidatePermission(Permission)` | `string` | `bool` | Valida un permiso específico |
| `ListPermissions()` | Ninguna | `string[]` | Lista permisos disponibles |
| `HealthCheck()` | Ninguna | `bool` | Verifica conectividad |

#### Errores

| Error | Código |
|---|---|
| AuthenticationFailed | `ERR_IDENTITY_AUTH_FAILED` |
| TokenExpired | `ERR_IDENTITY_TOKEN_EXPIRED` |
| TokenRefreshFailed | `ERR_IDENTITY_REFRESH_FAILED` |
| PermissionDenied | `ERR_IDENTITY_PERMISSION_DENIED` |
| NotAuthenticated | `ERR_IDENTITY_NOT_AUTHENTICATED` |

---

## 16. Session

### ISession

```
Nombre
    ISession
Responsabilidad
    Gestionar ámbitos de ejecución con estado aislado
Propósito
    ISession representa un ámbito de ejecución con contexto, identidad y
    estado propios. Permite que operaciones concurrentes tengan contextos
    aislados. Una sesión puede ser interactiva (usuario) o automatizada (CI).
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IContext, IIdentityProvider
Interfaces relacionadas
    Ninguna
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Start(Parameters)` | `hashtable` | `guid` | Inicia una nueva sesión |
| `End(SessionId)` | `guid` | `void` | Finaliza una sesión |
| `GetSession(SessionId)` | `guid` | `hashtable` | Obtiene datos de sesión |
| `GetActiveSessions()` | Ninguna | `guid[]` | Lista sesiones activas |
| `SetData(SessionId, Key, Value)` | `guid`, `string`, `object` | `void` | Establece dato en sesión |
| `GetData(SessionId, Key)` | `guid`, `string` | `object` | Obtiene dato de sesión |
| `IsActive(SessionId)` | `guid` | `bool` | Verifica si una sesión está activa |

---

## 17. Pipeline

### IPipeline

```
Nombre
    IPipeline
Responsabilidad
    Orquestar la ejecución secuencial de motores como un pipeline
Propósito
    IPipeline construye, valida y ejecuta una secuencia ordenada de motores.
    Soporta ejecución determinista por dependencias, fall-stop para errores
    críticos, degradación controlada para errores opcionales, rollback
    parcial y cancelación de operaciones en curso.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IServiceContainer, IEventBus, ILogger, IRuntime
Interfaces relacionadas
    IEngine, IRecovery
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Build(Engines, Parameters)` | `IEngine[]`, `hashtable` | `void` | Construye el pipeline con motores y parámetros |
| `Validate()` | Ninguna | `ValidationResult` | Valida que el pipeline esté correctamente construido |
| `Execute()` | Ninguna | `PipelineResult` | Ejecuta todos los motores en orden |
| `ExecuteStep(EngineName)` | `string` | `EngineResult` | Ejecuta un motor específico |
| `Resume()` | Ninguna | `PipelineResult` | Reanuda un pipeline pausado |
| `Rollback()` | Ninguna | `PipelineResult` | Revierte el pipeline completo |
| `Cancel()` | Ninguna | `PipelineResult` | Cancela la ejecución en curso |
| `GetState()` | Ninguna | `PipelineState` | Estado actual del pipeline |
| `GetProgress()` | Ninguna | `hashtable` | Progreso del pipeline |
| `GetResults()` | Ninguna | `hashtable` | Resultados por motor |

#### PipelineState (enum)

| Valor | Descripción |
|---|---|
| `Built` | Pipeline construido, no ejecutado |
| `Validated` | Pipeline validado |
| `Executing` | Ejecutando motores |
| `Paused` | Ejecución pausada |
| `Completed` | Todos los motores ejecutados exitosamente |
| `Failed` | Un motor crítico falló |
| `RolledBack` | Pipeline revertido |
| `Cancelled` | Pipeline cancelado |

#### PipelineResult

| Campo | Tipo | Descripción |
|---|---|---|
| `State` | `PipelineState` | Estado final |
| `EngineResults` | `hashtable` | Resultados por motor |
| `Duration` | `long` | Duración total en ms |
| `Errors` | `object[]` | Errores ocurridos |
| `Warnings` | `object[]` | Advertencias |
| `Summary` | `string` | Resumen ejecutivo |

#### Eventos publicados

| Evento | Payload |
|---|---|
| `Pipeline.Built` | `{ EngineCount, Order }` |
| `Pipeline.Validated` | `{ IsValid, Errors }` |
| `Pipeline.Executing` | `{ CurrentEngine, TotalEngines }` |
| `Pipeline.EngineStarted` | `{ EngineName }` |
| `Pipeline.EngineCompleted` | `{ EngineName, Duration, Result }` |
| `Pipeline.EngineFailed` | `{ EngineName, Error, IsCritical }` |
| `Pipeline.Completed` | `{ Duration, SuccessCount, FailCount }` |
| `Pipeline.Failed` | `{ FailedEngine, Error }` |
| `Pipeline.Paused` | `{ CurrentStep }` |
| `Pipeline.Resumed` | `{ CurrentStep }` |
| `Pipeline.RolledBack` | `{ StepsRolledBack }` |
| `Pipeline.Cancelled` | `{ CurrentStep }` |

#### Errores

| Error | Código |
|---|---|
| PipelineBuildFailed | `ERR_PIPELINE_BUILD_FAILED` |
| PipelineValidationFailed | `ERR_PIPELINE_VALIDATION_FAILED` |
| PipelineExecutionFailed | `ERR_PIPELINE_EXECUTION_FAILED` |
| PipelineRollbackFailed | `ERR_PIPELINE_ROLLBACK_FAILED` |
| PipelineCancelFailed | `ERR_PIPELINE_CANCEL_FAILED` |
| PipelineInvalidStateTransition | `ERR_PIPELINE_INVALID_TRANSITION` |

---

## 18. Engine

### IEngine

```
Nombre
    IEngine
Responsabilidad
    Ejecutar operaciones de dominio como unidad atómica del pipeline
Propósito
    IEngine es el contrato base para todos los motores del sistema. Cada
    motor encapsula un dominio funcional (Git, Azure, Templates, etc.)
    y se ejecuta como parte de un pipeline. Los motores son registrados
    en el ServiceContainer y consumen únicamente contratos del Kernel.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IServiceContainer, IEventBus, ILogger
Interfaces relacionadas
    IComponent
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Initialize(Parameters)` | `hashtable` | `void` | Prepara el motor con parámetros de inicialización |
| `Validate()` | Ninguna | `ValidationResult` | Valida que el motor esté correctamente configurado |
| `Start()` | Ninguna | `void` | Inicia el motor (registra handlers, prepara recursos) |
| `Execute(Parameters)` | `hashtable` | `EngineResult` | Ejecuta la operación principal del motor |
| `Stop()` | Ninguna | `void` | Detiene el motor ordenadamente |
| `Dispose()` | Ninguna | `void` | Libera recursos del motor |
| `HealthCheck()` | Ninguna | `HealthCheckResult` | Verifica la salud del motor |
| `CanExecute(Action)` | `string` | `bool` | Verifica si el motor puede ejecutar una acción específica |
| `Rollback()` | Ninguna | `bool` | Revierte los cambios realizados por el motor |
| `Recover(Error)` | `hashtable` | `bool` | Intenta recuperarse de un error |
| `Capabilities()` | Ninguna | `string[]` | Lista de capacidades que ofrece el motor |
| `Dependencies()` | Ninguna | `string[]` | Lista de dependencias (nombres de otros motores) |
| `GetState()` | Ninguna | `EngineState` | Estado actual del motor |

#### EngineState (enum)

| Valor | Descripción |
|---|---|
| `Created` | Instanciado |
| `Initialized` | Inicializado con parámetros |
| `Validated` | Validado exitosamente |
| `Started` | Iniciado y listo |
| `Executing` | Ejecutando operación |
| `Completed` | Operación completada |
| `Failed` | Error durante ejecución |
| `RolledBack` | Cambios revertidos |
| `Stopped` | Motor detenido |
| `Disposed` | Recursos liberados |

#### EngineResult

| Campo | Tipo | Descripción |
|---|---|---|
| `EngineName` | `string` | Nombre del motor |
| `Success` | `bool` | Éxito de la operación |
| `Duration` | `long` | Duración en ms |
| `Data` | `object` | Datos producidos |
| `Errors` | `string[]` | Errores ocurridos |
| `Warnings` | `string[]` | Advertencias |
| `State` | `EngineState` | Estado después de ejecución |

#### Eventos publicados

| Evento | Payload |
|---|---|
| `Engine.Initializing` | `{ EngineName }` |
| `Engine.Initialized` | `{ EngineName, Duration }` |
| `Engine.Starting` | `{ EngineName }` |
| `Engine.Started` | `{ EngineName }` |
| `Engine.Executing` | `{ EngineName, Action }` |
| `Engine.Completed` | `{ EngineName, Duration, Result }` |
| `Engine.Failed` | `{ EngineName, Error, Action }` |
| `Engine.RollingBack` | `{ EngineName }` |
| `Engine.RolledBack` | `{ EngineName, Duration }` |
| `Engine.Stopping` | `{ EngineName }` |
| `Engine.Stopped` | `{ EngineName }` |

#### Errores

| Error | Código |
|---|---|
| EngineInitFailed | `ERR_ENGINE_INIT_FAILED` |
| EngineValidationFailed | `ERR_ENGINE_VALIDATION_FAILED` |
| EngineStartFailed | `ERR_ENGINE_START_FAILED` |
| EngineExecutionFailed | `ERR_ENGINE_EXECUTION_FAILED` |
| EngineStopFailed | `ERR_ENGINE_STOP_FAILED` |
| EngineRollbackFailed | `ERR_ENGINE_ROLLBACK_FAILED` |
| EngineRecoveryFailed | `ERR_ENGINE_RECOVERY_FAILED` |
| EngineCapabilityNotFound | `ERR_ENGINE_CAPABILITY_NOT_FOUND` |
| EngineDependencyNotMet | `ERR_ENGINE_DEPENDENCY_NOT_MET` |

#### Catálogo de motores

Cada motor en esta lista debe implementar `IEngine`:

| Motor | Responsabilidad |
|---|---|
| `WorkspaceEngine` | Crear y validar estructura de directorios del proyecto |
| `EnvironmentEngine` | Detectar y validar runtimes (Python, Node, .NET) |
| `TemplateEngine` | Aplicar plantillas de proyecto |
| `ValidationEngine` | Validar proyecto completo |
| `DocumentationEngine` | Generar documentación técnica y funcional |
| `ReportingEngine` | Generar reportes de estado |
| `TestingEngine` | Ejecutar suites de prueba |
| `RecoveryEngine` | Recuperación ante fallos y rollback |
| `PublishingEngine` | Publicar releases, paquetes y artefactos |
| `DeploymentEngine` | Desplegar aplicaciones en entornos destino |
| `CloudEngine` | Orquestar operaciones cloud multi-proveedor |
| `AzureEngine` | Provisionar infraestructura Azure |
| `GitEngine` | Operaciones Git (init, clone, commit, push) |
| `GitHubEngine` | Operaciones GitHub (repos, actions, secrets) |
| `StorageEngine` | Configurar almacenamiento |
| `DataLakeEngine` | Configurar Data Lake |
| `DatabaseEngine` | Provisionar bases de datos |
| `AIEngine` | Integración con servicios de IA |
| `IdentityEngine` | Autenticación contra proveedores |
| `SecurityEngine` | Validar y configurar políticas de seguridad |
| `MessagingEngine` | Configurar mensajería asíncrona |
| `PipelineEngine` | Orquestar pipelines híbridos |

---

## 19. Provider

### IProvider

```
Nombre
    IProvider
Responsabilidad
    Conectar, autenticar y operar contra servicios externos
Propósito
    IProvider es el contrato base para todos los providers del sistema.
    Un provider encapsula la comunicación con un servicio externo: CLI,
    API REST, SDK. Todos los providers se registran en el ServiceContainer
    y son consumidos exclusivamente por Engines a través de contratos
    específicos (IGitProvider, IAzureProvider, etc.).
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger, ISecurityProvider (opcional)
Interfaces relacionadas
    Ninguna
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Connect(Parameters)` | `hashtable` | `bool` | Establece conexión con el servicio externo |
| `Disconnect()` | Ninguna | `void` | Cierra la conexión activa |
| `Authenticate(Credentials)` | `hashtable` | `bool` | Autentica contra el servicio |
| `Validate()` | Ninguna | `bool` | Valida configuración y conectividad |
| `Execute(Operation, Parameters)` | `string`, `hashtable` | `object` | Ejecuta una operación en el servicio externo |
| `HealthCheck()` | Ninguna | `HealthCheckResult` | Verifica salud de la conexión |
| `Dispose()` | Ninguna | `void` | Libera recursos del provider |

#### Eventos publicados

| Evento | Payload |
|---|---|
| `Provider.Connecting` | `{ ProviderName, Target }` |
| `Provider.Connected` | `{ ProviderName, Duration }` |
| `Provider.Disconnecting` | `{ ProviderName }` |
| `Provider.Disconnected` | `{ ProviderName }` |
| `Provider.Authenticated` | `{ ProviderName }` |
| `Provider.Executing` | `{ ProviderName, Operation }` |
| `Provider.Completed` | `{ ProviderName, Operation, Duration }` |
| `Provider.Failed` | `{ ProviderName, Operation, Error }` |
| `Provider.HealthChanged` | `{ ProviderName, Status }` |

#### Errores

| Error | Código |
|---|---|
| ProviderConnectionFailed | `ERR_PROVIDER_CONNECTION_FAILED` |
| ProviderDisconnectFailed | `ERR_PROVIDER_DISCONNECT_FAILED` |
| ProviderAuthenticationFailed | `ERR_PROVIDER_AUTH_FAILED` |
| ProviderExecutionFailed | `ERR_PROVIDER_EXECUTION_FAILED` |
| ProviderValidationFailed | `ERR_PROVIDER_VALIDATION_FAILED` |
| ProviderHealthCheckFailed | `ERR_PROVIDER_HEALTH_FAILED` |
| ProviderNotConnected | `ERR_PROVIDER_NOT_CONNECTED` |

---

## 20. Bootstrap

### IBootstrapPhase

```
Nombre
    IBootstrapPhase
Responsabilidad
    Representar una fase del proceso de arranque del sistema
Propósito
    IBootstrapPhase define una etapa atómica del bootstrap del Kernel.
    Cada fase tiene precondiciones, postcondiciones y un tiempo máximo
    de ejecución. Las fases se ejecutan secuencialmente y pueden ser
    verificadas de forma independiente.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IContext, ILogger
Interfaces relacionadas
    IPipeline
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Execute(Context)` | `IContext` | `BootstrapPhaseResult` | Ejecuta la fase de bootstrap |
| `Validate(Context)` | `IContext` | `ValidationResult` | Valida que la fase pueda ejecutarse |
| `Rollback(Context)` | `IContext` | `bool` | Revierte los cambios de la fase |
| `GetName()` | Ninguna | `string` | Nombre de la fase |
| `GetOrder()` | Ninguna | `int` | Orden de ejecución |

#### BootstrapPhaseResult

| Campo | Tipo | Descripción |
|---|---|---|
| `PhaseName` | `string` | Nombre de la fase |
| `Success` | `bool` | Éxito de la fase |
| `Duration` | `long` | Duración en ms |
| `State` | `string` | Estado después de la fase |

---

## 21. Workspace

### IWorkspaceEngine (hereda de IEngine)

```
Nombre
    IWorkspaceEngine
Responsabilidad
    Crear y validar la estructura de directorios del proyecto
Propósito
    IWorkspaceEngine gestiona la creación y validación de la estructura
    de directorios de un proyecto Hermes Enterprise. Define qué carpetas
    y archivos deben existir y verifica su integridad.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IContext
Interfaces relacionadas
    IEngine, ITemplateProvider
```

#### Métodos adicionales

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `CreateStructure(Definition)` | `hashtable` | `WorkspaceResult` | Crea la estructura de directorios |
| `ValidateStructure(Path)` | `string` | `WorkspaceResult` | Valida estructura existente |
| `ResolvePath(RelativePath)` | `string` | `string` | Resuelve una ruta relativa contra el workspace |
| `GetStructure()` | Ninguna | `hashtable` | Devuelve la definición de estructura |

#### WorkspaceResult

| Campo | Tipo |
|---|---|
| `RootPath` | `string` |
| `DirectoriesCreated` | `string[]` |
| `FilesCreated` | `string[]` |
| `Errors` | `string[]` |
| `Duration` | `long` |

---

## 22. Environment

### IEnvironmentEngine (hereda de IEngine)

```
Nombre
    IEnvironmentEngine
Responsabilidad
    Detectar y validar runtimes y herramientas del sistema
Propósito
    IEnvironmentEngine detecta los runtimes instalados (Python, Node.js,
    .NET, etc.), valida versiones mínimas y verifica herramientas
    necesarias (Git, Azure CLI, GitHub CLI, Docker, etc.).
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    Ninguna
Interfaces relacionadas
    IEngine
```

#### Métodos adicionales

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `DetectRuntimes()` | Ninguna | `hashtable` | Detecta runtimes disponibles |
| `DetectTools()` | Ninguna | `hashtable` | Detecta herramientas disponibles |
| `ValidateVersions(Requirements)` | `hashtable` | `ValidationResult` | Valida versiones contra requerimientos |
| `GetPath(Component)` | `string` | `string` | Obtiene la ruta de un componente |
| `GetEnvironmentReport()` | Ninguna | `hashtable` | Reporte completo del entorno |

---

## 23. Template

### ITemplateProvider

```
Nombre
    ITemplateProvider
Responsabilidad
    Resolver, cargar y aplicar plantillas de proyecto
Propósito
    ITemplateProvider abstrae el origen y la aplicación de plantillas
    de proyecto. Las plantillas pueden ser locales (archivos), remotas
    (GitHub) o generadas dinámicamente.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `ResolveTemplate(Name, Version)` | `string`, `string` | `hashtable` | Resuelve una plantilla por nombre y versión |
| `LoadTemplate(Name)` | `string` | `hashtable` | Carga el contenido de una plantilla |
| `ApplyTemplate(Template, Parameters)` | `hashtable`, `hashtable` | `string` | Aplica una plantilla con parámetros |
| `ListTemplates(Filter)` | `hashtable` | `hashtable[]` | Lista plantillas disponibles |
| `GetTemplateVersions(Name)` | `string` | `string[]` | Versiones disponibles de una plantilla |
| `ValidateTemplate(Template)` | `hashtable` | `bool` | Valida estructura de la plantilla |

---

## 24. Validation

### IValidationProvider

```
Nombre
    IValidationProvider
Responsabilidad
    Validar proyectos, configuraciones y dependencias del sistema
Propósito
    IValidationProvider ejecuta reglas de validación sobre proyectos
    Hermes Enterprise, archivos de configuración, dependencias entre
    componentes y estructuras de datos.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `ValidateProject(Path)` | `string` | `ValidationResult` | Valida un proyecto completo |
| `ValidateConfiguration(Config, Schema)` | `hashtable`, `hashtable` | `ValidationResult` | Valida configuración contra esquema |
| `ValidateDependencies(Dependencies)` | `string[]` | `ValidationResult` | Valida dependencias entre componentes |
| `ValidateContract(Implementation, Contract)` | `object`, `string` | `ValidationResult` | Valida que una implementación cumpla el contrato |
| `AddRule(RuleName, Rule)` | `string`, `ScriptBlock` | `void` | Agrega una regla de validación |
| `RemoveRule(RuleName)` | `string` | `bool` | Elimina una regla |

#### ValidationResult

| Campo | Tipo |
|---|---|
| `IsValid` | `bool` |
| `Errors` | `ValidationError[]` |
| `Warnings` | `string[]` |
| `Duration` | `long` |

#### ValidationError

| Campo | Tipo |
|---|---|
| `Rule` | `string` |
| `Message` | `string` |
| `Severity` | `string` (Error, Warning) |
| `Target` | `string` |

---

## 25. Documentation

### IDocumentationProvider

```
Nombre
    IDocumentationProvider
Responsabilidad
    Generar documentación técnica y funcional del proyecto
Propósito
    IDocumentationProvider genera documentación a partir de plantillas,
    metadatos y configuración del proyecto. Soporta múltiples formatos
    de salida (Markdown, HTML, PDF) y puede integrarse con sistemas
    de documentación externos (Sphinx, Docusaurus, etc.).
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ITemplateProvider
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `GenerateDocumentation(ProjectPath, Format)` | `string`, `string` | `DocumentationResult` | Genera documentación del proyecto |
| `GenerateSection(SectionName, Parameters)` | `string`, `hashtable` | `string` | Genera una sección específica |
| `ListSections()` | Ninguna | `string[]` | Lista secciones disponibles |
| `SetFormat(Format)` | `string` | `void` | Establece el formato de salida |
| `ValidateDocumentation(Path)` | `string` | `ValidationResult` | Valida documentación generada |

#### DocumentationResult

| Campo | Tipo |
|---|---|
| `Section` | `string` |
| `Format` | `string` |
| `Content` | `string` |
| `OutputPath` | `string` |
| `Duration` | `long` |

---

## 26. Reporting

### IReportingProvider

```
Nombre
    IReportingProvider
Responsabilidad
    Generar reportes de estado, integridad y auditoría del sistema
Propósito
    IReportingProvider genera reportes estructurados sobre el estado
    del sistema, resultados de operaciones y auditoría. Soporta múltiples
    formatos (JSON, HTML, Markdown, CSV) y puede integrarse con sistemas
    de reporting externos.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `GenerateReport(ReportType, Parameters)` | `string`, `hashtable` | `ReportResult` | Genera un reporte |
| `GenerateReportFromData(Data, Format)` | `hashtable`, `string` | `string` | Genera reporte desde datos |
| `ListReportTypes()` | Ninguna | `string[]` | Tipos de reporte disponibles |
| `ExportReport(Report, OutputPath)` | `ReportResult`, `string` | `bool` | Exporta reporte a archivo |

#### ReportResult

| Campo | Tipo |
|---|---|
| `Type` | `string` |
| `Format` | `string` |
| `Content` | `string` |
| `GeneratedAt` | `datetime` |

---

## 27. Testing

### ITestingProvider

```
Nombre
    ITestingProvider
Responsabilidad
    Ejecutar suites de prueba sobre el proyecto
Propósito
    ITestingProvider ejecuta pruebas unitarias, de integración y diagnóstico
    sobre proyectos Hermes Enterprise. Soporta múltiples frameworks de
    prueba (Pester, Pytest, etc.) y genera reportes de resultados.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IReportingProvider
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `RunTests(TestPath, Framework, Filter)` | `string`, `string`, `string` | `TestResult` | Ejecuta pruebas |
| `RunTestsByTag(Tags)` | `string[]` | `TestResult` | Ejecuta pruebas por etiqueta |
| `GetTestResults(Path)` | `string` | `hashtable` | Obtiene resultados de ejecuciones previas |
| `ValidateTestCoverage(Path, Threshold)` | `string`, `double` | `ValidationResult` | Valida cobertura de pruebas |
| `GetFrameworks()` | Ninguna | `string[]` | Frameworks de prueba disponibles |

#### TestResult

| Campo | Tipo |
|---|---|
| `Total` | `int` |
| `Passed` | `int` |
| `Failed` | `int` |
| `Skipped` | `int` |
| `Duration` | `long` |
| `Failures` | `TestFailure[]` |

---

## 28. Recovery

### IRecoveryProvider

```
Nombre
    IRecoveryProvider
Responsabilidad
    Gestionar recuperación ante fallos y rollback de operaciones
Propósito
    IRecoveryProvider define estrategias de recuperación para el sistema.
    Permite revertir cambios parciales, restaurar estados anteriores y
    registrar puntos de restauración para operaciones atómicas.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    ILogger, IPipeline
Interfaces relacionadas
    IEngine (Rollback/Recover)
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `CreateRestorePoint(OperationId, State)` | `string`, `hashtable` | `bool` | Crea un punto de restauración |
| `RollbackToPoint(RestorePointId)` | `string` | `bool` | Revierte a un punto de restauración |
| `RollbackOperation(OperationId)` | `string` | `bool` | Revierte una operación específica |
| `ListRestorePoints()` | Ninguna | `hashtable[]` | Lista puntos de restauración |
| `CleanRestorePoints(Age)` | `int` | `int` | Limpia puntos antiguos |
| `GetRecoveryStrategy()` | Ninguna | `string` | Estrategia de recuperación activa |

---

## 29. Publishing

### IPublishingProvider

```
Nombre
    IPublishingProvider
Responsabilidad
    Publicar artefactos, releases y paquetes del proyecto
Propósito
    IPublishingProvider publica releases en GitHub, paquetes en NuGet,
    PyPI, npm, Docker Hub, etc. Gestiona versionado, etiquetado y
    distribución de artefactos.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IGitProvider, ILogger
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `CreateRelease(Version, Notes)` | `string`, `string` | `ReleaseResult` | Crea un release |
| `PublishPackage(PackageType, PackagePath)` | `string`, `string` | `PublishResult` | Publica un paquete |
| `PublishArtifact(ArtifactPath, Target)` | `string`, `string` | `PublishResult` | Publica un artefacto |
| `TagRelease(Version, Commit)` | `string`, `string` | `bool` | Etiqueta un release |
| `ListReleases(Filter)` | `hashtable` | `hashtable[]` | Lista releases |

---

## 30. Deployment

### IDeploymentProvider

```
Nombre
    IDeploymentProvider
Responsabilidad
    Desplegar aplicaciones en entornos destino
Propósito
    IDeploymentProvider despliega aplicaciones en múltiples entornos:
    Azure App Service, Azure Functions, Azure Container Apps, servidores
    locales, etc. Soporta rollback, configuración de entorno y validación
    post-despliegue.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger, ISecurityProvider
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Deploy(Source, Target, Options)` | `string`, `string`, `hashtable` | `DeployResult` | Despliega una aplicación |
| `RollbackDeployment(Target, Version)` | `string`, `string` | `DeployResult` | Revierte un despliegue |
| `GetDeploymentStatus(Target)` | `string` | `DeployResult` | Estado del despliegue |
| `GetDeploymentLogs(Target, MaxLines)` | `string`, `int` | `string[]` | Logs del despliegue |
| `ValidateDeployment(Target)` | `string` | `ValidationResult` | Valida el despliegue |
| `ConfigureTarget(Target, Settings)` | `string`, `hashtable` | `bool` | Configura el entorno destino |

---

## 31. Cloud

### ICloudProvider

```
Nombre
    ICloudProvider
Responsabilidad
    Orquestar operaciones cloud multi-proveedor
Propósito
    ICloudProvider abstrae operaciones cloud comunes: autenticación,
    creación de grupos de recursos, gestión de regiones y recursos.
    Los proveedores específicos (Azure, AWS, GCP) implementan este
    contrato con sus respectivas APIs.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IIdentityProvider, ILogger
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Connect(Credentials)` | `hashtable` | `bool` | Autentica contra el cloud provider |
| `Disconnect()` | Ninguna | `void` | Cierra la sesión cloud |
| `ListRegions()` | Ninguna | `string[]` | Lista regiones disponibles |
| `GetCurrentRegion()` | Ninguna | `string` | Región activa actual |
| `SetRegion(Region)` | `string` | `void` | Establece la región activa |
| `CreateResourceGroup(Name, Region)` | `string`, `string` | `hashtable` | Crea un grupo de recursos |
| `DeleteResourceGroup(Name)` | `string` | `bool` | Elimina un grupo de recursos |
| `ResourceGroupExists(Name)` | `string` | `bool` | Verifica si un grupo existe |
| `ListResourceGroups()` | Ninguna | `hashtable[]` | Lista grupos de recursos |
| `ListResources(ResourceGroup)` | `string` | `hashtable[]` | Lista recursos de un grupo |
| `GetQuota()` | Ninguna | `hashtable` | Cuotas y límites |
| `CheckHealth()` | Ninguna | `HealthCheckResult` | Verifica conectividad cloud |

---

## 32. Azure

### 32.1. IAzureProvider

```
Nombre
    IAzureProvider
Responsabilidad
    Gestionar recursos de Microsoft Azure
Propósito
    IAzureProvider extiende ICloudProvider con operaciones específicas
    de Azure: Resource Manager, suscripciones, tags, políticas y
    regiones de Azure.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IIdentityProvider, ICloudProvider
Interfaces relacionadas
    IProvider, ICloudProvider
```

#### Métodos adicionales

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `GetSubscriptions()` | Ninguna | `hashtable[]` | Lista suscripciones de Azure |
| `SetSubscription(SubscriptionId)` | `string` | `void` | Establece suscripción activa |
| `GetCurrentSubscription()` | Ninguna | `hashtable` | Suscripción activa |
| `CreateResource(ResourceType, Name, ResourceGroup, Properties)` | `string`, `string`, `string`, `hashtable` | `hashtable` | Crea un recurso Azure |
| `DeleteResource(ResourceId)` | `string` | `bool` | Elimina un recurso |
| `TagResource(ResourceId, Tags)` | `string`, `hashtable` | `void` | Agrega tags a un recurso |
| `GetResource(ResourceId)` | `string` | `hashtable` | Obtiene detalles de un recurso |
| `ExecuteARMDeployment(Template, Parameters, ResourceGroup)` | `string`, `hashtable`, `string` | `hashtable` | Ejecuta despliegue ARM |
| `DeployBicep(Template, Parameters, ResourceGroup)` | `string`, `hashtable`, `string` | `hashtable` | Despliega plantilla Bicep |

### 32.2. IAzureIdentityProvider

```
Nombre
    IAzureIdentityProvider
Responsabilidad
    Autenticación específica de Azure (Entra ID, Managed Identity)
Propósito
    IAzureIdentityProvider gestiona autenticación contra Microsoft Entra ID,
    Managed Identity, Service Principals y cuentas de usuario de Azure.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IIdentityProvider
Interfaces relacionadas
    IIdentityProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `LoginAz(Parameters)` | `hashtable` | `bool` |
| `LoginWithManagedIdentity()` | Ninguna | `bool` |
| `LoginWithServicePrincipal(TenantId, ClientId, Secret)` | `string`, `string`, `string` | `bool` |
| `GetCurrentAccount()` | Ninguna | `hashtable` |
| `ListTenants()` | Ninguna | `hashtable[]` |
| `SetTenant(TenantId)` | `string` | `void` |

### 32.3. IAzureStorageProvider

```
Nombre
    IAzureStorageProvider
Responsabilidad
    Gestionar cuentas de almacenamiento de Azure
Propósito
    IAzureStorageProvider crea, configura y administra Azure Storage
    Accounts, incluyendo contenedores, tablas, colas y políticas de
    acceso.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IAzureProvider
Interfaces relacionadas
    IStorageProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `CreateStorageAccount(Name, ResourceGroup, Region, Sku)` | `string`, `string`, `string`, `string` | `hashtable` |
| `DeleteStorageAccount(Name, ResourceGroup)` | `string`, `string` | `bool` |
| `GetStorageAccountKeys(Name, ResourceGroup)` | `string`, `string` | `hashtable` |
| `RegenerateKey(Name, ResourceGroup, KeyName)` | `string`, `string`, `string` | `string` |
| `ListStorageAccounts(ResourceGroup)` | `string` | `hashtable[]` |
| `CreateContainer(StorageAccount, ContainerName)` | `string`, `string` | `bool` |

### 32.4. IAzureDeploymentProvider

```
Nombre
    IAzureDeploymentProvider
Responsabilidad
    Desplegar aplicaciones en servicios de cómputo de Azure
Propósito
    IAzureDeploymentProvider despliega aplicaciones en Azure App Service,
    Azure Functions, Azure Container Apps y Azure Kubernetes Service.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IDeploymentProvider, IAzureProvider
Interfaces relacionadas
    IDeploymentProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `CreateWebApp(Name, ResourceGroup, Plan, Runtime)` | `string`, `string`, `string`, `string` | `hashtable` |
| `DeployWebApp(Source, WebAppName, ResourceGroup)` | `string`, `string`, `string` | `DeployResult` |
| `CreateFunctionApp(Name, ResourceGroup, Storage, Runtime)` | `string`, `string`, `string`, `string` | `hashtable` |
| `DeployFunctionApp(Source, FunctionAppName, ResourceGroup)` | `string`, `string`, `string` | `DeployResult` |
| `CreateContainerApp(Name, ResourceGroup, Image)` | `string`, `string`, `string` | `hashtable` |
| `UpdateContainerApp(ContainerAppName, Image)` | `string`, `string` | `bool` |
| `GetAppSettings(AppName, ResourceGroup)` | `string`, `string` | `hashtable` |
| `SetAppSettings(AppName, ResourceGroup, Settings)` | `string`, `string`, `hashtable` | `void` |

### 32.5. IAzureDataFactoryProvider

```
Nombre
    IAzureDataFactoryProvider
Responsabilidad
    Gestionar Azure Data Factory y pipelines de datos
Propósito
    IAzureDataFactoryProvider crea y gestiona fábricas de datos, pipelines,
    linked services, datasets y triggers en Azure Data Factory.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IAzureProvider
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `CreateDataFactory(Name, ResourceGroup, Region)` | `string`, `string`, `string` | `hashtable` |
| `DeleteDataFactory(Name, ResourceGroup)` | `string`, `string` | `bool` |
| `CreatePipeline(DataFactory, PipelineName, Definition)` | `string`, `string`, `hashtable` | `hashtable` |
| `ExecutePipeline(DataFactory, PipelineName, Parameters)` | `string`, `string`, `hashtable` | `string` |
| `GetPipelineRunStatus(RunId)` | `string` | `string` |
| `CreateLinkedService(DataFactory, Name, Type, ConnectionString)` | `string`, `string`, `string`, `string` | `hashtable` |
| `CreateDataset(DataFactory, Name, LinkedService, Properties)` | `string`, `string`, `string`, `hashtable` | `hashtable` |

### 32.6. IAzureDataLakeProvider

```
Nombre
    IAzureDataLakeProvider
Responsabilidad
    Gestionar Azure Data Lake Storage Gen2
Propósito
    IAzureDataLakeProvider opera sobre ADLS Gen2: filesystems, directorios,
    archivos, permisos y ACLs.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IAzureStorageProvider
Interfaces relacionadas
    IDataLakeProvider, IStorageProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `CreateFileSystem(StorageAccount, Name)` | `string`, `string` | `bool` |
| `DeleteFileSystem(StorageAccount, Name)` | `string`, `string` | `bool` |
| `CreateDirectory(FileSystem, Path)` | `string`, `string` | `bool` |
| `UploadFile(FileSystem, Source, Destination)` | `string`, `string`, `string` | `bool` |
| `DownloadFile(FileSystem, Source, Destination)` | `string`, `string`, `string` | `bool` |
| `ListFiles(FileSystem, Path)` | `string`, `string` | `hashtable[]` |
| `SetPermissions(FileSystem, Path, Permissions)` | `string`, `string`, `hashtable` | `void` |
| `SetAcl(FileSystem, Path, Acl)` | `string`, `string`, `hashtable[]` | `void` |

### 32.7. IAzureAppServiceProvider

```
Nombre
    IAzureAppServiceProvider
Responsabilidad
    Gestionar Azure App Service Plans y Web Apps
Propósito
    IAzureAppServiceProvider gestiona planes de App Service, aplicaciones
    web, slots de deployment, configuraciones y escalado.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IAzureProvider, IDeploymentProvider
Interfaces relacionadas
    IDeploymentProvider, IAzureDeploymentProvider
```

### 32.8. IAzureFoundryProvider

```
Nombre
    IAzureFoundryProvider
Responsabilidad
    Gestionar Azure AI Foundry para proyectos de IA
Propósito
    IAzureFoundryProvider crea y gestiona hubs, projects, connections y
    deployments en Azure AI Foundry.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IAIProvider, IAzureProvider
Interfaces relacionadas
    IAIProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `CreateHub(Name, ResourceGroup, Region)` | `string`, `string`, `string` | `hashtable` |
| `CreateProject(HubName, ProjectName)` | `string`, `string` | `hashtable` |
| `CreateConnection(ProjectName, ConnectionType, Target)` | `string`, `string`, `string` | `hashtable` |
| `DeployModel(ProjectName, ModelName, ModelType, Version)` | `string`, `string`, `string`, `string` | `hashtable` |
| `ListModels(ProjectName)` | `string` | `hashtable[]` |
| `CreateEvaluation(ProjectName, EvaluationName, Data)` | `string`, `string`, `hashtable` | `string` |

---

## 33. Git

### IGitProvider

```
Nombre
    IGitProvider
Responsabilidad
    Ejecutar operaciones Git sobre repositorios locales
Propósito
    IGitProvider abstrae todas las operaciones del sistema de control
    de versiones Git: init, clone, add, commit, push, pull, branch,
    tag, merge, rebase, log y status. Las implementaciones usan git.exe
    o librerías como LibGit2Sharp.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Init(Path)` | `string` | `bool` | Inicializa un repositorio Git |
| `Clone(Url, Path, Branch)` | `string`, `string`, `string` | `bool` | Clona un repositorio remoto |
| `Add(Path, Files)` | `string`, `string[]` | `bool` | Agrega archivos al staging |
| `Commit(Path, Message)` | `string`, `string` | `bool` | Crea un commit |
| `Push(Path, Remote, Branch)` | `string`, `string`, `string` | `bool` | Sube cambios al remoto |
| `Pull(Path, Remote, Branch)` | `string`, `string`, `string` | `bool` | Trae cambios del remoto |
| `Fetch(Path, Remote)` | `string`, `string` | `bool` | Obtiene referencias del remoto |
| `Branch(Path, Name)` | `string`, `string` | `bool` | Crea una rama |
| `Checkout(Path, Name)` | `string`, `string` | `bool` | Cambia de rama |
| `Merge(Path, SourceBranch, TargetBranch)` | `string`, `string`, `string` | `bool` | Fusiona ramas |
| `Rebase(Path, Branch)` | `string`, `string` | `bool` | Rebase sobre una rama |
| `Tag(Path, Name, Message)` | `string`, `string`, `string` | `bool` | Crea un tag |
| `Status(Path)` | `string` | `hashtable` | Estado del repositorio |
| `Log(Path, MaxCount)` | `string`, `int` | `hashtable[]` | Historial de commits |
| `Remote(Path, Name, Url)` | `string`, `string`, `string` | `bool` | Gestiona remotos |
| `Stash(Path, Message)` | `string`, `string` | `bool` | Guarda cambios temporales |
| `StashPop(Path)` | `string` | `bool` | Recupera cambios guardados |
| `Diff(Path, FromRef, ToRef)` | `string`, `string`, `string` | `string` | Diferencia entre referencias |
| `HasChanges(Path)` | `string` | `bool` | Verifica si hay cambios sin commit |
| `GetCurrentBranch(Path)` | `string` | `string` | Rama actual |
| `ListBranches(Path)` | `string` | `string[]` | Lista ramas |
| `ListTags(Path)` | `string` | `string[]` | Lista tags |
| `GetRemoteUrl(Path, Remote)` | `string`, `string` | `string` | URL del remoto |

---

## 34. GitHub

### 34.1. IGitHubProvider

```
Nombre
    IGitHubProvider
Responsabilidad
    Gestionar repositorios y recursos de GitHub
Propósito
    IGitHubProvider abstrae la API de GitHub para gestionar repositorios,
    issues, pull requests, releases, branches, entornos y configuraciones
    del repositorio.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IIdentityProvider, ILogger
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `CreateRepo(Name, Description, IsPrivate)` | `string`, `string`, `bool` | `hashtable` | Crea repositorio |
| `DeleteRepo(Name)` | `string` | `bool` | Elimina repositorio |
| `RepoExists(Name)` | `string` | `bool` | Verifica existencia |
| `ListRepos(Organization)` | `string` | `hashtable[]` | Lista repositorios |
| `GetRepo(Owner, Name)` | `string`, `string` | `hashtable` | Obtiene detalles de repo |
| `ForkRepo(Owner, Name, NewOwner)` | `string`, `string`, `string` | `hashtable` | Forkea un repositorio |

### 34.2. IGitHubActionsProvider

```
Nombre
    IGitHubActionsProvider
Responsabilidad
    Gestionar GitHub Actions workflows, secrets y variables
Propósito
    IGitHubActionsProvider configura y gestiona GitHub Actions:
    workflows, secrets, variables, runners, entornos y despliegues.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IGitHubProvider, ISecurityProvider
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `CreateWorkflow(Repo, Name, Content)` | `string`, `string`, `string` | `bool` |
| `DeleteWorkflow(Repo, WorkflowId)` | `string`, `string` | `bool` |
| `ListWorkflows(Repo)` | `string` | `hashtable[]` |
| `TriggerWorkflow(Repo, WorkflowId, Parameters)` | `string`, `string`, `hashtable` | `string` |
| `GetWorkflowRun(Repo, RunId)` | `string`, `string` | `hashtable` |
| `ListWorkflowRuns(Repo, WorkflowId)` | `string`, `string` | `hashtable[]` |
| `CancelWorkflowRun(Repo, RunId)` | `string`, `string` | `bool` |
| `CreateSecret(Repo, Name, Value)` | `string`, `string`, `string` | `bool` |
| `DeleteSecret(Repo, Name)` | `string`, `string` | `bool` |
| `SecretExists(Repo, Name)` | `string`, `string` | `bool` |
| `ListSecrets(Repo)` | `string` | `string[]` |
| `CreateVariable(Repo, Name, Value)` | `string`, `string`, `string` | `bool` |
| `DeleteVariable(Repo, Name)` | `string`, `string` | `bool` |
| `ListVariables(Repo)` | `string` | `hashtable` |
| `CreateEnvironment(Repo, Name)` | `string`, `string` | `bool` |
| `DeleteEnvironment(Repo, Name)` | `string`, `string` | `bool` |
| `ListEnvironments(Repo)` | `string` | `hashtable[]` |
| `CreateDeployment(Repo, Ref, Environment)` | `string`, `string`, `string` | `hashtable` |
| `ListDeployments(Repo, Environment)` | `string`, `string` | `hashtable[]` |

### 34.3. IGitHubRepositoryProvider

```
Nombre
    IGitHubRepositoryProvider
Responsabilidad
    Gestionar configuraciones avanzadas del repositorio GitHub
Propósito
    IGitHubRepositoryProvider gestiona branch protection, colaboradores,
    code owners, webhooks, topics, proyectos y configuraciones de
    repositorio.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IGitHubProvider
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `ProtectBranch(Repo, Branch, Rules)` | `string`, `string`, `hashtable` | `bool` |
| `RemoveBranchProtection(Repo, Branch)` | `string`, `string` | `bool` |
| `GetBranchProtection(Repo, Branch)` | `string`, `string` | `hashtable` |
| `AddCollaborator(Repo, Username, Permission)` | `string`, `string`, `string` | `bool` |
| `RemoveCollaborator(Repo, Username)` | `string`, `string` | `bool` |
| `ListCollaborators(Repo)` | `string` | `hashtable[]` |
| `CreateWebhook(Repo, Url, Events)` | `string`, `string`, `string[]` | `hashtable` |
| `DeleteWebhook(Repo, WebhookId)` | `string`, `string` | `bool` |
| `ListWebhooks(Repo)` | `string` | `hashtable[]` |
| `SetTopics(Repo, Topics)` | `string`, `string[]` | `bool` |
| `GetTopics(Repo)` | `string` | `string[]` |
| `CreateIssue(Repo, Title, Body, Labels)` | `string`, `string`, `string`, `string[]` | `hashtable` |
| `CreatePullRequest(Repo, Title, Head, Base)` | `string`, `string`, `string`, `string` | `hashtable` |
| `CreateRelease(Repo, Tag, Name, Notes)` | `string`, `string`, `string`, `string` | `hashtable` |
| `DeleteRelease(Repo, ReleaseId)` | `string`, `string` | `bool` |
| `ListReleases(Repo)` | `string` | `hashtable[]` |
| `CreateDeployKey(Repo, Title, Key)` | `string`, `string`, `string` | `hashtable` |
| `ListDeployKeys(Repo)` | `string` | `hashtable[]` |
| `AddTeam(Repo, TeamName, Permission)` | `string`, `string`, `string` | `bool` |

---

## 35. Storage

### IStorageProvider

```
Nombre
    IStorageProvider
Responsabilidad
    Gestionar operaciones de almacenamiento (contenedores, archivos)
Propósito
    IStorageProvider abstrae operaciones de almacenamiento: creación y
    gestión de contenedores/buckets, subida/descarga de archivos, listado
    de contenidos y gestión de permisos. Implementaciones para Azure Blob,
    AWS S3, GCP Storage, etc.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `CreateContainer(Name, Region)` | `string`, `string` | `bool` |
| `DeleteContainer(Name)` | `string` | `bool` |
| `ContainerExists(Name)` | `string` | `bool` |
| `ListContainers()` | Ninguna | `string[]` |
| `UploadFile(Container, Source, Destination)` | `string`, `string`, `string` | `bool` |
| `DownloadFile(Container, Source, Destination)` | `string`, `string`, `string` | `bool` |
| `DeleteFile(Container, Path)` | `string`, `string` | `bool` |
| `FileExists(Container, Path)` | `string`, `string` | `bool` |
| `ListFiles(Container, Prefix)` | `string`, `string` | `hashtable[]` |
| `GetFileProperties(Container, Path)` | `string`, `string` | `hashtable` |
| `SetPermissions(Container, Permissions)` | `string`, `hashtable` | `void` |

---

## 36. DataLake

### IDataLakeProvider

```
Nombre
    IDataLakeProvider
Responsabilidad
    Gestionar sistemas de archivos Data Lake
Propósito
    IDataLakeProvider abstrae operaciones específicas de Data Lake:
    filesystems, directorios jerárquicos, ACLs, permisos POSIX y
    operaciones de datos masivos.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IStorageProvider
Interfaces relacionadas
    IStorageProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `CreateFileSystem(Name)` | `string` | `bool` |
| `DeleteFileSystem(Name)` | `string` | `bool` |
| `FileSystemExists(Name)` | `string` | `bool` |
| `ListFileSystems()` | Ninguna | `string[]` |
| `CreateDirectory(FileSystem, Path)` | `string`, `string` | `bool` |
| `DeleteDirectory(FileSystem, Path, Recursive)` | `string`, `string`, `bool` | `bool` |
| `DirectoryExists(FileSystem, Path)` | `string`, `string` | `bool` |
| `ListDirectories(FileSystem, Path)` | `string`, `string` | `string[]` |
| `UploadFile(FileSystem, Source, Destination)` | `string`, `string`, `string` | `bool` |
| `DownloadFile(FileSystem, Source, Destination)` | `string`, `string`, `string` | `bool` |
| `ListFiles(FileSystem, Path, Recursive)` | `string`, `string`, `bool` | `hashtable[]` |
| `SetAcl(FileSystem, Path, AclEntries)` | `string`, `string`, `hashtable[]` | `void` |
| `GetAcl(FileSystem, Path)` | `string`, `string` | `hashtable[]` |

---

## 37. Blob

### IBlobStorageProvider

```
Nombre
    IBlobStorageProvider
Responsabilidad
    Gestionar almacenamiento de objetos (blobs)
Propósito
    IBlobStorageProvider abstrae operaciones específicas de blob storage:
    blobs en bloque, blobs en páginas, snapshots, tiering y políticas de
    retención.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IStorageProvider
Interfaces relacionadas
    IStorageProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `UploadBlob(Container, Name, Content, Type)` | `string`, `string`, `object`, `string` | `bool` |
| `DownloadBlob(Container, Name)` | `string`, `string` | `object` |
| `DeleteBlob(Container, Name)` | `string`, `string` | `bool` |
| `BlobExists(Container, Name)` | `string`, `string` | `bool` |
| `ListBlobs(Container, Prefix)` | `string`, `string` | `hashtable[]` |
| `SetBlobTier(Container, Name, Tier)` | `string`, `string`, `string` | `void` |
| `CreateSnapshot(Container, Name)` | `string`, `string` | `string` |
| `SetLease(Container, Name)` | `string`, `string` | `string` |
| `ReleaseLease(Container, Name, LeaseId)` | `string`, `string`, `string` | `bool` |
| `SetRetentionPolicy(Container, Days)` | `string`, `int` | `void` |

---

## 38. Database

### IDatabaseProvider

```
Nombre
    IDatabaseProvider
Responsabilidad
    Provisionar, configurar y gestionar bases de datos
Propósito
    IDatabaseProvider abstrae la creación, configuración, escalado y
    gestión de bases de datos relacionales y NoSQL. Implementaciones
    para Azure SQL, PostgreSQL, Cosmos DB, MySQL, etc.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `CreateServer(Name, ResourceGroup, Region)` | `string`, `string`, `string` | `hashtable` | Crea servidor de base de datos |
| `DeleteServer(Name, ResourceGroup)` | `string`, `string` | `bool` | Elimina servidor |
| `ServerExists(Name, ResourceGroup)` | `string`, `string` | `bool` | Verifica existencia |
| `CreateDatabase(Server, Name, Collation)` | `string`, `string`, `string` | `hashtable` | Crea base de datos |
| `DeleteDatabase(Server, Name)` | `string`, `string` | `bool` | Elimina base de datos |
| `DatabaseExists(Server, Name)` | `string`, `string` | `bool` | Verifica existencia |
| `ListDatabases(Server)` | `string` | `hashtable[]` | Lista bases de datos |
| `GetConnectionString(Server, Database, AuthType)` | `string`, `string`, `string` | `string` | Cadena de conexión |
| `SetFirewallRule(Server, RuleName, StartIp, EndIp)` | `string`, `string`, `string`, `string` | `void` | Regla de firewall |
| `GetServerMetrics(Server)` | `string` | `hashtable` | Métricas del servidor |
| `ScaleDatabase(Server, Database, Tier)` | `string`, `string`, `string` | `bool` | Escala base de datos |
| `RunQuery(Server, Database, Query)` | `string`, `string`, `string` | `hashtable[]` | Ejecuta consulta |

---

## 39. AI

### 39.1. IAIProvider

```
Nombre
    IAIProvider
Responsabilidad
    Integrar con servicios de inteligencia artificial
Propósito
    IAIProvider abstrae el acceso a servicios de IA: modelos de lenguaje,
    embeddings, generación de código, análisis y razonamiento. Las
    implementaciones pueden usar Azure AI Foundry, Azure OpenAI, OpenAI
    API, etc.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger, ISecurityProvider (para API keys)
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Chat(Messages, Options)` | `object[]`, `hashtable` | `AIChatResult` | Chat completion con modelo |
| `Embeddings(Input, Model)` | `string`, `string` | `float[]` | Genera embeddings |
| `Completions(Prompt, Options)` | `string`, `hashtable` | `string` | Text completion |
| `Summarize(Text, Options)` | `string`, `hashtable` | `string` | Resumen de texto |
| `Analyze(Data, Options)` | `object`, `hashtable` | `object` | Análisis con IA |
| `HealthCheck()` | Ninguna | `HealthCheckResult` | Verifica conectividad |

#### AIChatResult

| Campo | Tipo |
|---|---|
| `Content` | `string` |
| `Model` | `string` |
| `Usage` | `hashtable` (promptTokens, completionTokens, totalTokens) |
| `Duration` | `long` |

### 39.2. IEmbeddingProvider

```
Nombre
    IEmbeddingProvider
Responsabilidad
    Generar embeddings vectoriales para texto
Propósito
    IEmbeddingProvider genera representaciones vectoriales de texto para
    búsqueda semántica, clustering, clasificación y RAG.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IAIProvider
Interfaces relacionadas
    IAIProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `GenerateEmbedding(Text, Model)` | `string`, `string` | `float[]` |
| `GenerateEmbeddings(Texts, Model)` | `string[]`, `string` | `float[][]` |
| `GetEmbeddingDimensions(Model)` | `string` | `int` |
| `GetAvailableModels()` | Ninguna | `string[]` |
| `CalculateSimilarity(Embedding1, Embedding2)` | `float[]`, `float[]` | `float` |

### 39.3. IChatProvider

```
Nombre
    IChatProvider
Responsabilidad
    Proveer interacciones conversacionales con modelos de lenguaje
Propósito
    IChatProvider gestiona conversaciones multi-turno con modelos de
    lenguaje, incluyendo system prompts, historial, funciones y streaming.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IAIProvider
Interfaces relacionadas
    IAIProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `Chat(Messages, Options)` | `ChatMessage[]`, `hashtable` | `ChatResult` |
| `ChatStream(Messages, Options, Callback)` | `ChatMessage[]`, `hashtable`, `ScriptBlock` | `void` |
| `CreateConversation()` | Ninguna | `string` |
| `AddMessage(ConversationId, Role, Content)` | `string`, `string`, `string` | `void` |
| `GetHistory(ConversationId)` | `string` | `ChatMessage[]` |
| `ClearHistory(ConversationId)` | `string` | `void` |
| `SetSystemPrompt(ConversationId, Prompt)` | `string`, `string` | `void` |

### 39.4. IReasoningProvider

```
Nombre
    IReasoningProvider
Responsabilidad
    Realizar tareas de razonamiento y análisis con IA
Propósito
    IReasoningProvider ejecuta tareas de razonamiento avanzado: análisis
    de causa raíz, toma de decisiones, planificación y evaluación.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IAIProvider, IChatProvider
Interfaces relacionadas
    IAIProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `AnalyzeRootCause(Incident, Context)` | `string`, `hashtable` | `RootCauseResult` |
| `EvaluateDecision(Options, Criteria)` | `hashtable[]`, `hashtable` | `DecisionResult` |
| `PlanSteps(Objective, Constraints)` | `string`, `hashtable[]` | `PlanStep[]` |
| `Classify(Input, Categories)` | `string`, `string[]` | `ClassificationResult` |
| `ExtractEntities(Text, Schema)` | `string`, `hashtable` | `hashtable[]` |

### 39.5. ICodeGenerationProvider

```
Nombre
    ICodeGenerationProvider
Responsabilidad
    Generar código fuente utilizando modelos de IA
Propósito
    ICodeGenerationProvider genera, completa, revisa y traduce código
    fuente usando modelos de lenguaje. Soporta múltiples lenguajes y
    puede integrarse con plantillas de proyecto.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    IAIProvider, ITemplateProvider
Interfaces relacionadas
    IAIProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `GenerateCode(Description, Language, Framework)` | `string`, `string`, `string` | `string` |
| `CompleteCode(PartialCode, Language)` | `string`, `string` | `string` |
| `ReviewCode(Code, Language)` | `string`, `string` | `CodeReviewResult` |
| `TranslateCode(Code, SourceLanguage, TargetLanguage)` | `string`, `string`, `string` | `string` |
| `GenerateTests(Code, Framework)` | `string`, `string` | `string` |
| `ExplainCode(Code)` | `string` | `string` |
| `GenerateDocumentation(Code)` | `string` | `string` |

#### CodeReviewResult

| Campo | Tipo |
|---|---|
| `Issues` | `CodeIssue[]` |
| `Score` | `int` (1-10) |
| `Summary` | `string` |
| `Suggestions` | `string[]` |

---

## 40. Messaging

### IMessagingProvider

```
Nombre
    IMessagingProvider
Responsabilidad
    Gestionar mensajería asíncrona entre componentes y sistemas
Propósito
    IMessagingProvider abstrae sistemas de mensajería: colas, tópicos,
    event grids y buses de servicio. Implementaciones para Azure Service
    Bus, Azure Event Grid, RabbitMQ, Kafka, etc.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    ILogger, ISecurityProvider
Interfaces relacionadas
    IProvider
```

#### Métodos

| Método | Entrada | Salida |
|---|---|---|
| `CreateQueue(Name)` | `string` | `bool` |
| `DeleteQueue(Name)` | `string` | `bool` |
| `QueueExists(Name)` | `string` | `bool` |
| `SendMessage(Queue, Message, Properties)` | `string`, `object`, `hashtable` | `bool` |
| `ReceiveMessage(Queue, Timeout)` | `string`, `int` | `object` |
| `PeekMessage(Queue)` | `string` | `object` |
| `CreateTopic(Name)` | `string` | `bool` |
| `DeleteTopic(Name)` | `string` | `bool` |
| `CreateSubscription(Topic, SubscriptionName, Filter)` | `string`, `string`, `string` | `bool` |
| `DeleteSubscription(Topic, SubscriptionName)` | `string`, `string` | `bool` |
| `PublishEvent(Topic, Event)` | `string`, `object` | `bool` |
| `GetQueueMetrics(Name)` | `string` | `hashtable` |
| `GetTopicMetrics(Name)` | `string` | `hashtable` |

---

## 41. Plugins

### IPluginManager

```
Nombre
    IPluginManager
Responsabilidad
    Gestionar el ciclo de vida de plugins del sistema
Propósito
    IPluginManager descubre, valida, carga, inicializa y descarga plugins.
    Los plugins son componentes que extienden la funcionalidad del Kernel
    sin modificar su código base.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IRegistry, ILogger, IServiceContainer, IManifest
Interfaces relacionadas
    IDiscovery, ICapabilities
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `DiscoverPlugins(Path)` | `string` | `PluginDescriptor[]` | Descubre plugins en una ruta |
| `ValidatePlugin(Descriptor)` | `PluginDescriptor` | `ValidationResult` | Valida un plugin contra el contrato |
| `LoadPlugin(Descriptor)` | `PluginDescriptor` | `bool` | Carga un plugin en memoria |
| `InitializePlugin(PluginName)` | `string` | `bool` | Inicializa un plugin cargado |
| `StartPlugin(PluginName)` | `string` | `bool` | Inicia un plugin inicializado |
| `StopPlugin(PluginName)` | `string` | `bool` | Detiene un plugin activo |
| `UnloadPlugin(PluginName)` | `string` | `bool` | Descarga un plugin |
| `GetPlugin(PluginName)` | `string` | `hashtable` | Obtiene información de un plugin |
| `ListPlugins(State)` | `string` | `hashtable[]` | Lista plugins por estado |
| `GetPluginState(PluginName)` | `string` | `string` | Estado actual del plugin |

#### PluginDescriptor

| Campo | Tipo |
|---|---|
| `Name` | `string` |
| `Version` | `string` |
| `Path` | `string` |
| `Type` | `string` |
| `Contracts` | `string[]` |
| `Capabilities` | `string[]` |
| `Dependencies` | `string[]` |
| `MinKernelVersion` | `string` |
| `MaxKernelVersion` | `string` |
| `State` | `string` |

---

## 42. Capabilities

### ICapabilities

```
Nombre
    ICapabilities
Responsabilidad
    Declarar y consultar capacidades de componentes del sistema
Propósito
    ICapabilities permite a los componentes declarar qué capacidades
    ofrecen y a los consumidores consultar qué componentes ofrecen una
    capacidad específica. Una capacidad es una acción atómica que un
    componente puede ejecutar.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IRegistry
Interfaces relacionadas
    IDiscovery
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `DeclareCapability(ComponentName, Capability)` | `string`, `string` | `void` | Declara una capacidad para un componente |
| `HasCapability(ComponentName, Capability)` | `string`, `string` | `bool` | Verifica si un componente tiene una capacidad |
| `FindByCapability(Capability)` | `string` | `string[]` | Encuentra componentes con una capacidad |
| `ListCapabilities(ComponentName)` | `string` | `string[]` | Lista capacidades de un componente |
| `GetCapabilityDetails(Capability)` | `string` | `hashtable` | Detalles de una capacidad |
| `RegisterCapabilityProvider(ProviderName, Capabilities)` | `string`, `string[]` | `void` | Registra un proveedor de capacidades |

#### Catálogo de capacidades estándar

| Capacidad | Descripción |
|---|---|
| `workspace.create` | Crear estructura de workspace |
| `workspace.validate` | Validar estructura de workspace |
| `environment.detect` | Detectar runtimes del sistema |
| `environment.validate` | Validar versiones de runtime |
| `template.resolve` | Resolver plantillas |
| `template.apply` | Aplicar plantillas |
| `git.init` | Inicializar repositorio Git |
| `git.clone` | Clonar repositorio |
| `git.commit` | Crear commit |
| `git.push` | Subir cambios |
| `github.repo.create` | Crear repositorio GitHub |
| `github.repo.configure` | Configurar repositorio |
| `github.actions.configure` | Configurar Actions |
| `github.secrets.manage` | Gestionar secrets |
| `azure.auth.login` | Autenticar en Azure |
| `azure.resource.create` | Crear recursos Azure |
| `azure.storage.create` | Crear storage account |
| `azure.datalake.create` | Crear Data Lake |
| `azure.database.create` | Crear base de datos |
| `azure.appservice.create` | Crear App Service |
| `azure.functions.create` | Crear Function App |
| `azure.ai.hub.create` | Crear hub AI Foundry |
| `deployment.execute` | Ejecutar despliegue |
| `deployment.rollback` | Revertir despliegue |
| `validation.project` | Validar proyecto |
| `validation.config` | Validar configuración |
| `documentation.generate` | Generar documentación |
| `reporting.generate` | Generar reportes |
| `testing.execute` | Ejecutar pruebas |
| `publishing.release` | Publicar release |
| `publishing.package` | Publicar paquete |
| `ai.chat` | Chat con IA |
| `ai.embeddings` | Generar embeddings |
| `ai.code.generate` | Generar código |
| `ai.analyze` | Analizar con IA |
| `storage.container.create` | Crear contenedor |
| `storage.file.upload` | Subir archivo |
| `messaging.queue.create` | Crear cola |
| `messaging.topic.create` | Crear tópico |
| `database.server.create` | Crear servidor de BD |
| `database.query.execute` | Ejecutar consulta |
| `pipeline.build` | Construir pipeline |
| `pipeline.execute` | Ejecutar pipeline |
| `pipeline.rollback` | Revertir pipeline |
| `recovery.restore` | Restaurar estado |
| `identity.login` | Iniciar sesión |
| `security.secret.get` | Obtener secreto |
| `security.secret.set` | Establecer secreto |

---

## 43. Discovery

### IDiscovery

```
Nombre
    IDiscovery
Responsabilidad
    Descubrir componentes, plugins y extensiones del sistema
Propósito
    IDiscovery escanea directorios, registros y fuentes externas para
    encontrar componentes disponibles, validar su compatibilidad y
    registrarlos en el sistema.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    IRegistry, IManifest, ILogger
Interfaces relacionadas
    IPluginManager, ICapabilities
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `ScanDirectory(Path, Pattern)` | `string`, `string` | `string[]` | Escanea un directorio buscando componentes |
| `FindComponents(Criteria)` | `hashtable` | `ComponentDescriptor[]` | Busca componentes por criterios |
| `FindPlugins(Path)` | `string` | `PluginDescriptor[]` | Busca plugins en una ruta |
| `ValidateComponent(Descriptor)` | `ComponentDescriptor` | `ValidationResult` | Valida un componente descubierto |
| `RegisterDiscovered(Descriptor)` | `ComponentDescriptor` | `bool` | Registra un componente descubierto |
| `GetDiscoveryReport()` | Ninguna | `hashtable` | Reporte de descubrimiento |

#### ComponentDescriptor

| Campo | Tipo |
|---|---|
| `Name` | `string` |
| `Path` | `string` |
| `Type` | `string` |
| `Version` | `string` |
| `Contracts` | `string[]` |
| `Capabilities` | `string[]` |
| `Dependencies` | `string[]` |
| `ManifestVersion` | `string` |
| `IsValid` | `bool` |
| `ValidationErrors` | `string[]` |

---

## 44. Scheduler

### IScheduler

```
Nombre
    IScheduler
Responsabilidad
    Programar y ejecutar tareas en intervalos definidos
Propósito
    IScheduler gestiona la ejecución programada de tareas: periodic checks,
    mantenimiento, reportes automáticos y operaciones batch. Soporta
    schedules basados en cron, intervalos y fechas específicas.
Estado
    Propuesto
Versión
    0.1.0
Dependencias
    ILogger, IRuntime, IEventBus
Interfaces relacionadas
    Ninguna
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `ScheduleTask(Name, Task, Trigger)` | `string`, `ScriptBlock`, `ScheduleTrigger` | `string` | Programa una tarea |
| `UnscheduleTask(TaskId)` | `string` | `bool` | Cancela una tarea programada |
| `PauseTask(TaskId)` | `string` | `bool` | Pausa una tarea |
| `ResumeTask(TaskId)` | `string` | `bool` | Reanuda una tarea |
| `GetTask(TaskId)` | `string` | `hashtable` | Obtiene información de una tarea |
| `ListTasks()` | Ninguna | `hashtable[]` | Lista tareas programadas |
| `GetSchedulerState()` | Ninguna | `string` | Estado del scheduler |
| `Start()` | Ninguna | `void` | Inicia el scheduler |
| `Stop()` | Ninguna | `void` | Detiene el scheduler |

#### ScheduleTrigger

| Campo | Tipo | Descripción |
|---|---|---|
| `Type` | `string` | Cron, Interval, Once |
| `CronExpression` | `string` | Expresión cron (si Type=Cron) |
| `IntervalSeconds` | `int` | Segundos entre ejecuciones (si Type=Interval) |
| `StartAt` | `datetime` | Fecha de inicio (si Type=Once) |
| `EndAt` | `datetime` | Fecha de fin (opcional) |
| `MaxExecutions` | `int` | Máximo de ejecuciones (0=ilimitado) |

---

## 45. Manifest

### IManifest

```
Nombre
    IManifest
Responsabilidad
    Leer y validar archivos de manifiesto de componentes
Propósito
    IManifest gestiona la lectura, validación y extracción de metadatos
    desde archivos de manifiesto (plugin.json, manifest.yaml, etc.).
    Cada componente del sistema debe declarar su identidad, dependencias,
    contratos y versión en un manifiesto.
Estado
    Aprobado
Versión
    1.0.0
Dependencias
    ILogger
Interfaces relacionadas
    IDiscovery, IRegistry
```

#### Métodos

| Método | Entrada | Salida | Descripción |
|---|---|---|---|
| `Load(ManifestPath)` | `string` | `Manifest` | Carga un manifiesto desde archivo |
| `Validate(Manifest)` | `Manifest` | `ValidationResult` | Valida estructura del manifiesto |
| `GetComponentInfo(Manifest)` | `Manifest` | `hashtable` | Extrae información del componente |
| `GetDependencies(Manifest)` | `Manifest` | `string[]` | Obtiene dependencias declaradas |
| `GetContracts(Manifest)` | `Manifest` | `string[]` | Obtiene contratos implementados |
| `GetCapabilities(Manifest)` | `Manifest` | `string[]` | Obtiene capacidades declaradas |
| `CheckKernelCompatibility(Manifest, KernelVersion)` | `Manifest`, `string` | `bool` | Verifica compatibilidad con versión del Kernel |
| `FindManifests(SearchPath)` | `string` | `string[]` | Busca archivos de manifiesto |

#### Estructura de Manifest

```json
{
  "name": "component-name",
  "version": "1.0.0",
  "type": "engine | provider | plugin | service",
  "description": "Descripción del componente",
  "author": "Autor",
  "minKernelVersion": "1.0.0",
  "maxKernelVersion": "2.0.0",
  "contracts": ["IEngine", "IGitProvider"],
  "capabilities": ["git.init", "git.commit"],
  "dependencies": ["ServiceContainer", "EventBus"],
  "entryPoint": "path/to/component.ps1",
  "config": {
    "settings": {}
  }
}
```

---

## 46. Apéndice A: Mapa de dependencias entre contratos

```
IKernel
 ├── IContext
 ├── IConfigurationManager
 │    └── IConfigurationSource
 ├── IServiceContainer
 ├── IEventBus
 ├── ILogger
 ├── IRuntime
 │    └── IEngine (ejecuta)
 │         ├── IWorkspaceEngine
 │         ├── IEnvironmentEngine
 │         └── ... (otros engines)
 └── IRegistry
      ├── ICapabilities
      └── IPluginManager
           ├── IDiscovery
           │    └── IManifest
           └── ICapabilities

IPipeline
 ├── IEngine[] (motores a ejecutar)
 ├── IEventBus
 ├── ILogger
 └── IServiceContainer

IProvider
 ├── IGitProvider
 ├── IGitHubProvider
 │    ├── IGitHubActionsProvider
 │    └── IGitHubRepositoryProvider
 ├── ICloudProvider
 │    └── IAzureProvider
 │         ├── IAzureIdentityProvider
 │         ├── IAzureStorageProvider
 │         ├── IAzureDeploymentProvider
 │         ├── IAzureDataFactoryProvider
 │         ├── IAzureDataLakeProvider
 │         ├── IAzureAppServiceProvider
 │         └── IAzureFoundryProvider
 ├── IStorageProvider
 │    ├── IDataLakeProvider
 │    └── IBlobStorageProvider
 ├── IDatabaseProvider
 ├── IDeploymentProvider
 ├── ITemplateProvider
 ├── IValidationProvider
 ├── IDocumentationProvider
 ├── IReportingProvider
 ├── ITestingProvider
 ├── IPublishingProvider
 ├── IRecoveryProvider
 ├── IAIProvider
 │    ├── IEmbeddingProvider
 │    ├── IChatProvider
 │    ├── IReasoningProvider
 │    └── ICodeGenerationProvider
 ├── IMessagingProvider
 ├── ISecurityProvider
 └── IIdentityProvider
      └── ISession
```

---

## 47. Apéndice B: Matriz de compatibilidad de versiones

| Contrato | Versión | Depende de | Compatible con |
|---|---|---|---|
| IKernel | 1.0.0 | IContext 1.x, IConfigurationManager 1.x, IServiceContainer 1.x, IEventBus 1.x, ILogger 1.x, IRuntime 1.x, IRegistry 1.x | Kernel 1.x |
| IContext | 1.0.0 | Ninguna | Cualquier versión |
| IServiceContainer | 1.0.0 | Ninguna | Cualquier versión |
| IEventBus | 1.0.0 | — | Cualquier versión |
| IConfigurationManager | 1.0.0 | IConfigurationSource 1.x | Config 1.x |
| IConfigurationSource | 1.0.0 | Ninguna | Cualquier versión |
| ILogger | 1.0.0 | — | Cualquier versión |
| IRuntime | 1.0.0 | IServiceContainer 1.x, IEventBus 1.x | Runtime 1.x |
| IRegistry | 1.0.0 | Ninguna | Cualquier versión |
| IEngine | 1.0.0 | IServiceContainer 1.x | Engine 1.x |
| IProvider | 1.0.0 | ILogger 1.x | Provider 1.x |
| IPipeline | 1.0.0 | IEngine 1.x, IServiceContainer 1.x | Pipeline 1.x |
| IPluginManager | 1.0.0 | IManifest 1.x, IDiscovery 1.x | Kernel >=1.0.0 |
| IManifest | 1.0.0 | — | Cualquier versión |
| IDiscovery | 1.0.0 | IManifest 1.x | Cualquier versión |
| ICapabilities | 1.0.0 | IRegistry 1.x | Cualquier versión |
| ISecurityProvider | 1.0.0 | ILogger 1.x | Provider 1.x |
| IIdentityProvider | 1.0.0 | ISecurityProvider 1.x | Provider 1.x |
| IGitProvider | 1.0.0 | ILogger 1.x | Provider 1.x |
| IGitHubProvider | 1.0.0 | IIdentityProvider 1.x | Provider 1.x |
| ICloudProvider | 1.0.0 | IIdentityProvider 1.x | Provider 1.x |
| IAzureProvider | 1.0.0 | ICloudProvider 1.x | Provider 1.x |
| IStorageProvider | 1.0.0 | ILogger 1.x | Provider 1.x |
| IDatabaseProvider | 1.0.0 | ILogger 1.x | Provider 1.x |
| IDeploymentProvider | 1.0.0 | ISecurityProvider 1.x | Provider 1.x |
| ITemplateProvider | 1.0.0 | ILogger 1.x | Provider 1.x |
| IAIProvider | 1.0.0 | ISecurityProvider 1.x | Provider 1.x |

---

## 48. Apéndice C: Glosario de términos

| Término | Definición |
|---|---|
| **Contrato** | Definición abstracta de un conjunto de métodos, propiedades y comportamientos que una implementación debe cumplir |
| **Engine** | Componente que ejecuta operaciones de dominio como unidad atómica del pipeline |
| **Provider** | Componente que implementa un contrato para comunicarse con un servicio externo |
| **Plugin** | Componente cargado dinámicamente que extiende la funcionalidad del Kernel |
| **Pipeline** | Secuencia ordenada de motores que se ejecutan secuencialmente |
| **Kernel** | Núcleo del sistema que gestiona el ciclo de vida, DI, eventos, configuración y runtime |
| **Context** | Objeto compartido con información base del sistema (rutas, versión, entorno) |
| **ServiceContainer** | Contenedor de inyección de dependencias |
| **EventBus** | Bus de eventos en memoria para comunicación desacoplada |
| **Manifest** | Archivo de metadatos que describe un componente |
| **Capability** | Acción atómica que un componente puede ejecutar |
| **Discovery** | Proceso de encontrar y validar componentes disponibles |
| **Bootstrap** | Fase de arranque del sistema que prepara el Kernel y los servicios base |
| **Health Check** | Evaluación del estado operativo de un componente |
| **Metric** | Medición cuantitativa de un aspecto del sistema |
| **Rollback** | Reversión de cambios realizados por una operación |
| **Recovery** | Proceso de restaurar el sistema después de un fallo |
| **Singleton** | Ciclo de vida donde existe una única instancia compartida |
| **Transient** | Ciclo de vida donde se crea una nueva instancia en cada resolución |
| **Scoped** | Ciclo de vida donde existe una instancia por ámbito de ejecución |
| **Adapter** | Componente que adapta una implementación existente a un contrato |
| **Wrapper** | Componente que envuelve funcionalidad existente para exponerla como contrato |

---

> **KERNEL CONTRACT SPECIFICATION — RC14.0**
>
> Estado: **CONGELADO**
>
> Próxima revisión: Al completar implementación de Fase 1 (Unificación del Kernel)
>
> Principio rector: **Contract First** — Todo componente nuevo debe existir primero como contrato.
>
> "EL KERNEL ES EL PRODUCTO. Bootstrap, Providers, Engines, Helpers, Builders, Adapters. Todos consumirán exclusivamente contratos públicos del Kernel."