# RC85 — Pruebas Canonicas CI/CD

## Problema Raiz

El workflow CI de GitHub Actions fallaba debido a dos problemas en la
prueba canonica `Test-ChildTemplateRendering.ps1`:

### 1. Ruta absoluta hardcodeada

```
$HermesRoot = "D:\HERMES-ENTERPRISE"   # ANTIGUO
```

El runner de GitHub Actions NO tiene `D:\HERMES-ENTERPRISE` como raiz
garantizada. Su estructura tipica es:

```
D:\a\HERMES-ENTERPRISE\HERMES-ENTERPRISE\pruebas\unitarias\
```

### 2. Conflicto con el alias `wt`

La funcion de prueba se llamaba `wt`, nombre que colisiona con
Windows Terminal (`wt.exe`). PowerShell resolvia `wt` como el
ejecutable de terminal, causando:

```
Cannot convert value "System.Object[]" to type "System.Boolean"
```

## Solucion

### 1. Descubrimiento dinamico del repositorio

Se reemplazo la ruta absoluta por calculo desde `$PSScriptRoot`:

```powershell
$RaizRepositorio = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
```

`$PSScriptRoot` es la carpeta donde reside el script:

```
pruebas/unitarias/Test-ChildTemplateRendering.ps1
       |--- $PSScriptRoot = pruebas/unitarias/
            |--- Split-Path (Parent) = pruebas/
                 |--- Split-Path (Parent) = Raiz del repositorio
```

### 2. Funcion renombrada a `Escribir-ResultadoPrueba`

```powershell
function Escribir-ResultadoPrueba {
    param([string]$NombrePrueba, [bool]$Resultado)
    ...
}
```

### 3. Verificacion pre-vuelo

Antes de ejecutar las 47 comprobaciones, se verifica que existan:

- `tools/Templates/backend/main.py` (plantilla Child)
- `tools/Crear-HermesProyecto.ps1` (Factory canonico)

Si alguno falta, se produce un fallo claro y se termina con diagnostico.

### 4. Nombres internos en espanol

Todas las variables, funciones y comentarios nuevos estan en espanol:

| Antiguo | Nuevo |
|---------|-------|
| `$HermesRoot` | `$RaizRepositorio` |
| `$c` | `$ContenidoPlantilla` |
| `$fc` | `$ContenidoFactory` |
| `wt(...)` | `Escribir-ResultadoPrueba(...)` |
| `$tp` / `$tf` | `$ConteoExitos` / `$ConteoFallos` |

## Arquitectura de Pruebas

### 11 suites canonicas (47 tests)

| # | Suite | Tests | Que valida |
|---|-------|-------|------------|
| 1 | Funciones | 3 | `_resolve_meta`, `_build_pipeline`, `consultar_sqlite_param` |
| 2 | Landing page | 2 | `HTMLResponse`, `_PIPELINE_DEF` |
| 3 | Nodos pipeline | 12 | 12 nodos (factory, child-repo, ci, ... online) |
| 4 | Var. entorno | 5 | HERMES_PROJECT_NAME, REGION, etc. |
| 5 | SQL parametrizado | 2 | `WHERE CorrelationId = ?`, `execute(query, params)` |
| 6 | UI sections | 8 | IDENTIDAD, INFRAESTRUCTURA, TRAZABILIDAD, etc. |
| 7 | Plan indicators | 4 | REUTILIZADO, Plan Creado: NO, OIDC badge |
| 8 | Sin duplicados | 1 | ACCESOS aparece exactamente una vez |
| 9 | Placeholders | 2 | `_REGION`, `_DEPLOYMENT_ID` con `{{...}}` |
| 10 | Implementacion | 4 | Factory, CI, ZIP Deploy, deployment-report |
| 11 | Factory canonico | 4 | `.Replace()`, REGION, DEPLOYMENT_ID, ContainsKey |

### Criterios PASS/FAIL

- **PASS**: Todas las pruebas pasan -> exit code 0
- **FAIL**: Una o mas pruebas fallan -> exit code 1
- **Bloqueante**: Archivo obligatorio no encontrado -> exit code 1 con diagnostico

### Salida tipica

```
[Prueba] Funciones de la plantilla
  [PASS] _resolve_meta
  [PASS] _build_pipeline
  [PASS] consultar_sqlite_param
...
RESULTADO
TOTAL : 47
PASS  : 47
FAIL  : 0
RESULT: ALL PASSED
```

## Relacion con Factory

La prueba valida que el Factory canonico (`Crear-HermesProyecto.ps1`)
use `.Replace()` en lugar de `-replace` para evitar problemas de
escapado con los placeholders `{{...}}`. Tambien verifica que los
tokens especificos (REGION, DEPLOYMENT_ID) sean reemplazados.

La plantilla `main.py` contiene los placeholders como variables:

```python
_REGION = "{{REGION}}"
_DEPLOYMENT_ID = "{{DEPLOYMENT_ID}}"
```

Factory los reemplaza en tiempo de creacion del proyecto mediante:

```powershell
$mainPy = $mainPy.Replace('{{REGION}}', $regionVal)
```

## Relacion con Child

Cada proyecto Child ejecuta su propia landing page en la ruta raiz.
La prueba valida que la plantilla tenga todas las secciones requeridas:

- IDENTIDAD DEL PROYECTO
- INFRAESTRUCTURA
- TRAZABILIDAD DE DESPLIEGUE (pipeline visual)
- DETALLE DE IMPLEMENTACION
- ACCESOS
- PRUEBAS FUNCIONALES
- LINEA DE TIEMPO

## Relacion con Control Plane

El Control Plane (`deploy-child.yml`) orquesta el despliegue del Child.
La prueba valida que la seccion DETALLE DE IMPLEMENTACION mencione
`deploy-child.yml` y `deployment-report.json` como evidencias.

## Relacion con CI

El workflow CI de GitHub Actions ejecuta la prueba canonica como
paso especifico en el job `validate-powershell`. Si la prueba falla,
el workflow falla con la causa real visible en los logs.

## Mantenimiento

### Agregar una nueva prueba

1. Agregar el test en la suite correspondiente dentro de
   `Test-ChildTemplateRendering.ps1`
2. Documentar el cambio en este archivo
3. Ejecutar localmente y verificar PASS
4. Hacer commit

### Cuando cambia el contrato

Si la plantilla `main.py` se modifica, las pruebas deben actualizarse
para reflejar el nuevo contrato. NO eliminar pruebas sin justificacion.

### Version

- RC85: Primera version portable de la prueba canonica
- Commit: `6265a21` (RC84) + proximo commit RC85