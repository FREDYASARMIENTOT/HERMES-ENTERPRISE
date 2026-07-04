# Hermes Enterprise 1.0.0 — Plan Maestro de Implementación

> **Para Hermes:** ejecutar este plan por fases. Antes de implementar código, crear issues/épicas o tablero Kanban si se desea trazabilidad formal. No modificar el core oficial de Hermes Agent; toda integración debe hacerse mediante configuración, módulos externos, scripts, plugins o adaptadores.

**Repositorio:** https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE

**Estado actual inspeccionado:** el repositorio local `D:\HERMES-ENTERPRISE` apunta al remoto `https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE.git`, rama `main`, sin commits iniciales y prácticamente vacío salvo `.git`.

**Objetivo:** construir Hermes Enterprise como framework empresarial modular para agentes inteligentes sobre Hermes Agent 0.17+, Azure AI Foundry, MCP, A2A, memoria semántica e integraciones Microsoft/enterprise.

**Arquitectura:** arquitectura hexagonal + Clean Architecture, con núcleo de dominio independiente, puertos/adaptadores para proveedores, configuración centralizada y automatización. PowerShell 7 será el lenguaje principal para operación/automatización; Python 3.11+ se usará para componentes donde convenga SDK, pruebas, análisis o servicios auxiliares.

**Stack base:** PowerShell 7, Python 3.11+, Hermes Agent 0.17+, Azure AI Foundry, GitHub Actions, Pester, PSScriptAnalyzer, pytest, dotenv, futura integración con Azure Key Vault, Microsoft Graph, Fabric, OneLake, Power BI, SQL Server, SAP, MCP, ACP y A2A.

**Filosofía del proyecto:** no construiremos únicamente un framework. Construiremos una Plataforma Empresarial de Ingeniería para Agentes Inteligentes. Su propósito será permitir que cualquier organización pueda desarrollar, desplegar, gobernar y operar ecosistemas completos de agentes inteligentes interoperables sobre Azure AI Foundry, manteniendo principios de arquitectura limpia, trazabilidad, seguridad y extensibilidad.

**Single Source of Truth:** el repositorio será la fuente única de verdad para código, arquitectura, requisitos, documentación, decisiones, pruebas, roadmap, releases y trazabilidad.

---

## 1. Diagnóstico inicial

El proyecto debe arrancar como producto empresarial, no como colección de scripts. La especificación entregada define un alcance amplio; por eso conviene dividirlo en capas, fases y entregables verificables.

Puntos clave detectados:

1. El repositorio está vacío, por lo que la primera prioridad es crear estructura, documentación, licencia, convenciones y pipeline mínimo.
2. Los RNF son suficientemente importantes para convertirse en artefactos trazables: épicas, historias, criterios de aceptación y pruebas.
3. El requisito más diferenciador para la versión 1.0.0 es el descubrimiento automático de deployments Azure AI Foundry y sincronización con perfiles/model registry de Hermes Enterprise.
4. El proyecto debe mantener independencia total del core de Hermes Agent.
5. Se requiere evitar configuración manual repetitiva desde el primer hito.
6. El idioma principal del proyecto puede ser español, pero la plataforma debe preparar internacionalización español/inglés.
7. La documentación no debe ser secundaria: será el sistema de gobierno del producto. El handbook `documentacion/` deberá evolucionar junto al código.
8. La trazabilidad completa debe existir desde el inicio: requisito → épica → historia → caso de uso → componente → módulo → prueba → commit → versión.

---

## 2. Principios rectores obligatorios

Estos principios deben aplicarse en cada fase:

- No guardar secretos en Git.
- No codificar rutas absolutas.
- No mantener listas estáticas de modelos si pueden descubrirse automáticamente.
- No modificar Hermes Agent oficial.
- Cada módulo debe tener responsabilidad única.
- Cada script debe validar prerequisitos, manejar errores y emitir mensajes descriptivos.
- Toda operación relevante debe generar logs estructurados.
- Cada requisito importante debe tener prueba o validación verificable.
- Todo cambio funcional debe pasar por PR y revisión.
- Automatizar cualquier configuración repetitiva.

---

## 2.1. Marco metodológico

Hermes Enterprise combinará buenas prácticas reconocidas, cada una aportando una dimensión distinta del producto.

| Disciplina | Estándar / Metodología | Aplicación en HERMES-ENTERPRISE |
|---|---|---|
| Ingeniería de requisitos | IEEE 29148 | Especificación, clasificación, criterios de aceptación y trazabilidad de requisitos. |
| Arquitectura de software | ISO/IEC/IEEE 42010 | Descripción formal de arquitectura, stakeholders, concerns, vistas y decisiones. |
| Calidad de software | ISO/IEC 25010 | Requisitos no funcionales y atributos de calidad medibles. |
| Ciclo de vida | ISO/IEC/IEEE 12207 | Organización del desarrollo, mantenimiento, operación y evolución. |
| Gestión ágil | Scrum + Kanban | Planificación iterativa, backlog, sprints, flujo continuo y seguimiento visual. |
| Documentación | Docs as Code | Documentación versionada junto con el código, revisada por PR y validada por CI. |
| Versionamiento | Semantic Versioning | Gestión de versiones, releases internas y releases enterprise. |
| Commits | Conventional Commits | Historial uniforme, automatizable y conectado con changelog/versiones. |
| Arquitectura de solución | Clean Architecture + Hexagonal | Separación entre dominio, aplicación, infraestructura y adaptadores. |
| Integración | OpenAPI + JSON Schema | Contratos explícitos para APIs, configuraciones y payloads interoperables. |

---

## 3. Estructura propuesta del repositorio

Crear esta estructura inicial. La carpeta canónica de documentación será `documentacion/`, no `docs/`, porque el proyecto se tratará como producto empresarial con un handbook formal de arquitectura e ingeniería de software.

```text
HERMES-ENTERPRISE/
├── .github/
├── .vscode/
├── arquitectura/
├── builders/
├── catalogo/
├── configuracion/
├── documentacion/
├── herramientas/
├── motor/
├── perfiles/
├── plantillas/
├── proveedores/
├── protocolos/
├── pruebas/
├── scripts/
├── src/
│   ├── Core/
│   ├── Providers/
│   ├── Profiles/
│   ├── Discovery/
│   ├── Memory/
│   ├── Registry/
│   ├── Agents/
│   ├── Gateway/
│   ├── VSCode/
│   ├── Desktop/
│   ├── Integrations/
│   ├── Observability/
│   └── Common/
└── tests/
```

---

## 3.1. Biblioteca técnica de documentación

No tendremos un único documento. Tendremos una biblioteca técnica versionada como Docs as Code.

```text
documentacion/
├── 00-PROYECTO/
│   ├── 00-Presentacion.md
│   ├── 01-Vision.md
│   ├── 02-Mision.md
│   ├── 03-Objetivos.md
│   ├── 04-Alcance.md
│   └── 05-Glosario.md
├── 01-INGENIERIA-REQUISITOS/
│   ├── SRS.md
│   ├── RequisitosFuncionales.md
│   ├── RequisitosNoFuncionales.md
│   ├── Restricciones.md
│   ├── ReglasNegocio.md
│   └── MatrizTrazabilidad.md
├── 02-ARQUITECTURA/
│   ├── ArquitecturaEmpresarial.md
│   ├── ArquitecturaLogica.md
│   ├── ArquitecturaFisica.md
│   ├── ArquitecturaTecnologica.md
│   ├── ArquitecturaIntegracion.md
│   ├── ArquitecturaDespliegue.md
│   ├── ArquitecturaSeguridad.md
│   ├── ArquitecturaDatos.md
│   └── ArquitecturaMemoria.md
├── 03-DOMINIO/
│   ├── ModeloDominio.md
│   ├── ModeloDatos.md
│   └── Diccionario.md
├── 04-DESARROLLO/
│   ├── Convenciones.md
│   ├── GuiaPowerShell.md
│   ├── GuiaPython.md
│   ├── GuiaMarkdown.md
│   └── GuiaGit.md
├── 05-HERMES/
│   ├── IntegracionHermes.md
│   ├── Providers.md
│   ├── Skills.md
│   ├── Profiles.md
│   └── Gateway.md
├── 06-AZURE/
│   ├── AzureFoundry.md
│   ├── AzureOpenAI.md
│   ├── MicrosoftGraph.md
│   ├── Fabric.md
│   └── OneLake.md
├── 07-PLANIFICACION/
│   ├── ProductBacklog.md
│   ├── Roadmap.md
│   ├── SprintPlanning.md
│   ├── HistoriasUsuario.md
│   └── CasosUso.md
├── 08-OPERACION/
│   ├── Observabilidad.md
│   ├── Seguridad.md
│   ├── Backup.md
│   └── Despliegue.md
└── anexos/
    ├── ADR/
    ├── diagramas/
    ├── plantillas/
    └── referencias/
```

