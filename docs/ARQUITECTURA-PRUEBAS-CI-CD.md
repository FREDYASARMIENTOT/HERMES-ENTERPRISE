# ARQUITECTURA DE PRUEBAS Y CI/CD — HERMES ENTERPRISE

## 1. Propósito de las Pruebas

Las pruebas en HERMES-ENTERPRISE existen exclusivamente para proteger
el flujo **Factory → Child → Despliegue**. No son un museo de tests
históricos ni un banco de pruebas de experimentos pasados.

Toda prueba debe responder una pregunta operacional:

> *"¿La Factory sigue generando correctamente un Child preparado
>  para ser desplegado mediante nuestro CI/CD?"*

## 2. Prueba Canónica

Actualmente existe **una única prueba activa**:

| Archivo | Ruta |
|---------|------|
| `Test-ChildTemplateRendering.ps1` | `pruebas/canonicas/Test-ChildTemplateRendering.ps1` |

### Qué valida

1. **Funciones de la plantilla**: `_resolve_meta`, `_build_pipeline`,
   `consultar_sqlite_param`
2. **Landing page**: `HTMLResponse`, `_PIPELINE_DEF`
3. **Nodos del pipeline**: factory, child-repo, ci, control-plane,
   oidc, asp-iaur, web-app, zip-deploy, readiness, functional-tests,
   evidence, online (12 nodos)
4. **Variables de entorno fallback**: HERMES_PROJECT_NAME, REGION,
   DEPLOYMENT_ID, CORRELATION_ID, WEBAPP_NAME
5. **SQL parametrizado**: seguridad contra inyección
6. **Secciones de la UI**: IDENTIDAD, INFRAESTRUCTURA, TRAZABILIDAD,
   DETALLE DE IMPLEMENTACION, ACCESOS, PRUEBAS FUNCIONALES, Redoc,
   Footer
7. **Indicadores visuales**: Badge REUTILIZADO, Plan Creado: NO,
   Plan Reutilizado: SI, Badge OIDC
8. **Sin duplicados**: secciones críticas aparecen exactamente una vez
9. **Placeholders de Factory**: `{{REGION}}`, `{{DEPLOYMENT_ID}}`
10. **Detalle de implementación**: Crear-HermesProyecto, deploy-child.yml,
    ZIP Deploy, deployment-report.json
11. **Factory canónico**: Crear-HermesProyecto.ps1 usa `.Replace()`,
    valida ubicación, reemplaza placeholders
### Qué NO valida

- Implementación interna de módulos que no forman parte del contrato
  Factory → Child
- Kernel, Plugins, Providers, Bootstrap (arquitectura reemplazada)
- Pester ni ningún framework de pruebas externo
- Rutas absolutas (la prueba es portable)
- Azure directamente (eso es responsabilidad de CD/E2E)
- SQLite Catalog (componente interno sin contrato público)

## 3. Relación Factory → Child

```
Factory (tools/Crear-HermesProyecto.ps1)
  ↓
Genera proyecto Child con:
  - Plantilla main.py (tools/Templates/backend/main.py)
  - CI template (tools/Templates/github/ci.yml)
  - Estructura de directorios
  - Metadatos, pipeline, infraestructura
  ↓
Prueba canónica verifica que la plantilla main.py
contiene todos los elementos contractuales necesarios
  ↓
Child listo para GitHub → CI → Control Plane → Azure
```

## 4. Relación CI → CD

| Fase | Workflow | Responsabilidad |
|------|----------|-----------------|
| **CI** | `.github/workflows/ci.yml` | Validar código, estructura, templates, dependencias, prueba canónica |
| **CD** | `.github/workflows/deploy-child.yml` | Despliegue real a Azure (OIDC, Web App, readiness, endpoints) |

CI **NO** reemplaza a CD. CD **NO** reemplaza a CI.

CI valida que el Factory produce Childs correctos.
CD despliega Childs reales en Azure y verifica que funcionan.

## 5. Relación Control Plane → Azure

El Control Plane (`deploy-child.yml`) orquesta:
1. Validación de entradas
2. OIDC (FIC existente)
3. Checkout del Child
4. Provision/validación de Web App
5. ZIP Deploy
6. Readiness polling
7. Tests funcionales
8. Validación user-facing
9. Generación de evidencia
10. Reporte final

Azure se valida en CD, no en CI.

## 6. Estrategia de Pruebas E2E

Las pruebas E2E se ejecutan en `deploy-child.yml`:
- Readiness: polling con MAX_ATTEMPTS (no `sleep 30`)
- Funcionales: HTTP 200 en endpoints clave
- User-facing: verificación de contenido HTML
- Evidencia: `deployment-report.json` con resultados reales

No existe suite E2E separada en `pruebas/`.

## 7. Criterios PASS/FAIL

