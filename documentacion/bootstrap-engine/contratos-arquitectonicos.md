---
titulo: Bootstrap Engine - Contratos Arquitectónicos
fase: 4.5
estado: aprobado
fecha: 2026-07-10
autor: Hermes Agent + Usuario
reemplaza: bootstrap-contracts.md (v1, eliminada por consolidación)
---

# Bootstrap Engine - Contratos Arquitectónicos

## Resumen de Componentes

La arquitectura del Bootstrap Engine distingue entre **interfaces** (contratos) y **componentes implementables**.

### Interfaces (Contratos)

Son contratos puros que definen estructura de datos. No contienen lógica de negocios.

#### 1. BootstrapRequest
- **Propósito**: Representar la solicitud del usuario para crear un proyecto
- **Naturaleza**: DTO inmutable con propiedades públicas de solo lectura
- **Responsabilidad**: Contener SOLO los datos que el usuario desea para su proyecto
- **Inmutabilidad**: Una vez creado, no puede modificarse

#### 2. BootstrapState
- **Propósito**: Representar el estado interno del motor durante la ejecución
- **Naturaleza**: Objeto mutable que evoluciona con cada paso de la orquestación
- **Responsabilidad**: Contener SOLO metadatos de ejecución (ID, fase, estado, tiempos)
- **Ciclo de vida**: Creado al inicio, actualizado durante ejecución, sellado al final

---

### Componentes Implementables

Son unidades ejecutables con responsabilidades específicas.

#### 3. Start-HermesProject (Entry Point)
- **Propósito**: Interfaz primaria, responsable de toda interacción con el usuario
- **Responsabilidad ÚNICA**: 
  - Capturar inputs del usuario
  - Construir BootstrapRequest
  - Delegar al orquestador
  - Mostrar resultados al usuario
- **NO hace**: Ejecutar pasos, crear archivos, invocar managers directamente

#### 4. BootstrapOrchestrator (Coordinador)
- **Propósito**: Coordinar la ejecución de los pasos del bootstrap
- **Responsabilidad ÚNICA**:
  - Recibir BootstrapRequest y BootstrapState
  - Ejecutar pasos en orden correcto
  - Actualizar BootstrapState
  - Manejar errores y rollbacks
- **NO hace**: 
  - Interactuar con usuario
  - Crear BootstrapRequest
  - Ejecutar lógica de negocios directamente

#### 5. New-BootstrapStateFromRequest (Constructor)
- **Propósito**: Crear estado inicial del motor a partir de la solicitud del usuario
- **Responsabilidad ÚNICA**:
  - Recibir BootstrapRequest
  - Generar BootstrapState con valores iniciales
- **NO hace**:
  - Interactuar con usuario
  - Modificar BootstrapRequest
  - Ejecutar pasos
  - Invocar managers

---

## Matriz de Dependencias

| Componente | PUEDE depender de | NO PUEDE depender de |
|------------|-------------------|----------------------|
| **BootstrapRequest** | (ninguno) | Cualquier otro componente |
| **BootstrapState** | (ninguno) | Cualquier otro componente |
| **Start-HermesProject** | BootstrapRequest, BootstrapState | BootstrapOrchestrator, Managers |
| **BootstrapOrchestrator** | BootstrapRequest, BootstrapState | Start-HermesProject, Managers |
| **New-BootstrapStateFromRequest** | BootstrapRequest, BootstrapState | Start-HermesProject, BootstrapOrchestrator, Managers |

## Matriz de Consumidores

| Componente | ES consumido por | NO ES consumido por |
|------------|------------------|---------------------|
| **BootstrapRequest** | Start-HermesProject, BootstrapOrchestrator, New-BootstrapStateFromRequest | (ninguno) |
| **BootstrapState** | Start-HermesProject, BootstrapOrchestrator, Managers | (ninguno) |
| **BootstrapOrchestrator** | Start-HermesProject | (ninguno) |
| **New-BootstrapStateFromRequest** | Start-HermesProject | BootstrapOrchestrator |

---

## Responsabilidades Prohibidas

### BootstrapRequest NO DEBE:
- ❌ Ejecutar validaciones de entorno
- ❌ Interactuar con sistema de archivos
- ❌ Invocar comandos del sistema
- ❌ Modificar estado global
- ❌ Contener métodos que ejecuten acciones

### BootstrapState NO DEBE:
- ❌ Contener datos del usuario
- ❌ Definir propiedades de configuración del proyecto
- ❌ Ejecutar validaciones
- ❌ Interactuar con sistema de archivos
- ❌ Almacenar preferencias del usuario

### Start-HermesProject NO DEBE:
- ❌ Ejecutar pasos directamente
- ❌ Crear archivos/carpetas del proyecto
- ❌ Invocar EnvironmentManager, GitManager, ContextEngine, VSCodeManager
- ❌ Modificar BootstrapState
- ❌ Contener lógica de orquestación compleja

### BootstrapOrchestrator NO DEBE:
- ❌ Interactuar con el usuario (Read-Host, Write-Host para prompts)
- ❌ Crear BootstrapRequest
- ❌ Ejecutar comandos del sistema directamente
- ❌ Crear archivos/carpetas
- ❌ Implementar lógica de validación de entorno

### New-BootstrapStateFromRequest NO DEBE:
- ❌ Interactuar con el usuario
- ❌ Modificar el BootstrapRequest recibido
- ❌ Ejecutar pasos
- ❌ Invocar managers
- ❌ Contener lógica de negocios compleja

---

## Nivel de Estabilidad

### 🔵 Componentes Congelados
**Estabilidad**: Alta (no se modifican en esta fase)