La estructura anterior reemplaza el esquema plano inicial de capítulos 00 a 20. Los capítulos siguen existiendo conceptualmente, pero quedan organizados en carpetas empresariales para facilitar mantenimiento, escalabilidad y trazabilidad.

---

## 3.2. Software Architecture & Engineering Handbook

La documentación propuesta se integra como un handbook empresarial versionado dentro de `documentacion/`. Su propósito no es solo describir el sistema, sino gobernar su evolución.

### Capítulo 0 — Introducción

**Archivo:** `documentacion/00-PROYECTO/00-Presentacion.md`

Debe describir:

- Qué es Hermes Enterprise.
- Por qué existe.
- Objetivos generales y específicos.
- Alcance funcional y no funcional.
- Audiencia objetivo: arquitectos, desarrolladores, administradores, auditores, usuarios avanzados.
- Relación con Hermes Agent, Azure AI Foundry, MCP, A2A y memoria empresarial.

### Capítulo 1 — Visión

**Archivo:** `documentacion/00-PROYECTO/01-Vision.md`

Debe construirse como un Vision Document de nivel empresarial.

Contenido obligatorio:

- Misión.
- Visión.
- Principios.
- Objetivos.
- Metas.
- Stakeholders.
- Restricciones.
- Riesgos.
- Oportunidades.
- Criterios de éxito.

### Capítulo 2 — SRS

**Archivo:** `documentacion/01-INGENIERIA-REQUISITOS/SRS.md`

Será el documento principal de especificación de requisitos, alineado con IEEE 29148. Puede crecer progresivamente hasta más de 100 páginas.

Contenido obligatorio:

- Introducción.
- Propósito.
- Alcance.
- Glosario.
- Referencias.
- Visión general.
- Actores.
- Casos de uso.
- Modelo de dominio.
- Interfaces externas.
- Requisitos funcionales.
- Requisitos no funcionales.
- Restricciones.
- Supuestos.
- Dependencias.
- Trazabilidad.
- Apéndices.

### Capítulo 3 — Arquitectura

**Archivo:** `documentacion/02-ARQUITECTURA/ArquitecturaEmpresarial.md`

Debe combinar TOGAF, Clean Architecture, arquitectura hexagonal e ISO 42010.

Vistas obligatorias:

- Arquitectura empresarial.
- Arquitectura lógica.
- Arquitectura física.
- Arquitectura tecnológica.
- Arquitectura de despliegue.
- Arquitectura de integración.
- Arquitectura de agentes.
- Arquitectura MCP.
- Arquitectura A2A.
- Arquitectura Azure.
- Arquitectura VS Code.
- Arquitectura Desktop.
- Arquitectura Gateway.
- Arquitectura memoria.
- Arquitectura observabilidad.
- Arquitectura seguridad.

### Capítulo 4 — Modelo de Dominio

**Archivo:** `documentacion/03-DOMINIO/ModeloDominio.md`

Debe documentar los objetos principales del dominio.

Objetos iniciales:

- Proveedor.
- Deployment.
- Modelo.
- Perfil.
- Agente.
- Skill.
- Gateway.
- Tool.
- Conversation.
- Prompt.
- Context.
- Memory.
- Embedding.
- KnowledgeBase.
- Workflow.
- Task.
- Project.
- Repository.
- Plugin.
- Extension.
- Capability.
- Provider.
- Resource.
- Credential.
- Endpoint.
- Environment.
- Configuration.
- Registry.

Cada objeto debe incluir:

- Responsabilidades.
- Relaciones.
- Atributos.
- Métodos.
- Estados.
- Reglas de negocio asociadas.
- Requisitos relacionados.
- Componentes de código relacionados.

### Capítulo 5 — Requisitos

**Archivo:** `documentacion/01-INGENIERIA-REQUISITOS/RequisitosFuncionales.md` y `documentacion/01-INGENIERIA-REQUISITOS/RequisitosNoFuncionales.md`

Debe consolidar más de 200 requisitos progresivamente.

Tipos de requisitos:

- RF: requisitos funcionales.
- RNF: requisitos no funcionales.
- RN: reglas de negocio.
- RI: requisitos de interfaz.
- RC: restricciones.
- RO: requisitos operacionales.
- RS: requisitos de seguridad.
- RG: requisitos de gobierno de IA.

Formato obligatorio de identificador:

- `RF-001` para requisitos funcionales.
- `RNF-001` para requisitos no funcionales.
- `RN-001` para reglas de negocio.
- `RI-001` para interfaces.
- `RC-001` para restricciones.
- `RO-001` para operación.
- `RS-001` para seguridad.
- `RG-001` para gobierno de IA.

Cada requisito debe tener:

- Identificador único.
- Nombre.
- Descripción.
- Justificación.
- Prioridad.
- Fuente.
- Criterio de aceptación medible.
- Estado.
- Épica relacionada.
- Historias relacionadas.
- Casos de uso relacionados.
- Componentes afectados.
- Pruebas asociadas.
- Versión objetivo.

### Capítulo 6 — Casos de Uso

**Archivo:** `documentacion/07-PLANIFICACION/CasosUso.md`

Casos iniciales:

- `CU-001` Descubrir deployments.
- `CU-002` Crear perfil.
- `CU-003` Actualizar perfil.
- `CU-004` Sincronizar Azure.
- `CU-005` Consultar modelo.
- `CU-006` Registrar memoria.
- `CU-007` Crear agente.
- `CU-008` Ejecutar workflow.
- `CU-009` Sincronizar MCP.
- `CU-010` Registrar plugin.
- `CU-011` Instalar distribución.

Cada caso de uso debe incluir:

- Actor principal.
- Actores secundarios.
- Disparador.
- Precondiciones.
- Flujo principal.
- Flujos alternos.
- Excepciones.
- Postcondiciones.
- Requisitos relacionados.
- Pruebas relacionadas.

### Capítulo 7 — Historias de Usuario

**Archivo:** `documentacion/07-PLANIFICACION/HistoriasUsuario.md`

Formato Scrum obligatorio:

```text
Como [rol]
Quiero [capacidad]
Para [beneficio]
```

Cada historia debe incluir:

- Identificador `HU-000`.
- Épica.
- Feature.
- Criterios de aceptación.
- Requisitos relacionados.
- Casos de uso relacionados.
- Componentes afectados.
- Pruebas asociadas.
- Estado.
- Versión objetivo.

### Capítulo 8 — Product Backlog

**Archivo:** `documentacion/07-PLANIFICACION/ProductBacklog.md`

Debe organizarse por:

- Épicas.
- Features.
- Historias.
- Tasks.
- Subtasks.

Jerarquía recomendada:

```text
EPIC-000
  FEATURE-000
    HU-000
      TASK-000
        SUBTASK-000
```

### Capítulo 9 — Roadmap

**Archivo:** `documentacion/07-PLANIFICACION/Roadmap.md`

Roadmap estratégico de cinco versiones:

- `v1.0 Foundation`: fundación, configuración, Azure Foundry, registro de modelos, perfiles, observabilidad base.
- `v2.0 Enterprise`: seguridad avanzada, integraciones Microsoft, gobierno, administración empresarial.
- `v3.0 Memory`: memoria semántica empresarial, knowledge bases, embeddings, recuperación y contexto persistente.
- `v4.0 Multi Agent`: orquestación multiagente, MCP/A2A avanzado, workflows distribuidos.
- `v5.0 Autonomous Organization`: organización autónoma basada en agentes, automatización estratégica y operación continua.

### Capítulo 10 — Convenciones

**Archivo:** `documentacion/04-DESARROLLO/Convenciones.md`

Debe contener reglas para:

- Variables.
- Funciones.
- Comentarios.
- PowerShell.
- Python.
- Markdown.
- JSON.
- YAML.
- Git.
- Commits.
- Versionado.
- Documentación.
- Trazabilidad.

### Capítulo 11 — Guía de Desarrollo

**Archivo:** `documentacion/04-DESARROLLO/GuiaGit.md` y `documentacion/07-PLANIFICACION/SprintPlanning.md`

Debe explicar:

- Cómo contribuir.
- Cómo crear Pull Requests.
- Cómo crear features.
- Cómo crear providers.
- Cómo crear plugins.
- Cómo escribir pruebas.
- Cómo actualizar documentación y trazabilidad.

### Capítulo 12 — Estándar PowerShell

**Archivo:** `documentacion/04-DESARROLLO/GuiaPowerShell.md`

Será un estándar propio del proyecto, más estricto que el mínimo oficial.

Debe cubrir:

- Nombres descriptivos en español.
- Funciones verbo-sustantivo.
- Validación de parámetros.
- Manejo de errores.
- Logging estructurado.
- Comentarios detallados.
- Pruebas con Pester.
- PSScriptAnalyzer.
- Seguridad y secretos.
- Compatibilidad multiplataforma.

Nota: se corrige el nombre propuesto `12-GUIA-POWERHELL.md` a `12-GUIA-POWERSHELL.md`.

### Capítulo 13 — Estándar Python

**Archivo:** `documentacion/04-DESARROLLO/GuiaPython.md`

Debe cubrir:

- Organización de paquetes.
- Tipado.
- pytest.
- Estilo.
- Logging.
- Manejo de errores.
- Configuración.
- Seguridad.
- Integración con PowerShell.

### Capítulo 14 — Estándar Hermes

**Archivo:** `documentacion/05-HERMES/IntegracionHermes.md`

Debe explicar:

- Cómo extender Hermes sin modificar core.
- Cómo crear providers.
- Cómo crear skills.
- Cómo crear profiles.
- Cómo crear gateway plugins.
- Cómo integrar Desktop, Gateway y CLI.

### Capítulo 15 — Azure Foundry

**Archivo:** `documentacion/06-AZURE/AzureFoundry.md`

Debe documentar:

- Modelo de integración.
- Autenticación.
- Descubrimiento de deployments.
- Registro de modelos.
- Mapeo Azure → Hermes Enterprise.
- Errores comunes.
- Seguridad.
- Pruebas.

### Capítulo 16 — MCP

**Archivo:** `documentacion/05-HERMES/Providers.md` y sección MCP en `documentacion/02-ARQUITECTURA/ArquitecturaIntegracion.md`

Debe documentar servidores MCP, capacidades, contratos, configuración y pruebas.

### Capítulo 17 — A2A

**Archivo:** sección A2A en `documentacion/02-ARQUITECTURA/ArquitecturaIntegracion.md`

Debe documentar comunicación agente-a-agente, contratos de mensajes, descubrimiento de capacidades y gobierno.

### Capítulo 18 — Enterprise Memory

**Archivo:** `documentacion/02-ARQUITECTURA/ArquitecturaMemoria.md`

Debe documentar memoria semántica, embeddings, knowledge bases, recuperación, retención, seguridad y gobernanza.

### Capítulo 19 — Estándares

**Archivo:** `documentacion/04-DESARROLLO/Convenciones.md` y anexos de referencias.

Estándares base:

- ISO/IEC 25010.
- IEEE 29148.
- IEEE 1016.
- ISO/IEC/IEEE 42010.
- ISO/IEC/IEEE 12207.
- OpenAPI.
- JSON Schema.
- SemVer.
- Conventional Commits.

Cada estándar debe indicar:

- Cómo aplica al proyecto.
- Qué artefactos lo implementan.
- Qué validación se usará.

### Capítulo 20 — Diccionario de Datos

**Archivo:** `documentacion/03-DOMINIO/Diccionario.md`

Debe funcionar como una Wikipedia del proyecto.

Cada término debe incluir:

- Definición.
- Sinónimos.
- Contexto.
- Relaciones.
- Ejemplos.
- Requisitos asociados.
- Componentes relacionados.

---

## 3.3. Matriz Maestra de Trazabilidad empresarial

La matriz de trazabilidad será un mecanismo de gobernanza, no un anexo decorativo. Debe mantenerse desde el inicio y bloquear cambios incompletos cuando aplique.

Esta matriz será el eje del proyecto. Cada requisito RF/RNF tendrá un identificador único y se enlazará con todos los artefactos relacionados: visión, objetivos, épica, historia de usuario, caso de uso, componente de arquitectura, módulos de código, pruebas unitarias, pruebas de integración, pruebas de aceptación, commits, pull requests y versiones.

### Entidades trazables

Cada elemento debe tener identificador único:

- Épica: `EPIC-001`.
- Feature: `FEATURE-001`.
- Historia de usuario: `HU-001`.
- Caso de uso: `CU-001`.
- Requisito funcional: `RF-001`.
- Requisito no funcional: `RNF-001`.
- Regla de negocio: `RN-001`.
- Requisito de seguridad: `RS-001`.
- Requisito de gobierno: `RG-001`.
- Componente de arquitectura: `COMP-001`.
- Módulo de código: ruta real del repositorio.
- Caso de prueba: `TEST-001` o ruta real de test.
- Commit: SHA de Git.
- Versión: SemVer.

### Matriz principal

**Archivo:** `documentacion/01-INGENIERIA-REQUISITOS/MatrizTrazabilidad.md`

Columnas mínimas:

```text
ID Requisito | Tipo | Nombre | Épica | Feature | Historia | Caso de Uso | Componente | Módulo Código | Caso Prueba | Commit | Versión | Estado
```

### Matrices auxiliares

- `documentacion/01-INGENIERIA-REQUISITOS/MatrizTrazabilidad.md`
- `documentacion/07-PLANIFICACION/ProductBacklog.md`
- `documentacion/07-PLANIFICACION/HistoriasUsuario.md`
- `documentacion/07-PLANIFICACION/CasosUso.md`
- `documentacion/02-ARQUITECTURA/ArquitecturaEmpresarial.md`

### Reglas de trazabilidad

1. Ningún RF/RNF/RG crítico debe quedar sin épica.
2. Ningún requisito listo para desarrollo debe quedar sin historia de usuario.
3. Ninguna historia lista para implementar debe quedar sin criterio de aceptación.
4. Ninguna funcionalidad implementada debe quedar sin prueba o justificación explícita.
5. Ningún PR funcional debe aprobarse si no actualiza documentación/trazabilidad correspondiente.
6. Cada release debe declarar qué requisitos implementa.

### Automatización de trazabilidad

Crear un validador futuro:

- `scripts/Validar-TrazabilidadHermesEnterprise.ps1`
- `.github/workflows/trazabilidad-requisitos.yml`

