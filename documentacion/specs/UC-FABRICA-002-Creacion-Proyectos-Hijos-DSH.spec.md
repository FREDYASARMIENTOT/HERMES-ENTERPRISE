# UC-FABRICA-002 — Creación de Proyectos Hijos con DeepSeek Harness (DSH)

**Estado:** APROBADO (decisiones P1-P5 cerradas — ver §9)
**Versión:** 1.1.0
**Fecha:** 2026-10-27
**Reemplaza a:** UC-FABRICA-001 (ejecución por Hermes Agentic Harness)
**Ámbito:** `Hermes.Web/` (portal) + `tools/` (factory) + `.github/workflows/` (runner)

---

## 0. Decisiones Cerradas (2026-10-27)

| # | Decisión | Resolución |
|---|----------|------------|
| P1 | Alcance del toggle global | **Toggle global de la tabla**, cubre **sólo Iniciar/Detener** (acciones operativas). `Eliminar` y `VS Code` quedan **fuera** del toggle, con confirmación explícita. |
| P2 | ¿`Eliminar` dentro del toggle? | **No.** Siempre accesible con confirmación explícita. |
| P3 | Alcance de los flags | **Catálogo de características elegibles** y extensible (no perfiles fijos). |
| P4 | Alcance de DSH | **Doble:** DSH es el harness con el que se desarrolla la **fábrica** Y con el que se **mejoran los elementos de los proyectos hijos**. El flujo de generación sigue siendo **determinista**. |
| P5 | `pasos_json` incompleto | Se **normaliza a 13** pasos, los faltantes en `PENDIENTE`. |

### 0.1 Principio de arquitectura (P4)

DSH **no** entra en el bucle de ejecución del pipeline. La separación es:

```
DESARROLLO (humano + DSH)          EJECUCIÓN (determinista, sin LLM)
─────────────────────────          ──────────────────────────────────
DSH mejora la fábrica        ──►   factory-run.yml → Crear-HermesProyecto.ps1
DSH mejora la plantilla      ──►   deploy-child.yml (10 jobs) → Azure
   de proyectos hijos
```

**Racional:** la ejecución debe permanecer reproducible y auditable. Un LLM en el camino crítico
introduciría no-determinismo en la creación de infraestructura. DSH aporta valor **antes** (mejorar
la plantilla, el catálogo de características, los contratos) y **después** (diagnóstico), nunca
**durante** el aprovisionamiento.

### 0.2 Identidad y marca

| Nombre | Rol | Dónde |
|--------|-----|-------|
| **Fábrica de Proyectos UR** | Front-end / producto | Títulos, navbar, portada, pie |
| **HERMES Enterprise** | Plataforma / motor | Documentación técnica, repositorio, API interna |

**Regla:** la UI orientada al usuario dice "Fábrica de Proyectos UR"; la documentación de
plataforma dice "HERMES Enterprise". No se mezclan en el mismo contexto visual.

### 0.3 Identidad visual (Universidad del Rosario)

**Hallazgo:** el logo existe en [Hermes.Web/static/images/logoURrojoFondoTransparente.png](Hermes.Web/static/images/logoURrojoFondoTransparente.png)
pero pesa **5.2 MB** (3154×1344 px) y se renderiza a **32 px** de alto — un desperdicio de ~93×.
Además se usa **sólo** en `index.html:214`; las otras dos páginas del portal y la plantilla del
hijo **no tienen logo**.

**Requisito RF-07:**
- Optimizar el logo a un tamaño de render realista (256 px de ancho ≈ 56 KB, o WebP ≈ 15 KB).
- Servir variantes: navbar (32 px), hero/portada (más grande), favicon.
- Aplicar en `index.html`, `proyecto.html`, `proyecto_listado.html`.
- Aplicar en la plantilla del proyecto hijo (`tools/Templates/backend/main.py`, sección hero).
- `alt="Universidad del Rosario"` obligatorio; el logo es decorativo-identitario, no un enlace.

---

## 1. Cambio de Alcance (Rationale)

El desarrollo del caso de uso de creación de proyectos hijos se retoma con **DeepSeek Harness (DSH)** como
harness de ejecución, **reemplazando a Hermes Agentic**. Este spec redefine el caso de uso completo —
no sólo el motor de ejecución, sino también la **visualización en el portal de los 13 pasos**, la
**capacidad de activar/desactivar el App Service**, y la **navegación desde el portal de la fábrica
hacia el portal del proyecto hijo**.

### 1.1 Defectos observados en producción (motivan este spec)

Portal: `https://as-hermesportal.azurewebsites.net/`

| # | Defecto | Evidencia (producción, 2026-10-27) | Severidad |
|---|---------|-----------------------------------|-----------|
| D1 | El enlace **Sitio** no aparece para `gestioncontenidoflujosdetrabajo`, aunque el sitio responde **HTTP 200**. | `GET /api/fabrica/proyectos/historial` devuelve `azure_resource_check_status: "NO_EXISTE"`, `azure_resource_exists: 0`. El sitio real responde HTTP 200. | **Crítica** |
| D2 | El enlace se **deshabilita** por un estado de verificación erróneo. | `index.html:1428` → `var linkApp = !!appUrl && azureStatus !== 'NO_EXISTE';` | **Crítica** |
| D3 | La verificación ARM **falla silenciosamente** en el App Service desplegado. | `servicio_azure.py` usa `DefaultAzureCredential` (Managed Identity). Sin rol *Reader* asignado, la verificación devuelve `NO_EXISTE` en lugar de `NO_VERIFICADO`. | **Crítica** |
| D4 | `crearproyectohijo` figura `EXISTE` pero su host **no resuelve** (DNS). | `https://as-crearproyectohijo.azurewebsites.net/` → *Host desconocido*. Estado obsoleto desde `2026-09-29`. | Alta |
| D5 | No hay forma de iniciar/detener el App Service desde el portal para proyectos ya creados. | `POST /iniciar-app` y `/detener-app` existen en la API pero no se exponen como control visible para todos los estados. | Media |
| D6 | Los badges **GitHub** y **VENV/Runtime** nunca reflejan datos reales; los contadores quedan en 0. | `index.html:1376-1404` lee `github_resource_check_status` y `runtime_resource_check_status`, claves **ausentes** del payload de `historial_proyectos` → siempre `undefined` → badge `NO_VERIF` fijo. | Media |
| D7 | Detener un App Service **no persiste** el estado detenido. | `servicio_fabrica.py:1266-1270` re-persiste `status = "EXISTE"` tras un stop. El badge sigue `EXISTE` y `Iniciar`/`Detener` no pueden ser mutuamente excluyentes sin un estado real. | Media |
| D8 | `proyecto.html` **no tiene botón Iniciar** (sólo Detener y Eliminar). | `proyecto.html:238,243`. Un proyecto detenido no puede reiniciarse desde su página de detalle. | Media |

