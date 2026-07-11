# PROJECT_ARCHITECTURE_CONTRACT.md

## Sprint 5.4 — Design Lock
## Versión: 1.0
## Fecha: 2026-07-10

---

## Índice

1. [Responsabilidad](#responsabilidad)
2. [Entradas](#entradas)
3. [Salidas](#salidas)
4. [Responsabilidades Prohibidas](#responsabilidades-prohibidas)
5. [Dependencias](#dependencias)

---

## 1. Responsabilidad

ProjectArchitecture representa el contrato arquitectónico de un proyecto antes de su creación física.

Su responsabilidad es definir el modelo arquitectónico abstracto que servirá como entrada para todo el Kernel de Hermes Enterprise.

ProjectArchitecture es independiente del lenguaje, framework o proveedor cloud.

---

## 2. Entradas

Información necesaria para diseñar un proyecto:

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| NombreProyecto | String | Sí | Identificador único del proyecto |
| Descripción | String | Sí | Propósito y alcance del proyecto |
| TipoProyecto | Enum | Sí | Clasificación del proyecto |
| LenguajePrincipal | String | Sí | Lenguaje de programación principal |
| FrameworkFrontend | String | No | Framework para interfaz de usuario |
| FrameworkBackend | String | No | Framework para lógica de negocio |
| RequiereFrontend | Boolean | Sí | Indica si requiere interfaz de usuario |
| RequiereBackend | Boolean | Sí | Indica si requiere lógica de negocio |
| RequiereAzure | Boolean | Sí | Indica si requiere infraestructura Azure |
| RequiereGitHub | Boolean | Sí | Indica si requiere integración con GitHub |
| CapacidadesSeleccionadas | Array | No | Lista de capacidades adicionales |

---

## 3. Salidas

Modelo arquitectónico aprobado que contiene:

- Nombre del proyecto
- Descripción del proyecto
- Tipo de proyecto
- Lenguaje principal
- Componentes requeridos (Frontend, Backend, Azure, GitHub)
- Capacidades seleccionadas
- Estructura mínima obligatoria del proyecto

### Estructura Mínima Obligatoria

Todo proyecto generado por Hermes Enterprise tendrá SIEMPRE esta estructura:

```
Proyecto/
├── FrontEnd/
├── BackEnd/
├── README.md
├── .gitignore
└── .hermes/
```

**Nota:** Aunque FrontEnd o BackEnd no se utilicen, las carpetas deben existir vacías.

La estructura será la base para futuros despliegues independientes.

---

## 4. Responsabilidades Prohibidas

ProjectArchitecture NO debe:

- ✗ Crear carpetas
- ✗ Crear archivos
- ✗ Ejecutar comandos del sistema operativo
- ✗ Consultar Azure
- ✗ Consultar Git
- ✗ Validar infraestructura
- ✗ Instalar software

ProjectArchitecture es un contrato puro. Solo define el modelo.

---

## 5. Dependencias

ProjectArchitecture no tiene dependencias.

Es un componente autónomo que recibe datos y produce un modelo arquitectónico.

No interactúa con:

- BootstrapEngine
- BootstrapState
- BootstrapRequest
- BootstrapOrchestrator
- ContextEngine
- Providers
- Capabilities
- Plugins
- Builders

---

## Criterios de Aceptación

✓ Solo define el modelo arquitectónico
✓ No ejecuta ninguna acción física
✓ Es independiente del lenguaje y proveedor
✓ Sirve como entrada para todo el Kernel
✓ Define la estructura mínima obligatoria del proyecto

---

## Documento Relacionado

Ver [PROJECT_STRUCTURE_SEQUENCE.md](./PROJECT_STRUCTURE_SEQUENCE.md) para la secuencia de creación.

---

## Fin del Documento