Validaciones iniciales:

- Verificar existencia de capítulos 00 a 20.
- Verificar que cada identificador tenga formato correcto.
- Verificar que RNF-001 a RNF-028 existan.
- Verificar que no existan IDs duplicados.
- Verificar que cada requisito tenga criterio de aceptación.

---

## 4. Roadmap por fases

### Fase 0 — Fundación del producto

**Objetivo:** convertir el repositorio vacío en un producto empresarial gobernable. Esta fase no desarrolla software: construye la ingeniería del proyecto.

**Objetivos específicos:**

- Definir visión.
- Definir alcance.
- Definir arquitectura.
- Definir normas.
- Definir convenciones.
- Definir calidad.
- Definir gobierno.
- Definir organización.

**Resultado esperado:** al terminar la Fase 0 tendremos un repositorio equivalente al que una organización de ingeniería madura crea antes de escribir la primera línea de código.

**Entregables:**

- `README.md`: identidad, problema, solución, componentes, instalación, desarrollo, contribución, roadmap, licencia y autores.
- `PROJECT_CHARTER.md`: acta de nacimiento del proyecto.
- `VISION.md`: visión a 10 años.
- `MISSION.md`: misión actual del producto.
- `OBJECTIVES.md`: objetivos estratégicos, tácticos, técnicos, científicos y de negocio.
- `PRINCIPLES.md`: principios de diseño.
- `CODING_STANDARD.md`: estándar obligatorio de codificación.
- `DIRECTORY_STANDARD.md`: propósito de cada directorio y reglas de dependencia.
- `ARCHITECTURE_DECISIONS.md`: índice del registro ADR.
- `CHANGELOG.md`: Keep a Changelog + SemVer.
- `LICENSE`: licencia inicial MIT o Apache 2.0 según decisión final.
- `CONTRIBUTING.md`: guía de colaboración.
- `CODE_OF_CONDUCT.md`: código de conducta.
- `SECURITY.md`: reporte de vulnerabilidades y prácticas mínimas.
- `.github/ISSUE_TEMPLATE/`: plantillas de issues.
- `.github/PULL_REQUEST_TEMPLATE.md`: plantilla de PR.
- `.github/CODEOWNERS`: responsables de revisión.
- Configuración inicial de etiquetas, hitos y proyectos GitHub.
- Handbook empresarial `documentacion/` inicializado.
- Matriz Maestra de Trazabilidad inicial.
- Validación automatizada mínima de documentación y trazabilidad.

**Detalle de entregables Fase 0:**

- Entregable 0.1 — `README.md`.
  - Debe responder qué es Hermes Enterprise, por qué existe, qué problema resuelve, cuáles son sus componentes, cómo se instala, cómo se desarrolla, cómo se contribuye, roadmap, licencia y autores.
- Entregable 0.2 — `PROJECT_CHARTER.md`.
  - Incluye proyecto, patrocinador, autores, stakeholders, objetivos, justificación, alcance, restricciones, supuestos, riesgos y éxito esperado.
- Entregable 0.3 — `VISION.md`.
  - Describe la visión a 10 años. Ejemplo base: "Hermes Enterprise será la plataforma abierta de referencia para la construcción, gobierno y operación de ecosistemas de agentes inteligentes interoperables en organizaciones públicas y privadas, integrando modelos fundacionales, protocolos abiertos y arquitecturas empresariales bajo principios de transparencia, trazabilidad y soberanía tecnológica."
- Entregable 0.4 — `MISSION.md`.
  - Define qué hace Hermes Enterprise hoy.
- Entregable 0.5 — `OBJECTIVES.md`.
  - Objetivos estratégicos, tácticos, técnicos, científicos y de negocio.
- Entregable 0.6 — `PRINCIPLES.md`.
  - Arquitectura limpia, Open Standards, Security First, Human in the Loop, Cloud Agnostic, Azure Native, OpenAI Compatible, Provider Agnostic, Everything as Code, Documentation First, Test First, Observability First y Zero Secrets.
- Entregable 0.7 — `CODING_STANDARD.md`.
  - Código en inglés para clases, funciones y APIs cuando sea necesario para interoperabilidad.
  - Objetos de dominio, módulos, documentación y variables de alto nivel en español cuando aporten semántica empresarial.
  - Nombres largos, completos y semánticamente descriptivos.
  - Sin abreviaturas ambiguas.
  - Cada bloque de lógica de negocio con comentarios explicativos.
  - Decisiones de diseño justificadas cuando no sean evidentes.
  - Algoritmos complejos con precondiciones, postcondiciones y efectos secundarios.
  - Scripts PowerShell como archivos completos y ejecutables, no fragmentos aislados.
- Entregable 0.8 — `DIRECTORY_STANDARD.md`.
  - Propósito de cada directorio, reglas de organización y dependencias permitidas entre módulos.
- Entregable 0.9 — `ARCHITECTURE_DECISIONS.md`.
  - Registro de decisiones arquitectónicas con identificador, contexto, alternativas, decisión y consecuencias.
- Entregable 0.10 — `CHANGELOG.md`.
  - Historial desde el primer día conforme a Keep a Changelog y SemVer.
- Entregable 0.11 — `LICENSE`.
  - MIT inicialmente, con posibilidad de evaluar Apache 2.0.
- Entregable 0.12 — `CONTRIBUTING.md`.
  - Flujo de ramas, revisiones, estándares de documentación y criterios de aceptación de contribuciones.
- Entregable 0.13 — `CODE_OF_CONDUCT.md`.
- Entregable 0.14 — `SECURITY.md`.
- Entregable 0.15 — Plantillas de GitHub.
  - `ISSUE_TEMPLATE/`, `PULL_REQUEST_TEMPLATE.md`, `CODEOWNERS`, etiquetas, proyectos e hitos.

**Hito de cierre de Fase 0:**

La Fase 0 se considerará completada cuando el repositorio cuente con:

- Identidad clara y documentada.
- Especificación de gobierno del proyecto.
- Normas de ingeniería y desarrollo.
- Estructura documental y técnica inicial.
- Mecanismos de colaboración y control de cambios.

**Criterio de aceptación:**

- El repositorio puede clonarse y entenderse sin contexto externo.
- `git status` queda limpio después del commit inicial.
- La documentación identifica claramente propósito, alcance, stack, arquitectura y normas.

---

### Fase 1 — Configuración centralizada y validación de entorno

**Objetivo:** implementar el punto único de configuración y validación automatizada.

**Componentes:**

- `config/hermes-enterprise.config.example.json`
- `scripts/Validar-EntornoHermesEnterprise.ps1`
- `scripts/Inicializar-ConfiguracionHermesEnterprise.ps1`
- módulo `src/HermesEnterprise/Configuracion/`

**Capacidades:**

- Validar PowerShell 7+.
- Validar Python 3.11+.
- Validar existencia de Hermes CLI.
- Validar Azure CLI o mecanismo elegido para Azure.
- Validar variables de entorno obligatorias.
- Crear configuración local desde archivos `.example` sin copiar secretos.
- Leer configuración desde archivo y variables de entorno.

**RNF cubiertos:** RNF-003, RNF-008, RNF-014, RNF-015, RNF-017.

**Criterio de aceptación:**

- Un usuario nuevo puede ejecutar un script de validación y recibir diagnóstico claro.
- No se requiere editar rutas dentro del código.
- No se guardan secretos en archivos versionados.

---

### Fase 2 — Adaptador Azure AI Foundry y descubrimiento automático

**Objetivo:** descubrir deployments disponibles en Azure AI Foundry y construir el registro empresarial inicial de modelos.

**Componentes:**