### 1.2 Causa raíz (confirmada el 2026-10-28)

> **Corrección de un diagnóstico previo.** La hipótesis inicial culpaba a la Managed Identity sin rol
> *Reader*. Se verificó contra Azure y **era falsa**: la MI ya tenía `Reader` (asignado 2026-09-15) y
> `Website Contributor` (2026-09-28) en `RG-Hermes-Proyectos`, y `GET /api/fabrica/app-service-plans`
> responde `exito: true`. **El problema nunca fue de permisos.**

La causa real combina una **carrera de tiempo** con un **estado congelado**:

```
t+0s    POST /api/fabrica/proyectos  → proyecto en SOLICITADO
t+8s    la UI dispara POST /azure-check (la fila acaba de aparecer)
        el App Service AÚN NO EXISTE
        → ARM responde 404 (autenticado y legítimo)
        │
        ▼
        se persiste azure_resource_check_status = "NO_EXISTE"
        │
        ▼
        index.html excluía las filas NO_EXISTE de la reverificación:
              if (azureStatus !== 'NO_EXISTE' && ...)   ← nunca se vuelve a comprobar
        │
        ▼
        el estado queda CONGELADO para siempre
        → sin enlace, badge "ELIMINADO", pese a que el sitio responde HTTP 200
```

El mismo mecanismo, en sentido inverso, produce el falso positivo: `crearproyectohijo` se verificó
el 2026-09-29 cuando **sí** existía → `EXISTE`; el recurso se borró después y nadie volvió a comprobar
(las filas `EXISTE` con URL tampoco se reverificaban).

**Evidencia (2026-10-28):**

| Proyecto | El portal decía | Realidad | Resultado |
|----------|-----------------|----------|-----------|
| `gestioncontenidoflujosdetrabajo` | `NO_EXISTE` | HTTP 200 (vivo) | falso negativo |
| `crearproyectohijo` | `EXISTE` | host no resuelve | falso positivo |
| 8 proyectos restantes | `NO_EXISTE` | host no resuelve | correctos |

**Reglas de diseño que se introducen:**

1. **FIX-D1** — Un **fallo de verificación nunca debe degradar la navegación**. Error de credencial,
   red o permisos es `NO_VERIFICADO` (desconocido), **no** `NO_EXISTE`. Sólo un **404 autenticado**
   afirma inexistencia.
2. **FIX-02** — Un 404 durante la **creación** no es una eliminación: el recurso todavía no se ha
   aprovisionado. Mientras el proyecto esté en curso, el estado es `NO_VERIFICADO`.
3. **FIX-03** — El estado **caduca**: se reverifica cuando la última comprobación supera el TTL
   (10 min), en lugar de congelarse en la primera observación.

---

## 2. Actores

| Actor | Descripción |
|-------|-------------|
| **PO** | Product Owner — solicita la creación del proyecto hijo desde el portal. |
| **Portal** | `AS-HERMES-PORTAL` — UI + API (`Hermes.Web/`). |
| **DSH** | DeepSeek Harness — harness de ejecución que reemplaza a Hermes Agentic. |
| **Factory Runner** | `.github/workflows/factory-run.yml` → `tools/Crear-HermesProyecto.ps1`. |
| **Control Plane** | `.github/workflows/deploy-child.yml` — aprovisiona Azure vía OIDC. |
| **Azure** | `RG-Hermes-Proyectos` / `ASP-HERMES-PORTAL` (Basic B1). |

---

## 3. Flujo Principal (13 pasos canónicos)

Los 13 pasos se mantienen y **deben visualizarse en el portal** con estado por paso.

| # | Paso | Responsable | Visualización en portal |
|---|------|-------------|-------------------------|
| 1 | SOLICITUD | Portal | Badge de estado + fecha |
| 2 | FACTORY | Factory Runner | Run ID + enlace a GitHub Actions |
| 3 | GITHUB | Factory Runner | Enlace a repositorio + commit SHA |
| 4 | CI CHILD | GitHub Actions | Run ID + estado CI |
| 5 | CONTROL PLANE | `deploy-child.yml` | Run ID + enlace |
| 6 | AUTENTICACIÓN | OIDC / FIC | Estado OIDC |
| 7 | AZURE | Control Plane | **Estado real** + nombre del recurso |
| 8 | DEPLOY | Control Plane | Deployment ID Azure |
| 9 | READINESS | Control Plane | HTTP status + URL |
| 10 | PRUEBAS FUNC. | Control Plane | pass/fail counts |
| 11 | EVIDENCIA | Control Plane | Enlace al reporte |
| 12 | PUBLICACIÓN | Control Plane | Estado |
| 13 | NAVEGADOR | Portal | **Enlace "Sitio" al hijo** |

**Contrato de visualización:** cada paso expone `numero`, `nombre`, `estado` ∈
{`PENDIENTE`, `EN_PROCESO`, `COMPLETADO`, `FALLIDO`, `OMITIDO`}, `detalle`, `evidencia`,
`fecha_inicio`, `fecha_fin`, `duracion_segundos`, `subpasos[]`.

---

## 4. Requisitos Funcionales

### RF-01 — Sustitución del harness de ejecución por DSH
El pipeline de creación de proyectos hijos **no debe depender de Hermes Agentic**. La ejecución de
los pasos se realiza con **DeepSeek Harness**. Los artefactos de trazabilidad
(`factory_run_id`, `control_plane_run_id`, `commit_sha`) se conservan sin cambios de contrato.

**Criterio de aceptación:** ninguna referencia a Hermes Agentic permanece en el camino crítico de
creación; `factory-run.yml` y `deploy-child.yml` no invocan al harness anterior.

#### RF-01.1 — Frontera de responsabilidades (hallazgo de investigación)

**Hallazgo importante:** la creación de proyectos hijos **ya no depende de un harness de agente**.
El camino crítico está hoy 100% determinista:

```
Portal (POST /api/fabrica/proyectos)
   └─► workflow_dispatch  factory-run.yml
         └─► tools/Crear-HermesProyecto.ps1      (PowerShell, sin LLM)
               └─► git push del repo hijo
                     └─► deploy-child.yml          (10 jobs, sin LLM)
                           └─► Azure RG-Hermes-Proyectos
```

Toda la telemetría se auto-reporta al Portal por HTTP:
- `factory-run.yml:414-425` → `PUT /api/fabrica/proyectos/{id}/metadata`
- `deploy-child.yml:1009-1078` → `POST /api/fabrica/proyectos/{id}/paso` (pasos 4-13)

**Por lo tanto, RF-01 se satisface mayormente por verificación, no por reescritura.** El trabajo real
es: (a) auditar y eliminar cualquier referencia residual al harness anterior en el camino crítico,
(b) documentar DSH como el harness soportado, y (c) **no introducir** dependencia de agente en los
pasos nuevos.

