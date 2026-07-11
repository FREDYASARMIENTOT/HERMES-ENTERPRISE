# PROJECT_STRUCTURE_SEQUENCE.md

## Sprint 5.4 — Design Lock
## Versión: 1.0
## Fecha: 2026-07-10

---

## Índice

1. [Secuencia de Creación](#secuencia-de-creación)
2. [Flujo Detallado](#flujo-detallado)
3. [Consumo y Producción por Etapa](#consumo-y-producción-por-etapa)

---

## 1. Secuencia de Creación

```
Usuario
↓
Start-HermesProject
↓
ProjectArchitecture
↓
BootstrapRequest
↓
BootstrapState
↓
BootstrapOrchestrator
↓
Capabilities
↓
Proyecto Generado
```

---

## 2. Flujo Detallado

### 2.1 Usuario

**Roll:** Define los requisitos iniciales del proyecto.

**Acción:** Proporciona información sobre el proyecto que desea crear.

**Salida:** Datos de entrada para Start-HermesProject.

---

### 2.2 Start-HermesProject

**Roll:** Interfaz de entrada del usuario al sistema de creación de proyectos.

**Consumo:** Datos proporcionados por el usuario.

**Producción:** Solicitud estructurada para ProjectArchitecture.

**Acción:** Recopila y valida la información inicial del usuario.

---

### 2.3 ProjectArchitecture

**Roll:** Diseñador arquitectónico abstracto.

**Consumo:** Datos estructurados de Start-HermesProject.

**Producción:** Modelo arquitectónico aprobado.

**Acción:** Define el modelo arquitectónico del proyecto:

- Nombre del proyecto
- Descripción del proyecto
- Tipo de proyecto
- Lenguaje principal
- Componentes requeridos (Frontend, Backend, Azure, GitHub)
- Capacidades seleccionadas
- Estructura mínima obligatoria:
  ```
  Proyecto/
  ├── FrontEnd/
  ├── BackEnd/
  ├── README.md
  ├── .gitignore
  └── .hermes/
  ```

**Nota:** Aunque FrontEnd o BackEnd no se utilicen, las carpetas deben existir vacías.

---

### 2.4 BootstrapRequest

**Roll:** Solicitud física de creación de proyecto.

**Consumo:** Modelo arquitectónico de ProjectArchitecture.

**Producción:** Solicitud ejecutable para BootstrapState.

**Acción:** Convierte el modelo arquitectónico abstracto en una solicitud concreta que puede ser procesada por el sistema.

---

### 2.5 BootstrapState

**Roll:** Estado dinámico del proceso de creación.

**Consumo:** BootstrapRequest.

**Producción:** Estado actualizado con métricas y progreso.

**Acción:** Tracking el progreso de la creación del proyecto:

- Métricas de ejecución
- Estado de cada etapa
- Errores detectados
- Contexto acumulado

---

### 2.6 BootstrapOrchestrator

**Roll:** Coordinador del proceso de creación.

**Consumo:** BootstrapState actualizado.

**Producción:** Instrucciones de ejecución para Capabilities.

**Acción:** Coordina la secuencia de ejecución basada en el estado actual.

---

### 2.7 Capabilities

**Roll:** Capacidad específica del proyecto.

**Consumo:** Instrucciones del BootstrapOrchestrator.

**Producción:** Componentes físicos del proyecto.

**Acción:** Ejecuta las acciones concretas para crear cada componente del proyecto.

---

### 2.8 Proyecto Generado

**Roll:** Resultado final del proceso.

**Consumo:** Componentes creados por Capabilities.

**Producción:** Proyecto físico listo para usar.

**Estructura Final:**

```
Proyecto/
├── FrontEnd/
├── BackEnd/
├── README.md
├── .gitignore
└── .hermes/
```

**Nota:** Aunque FrontEnd o BackEnd no se utilicen, las carpetas deben existir vacías.

---

## 3. Consumo y Producción por Etapa

| Etapa | Role | Consumo | Producción |
|-------|------|---------|------------|
| Usuario | Define requisitos | — | Datos de entrada |
| Start-HermesProject | Interfaz de entrada | Datos del usuario | Solicitud estructurada |
| ProjectArchitecture | Diseñador arquitectónico | Solicitud estructurada | Modelo arquitectónico |
| BootstrapRequest | Solicitud física | Modelo arquitectónico | Solicitud ejecutable |
| BootstrapState | Estado dinámico | Solicitud ejecutable | Estado actualizado |
| BootstrapOrchestrator | Coordinador | Estado actualizado | Instrucciones de ejecución |
| Capabilities | Capacidad específica | Instrucciones | Componentes físicos |
| Proyecto Generado | Resultado | Componentes físicos | Proyecto listo para usar |

---

## Documento Relacionado

Ver [PROJECT_ARCHITECTURE_CONTRACT.md](./PROJECT_ARCHITECTURE_CONTRACT.md) para la definición del modelo arquitectónico.

---

## Fin del Documento