- `src/HermesEnterprise/Dominio/Modelos/ModeloEmpresarial.ps1`
- `src/HermesEnterprise/Dominio/Proveedores/ProveedorModelo.ps1`
- `src/HermesEnterprise/Aplicacion/Descubrimiento/ServicioDescubrimientoModelos.ps1`
- `src/HermesEnterprise/Adaptadores/AzureFoundry/AdaptadorAzureFoundry.ps1`
- `scripts/Descubrir-ImplementacionesAzureFoundry.ps1`
- `tests/powershell/AzureFoundry.Tests.ps1`

**Capacidades:**

- Autenticarse con Azure sin guardar secretos.
- Leer suscripción, resource group, proyecto/hub o endpoint desde configuración.
- Consultar deployments reales disponibles.
- Normalizar metadatos del deployment: nombre, proveedor, modelo base, región, endpoint, capacidades, ventana de contexto si está disponible.
- Medir duración del descubrimiento.
- Generar salida JSON estructurada.
- Manejar fallos de red o permisos con degradación controlada.

**RNF cubiertos:** RNF-002, RNF-011, RNF-012, RNF-016, RNF-027.

**Criterio de aceptación:**

- El descubrimiento completa en menos de 5 segundos en condiciones normales.
- Si Azure no responde, el comando falla con mensaje claro y código de salida controlado.
- No existe lista estática de modelos.

---

### Fase 3 — Registro empresarial de modelos

**Objetivo:** persistir y consultar un catálogo normalizado de deployments/modelos.

**Componentes:**

- `src/HermesEnterprise/Dominio/RegistroModelos/RegistroEmpresarialModelos.ps1`
- `src/HermesEnterprise/Infraestructura/Persistencia/RepositorioModelosJson.ps1`
- `config/registro-modelos.example.json`
- `tests/powershell/RegistroModelos.Tests.ps1`

**Capacidades:**

- Registrar modelos descubiertos.
- Consultar por proveedor, capacidad, costo, contexto o estado.
- Marcar modelos como disponibles/no disponibles.
- Registrar fecha de último descubrimiento.
- Mantener historial básico o snapshot.

**RNF cubiertos:** RNF-009, RNF-010, RNF-013, RNF-021, RNF-027.

**Criterio de aceptación:**

- Un descubrimiento produce un registro JSON válido.
- El registro se puede reconstruir desde Azure o respaldo.
- Cada entrada incluye proveedor, deployment, perfil y configuración relevante.

---

### Fase 4 — Administración de perfiles inteligentes

**Objetivo:** crear perfiles de ejecución que seleccionen modelos según propósito, costo, contexto y disponibilidad.

**Componentes:**

- `src/HermesEnterprise/Dominio/Perfiles/PerfilInteligente.ps1`
- `src/HermesEnterprise/Aplicacion/Perfiles/ServicioSeleccionPerfil.ps1`
- `src/HermesEnterprise/Aplicacion/Perfiles/PoliticaSeleccionModelo.ps1`
- `config/perfiles.example.json`
- `tests/powershell/Perfiles.Tests.ps1`

**Capacidades:**

- Perfil por tarea: razonamiento, código, visión, extracción, bajo costo, alto contexto.
- Estrategia de fallback cuando el deployment principal falla.
- Compatibilidad con configuración Hermes sin modificar core.
- Exportar recomendaciones o configuración consumible por Hermes CLI.

**RNF cubiertos:** RNF-004, RNF-012, RNF-014, RNF-027.

**Criterio de aceptación:**

- Dada una intención de uso, el servicio recomienda un deployment disponible.
- Si el deployment principal no existe, propone fallback.

---

### Fase 5 — Observabilidad, auditoría y gobierno de IA

**Objetivo:** registrar cada operación importante con trazabilidad empresarial.

**Componentes:**

- `src/HermesEnterprise/Observabilidad/LoggerEstructurado.ps1`
- `src/HermesEnterprise/Observabilidad/MedidorEjecucion.ps1`
- `src/HermesEnterprise/Dominio/Auditoria/EventoAuditoria.ps1`
- `documentacion/03-ARQUITECTURA.md` sección observabilidad.
- `documentacion/19-ESTANDARES.md` sección observabilidad y auditoría.
- `tests/powershell/Observabilidad.Tests.ps1`

**Capacidades:**

- Logs JSONL.
- Campos mínimos: timestamp, operación, proveedor, deployment, perfil, tokens, costo, latencia, errores, correlationId.
- Redacción de secretos.
- Niveles de log.
- Export futuro a Application Insights o Log Analytics.

**RNF cubiertos:** RNF-009, RNF-010, RNF-027, RNF-028.

**Criterio de aceptación:**

- Cada comando principal genera un evento estructurado.
- Los logs no contienen claves API.
- La latencia y el deployment utilizado son consultables.

---

### Fase 6 — Orquestación de agentes especializados

**Objetivo:** definir una capa de agentes empresariales interoperables y gobernables.

**Componentes:**

- `src/HermesEnterprise/Dominio/Agentes/AgenteEmpresarial.ps1`
- `src/HermesEnterprise/Aplicacion/Agentes/OrquestadorAgentes.ps1`
- `documentacion/03-ARQUITECTURA.md` sección arquitectura de agentes.
- `documentacion/06-CASOS-USO.md` casos de uso de agentes.
- `config/agentes.example.json`

**Agentes iniciales sugeridos:**

- AgenteArquitectoEmpresarial
- AgenteDevOpsAzure
- AgenteAnalistaDatos
- AgenteGobiernoIA
- AgenteIntegracionMicrosoft
- AgenteDocumentador
- AgenteQA

**RNF cubiertos:** RNF-006, RNF-023, RNF-024, RNF-026.

**Criterio de aceptación:**

- Los agentes se definen declarativamente.
- El orquestador puede cargar agentes desde configuración.
- No hay dependencias rígidas entre agentes.

---

### Fase 7 — MCP, ACP y A2A

**Objetivo:** preparar interoperabilidad estándar entre herramientas, agentes y procesos.

**Componentes:**

- `documentacion/16-GUIA-MCP.md`
- `documentacion/17-GUIA-A2A.md`
- `documentacion/14-GUIA-HERMES.md` sección ACP/Hermes.
- `src/HermesEnterprise/Adaptadores/MCP/`
- `src/HermesEnterprise/Adaptadores/A2A/`

**Capacidades:**

- Inventario de servidores MCP soportados.
- Contratos mínimos de entrada/salida.
- Definición de mensajes A2A.
- Registro de capacidades por agente.

**RNF cubiertos:** RNF-005, RNF-026.

**Criterio de aceptación:**

- Existe contrato documentado para integrar un nuevo MCP.
- Existe contrato documentado para comunicación A2A.

---

### Fase 8 — Integraciones empresariales Microsoft y datos

**Objetivo:** crear adaptadores para fuentes y servicios empresariales.

**Orden recomendado:**

1. Microsoft Graph.
2. SQL Server.
3. Microsoft Fabric.
4. OneLake.
5. Power BI.
6. SAP.

**Componentes:**

- `src/HermesEnterprise/Adaptadores/MicrosoftGraph/`
- `src/HermesEnterprise/Adaptadores/SqlServer/`
- `src/HermesEnterprise/Adaptadores/Fabric/`
- `src/HermesEnterprise/Adaptadores/OneLake/`
- `src/HermesEnterprise/Adaptadores/PowerBI/`
- `src/HermesEnterprise/Adaptadores/SAP/`

**RNF cubiertos:** RNF-002, RNF-004, RNF-005, RNF-024.

**Criterio de aceptación:**

- Cada integración tiene interfaz común, documentación, configuración ejemplo y prueba mínima.

---

### Fase 9 — VS Code, Desktop y Gateway

**Objetivo:** integrar Hermes Enterprise al flujo operativo del usuario.

**Componentes:**