- **BootstrapState** (definición de interfaz)
- **BootstrapOrchestrator** (estructura del orquestador)

### 🟡 Componentes en Evolución
**Estabilidad**: Media (pueden refinarse en iteraciones futuras)

- **BootstrapRequest** (interfaz estable, propiedades pueden extenderse con cuidado)
- **Start-HermesProject** (implementación puede ajustarse)

### ⚪ Componentes Pendientes
**Estabilidad**: Baja (pendientes de implementación)

- **New-BootstrapStateFromRequest** (pendiente de implementación en iteración 4.5-B)

---

## Criterios de Aceptación

### Para que este documento sea aprobado:

✅ **Claridad de Interfaces**
- Definición clara de BootstrapRequest y BootstrapState
- Propiedades bien especificadas
- Reglas de inmutabilidad/mutabilidad explícitas

✅ **Separación de Responsabilidades**
- Cada componente tiene UNA responsabilidad principal
- No hay duplicación de responsabilidades
- Las dependencias son unidireccionales y verificables

✅ **Matriz de Dependencias Completa**
- Todas las relaciones componente→contrato están documentadas
- No existen dependencias circulares
- Los límites de lo que NO debe hacer cada componente están explícitos

✅ **Matriz de Consumidores Completa**
- Se sabe quién consume cada componente
- Las relaciones consumidor→componente están documentadas

✅ **Niveles de Estabilidad Definidos**
- Se identifican componentes congelados
- Se identifican componentes en evolución
- Se identifican componentes pendientes

✅ **Criterios de Aceptación por Iteración**
- Iteración 4.5-A: documento de contratos aprobado
- Iteración 4.5-B: implementación de New-BootstrapStateFromRequest

---

## Próximos Pasos

### Una vez aprobado este documento:

**Iteración 4.5-A**: Validación de Contratos
- Revisión por el equipo
- Aprobación del documento
- No se modifica código

**Iteración 4.5-B**: Implementación de New-BootstrapStateFromRequest
- Crear archivo: `motor/bootstrap/engine/New-BootstrapStateFromRequest.ps1`
- Implementar función: `New-BootstrapStateFromRequest`
- Pruebas unitarias
- Verificación ad-hoc
- Limpieza de scripts temporales
- Working tree limpio
- Commit atómico

**Iteración 4.5-C**: Decisión sobre ConvertToBootstrapState
- Evaluar si eliminar, refactorizar o mantener
- Implementar decisión
- Pruebas
- Commit atómico

---

## Notas de Diseño

### Principio de Inversión de Dependencias
Los componentes de alto nivel (Start-HermesProject, BootstrapOrchestrator) deben depender de abstracciones (BootstrapRequest, BootstrapState), no de implementaciones concretas.

### Principio de Responsabilidad Única
Cada componente hace UNA cosa y la hace bien. Si un componente necesita hacer múltiples cosas, debe delegar.

### Principio de Inmutabilidad
BootstrapRequest es inmutable por diseño. Esto garantiza que la intención del usuario no cambie durante la ejecución.

### Principio de Separación de Preocupaciones
- Datos del usuario → BootstrapRequest
- Estado del motor → BootstrapState
- Interacción con usuario → Start-HermesProject
- Orquestación → BootstrapOrchestrator
- Conversión → New-BootstrapStateFromRequest

---

## Cambios Documentados

### Diferencias con la implementación anterior

#### BootstrapRequest
- **Antes**: Propiedades como `SolicitarEntorno`, `SolicitarGit` indicaban qué solicitar
- **Ahora**: Propiedades como `CrearEntornoVirtual`, `InicializarGit` declaran QUÉ HACER
- **Razón**: El Entry Point solo necesita saber qué desea el usuario, no qué preguntar

#### BootstrapState (invariante)
- **Antes**: Solo metadatos de ejecución
- **Ahora**: Solo metadatos de ejecución (sin cambios)
- **Razón**: Separación clara entre datos del usuario y estado del motor

#### BootstrapOrchestrator (invariante)
- **Antes**: Solo coordinación
- **Ahora**: Solo coordinación
- **Razón**: Congelado, mantiene su responsabilidad única

#### Start-HermesProject (refinado)
- **Antes**: Delegaba preguntas, ejecutaba lógica
- **Ahora**: ÚNICA interfaz, construye BootstrapRequest, delega todo
- **Razón**: Centralización de interacción con usuario

#### New-BootstrapStateFromRequest (nuevo)
- **Antes**: No existía
- **Ahora**: Constructor de BootstrapState a partir de BootstrapRequest
- **Razón**: Componente intermedio necesario para mantener inmutabilidad de Request y State

---

## Glosario

- **DTO**: Data Transfer Object. Objeto que transporta datos entre procesos.
- **Immutable**: No puede modificarse después de su creación.
- **Entry Point**: Punto de entrada principal al sistema.
- **Orchestration**: Coordinación de múltiples pasos en secuencia correcta.
- **Contract**: Interfaz que define estructura de datos sin lógica de negocios.
- **Component**: Unidad ejecutable con responsabilidad específica.

---

## Aprobación

- [ ] Documento revisado
- [ ] Matriz de dependencias validada
- [ ] Matriz de consumidores validada
- [ ] Responsabilidades prohibidas aceptadas
- [ ] Niveles de estabilidad acordados
- [ ] Criterios de aceptación definidos

**Fecha de aprobación**: ___________
**Firmado por**: ___________

---

*Documento generado en colaboración Hermes Agent + Usuario durante la fase 4.5 de estabilización arquitectónica del Bootstrap Engine.*