```
PASS = exit 0  →  GitHub Actions step verde
FAIL = exit 1  →  GitHub Actions step rojo → bloquea el job
```

La prueba canónica sigue exactamente este contrato:
- Todos los tests PASS → `exit 0`
- Uno o más tests FAIL → `exit 1`
## 8. Pruebas Eliminadas

Durante RC86 se eliminaron del repositorio activo:

| Grupo | Cantidad | Motivo |
|-------|----------|--------|
| pruebas/archive/RC62/ | 1 | Suite original Kernel/Plugins (arquitectura reemplazada) |
| pruebas/archive/RC85.2/ | 79 | Pruebas de Kernel, Plugins, Providers, Bootstrap, Context, Azure heredado (arquitectura reemplazada) |
| pruebas/archive/README.md | 1 | Documentación del archive (historia preservada en git) |
| scripts/Test-HermesEnterprise.ps1 | 1 | Smoke test que referenciaba pruebas ya eliminadas |
| scripts/Test-HermesEnterpriseSandbox.ps1 | 1 | Wrapper del anterior |
| tools/Test-CatalogDb.ps1 | 1 | Debug SQLite, sin valor operativo |
| tools/Test-CatalogVerification.ps1 | 1 | Debug SQLite, sin valor operativo |
| tools/Test-DbCounts.ps1 | 1 | Conteo de filas, sin valor operativo |
| tools/Test-DebugTables.ps1 | 1 | Debug temporal |
| docs/archive/provision-appservice.yml | 1 | Workflow histórico |
| **Total** | **87** | |

Todas estas pruebas pertenecían a la arquitectura **Kernel / Plugins / Providers / Bootstrap**
que fue reemplazada por:

    Factory → Child → CI del Child → Control Plane → OIDC → Azure → Web App

La historia completa de RCs está preservada en **git history** y en
CHANGELOG.md, no en archivos dentro del árbol de trabajo.

## 9. Pruebas que Quedan

`
pruebas/
  └── canonicas/
       └── Test-ChildTemplateRendering.ps1    # 47 tests, Factory→Child
`

No existen más archivos de prueba en scripts/, tools/, ni ningún
otro directorio del repositorio.

## 10. Cómo Agregar una Prueba Nueva

**ANTES de crear una nueva prueba**, seguir esta regla:

1. ¿La capacidad ya está cubierta por la prueba canónica?
   - Si SÍ → no crear nueva prueba
2. ¿Se puede ampliar la prueba canónica existente?
   - Si SÍ → agregar un nuevo caso Escribir-ResultadoPrueba en
     Test-ChildTemplateRendering.ps1
3. ¿Existe una responsabilidad realmente distinta que justifique una
   prueba separada?
   - Si SÍ → crear la prueba en pruebas/canonicas/ con nombre
     descriptivo y conectarla explícitamente a CI/CD
   - Documentar en este archivo la razón de la nueva prueba
4. Justificar funcionalmente — **NO permitir**:
   - TestNuevo.ps1, TestNuevo2.ps1, TestFinal.ps1
   - TestRCxx.ps1 sin justificación

## 11. Regla Anti-Legacy

**NO** se permite acumulación de pruebas legacy por las siguientes razones:

- Una prueba que no protege el sistema actual es basura
- Una prueba que no se ejecuta en CI/CD es ruido
- Cada prueba legacy aumenta el costo de mantenimiento
- Cada prueba legacy confunde a nuevos desarrolladores
- El repositorio no es un museo

Si una prueba no responde la pregunta operacional del punto 1,
debe ser eliminada.

## 12. Nomenclatura

| Concepto | Convención |
|----------|-----------|
| Funciones internas | Español (Escribir-ResultadoPrueba, Validar-PlantillaChild) |
| Variables internas | Español (, ) |
| Comentarios | Español, explicativos (no obvios) |
| Contratos externos | Inglés (GitHub Actions, YAML, Azure CLI, FastAPI, OpenAPI) |
| Nombres de workflows | Inglés (ci.yml, deploy-child.yml) |
| Nombres de jobs | Español (Validar PowerShell, Validar documentación) |

## 13. Jobs de CI

| Job | Runner | Qué valida |
|-----|--------|-----------|
| validate-python | ubuntu-latest | Dependencias Python, entrypoint FastAPI, archivos canónicos |
| validate-powershell | windows-latest | Sintaxis de módulos PowerShell + Factory |
| validate-docs | ubuntu-latest | Existencia de README, CHANGELOG, ArchitectureState |
| validate-actions | ubuntu-latest | YAML workflows, deriva de capacidades |

El job validate-powershell ejecuta la **prueba canónica**
(pruebas/canonicas/Test-ChildTemplateRendering.ps1) que es el
único test determinista que bloquea CI.