- `.vscode/extensions.json`
- `.vscode/settings.json.example`
- `documentacion/11-GUIA-DESARROLLO.md` sección VS Code.
- `documentacion/14-GUIA-HERMES.md` secciones Hermes Desktop y Hermes Gateway.

**Capacidades:**

- Recomendaciones VS Code.
- Tareas de validación.
- Guía de uso con Hermes Desktop.
- Guía de gateway/mensajería.

**RNF cubiertos:** RNF-004, RNF-015, RNF-019.

**Criterio de aceptación:**

- Un desarrollador puede abrir el repo en VS Code y ejecutar validaciones desde tareas.

---

## 4.1. Modelo de desarrollo por fase

Cada fase del proyecto tendrá obligatoriamente:

- Objetivo.
- Productos o artefactos entregables.
- Criterios de aceptación.
- Commit Git asociado.
- Release interna.
- Actualización de la Matriz Maestra de Trazabilidad.

El cierre de una fase no se medirá solo por código terminado, sino por evidencia versionada en el repositorio.

---

## 4.2. Roadmap General Enterprise

| Fase | Nombre | Propósito principal |
|---:|---|---|
| Fase 0 | Fundación del proyecto | Ingeniería del proyecto, identidad, gobierno, documentación base y estándares. |
| Fase 1 | Ingeniería de Requisitos | SRS, RF, RNF, reglas, restricciones, casos de uso, historias y backlog. |
| Fase 2 | Arquitectura Empresarial | Vistas empresariales, stakeholders, capabilities, dominios y gobierno. |
| Fase 3 | Modelo de Dominio | Entidades, relaciones, estados, diccionario y modelo de datos. |
| Fase 4 | Arquitectura Técnica | Componentes, módulos, runtime, despliegue, seguridad e integración. |
| Fase 5 | Plataforma Hermes Enterprise | Core, configuración, registro central, perfiles y proveedores. |
| Fase 6 | Azure Foundry Runtime | Descubrimiento de deployments, catálogo de capacidades y perfiles dinámicos. |
| Fase 7 | Sistema de Agentes | Supervisor, arquitecto, desarrollador, revisor, documentador e investigador. |
| Fase 8 | Motor MCP / A2A | Protocolos, registro de capacidades, interoperabilidad y mensajería. |
| Fase 9 | Memoria Empresarial | Memoria conversacional, semántica, de proyectos y organizacional. |
| Fase 10 | Observabilidad | Métricas, logs, auditoría, costos, trazabilidad y reporting. |
| Fase 11 | Seguridad | Zero secrets, controles, threat model, Key Vault futuro y hardening. |
| Fase 12 | DevOps | CI/CD, releases, validaciones, automatización y entornos. |
| Fase 13 | Release Enterprise | Empaquetado, documentación final, pruebas de aceptación y publicación. |

---

## 5. Épicas sugeridas

Crear estas épicas en GitHub Issues o Projects:

1. EPIC-001 Fundación del repositorio y gobierno inicial.
2. EPIC-002 Configuración centralizada y validación de entorno.
3. EPIC-003 Descubrimiento Azure AI Foundry.
4. EPIC-004 Registro empresarial de modelos.
5. EPIC-005 Perfiles inteligentes y selección de deployment.
6. EPIC-006 Observabilidad, auditoría y gobierno de IA.
7. EPIC-007 Orquestación de agentes especializados.
8. EPIC-008 Interoperabilidad MCP/ACP/A2A.
9. EPIC-009 Integraciones Microsoft y datos empresariales.
10. EPIC-010 Integración VS Code, Desktop y Gateway.
11. EPIC-011 Seguridad, recuperación y automatización.
12. EPIC-012 Internacionalización español/inglés.

---

## 6. Historias iniciales recomendadas

### HU-001 Inicializar estructura empresarial del repositorio

Como propietario del proyecto, quiero una estructura estándar de producto empresarial para que todo desarrollo futuro sea trazable, mantenible y auditable.

**Aceptación:**

- Existe README, LICENSE, CONTRIBUTING, SECURITY y CHANGELOG.
- Existe estructura `src/`, `tests/`, `documentacion/`, `config/`, `scripts/`.
- Existe pipeline inicial de validación.

### HU-002 Validar entorno local

Como desarrollador, quiero ejecutar una validación automática del entorno para saber si mi máquina puede operar Hermes Enterprise.

**Aceptación:**

- El script valida PowerShell, Python, Git, Hermes CLI y Azure CLI.
- El script no falla con errores crípticos.
- El resultado es legible y estructurado.

### HU-003 Descubrir deployments Azure AI Foundry

Como arquitecto, quiero descubrir automáticamente los deployments Azure AI Foundry para evitar mantener modelos manualmente.

**Aceptación:**

- El comando consulta Azure dinámicamente.
- La salida es JSON.
- La operación tarda menos de 5 segundos en red normal.
- No existen listas estáticas de modelos.

### HU-004 Construir registro empresarial de modelos

Como administrador, quiero persistir un catálogo de modelos disponibles para auditar y seleccionar deployments confiables.

**Aceptación:**

- El registro incluye proveedor, deployment, región, estado y fecha de descubrimiento.
- El registro puede actualizarse automáticamente.
- El registro no contiene secretos.

### HU-005 Seleccionar perfil inteligente

Como usuario empresarial, quiero que Hermes Enterprise seleccione el deployment adecuado según tarea, costo y disponibilidad.

**Aceptación:**

- La selección usa reglas configurables.
- Existe fallback documentado.
- La decisión queda auditada.

---

## 7. Matriz inicial RNF → verificación

| RNF | Verificación propuesta |
|---|---|
| RNF-001 Modularidad | Revisión de estructura por capas y dependencias. |
| RNF-002 Extensibilidad | Prueba agregando proveedor simulado sin tocar núcleo. |
| RNF-003 Portabilidad | CI en Windows, Linux y macOS cuando sea posible. |
| RNF-004 Compatibilidad | Pruebas con Hermes CLI/Desktop/Gateway documentadas. |
| RNF-005 Interoperabilidad | Contratos MCP/ACP/A2A documentados y ejemplo funcional. |
| RNF-006 Escalabilidad horizontal | Prueba de carga simulada de N agentes configurados. |
| RNF-007 Escalabilidad vertical | Prueba con metadata de modelos >1M tokens cuando disponible. |
| RNF-008 Seguridad | Escaneo de secretos y revisión `.gitignore`. |
| RNF-009 Auditoría | Validar generación de logs JSONL. |
| RNF-010 Observabilidad | Validar tokens, costo, latencia, errores y deployment en logs. |
| RNF-011 Rendimiento | Medición de descubrimiento <5s. |
| RNF-012 Disponibilidad | Prueba de fallback ante proveedor caído. |
| RNF-013 Recuperación | Export/import de configuración y registros. |
| RNF-014 Configuración centralizada | Prueba de carga desde un único archivo + env vars. |
| RNF-015 Automatización | Scripts para inicializar y validar sin pasos manuales repetitivos. |
| RNF-016 Descubrimiento automático | Prueba que falle si se introduce lista estática de deployments. |
| RNF-017 Independencia del core | Verificar que no se modifica código de Hermes Agent. |
| RNF-018 Versionamiento | CHANGELOG y tags SemVer. |
| RNF-019 Documentación | Checklist por componente. |
| RNF-020 Comentarios | Revisión de scripts complejos. |
| RNF-021 Trazabilidad | Matriz requisito-épica-historia-prueba-commit. |
| RNF-022 Calidad | PSScriptAnalyzer + revisión PR. |
| RNF-023 Mantenibilidad | Una responsabilidad por módulo. |
| RNF-024 Reutilización | Adaptadores e interfaces genéricas. |
| RNF-025 Internacionalización | Recursos de mensajes `es`/`en`. |
| RNF-026 Inteligencia distribuida | Mensajería estándar MCP/A2A sin acoplamiento rígido. |
| RNF-027 Gobierno IA | Logs con proveedor, deployment, perfil y configuración. |
| RNF-028 Calidad medible | Cada RNF con criterio cuantificable. |