**Criterio de aceptación (revisado):**
- Auditoría del camino crítico sin referencias a Hermes Agentic (grep + CI guard).
- El pipeline sigue siendo reproducible sin intervención de LLM.
- Los flags de RF-05 se propagan de forma determinista (sin pasos generativos).

> **Nota de alcance (resuelto — P4):** DSH tiene **doble alcance**: desarrolla la fábrica y mejora
> los elementos de los proyectos hijos. Pero **no** entra en el bucle de ejecución: el pipeline sigue
> siendo determinista (ver §0.1). DSH aporta valor antes (mejor plantilla, mejor catálogo) y después
> (diagnóstico), nunca durante el aprovisionamiento.

#### RF-01.2 — Mejora de los proyectos hijos (P4)

Los "elementos de los proyectos hijos" que DSH puede mejorar son, inicialmente:

| Elemento | Estado actual | Mejora objetivo |
|----------|--------------|-----------------|
| Home del hijo | Ficha de despliegue técnica, f-string de 597 líneas | Home orientado a usuario + navegación |
| Navegación | **No existe** | Menú lateral (flag `menu_hamburguesa`) |
| Persistencia | SQLite incondicional | Elegible (flag `usar_sqlite`) |
| Trazabilidad de deploy | Sólo en el portal padre | También en el hijo (flag `telemetria_deploy`) |
| Identidad visual | Sin logo | Logo UR (flag `logo_ur`) |
| Endpoints del catálogo | 8 de 11 implementados; 3 dan 404 | Completar los 11 |

> **Deuda confirmada:** `/api/entorno`, `/api/telemetria` y `/api/bootstrap` se anuncian en el
> catálogo y se renderizan como tarjetas, pero **no existen** en el hijo → 404. Además
> `RenderEngine.ps1:396` referencia `timestampField`, que no existe en el HTML generado → `TypeError`
> que aborta el resto de fetches.

### RF-02 — Visualización completa de los 13 pasos
El portal debe mostrar, para cada proyecto, el detalle de los 13 pasos con su estado y duración.