---

## 8. Plan de implementación detallado inicial

### Tarea 1: Crear archivos base del producto

**Objetivo:** inicializar documentación y gobierno mínimo.

**Archivos:**

- Crear: `README.md`
- Crear: `LICENSE`
- Crear: `CHANGELOG.md`
- Crear: `CONTRIBUTING.md`
- Crear: `SECURITY.md`
- Crear: `CODE_OF_CONDUCT.md`
- Crear: `.gitignore`
- Crear: `.editorconfig`

**Validación:**

```bash
git status --short
```

Debe mostrar solo archivos nuevos esperados.

---

### Tarea 2: Crear estructura de carpetas

**Objetivo:** dejar listas las capas del proyecto y el handbook empresarial.

**Archivos/carpetas:**

- Crear: `src/HermesEnterprise/Dominio/`
- Crear: `src/HermesEnterprise/Aplicacion/`
- Crear: `src/HermesEnterprise/Infraestructura/`
- Crear: `src/HermesEnterprise/Adaptadores/`
- Crear: `src/HermesEnterprise/Configuracion/`
- Crear: `src/HermesEnterprise/Observabilidad/`
- Crear: `src/HermesEnterprise/Seguridad/`
- Crear: `scripts/`
- Crear: `tests/powershell/`
- Crear: `tests/python/`
- Crear: `documentacion/`
- Crear: `documentacion/trazabilidad/`
- Crear: `documentacion/anexos/ADR/`
- Crear: `documentacion/anexos/diagramas/`
- Crear: `documentacion/anexos/plantillas/`
- Crear: `documentacion/anexos/referencias/`
- Crear: `config/`

**Validación:**

```bash
git status --short
```

---

### Tarea 3: Crear handbook empresarial de arquitectura e ingeniería

**Objetivo:** inicializar los capítulos 00 a 20 de `documentacion/` como documentación viva del producto.

**Archivos:**

- Crear: `documentacion/00-INTRODUCCION.md`
- Crear: `documentacion/01-VISION.md`
- Crear: `documentacion/02-SRS.md`
- Crear: `documentacion/03-ARQUITECTURA.md`
- Crear: `documentacion/04-MODELO-DOMINIO.md`
- Crear: `documentacion/05-REQUISITOS.md`
- Crear: `documentacion/06-CASOS-USO.md`
- Crear: `documentacion/07-HISTORIAS-USUARIO.md`
- Crear: `documentacion/08-BACKLOG.md`
- Crear: `documentacion/09-ROADMAP.md`
- Crear: `documentacion/10-CONVENCIONES.md`
- Crear: `documentacion/11-GUIA-DESARROLLO.md`
- Crear: `documentacion/12-GUIA-POWERSHELL.md`
- Crear: `documentacion/13-GUIA-PYTHON.md`
- Crear: `documentacion/14-GUIA-HERMES.md`
- Crear: `documentacion/15-GUIA-AZURE-FOUNDRY.md`
- Crear: `documentacion/16-GUIA-MCP.md`
- Crear: `documentacion/17-GUIA-A2A.md`
- Crear: `documentacion/18-GUIA-MEMORIA.md`
- Crear: `documentacion/19-ESTANDARES.md`
- Crear: `documentacion/20-DICCIONARIO-DATOS.md`

**Validación:**

- Deben existir los 21 capítulos.
- Cada capítulo debe tener título, propósito, alcance y estado.
- El README debe enlazar el índice del handbook.

---

### Tarea 4: Crear documentación de requisitos y trazabilidad

**Objetivo:** formalizar RF, RNF y matriz de trazabilidad desde el inicio.

**Archivos:**

- Crear o poblar: `documentacion/05-REQUISITOS.md`
- Crear o poblar: `documentacion/trazabilidad/matriz-trazabilidad.md`
- Crear: `documentacion/trazabilidad/requisitos-a-epicas.md`
- Crear: `documentacion/trazabilidad/requisitos-a-historias.md`
- Crear: `documentacion/trazabilidad/requisitos-a-casos-prueba.md`
- Crear: `documentacion/trazabilidad/requisitos-a-componentes.md`
- Crear: `documentacion/trazabilidad/requisitos-a-versiones.md`

**Validación:**

- Cada RNF-001 a RNF-028 debe aparecer al menos una vez.
- Cada RNF debe tener criterio de aceptación verificable.
- La matriz debe incluir columnas para épica, historia, caso de uso, componente, módulo, prueba, commit y versión.

---

### Tarea 5: Crear visión arquitectónica y ADR iniciales

**Objetivo:** documentar decisiones base.

**Archivos:**

- Crear o poblar: `documentacion/01-VISION.md`
- Crear o poblar: `documentacion/03-ARQUITECTURA.md`
- Crear: `documentacion/anexos/ADR/ADR-0001-arquitectura-hexagonal.md`
- Crear: `documentacion/anexos/ADR/ADR-0002-no-modificar-hermes-core.md`
- Crear: `documentacion/anexos/ADR/ADR-0003-configuracion-centralizada.md`

**Validación:**

- Las ADR deben explicar contexto, decisión y consecuencias.

---

### Tarea 6: Crear configuración ejemplo

**Objetivo:** establecer configuración centralizada sin secretos.

**Archivos:**

- Crear: `config/hermes-enterprise.config.example.json`
- Crear: `config/proveedores.example.json`
- Crear: `config/perfiles.example.json`

**Validación:**

```bash
python -m json.tool config/hermes-enterprise.config.example.json
python -m json.tool config/proveedores.example.json
python -m json.tool config/perfiles.example.json
```

---

### Tarea 7: Crear script de validación de entorno

**Objetivo:** diagnosticar prerequisitos locales.

**Archivo:**

- Crear: `scripts/Validar-EntornoHermesEnterprise.ps1`

**Validaciones mínimas:**

- PowerShell 7+.
- Git disponible.
- Hermes CLI disponible.
- Python 3.11+ disponible.
- Azure CLI disponible o mensaje de instalación.
- Variables de entorno esperadas documentadas.

**Pruebas:**

- Crear: `tests/powershell/Validar-EntornoHermesEnterprise.Tests.ps1`

**Validación:**

```powershell
pwsh -NoProfile -File ./scripts/Validar-EntornoHermesEnterprise.ps1
```

---

### Tarea 8: Configurar PSScriptAnalyzer

**Objetivo:** asegurar calidad PowerShell.

**Archivos:**

- Crear: `PSScriptAnalyzerSettings.psd1`
- Crear: `.github/workflows/validacion-powershell.yml`

**Validación local:**

```powershell
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings ./PSScriptAnalyzerSettings.psd1
```

---

### Tarea 9: Configurar Python mínimo

**Objetivo:** preparar componentes Python futuros y pruebas.

**Archivos:**

- Crear: `pyproject.toml`
- Crear: `src/python/hermes_enterprise/__init__.py`
- Crear: `.github/workflows/validacion-python.yml`

**Validación:**

```bash
python -m pytest tests/python
```

---

### Tarea 10: Crear adaptador inicial Azure Foundry

**Objetivo:** diseñar e implementar el primer puerto/adaptador.

**Archivos:**

- Crear: `src/HermesEnterprise/Dominio/Proveedores/ProveedorModelo.ps1`
- Crear: `src/HermesEnterprise/Dominio/Modelos/ModeloEmpresarial.ps1`
- Crear: `src/HermesEnterprise/Adaptadores/AzureFoundry/AdaptadorAzureFoundry.ps1`
- Crear: `scripts/Descubrir-ImplementacionesAzureFoundry.ps1`
- Crear: `tests/powershell/AzureFoundry.Tests.ps1`

**Validación:**

```powershell
pwsh -NoProfile -File ./scripts/Descubrir-ImplementacionesAzureFoundry.ps1 -Formato Json
```

Resultado esperado: JSON válido o error controlado si no hay credenciales/permisos.

---

### Tarea 11: Crear logging estructurado

**Objetivo:** dejar base de auditoría y gobierno de IA.

**Archivos:**

- Crear: `src/HermesEnterprise/Observabilidad/LoggerEstructurado.ps1`
- Crear: `src/HermesEnterprise/Observabilidad/MedidorEjecucion.ps1`
- Crear: `tests/powershell/Observabilidad.Tests.ps1`

**Validación:**

- Ejecutar operación de prueba.
- Confirmar salida JSONL con campos obligatorios.
- Confirmar que no aparecen secretos.

---

## 9. Convenciones de código

### PowerShell

- Funciones en español con verbo-sustantivo, por ejemplo:
  - `Obtener-ImplementacionesAzureFoundry`
  - `Sincronizar-ModelosAzureFoundryConHermes`
  - `Validar-ConfiguracionHermesEnterprise`
- Variables descriptivas:
  - `$RutaArchivoConfiguracionCentralizada`
  - `$NombreImplementacionAzureFoundry`
  - `$ResultadoValidacionEntorno`
- Scripts autocontenidos.
- Manejo de errores con `try/catch` y mensajes accionables.
- Sin rutas codificadas.
- Sin secretos.

### Python

- Usar snake_case por convención del lenguaje, manteniendo nombres descriptivos.
- Tipado gradual.
- pytest para pruebas.
- Evitar que Python duplique lógica crítica si ya existe en PowerShell; usarlo para adaptadores, análisis o servicios donde aporte valor.

---

## 10. Seguridad

Reglas iniciales:

- Agregar `.env`, `*.secret.*`, `secrets/`, archivos de credenciales y exports locales al `.gitignore`.
- Crear `config/*.example.json`, nunca `config/*.local.json` versionados.
- Preparar futura integración con Azure Key Vault.
- Usar variables de entorno para tokens.
- Agregar escaneo básico de secretos en CI en una fase posterior.

---

## 11. CI/CD recomendado

Pipelines iniciales:

1. `validacion-powershell.yml`
   - Instalar/validar PowerShell.
   - Instalar PSScriptAnalyzer.
   - Ejecutar análisis en `scripts/` y `src/HermesEnterprise/`.
   - Ejecutar Pester cuando existan pruebas.

2. `validacion-python.yml`
   - Python 3.11.
   - Instalar dependencias.
   - Ejecutar pytest.
   - Ejecutar ruff/mypy si se incorporan.

3. `trazabilidad-requisitos.yml`
   - Validar que documentos mencionen RNF-001 a RNF-028.
   - Validar enlaces a épicas/historias cuando estén creadas.

---

## 12. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|---|---:|---|
| Alcance demasiado amplio para 1.0.0 | Alto | Priorizar MVP: configuración, Azure Foundry, registro, perfiles, observabilidad. |
| Azure AI Foundry cambia APIs o comandos | Medio | Aislar en adaptador y documentar versión/API usada. |
| Mezcla excesiva PowerShell/Python | Medio | Definir responsabilidades claras por lenguaje. |
| Falta de pruebas de integraciones reales | Alto | Separar pruebas unitarias con mocks y pruebas integración opt-in. |
| Secretos accidentalmente versionados | Alto | `.gitignore`, documentación, escaneo CI. |
| Dependencia rígida con Hermes core | Alto | ADR explícita y adaptadores externos. |

---

## 12.1. Riesgos documentales y mitigaciones

| Riesgo | Impacto | Mitigación |
|---|---:|---|
| Documentación demasiado extensa antes de tener código | Medio | Crear primero esqueletos completos y profundizar por iteraciones ligadas a épicas. |
| Handbook desactualizado frente al código | Alto | Obligar actualización de trazabilidad y documentación en PR funcionales. |
| Trazabilidad manual difícil de mantener | Alto | Automatizar validaciones de IDs, duplicados y cobertura mínima. |
| SRS de más de 100 páginas bloquea avance inicial | Medio | Construir SRS incremental: índice completo desde Fase 0, contenido profundo por release. |
| Duplicación entre SRS, requisitos y backlog | Medio | Definir fuente de verdad: `05-REQUISITOS.md` para requisitos; SRS referencia y resume. |

---

## 13. MVP recomendado para versión 0.1.0

Antes de declarar 1.0.0, publicar una versión 0.1.0 con:

- Estructura empresarial del repo.
- Handbook `documentacion/` con capítulos 00 a 20 inicializados.
- SRS incremental con índice completo y primera versión de RF/RNF.
- Matriz de trazabilidad inicial.
- Configuración centralizada example.
- Script de validación de entorno.
- Descubrimiento Azure AI Foundry funcional o stub controlado si falta API final.
- Registro JSON de modelos.
- Logging estructurado básico.
- Documentación de arquitectura y RNF.
- CI inicial.

Criterio para cerrar 0.1.0:

```bash
git status --short
```

Debe estar limpio.

Validaciones mínimas:

```powershell
pwsh -NoProfile -File ./scripts/Validar-EntornoHermesEnterprise.ps1
pwsh -NoProfile -File ./scripts/Descubrir-ImplementacionesAzureFoundry.ps1 -Formato Json
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings ./PSScriptAnalyzerSettings.psd1
```

```bash
python -m json.tool config/hermes-enterprise.config.example.json
python -m pytest tests/python
```

---

## 14. Orden de ejecución recomendado

1. Crear archivos base y documentación mínima.
2. Crear estructura de carpetas.
3. Inicializar handbook `documentacion/` capítulos 00 a 20.
4. Formalizar RF/RNF y matriz de trazabilidad.
5. Crear visión arquitectónica y ADR iniciales.
6. Agregar configuración ejemplo.
7. Implementar validación de entorno.
8. Configurar PSScriptAnalyzer y CI PowerShell.
9. Configurar Python mínimo y CI Python.
10. Diseñar dominio de modelos/proveedores.
11. Implementar adaptador Azure Foundry.
12. Implementar registro empresarial de modelos.
13. Implementar logging estructurado.
14. Implementar perfiles inteligentes.
15. Crear documentación MCP/A2A/ACP.
16. Expandir integraciones Microsoft.
17. Preparar release 0.1.0.

---

## 15. Preguntas abiertas antes de implementar integraciones profundas

1. ¿Se usará Azure CLI, SDK Python, API REST o módulo PowerShell específico para consultar Azure AI Foundry?
2. ¿Cuál será el recurso Azure exacto: Foundry Project, AI Hub, Azure OpenAI resource o combinación?
3. ¿El registro de modelos será solo JSON inicialmente o se desea SQLite/SQL Server desde el inicio?
4. ¿La sincronización con Hermes CLI debe modificar perfiles locales de Hermes o solo generar recomendaciones/config exportable?
5. ¿Qué nivel de compatibilidad se espera con Hermes Desktop y Gateway para 1.0.0?
6. ¿Qué integración empresarial debe tener prioridad después de Azure Foundry: Graph, Fabric, SQL Server o Power BI?

---

## 16. Recomendación ejecutiva

Para maximizar valor y reducir riesgo, recomiendo construir primero el núcleo operativo mínimo:

1. Repositorio empresarial bien documentado.
2. Configuración centralizada.
3. Validador de entorno.
4. Descubridor Azure AI Foundry.
5. Registro empresarial de modelos.
6. Observabilidad/gobierno.
7. Perfiles inteligentes.

Después de ese núcleo, MCP/A2A e integraciones Microsoft se vuelven extensiones naturales, no piezas acopladas.