**Estado actual (verificado):** la visualización **ya existe**, pero **sólo en la página de detalle**
`/proyectos/{deployment_id}` ([proyecto.html:483-498](Hermes.Web/templates/proyecto.html#L483-L498),
función `renderTimeline()`). El **home no tiene ninguna visualización de pasos**.

| Capa | Artefacto | Estado |
|------|-----------|--------|
| Fuente canónica | `PASOS_CANONICOS` ([servicio_fabrica.py:55-69](Hermes.Web/backend/servicio_fabrica.py#L55-L69)) | ✅ Existe |
| Materialización | `_inicializar_pasos()` ([servicio_fabrica.py:292-302](Hermes.Web/backend/servicio_fabrica.py#L292-L302)) | ✅ 13 pasos PENDIENTE |
| Render (detalle) | `renderTimeline()` ([proyecto.html:483-498](Hermes.Web/templates/proyecto.html#L483-L498)) | ✅ Funciona |
| Render (home) | — | ❌ **No existe** |
| Payload home | `historial_proyectos` ([api_fabrica.py:183-207](Hermes.Web/api/api_fabrica.py#L183-L207)) | ❌ **Sin array `pasos`** |

**Criterio de aceptación:**
- El home muestra los 13 pasos por proyecto (celda expandible o columna dedicada).
- `GET /api/fabrica/proyectos/historial` incluye `pasos[]` (o un `pasos_resumen`), **sin** romper el
  contrato actual consumido por el resto de la UI.
- `GET /proyectos/{deployment_id}` renderiza los 13 pasos.
- `GET /api/fabrica/proyectos/{deployment_id}/trace/json` devuelve `steps[]` con los 13 elementos.
- Un proyecto con `pasos_json` de menos de 13 elementos se completa con los faltantes en `PENDIENTE`
  (no se muestran sólo los presentes). *(Defecto real: `hermes-e2e-b1-portal-20260915-073901`
  persiste sólo **11** pasos — faltan 11 EVIDENCIA y 12 PUBLICACIÓN.)*

> **Deuda detectada:** el nombre de los pasos está **duplicado y codificado a mano** en
> [proyecto.html:485](Hermes.Web/templates/proyecto.html#L485) (`var pn={1:'SOLICITUD',...}`), en
> divergencia con `PASOS_CANONICOS`. Debe eliminarse esa duplicación (servir los nombres desde la API).

### RF-03 — Enlace del proyecto al portal del hijo (FIX-D1, FIX-D2)
Al hacer clic sobre el **nombre del proyecto**, el navegador debe ir del portal de la fábrica al
**portal del proyecto hijo**.

**Estado actual (verificado):** **no existe** ningún código que navegue al portal del hijo. El nombre
apunta hoy a la landing page del App Service ([index.html:1445-1446](Hermes.Web/templates/index.html#L1445-L1446)):

```javascript
if (linkApp) {
    nombreCell = '<a href="' + esc(appUrl) + '" target="_blank" rel="noopener" class="proj-link" ...>' + nombreInner + ...
```

No existe ningún campo de "URL del portal del hijo" en `SolicitudProyecto` ni en ninguna respuesta de
API. **RF-03 requiere un campo/derivación nuevo.**

#### RF-03.1 — Semántica del defecto D1 (corrección importante)

El badge y el enlace se degradan por una **etiqueta mal nombrada**, no sólo por credenciales:

```
ARM no autenticado  →  verificar_existencia_web_app() no obtiene token
                    →  resultado.status = "NO_EXISTE"      ← ¡afirma inexistencia!
                    →  persiste azure_resource_exists = 0
                    →  index.html: azureStatus === 'NO_EXISTE'  →  linkApp = false  →  SIN ENLACE
```

En producción esto produce una contradicción visible: el sitio del hijo responde **HTTP 200** y el
portal lo muestra como **"ELIMINADO"** (la etiqueta que `index.html:1393` pinta para `NO_EXISTE`).
Es decir: **el portal afirma que un recurso fue borrado cuando en realidad sólo no pudo verificarlo.**

**Regla de diseño (FIX-D1):** un **fallo de verificación nunca debe degradar la navegación**. Un error
de credencial, red o permisos es `NO_VERIFICADO` (estado desconocido), **no** `NO_EXISTE` (afirmación
de inexistencia). `NO_EXISTE` se reserva para **404 autenticado** de ARM.

**Regla de visibilidad:**
```
linkApp = appUrl != "" AND azureStatus != "NO_EXISTE_CONFIRMADO"
```

**Regla de resolución de URL (orden de precedencia):**
1. `web_app_url` — URL canónica persistida.
2. `azure_hostname` — `defaultHostName` real reportado por Azure.
3. `https://{web_app}.azurewebsites.net` — derivación por nombre de recurso.
4. `https://as-{nombre_proyecto_normalizado}.azurewebsites.net` — derivación de último recurso.

**Criterio de aceptación:**
- Clic en el nombre del proyecto navega al **portal del hijo** (no a la landing page).
- `gestioncontenidoflujosdetrabajo` presenta enlace funcional a
  `https://as-gestioncontenidoflujosdetrabajo.azurewebsites.net/`.
- Si la verificación ARM falla, el enlace **sigue visible** y el badge indica `NO_VERIF` — **nunca**
  `ELIMINADO`/`NO_EXISTE`.
- La afordancia "abrir App Service" se **preserva** mediante el mini-link "Sitio"
  ([index.html:1463](Hermes.Web/templates/index.html#L1463)) y el badge clicable
  ([index.html:1457](Hermes.Web/templates/index.html#L1457)), que hoy ya apuntan a `appUrl`.

### RF-04 — Activación/desactivación del App Service (FIX-D5)
Debe existir un control visible en el home para **iniciar** y **detener** el App Service del proyecto.

**Estado actual (verificado):** la capacidad **ya existe completa en el backend** pero no está bien
expuesta en la UI:

| Endpoint | Implementación | Mecanismo |
|----------|---------------|-----------|
| `POST /iniciar-app` | [servicio_fabrica.py:1274](Hermes.Web/backend/servicio_fabrica.py#L1274) | ARM REST `POST .../sites/{name}/start` |
| `POST /detener-app` | [servicio_fabrica.py:1218](Hermes.Web/backend/servicio_fabrica.py#L1218) | ARM REST `POST .../sites/{name}/stop` |
| `POST /eliminar-app` | [servicio_fabrica.py:1330](Hermes.Web/backend/servicio_fabrica.py#L1330) | ARM REST `DELETE .../sites/{name}` |

Mecanismo: **ARM REST vía `httpx` + `DefaultAzureCredential`** ([servicio_azure.py:97-273](Hermes.Web/backend/servicio_azure.py#L97-L273)),
`API_VERSION=2023-01-01`, timeout 30 s. Éxito = `200/202/204`; `404`→`NO_EXISTE`; `403`→`ERROR_PERMISOS`.

**Por tanto RF-04 es mayormente trabajo de UI**, más un arreglo de estado en el backend (D7).

**Criterio de aceptación:**
- Controles `Iniciar` / `Detener` presentes y **mutuamente excluyentes** según el estado real.
- El estado `Running` / `Stopped` se **persiste** y se refleja en la UI (corrige D7: hoy un stop
  re-persiste `EXISTE` en [servicio_fabrica.py:1266-1270](Hermes.Web/backend/servicio_fabrica.py#L1266-L1270)).
- `proyecto.html` incorpora el botón **Iniciar** (corrige D8: hoy sólo tiene Detener y Eliminar).
- `Eliminar` se mantiene como acción **separada** con confirmación explícita — nunca dentro del mismo
  control que activa/desactiva.
- Si la operación ARM falla, la UI muestra el error y **no** cambia el estado optimistamente.
- **Degradación:** dado que la Managed Identity puede no tener permisos (ver D3/§8), la UI debe
  mostrar el error ARM de forma legible y no dejar los botones en estado inconsistente.

### RF-05 — Catálogo de características elegibles del proyecto hijo
Al crear un proyecto, el PO debe poder elegir características de un **catálogo extensible**.

**Catálogo inicial (P3):**

| ID | Característica | Descripción | Default | Depende de |
|----|---------------|-------------|---------|-----------|
| `usar_sqlite` | Base de datos SQLite | Implementa SQLite dentro del proyecto hijo | `true` | — |
| `menu_hamburguesa` | Menú lateral | Menú hamburguesa izquierdo en el home del hijo | `false` | — |
| `telemetria_deploy` | Telemetría de deploy | Log de cambios en cada deploy de GitHub del hijo | `false` | `usar_sqlite` |
| `logo_ur` | Identidad UR | Logo de la Universidad del Rosario en el hijo | `true` | — |

**Contrato de extensibilidad (P3):** el catálogo se define en **un solo lugar** y la UI lo renderiza
dinámicamente. Añadir una característica nueva no debe requerir tocar la UI ni los endpoints.

```http
GET /api/fabrica/caracteristicas
→ { "caracteristicas": [
      { "id": "usar_sqlite", "nombre": "Base de datos SQLite",
        "descripcion": "...", "default": true, "depende_de": [], "disponible": true }
  ] }
```

**Criterio de aceptación:**
- `POST /api/fabrica/proyectos` acepta `caracteristicas: {<id>: <bool>, ...}`.
- Los flags se persisten en `solicitudes_proyecto` y viajan a `factory-run.yml` → `Crear-HermesProyecto.ps1`.
- El proyecto hijo generado refleja los flags.
- Ausencia del bloque `caracteristicas` ⇒ se aplican los defaults (retrocompatibilidad).
- **El catálogo es la única fuente de verdad**: la UI se genera desde `GET /api/fabrica/caracteristicas`.

#### RF-05.1 — Estado actual del scaffolding (hallazgo de investigación)

**No existe hoy ningún mecanismo de feature flags en la fábrica.** El único condicional es
`-SkipAzure` ([Crear-HermesProyecto.ps1:222](tools/Crear-HermesProyecto.ps1#L222)), que **gatea etapas
del pipeline, no texto renderizado**. Implicaciones verificadas:

| Flag | Punto de inserción real | Obstáculo principal |
|------|------------------------|---------------------|
| `usar_sqlite` | `Inicializar-BaseDatosProyecto` (`SQLite.ps1:24-28`, CLI `sqlite3`) **y** bloque inline de `startup.sh:13-112` **y** `consultar_sqlite_param` (`main.py:47-61`) | SQLite está cableado incondicionalmente en **4 capas**. `schema.sql` **nunca se copia al hijo** (`startup.sh:22`: *"schema.sql never exists in child"*) — hay que gatear ambas rutas. |
| `menu_hamburguesa` | Nuevo markup en el home inline (`main.py:338-457`) | **No existe markup de navegación alguno.** Se añade, no se conmuta. El home es un f-string híbrido con costura en `main.py:457/471`. |
| `telemetria_deploy` | Nuevo sumidero de escritura | **No existe sink de telemetría dentro del hijo.** Depende de `usar_sqlite`. |

**Dependencia dura: `telemetria_deploy` ⇒ requiere `usar_sqlite=true`.** El único endpoint de
telemetría entrante del hijo es `POST /api/implementacion/paso`
([main.py:182](tools/Templates/backend/main.py#L182)), que falla sin `SQLITE_DB`
(`{"error": "Base de datos no encontrada"}`). **El portal debe rechazar (HTTP 400) la combinación
`telemetria_deploy=true` + `usar_sqlite=false`**, con mensaje explícito.

#### RF-05.2 — Propagación de flags (3 puntos obligatorios)

Todo flag nuevo debe propagarse en **tres** lugares, o quedará silenciosamente inerte:

1. Bloque `param()` de [Crear-HermesProyecto.ps1:24-35](tools/Crear-HermesProyecto.ps1#L24-L35).
2. **Ambas** cadenas `.Replace()` — la de `startup.sh` (líneas 96-102) **y** la de `main.py`
   (líneas 122-127). Son copias duplicadas; actualizar sólo una rompe la coherencia.
3. `workflow_dispatch.inputs` de [factory-run.yml:13-33](.github/workflows/factory-run.yml#L13-L33)
   **y** la invocación de la línea 192.

**Restricción de seguridad:** el script usa `Set-StrictMode -Version Latest`
([línea 37](tools/Crear-HermesProyecto.ps1#L37)) — leer una variable no declarada **lanza excepción**.
Los flags deben declararse explícitamente en `param()`.

#### RF-05.3 — Convención de placeholder y degradación elegante

La sintaxis es `{{TOKEN_MAYÚSCULAS}}`, sustituida por `.Replace()` literal (**no** por el renderer
genérico `RenderEngine.ps1`, que no se usa para estas plantillas).

Para el home del hijo se reutiliza el patrón ya existente `_resolve_meta()`
([main.py:32-45](tools/Templates/backend/main.py#L32-L45)): valor renderizado → variable de entorno →
default. Un token no reemplazado degrada a un valor por defecto en lugar de mostrarse crudo.

> **Deuda detectada (fuera de alcance, registrar):** 6 placeholders se declaran y **nunca** se
> sustituyen — `{{TIMESTAMP}}`, `{{USER}}`, `{{DESCRIPTION}}`, `{{ESTADO}}`, `{{GITHUB_REPO}}`,
> `{{YEAR}}`. Los de `README.md` y `schema.sql` viajan crudos al hijo.

### RF-06 — Control unificado (toggle global) de acciones del home
Un **único toggle global** debe habilitar/deshabilitar las acciones de **toda la tabla** de proyectos.

**Alcance confirmado (P1/P2):**

| Acción | ¿Cubierta por el toggle? | Comportamiento |
|--------|-------------------------|----------------|
| `Iniciar` | ✅ Sí | Habilitado/deshabilitado por el toggle |
| `Detener` | ✅ Sí | Habilitado/deshabilitado por el toggle |
| `VS Code` | ❌ No | Siempre disponible (acción local, no destructiva) |
| `Eliminar` | ❌ No | **Siempre** disponible, con confirmación explícita |
| Ver detalle / enlaces | ❌ No | Navegación de lectura; nunca se bloquea |

**Criterio de aceptación:**
- Un toggle único en el home activa/desactiva las acciones operativas de **todas** las filas.
- El estado del toggle **persiste** entre recargas (no se pierde al refrescar).
- Con el toggle **inactivo**: los botones Iniciar/Detener aparecen deshabilitados, con tooltip
  explicativo ("Acciones deshabilitadas").
- Con el toggle **activo**: el comportamiento es el actual.
- `Eliminar` **nunca** se deshabilita por el toggle, pero **siempre** exige confirmación.
- El estado por defecto es **inactivo** (postura segura).

> **Racional de seguridad:** el toggle agrupa acciones reversibles (start/stop). `Eliminar` es
> **irreversible** y por eso queda fuera: un interruptor pensado para "apagar un rato las acciones"
> no debe ser la única barrera frente a un borrado.

---

### RF-07 — Identidad visual Universidad del Rosario (§0.3)

**Criterio de aceptación:**
- El logo pesa **< 100 KB** en la variante de navbar (desde 5.2 MB).
- Aparece en las 3 páginas del portal y en el hero de la plantilla del hijo.
- `alt="Universidad del Rosario"` presente en todas las instancias.
- Existe `favicon` servido desde `/static/images/`.
- El logo se copia al proyecto hijo (ruta `/static/images/` del hijo), no se enlaza al portal padre.

---

### RF-08 — Ciclo de vida del proyecto desde el portal (P9, P10)

El PO debe poder **eliminar un proyecto** desde el portal de la fábrica, sin intervenir Azure a mano.

#### RF-08.1 — Dos modos, con nombres distintos

| Modo | Efecto | Reversible | Uso |
|------|--------|-----------|-----|
| **Archivar** | El registro se oculta de la tabla; **conserva** trazabilidad y recursos | Sí (desarchivar) | Limpiar la vista de proyectos fantasma |
| **Eliminar** | Borra recursos seleccionados + registro | **No** | Decomiso definitivo |

La UI **nunca** llama "eliminar" a archivar. Son botones separados con textos distintos.

#### RF-08.2 — Ámbito seleccionable (eliminación)

Al eliminar, el PO elige qué se destruye:

| Componente | Default | Confirmación extra |
|------------|---------|--------------------|
| App Service (Azure) | ✅ marcado | — |
| Registro en el portal | ✅ marcado | — |
| Repositorio GitHub | ❌ **desmarcado** | Requiere escribir el nombre del repo |
| Eventos / bitácora | ❌ desmarcado | — |

**El repositorio GitHub viene desmarcado por defecto**: contiene el código y su borrado es
irrecuperable. Activarlo exige confirmación adicional explícita.

#### RF-08.3 — Salvaguardas (obligatorias)

1. **Reconciliación previa:** antes de borrar, se consulta ARM. Si el recurso **existe** y el estado
   local dice lo contrario, se **aborta** y se muestra la discrepancia. Esto evita destruir un
   recurso vivo por un estado obsoleto (el defecto D1, ahora en dirección peligrosa).
2. **Confirmación por nombre:** el PO debe escribir el `nombre_proyecto` exacto. Se valida
   **en servidor**, no sólo en el navegador.
3. **Auditoría:** toda eliminación registra evento `ELIMINACION` con actor, timestamp y componentes
   afectados, **antes** de borrar.
4. **Verificación posterior:** tras borrar, se re-consulta ARM y sólo entonces se elimina el registro.
5. **Nunca en lote:** sin "eliminar todos". Una operación por proyecto.

#### RF-08.4 — Contrato

```http
POST /api/fabrica/proyectos/{deployment_id}/archivar
→ { "ok": true, "archivado": true }

DELETE /api/fabrica/proyectos/{deployment_id}
Content-Type: application/json

{
  "nombre_confirmacion": "crearproyectohijo",   // debe coincidir exactamente
  "eliminar_app_service": true,
  "eliminar_registro":    true,
  "eliminar_repositorio": false,
  "eliminar_eventos":     false
}
→ { "ok": true,
    "reconciliacion_previa": "EXISTE|NO_EXISTE",
    "componentes": { "app_service": "...", "registro": "...", "repositorio": "OMITIDO" } }
```

**Errores esperados:** `409` si `nombre_confirmacion` no coincide; `409` si la reconciliación previa
detecta discrepancia; `404` si el deployment no existe.

**Criterio de aceptación:**
- Se puede archivar y desarchivar; el proyecto desaparece de la tabla y puede recuperarse.
- Se puede eliminar definitivamente eligiendo componentes.
- Con el nombre de confirmación incorrecto, la operación se rechaza (validado en servidor).
- Si ARM dice que el recurso existe y el estado local no, la eliminación **se aborta**.
- Toda eliminación deja rastro en la bitácora.
- `crearproyectohijo` puede eliminarse o archivarse desde la UI.

---

## 5. Requisitos No Funcionales

| ID | Requisito |
|----|-----------|
| RNF-01 | Sin secretos en código; `HERMES_GITHUB_TOKEN` sólo vía App Settings. |
| RNF-02 | Un fallo de verificación **nunca** degrada la navegación (ver FIX-D1). |
| RNF-03 | Degradación elegante: si ARM no está disponible, la UI funciona en modo lectura. |
| RNF-04 | Sin `javascript:` hrefs ni `href="#"` en enlaces de proyecto. |
| RNF-05 | Operaciones destructivas requieren confirmación explícita. |
| RNF-06 | `rel="noopener"` en todo enlace `target="_blank"`. |

---

## 6. Contratos de API

### 6.1 Crear solicitud (extendido — RF-05)

```http
POST /api/fabrica/proyectos
Content-Type: application/json

{
  "nombre_proyecto": "encuestas-ur",
  "descripcion": "Sistema de encuestas",
  "app_service_plan_id": "/subscriptions/01bfad48-.../serverfarms/ASP-HERMES-PORTAL",
  "caracteristicas": {
    "usar_sqlite": true,
    "menu_hamburguesa": false,
    "telemetria_deploy": false
  }
}
```

### 6.2 Estado del App Service (nuevo — RF-04)

```http
GET /api/fabrica/proyectos/{deployment_id}/app-state
→ { "deployment_id": "...", "state": "Running|Stopped|Unknown",
    "verificado": true, "error": "" }
```

### 6.3 Detalle de los 13 pasos (existente — RF-02)

```http
GET /api/fabrica/proyectos/{deployment_id}/trace/json
→ { "project": "...", "status": "...", "steps": [ {numero, nombre, estado, ...} × 13 ] }
```

### 6.4 Payload del home extendido (RF-02, D6)

```http
GET /api/fabrica/proyectos/historial?limit=5
→ { "proyectos": [ {
      ...campos actuales...,
      "pasos":            [ {numero, nombre, estado, detalle} × 13 ],   // NUEVO (RF-02)
      "pasos_completados": 13,                                          // NUEVO (RF-02)
      "github_resource_check_status": "EXISTE",                         // NUEVO (D6)
      "runtime_resource_check_status": "EXISTE",                        // NUEVO (D6)
      "azure_state": "Running",                                         // NUEVO (RF-04)
      "portal_hijo_url": "https://as-x.azurewebsites.net/"              // NUEVO (RF-03)
  } ] }
```

**Contrato de compatibilidad:** las claves nuevas son **aditivas**. Ningún consumidor actual debe
romperse; el payload sigue siendo un objeto con `proyectos[]`.

### 6.5 URL del portal del hijo (nuevo — RF-03)

```http
GET /api/fabrica/proyectos/{deployment_id}/child-portal
→ { "deployment_id": "...", "portal_hijo_url": "https://...",
    "resuelto_por": "web_app_url|azure_hostname|web_app|derivado", "disponible": true }
```

`resuelto_por` hace explícita la **fuente** de la URL, para poder diagnosticar enlaces incorrectos
sin volver a instrumentar el portal.

---

## 7. Modelo de Datos

Nuevas columnas en `solicitudes_proyecto` (migración aditiva, nullable/default seguro):

| Columna | Tipo | Default | Uso |
|---------|------|---------|-----|
| `caracteristicas_json` | TEXT | `NULL` | Flags de RF-05 (catálogo extensible) |
| `azure_state` | TEXT | `""` | `Running` / `Stopped` (ya existe — **poblar**, ver D7) |
| `azure_state_checked_at` | TEXT | `""` | Frescura del estado |
| `portal_hijo_url` | TEXT | `""` | URL del portal del hijo (RF-03) |
| `portal_hijo_url_origen` | TEXT | `""` | Fuente de la URL (`web_app_url`, `derivado`, …) |

**Regla de migración:** columnas aditivas con default; ningún `NOT NULL` sin default; la BD de
producción (`/home/data/proyecto.db`) se migra en el arranque sin pérdida de datos.

---

## 8. Tratamiento del defecto D3 (verificación ARM)

El portal desplegado requiere el rol **Reader** para la Managed Identity en
`RG-Hermes-Proyectos`. El pipeline **no puede** asignar RBAC (requiere Owner/UserAccessAdmin).

**Mitigación obligatoria (independiente de RBAC):** distinguir tres estados:

| Estado | Significado | Efecto en UI |
|--------|-------------|--------------|
| `EXISTE` | ARM confirmó existencia | Enlace visible, badge verde |
| `NO_EXISTE` | ARM confirmó **404 autenticado** | Enlace oculto, badge rojo |
| `NO_VERIFICADO` | Fallo de token/red/permisos | **Enlace visible**, badge gris |

**Acción manual documentada:** ejecutar `bash scripts/assign-portal-mi-reader.sh` desde Azure Cloud
Shell con permisos Owner/UserAccessAdmin.

---

## 9. Decisiones del PO

### 9.1 Cerradas (2026-10-27)

Ver **§0** para el detalle. Resumen: P1 toggle global sólo Iniciar/Detener · P2 `Eliminar` fuera del
toggle · P3 catálogo de características extensible · P4 DSH con doble alcance, ejecución
determinista · P5 normalizar a 13 pasos.

### 9.2 Decisiones de segunda ronda

#### P14 — RESUELTA (regla defensiva + estado con caducidad)

**Corrección importante:** se verificó contra Azure y los roles **ya estaban** asignados desde
septiembre (`Reader` 2026-09-15, `Website Contributor` 2026-09-28). `GET /api/fabrica/app-service-plans`
responde `exito: true`. **RBAC no era el problema.** La causa real está en §1.2 (carrera de creación +
estado congelado).

**Resolución aplicada (desplegada en `f35f0f8`):**

| # | Medida | Archivo |
|---|--------|---------|
| 1 | Fallo de token / 401 / 403 / 5xx → `NO_VERIFICADO` con `exists=None` | `servicio_azure.py` |
| 2 | Un 404 durante la creación **no** se persiste como eliminado | `servicio_fabrica.py` |
| 3 | `_actualizar_estado_azure_en_bd` escribe `NULL` (desconocido) en vez de `False` | `servicio_fabrica.py` |
| 4 | Badge `NO_VERIF` en vez de `ELIMINADO` ante fallo, con el error en tooltip | `index.html` |
| 5 | Reverificación cada 10 min (antes: nunca) | `index.html` |

**Regla de clasificación (vigente):**

```
respuesta ARM:
  200 / 2xx           → EXISTE           (persistir)
  404 AUTENTICADO     → NO_EXISTE        (persistir) — único caso que afirma inexistencia
  401 / 403           → ERROR_PERMISOS   (no degradar enlace)
  5xx / timeout / red → NO_VERIFICADO    (no degradar enlace)
  proyecto en curso   → NO_VERIFICADO    (aunque ARM diga 404)
```

> **Herramienta de diagnóstico:** `scripts/Diagnose-PortalMI.ps1` (sólo lectura por defecto) contrasta
> los App Services **reales** del RG contra lo que el portal cree. Nota: vive en `scripts/`, que está
> en `.gitignore`, así que no se versiona.

#### P7 — OPCIONES AMPLIADAS (pendiente de elección)

Con `usar_sqlite=false`, **8 rutas** del hijo quedan sin fuente de datos. Opciones:

| Op | Comportamiento | Ventaja | Desventaja |
|----|----------------|---------|------------|
| **P7-a** | `200` con `{"disponible": false, "motivo": "..."}` | Las tarjetas no salen en error; UI limpia | Respuestas "vacías" que parecen éxito |
| **P7-b** | `503` con cuerpo explicativo | Semánticamente correcto | La UI del hijo pinta error |
| **P7-c** | Las rutas se **eliminan del catálogo** | Honesto: no se anuncia lo que no existe | El catálogo varía según flags |
| **P7-d** | **Desacoplar** las rutas de SQLite (leer de entorno/FS) | La mayoría **no necesitan** BD | Más trabajo de refactor |
| **P7-e** | **Híbrido**: desacoplar las que pueden (d) + `200 disponible:false` en las que no (a) | Mejor UX y honestidad | Requiere clasificar ruta por ruta |

**Recomendación: P7-e.** Varias rutas no necesitan realmente la BD: `/api/version` puede devolver la
versión de la app, `/api/git` ya lee del sistema de archivos. Sólo `/api/proyecto`, `/api/github`,
`/api/azure`, `/api/despliegue`, `/api/sqlite` dependen de verdad de SQLite.

Clasificación propuesta:

| Ruta | ¿Necesita SQLite? | Acción P7-e |
|------|-------------------|-------------|
| `/api/version` | No | Desacoplar (d) |
| `/api/git` | No | Desacoplar (d) |
| `/api/workspace` | Parcial | Desacoplar (d) |
| `/api/proyecto` | Sí | `disponible:false` (a) |
| `/api/github` | Sí | `disponible:false` (a) |
| `/api/azure` | Sí | `disponible:false` (a) |
| `/api/despliegue` | Sí | `disponible:false` (a) |
| `/api/sqlite` | Sí | `disponible:false` (a) — por definición |

#### P9 — RESUELTA (eliminación desde el portal)

La gestión del ciclo de vida se hace **desde el portal de la fábrica**, no por intervención manual
en Azure. Ver **RF-08**.

#### P10 — RESUELTA (eliminación desde el portal)

Los proyectos fantasma (registro en el portal sin recurso vivo, como `crearproyectohijo`) se
eliminan desde el portal con **RF-08**, en modo archivar o eliminar. El estado se reconcilia contra
ARM antes de borrar, para no destruir un recurso que sí existe.

#### P6, P8, P11, P12, P13 — ABIERTAS

Siguen pendientes de decisión (ver §9.3).

### 9.3 Decisiones abiertas con opciones

| # | Pregunta | Opciones | Recomendación |
|---|----------|----------|---------------|
| **P6** | ¿Dónde vive la telemetría de deploy del hijo? | (a) Dentro del hijo (SQLite) · (b) Sólo portal padre · (c) Ambos | **(c)** — el hijo la muestra, el padre la agrega |
| **P8** | ¿Qué lleva el menú hamburguesa del hijo? | Ver lista propuesta abajo | Las 6 secciones propuestas |
| **P11** | ¿El toggle es por navegador o global? | (a) `localStorage` por navegador · (b) Global en servidor · (c) Por sesión | **(a)** — sin estado compartido, sin sorpresas |
| **P12** | ¿El toggle bloquea en servidor o es cosmético? | (a) Sólo UI · (b) Guard en servidor | **(a) para esta fase**, con la limitación documentada |
| **P13** | Los 3 endpoints que dan 404 | (a) Implementarlos · (b) Quitarlos del catálogo | **(a)** — el catálogo debe ser veraz |

**P8 — menú hamburguesa propuesto:**

| Sección | Contenido |
|---------|-----------|
| Inicio | La landing del hijo |
| Endpoints | Catálogo de API del hijo |
| Evidencia | `deployment-report` |
| Estado | `/health` y versión |
| Repositorio | Enlace a GitHub |
| Documentación | Swagger / ReDoc |

> **Nota sobre P12:** si el toggle es sólo UI, cualquiera que conozca la URL puede seguir invocando
> `POST /iniciar-app` directamente. Para esta fase es aceptable (el portal no tiene autenticación
> propia), pero **debe quedar escrito** para que nadie asuma que es un control de seguridad.

---

## 10. Criterios de Aceptación (End-to-End)

1. **AC-01** — El portal muestra los 13 pasos de un proyecto creado, con estado por paso.
2. **AC-02** — Clic en el nombre del proyecto navega al **portal del hijo**.
3. **AC-03** — `gestioncontenidoflujosdetrabajo` tiene enlace funcional (HTTP 200 verificado).
4. **AC-04** — Un fallo de verificación ARM **no** oculta el enlace ni etiqueta el recurso como
   `ELIMINADO` (badge `NO_VERIF`).
5. **AC-05** — Iniciar/Detener App Service funciona, es mutuamente excluyente y refleja el estado real.
6. **AC-06** — `Eliminar` requiere confirmación explícita y es una acción separada.
7. **AC-07** — Al crear un proyecto se pueden elegir los 3 flags de RF-05.
8. **AC-08** — Un proyecto hijo creado con `usar_sqlite=false` no incluye SQLite.
9. **AC-09** — Un proyecto hijo con `menu_hamburguesa=true` muestra el menú lateral en su home.
10. **AC-10** — Un proyecto hijo con `telemetria_deploy=true` registra log de cambios en cada deploy.
11. **AC-11** — Ninguna referencia a Hermes Agentic en el camino crítico de creación.
12. **AC-12** — La BD de producción migra sin pérdida de datos.
13. **AC-13** — Los badges GitHub y VENV/Runtime muestran datos reales (corrige D6).
14. **AC-14** — `proyecto.html` permite reiniciar un App Service detenido (corrige D8).
15. **AC-15** — Un `pasos_json` incompleto se normaliza a 13 pasos en `PENDIENTE` (corrige P5).
16. **AC-16** — El toggle global deshabilita Iniciar/Detener en todas las filas y persiste tras recargar.
17. **AC-17** — `Eliminar` sigue disponible con el toggle inactivo, y siempre pide confirmación.
18. **AC-18** — El catálogo de características se sirve desde la API y la UI se genera dinámicamente.
19. **AC-19** — Añadir una característica nueva no requiere editar la UI.
20. **AC-20** — El logo pesa < 100 KB y aparece en las 3 páginas del portal y en el hijo.
21. **AC-21** — La UI usa "Fábrica de Proyectos UR"; la documentación técnica usa "HERMES Enterprise".
22. **AC-22** — Ningún fallo de verificación Azure puede **escribir** `NO_EXISTE` sin 404 autenticado (P14).
23. **AC-23** — La MI del portal tiene `Reader` y `Website Contributor` en `RG-Hermes-Proyectos`.
24. **AC-24** — Se puede **archivar** un proyecto y desarchivarlo después.
25. **AC-25** — Se puede **eliminar** un proyecto eligiendo componentes, con confirmación por nombre validada en servidor.
26. **AC-26** — La eliminación **se aborta** si ARM reporta que el recurso existe y el estado local no.
27. **AC-27** — El repositorio GitHub viene desmarcado por defecto al eliminar.

---

## 11. Trazabilidad

| Requisito | Artefacto | Verificación |
|-----------|-----------|--------------|
| RF-01 | `.github/workflows/factory-run.yml`, `deploy-child.yml` | Inspección + CI guard |
| RF-02 | `Hermes.Web/templates/proyecto.html`, `index.html`, `api_fabrica.py:157-211` | AC-01, AC-15 |
| RF-03 | `Hermes.Web/templates/index.html:1413-1471`, `servicio_fabrica.py:94-119` | AC-02..AC-04 |
| RF-04 | `api_fabrica.py:296-330`, `servicio_azure.py:97-273`, `index.html:1477-1486`, `proyecto.html:238` | AC-05, AC-06, AC-14 |
| RF-05 | `tools/Crear-HermesProyecto.ps1:24-35,96-102,122-127`, `tools/Templates/**`, `.github/workflows/factory-run.yml:13-33,192` | AC-07..AC-10 |
| RF-06 | `Hermes.Web/templates/index.html` | AC-16, AC-17 |
| RF-07 | `Hermes.Web/static/images/`, `index.html:214`, `proyecto.html`, `proyecto_listado.html`, `tools/Templates/backend/main.py:380` | AC-20 |
| RF-08 | `api_fabrica.py`, `servicio_fabrica.py`, `index.html`, `proyecto.html` | AC-24..AC-27 |
| P14 | `scripts/Diagnose-PortalMI.ps1`, `servicio_azure.py`, `servicio_fabrica.py` | AC-22, AC-23 |
| D6 | `api_fabrica.py:183-207` (añadir claves faltantes) | AC-13 |

---

## 12. Plan de Implementación por Fases

### Fase 1 — Detener el sangrado (crítico, sin dependencias)
Corrige el defecto que motiva todo el UC.

| Tarea | Artefacto |
|-------|-----------|
| Asignar `Reader` + `Website Contributor` a la MI | `scripts/Diagnose-PortalMI.ps1 -Fix` |
| Verificar que ARM responde y los planes se listan | mismo script (secciones 4-5) |
| Distinguir `NO_EXISTE` (404 autenticado) de `NO_VERIFICADO` (fallo) | `servicio_azure.py`, `servicio_fabrica.py` |
| No persistir `NO_EXISTE` ante fallo de token/red | `servicio_fabrica.py:1073-1106` |
| Badge `NO_VERIF` en lugar de `ELIMINADO` ante fallo | `index.html:1391-1395` |
| Desacoplar `linkApp` de `azureStatus` | `index.html:1428` |
| Endpoint `child-portal` + cambio del ancla del nombre | `api_fabrica.py`, `index.html:1445` |

**Entrega:** el enlace funciona para `gestioncontenidoflujosdetrabajo`. **AC-02, AC-03, AC-04, AC-22, AC-23.**

### Fase 2 — Correcciones de datos y UI
| Tarea | Artefacto |
|-------|-----------|
| Añadir claves faltantes al payload del historial | `api_fabrica.py:183-207` |
| Normalizar `pasos_json` a 13 | `servicio_fabrica.py` |
| Persistir estado real del App Service | `servicio_fabrica.py:1266-1270` |
| Botón Iniciar en `proyecto.html` | `proyecto.html:238` |
| Toggle global (sólo Iniciar/Detener) | `index.html:1477-1486` |

**Entrega:** badges correctos, on/off real. **AC-05, AC-13, AC-14, AC-15, AC-16, AC-17.**

### Fase 3 — 13 pasos en el home + identidad visual
| Tarea | Artefacto |
|-------|-----------|
| `pasos[]` en el payload del home | `api_fabrica.py` |
| Portar `renderTimeline()` al home | `index.html` |
| Optimizar logo y aplicarlo en 4 sitios | `static/images/`, 3 templates, plantilla hijo |

**Entrega:** visualización completa + marca UR. **AC-01, AC-20, AC-21.**

### Fase 3b — Ciclo de vida (archivar / eliminar) — RF-08
| Tarea | Artefacto |
|-------|-----------|
| `archivado` en modelo de datos | `servicio_fabrica.py`, migración |
| Endpoints archivar/desarchivar/eliminar | `api_fabrica.py` |
| Reconciliación previa obligatoria | `servicio_fabrica.py` + `servicio_azure.py` |
| Modal de confirmación por nombre + selección de componentes | `index.html`, `proyecto.html` |

**Entrega:** limpiar fantasmas como `crearproyectohijo` desde la UI. **AC-24..AC-27.**

### Fase 4 — Catálogo de características (mayor esfuerzo)
| Tarea | Artefacto |
|-------|-----------|
| Endpoint `GET /caracteristicas` | `api_fabrica.py` |
| UI dinámica del catálogo | `index.html` |
| Propagación de flags (3 puntos) | `.ps1:24-35,96-102,122-127`, `factory-run.yml:13-33,192` |
| Gatear SQLite en 4 capas | `SQLite.ps1`, `startup.sh:13-112`, `main.py:47-61` |
| Menú hamburguesa + telemetría | plantilla del hijo |

**Entrega:** proyectos hijos configurables. **AC-07..AC-10, AC-18, AC-19.**

> **Riesgo de Fase 4:** es la única fase que toca el **generador** de proyectos hijos. Un error aquí
> no rompe el portal: rompe **todos los proyectos futuros**. Requiere pruebas con un proyecto de
> ensayo antes de tocar la plantilla en uso.

---

## 13. Fuera de Alcance

- Ejecución de pasos del pipeline por un LLM (ver §0.1 — decisión P4).
- Migración de proyectos históricos más allá de la reconciliación de estado (ver P9).
- Cambios en la infraestructura Azure (`ASP-HERMES-PORTAL` permanece como está).