# RBAC — Gestión de App Service desde el Portal (Iniciar / Detener / Eliminar)

> **Estado:** ✅ APLICADO y VERIFICADO en producción (`as-hermesportal`)
> **Fecha:** 2026-09-28
> **Feature:** Botones *Iniciar / Detener / Eliminar* en la tabla
> "Últimas 5 Creaciones de Proyectos Hijos" del portal.

## 1. Problema

Los endpoints de gestión de App Service del Portal:

| Endpoint | Acción ARM |
|----------|-----------|
| `POST /api/fabrica/proyectos/{id}/iniciar-app` | `Microsoft.Web/sites/start/action` |
| `POST /api/fabrica/proyectos/{id}/detener-app` | `Microsoft.Web/sites/stop/action` |
| `POST /api/fabrica/proyectos/{id}/eliminar-app` | `Microsoft.Web/sites/delete` |

Autentican contra Azure ARM con `DefaultAzureCredential` → **System-Assigned Managed Identity** del App Service `as-hermesportal`.

Esa MI tenía **únicamente el rol `Reader`** en `RG-Hermes-Proyectos`. `Reader` permite
consultar (reconciliación de recursos, listar App Service Plans) pero **no** ejecutar
acciones de escritura, por lo que los tres endpoints respondían:

```json
{
  "exito": false,
  "status": "ERROR_PERMISOS",
  "status_code": 403,
  "error": "Azure ARM 403 para detener as-hermes-e2e-b5-005"
}
```

## 2. Solución aplicada (mínimo privilegio)

Asignar el rol **`Website Contributor`** a la MI del Portal en el scope del Resource Group:

| Propiedad | Valor |
|-----------|-------|
| Principal (MI) | `as-hermesportal` → `0aefeacd-4cb2-41f1-9476-982bc5a09618` |
| Rol | `Website Contributor` (`Microsoft.Web/sites/*`) |
| Scope | `/subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/resourceGroups/RG-Hermes-Proyectos` |

`Website Contributor` **no** otorga control sobre App Service Plans, Storage, Key Vault
ni el resto de recursos del RG — solo sobre los sitios (`Microsoft.Web/sites/*`).

### Reproducir / verificar

```bash
bash scripts/assign-portal-mi-website-contributor.sh
bash scripts/assign-portal-mi-website-contributor.sh --verify
```

Requiere una identidad con `Microsoft.Authorization/roleAssignments/write` (Owner o
User Access Administrator) en el scope. La identidad OIDC del pipeline **no** puede
asignar RBAC (por eso el paso del workflow hace fallback con nota informativa).

## 3. Evidencia de validación (producción, commit `2f8988d`)

Prueba E2E real desde el portal sobre `crearproyectohijo` (`deployment_id`
`88196510D29340AC`, Web App `as-crearproyectohijo`):

| # | Operación | Respuesta portal | Estado real en Azure |
|---|-----------|------------------|----------------------|
| 1 | `POST .../detener-app` | `{"exito":true,"status":"DETENIDO","status_code":200}` | `Stopped` ✔ |
| 2 | `POST .../iniciar-app` | `{"exito":true,"status":"INICIADO","status_code":200}` | `Running` ✔ |
| 3 | `POST .../eliminar-app` (sobre proyecto ya eliminado) | `{"exito":true,"status":"ELIMINADO","status_code":204}` | idempotente ✔ |

Sincronización de estado en BD (columna App Service del portal):

- `crearproyectohijo` → `azure_resource_check_status = EXISTE`
- `hermes-e2e-b5-005` → `azure_resource_check_status = NO_EXISTE` (badge `ELIMINADO`)

Bitácora (fase `GESTION`, componente `AZURE`):

```json
{"accion":"DETENER","web_app":"as-crearproyectohijo","status":"DETENIDO","exito":true}
{"accion":"INICIAR","web_app":"as-crearproyectohijo","status":"INICIADO","exito":true}
```

## 4. Regresión a vigilar

Si alguien revierte la MI a solo `Reader`, los botones del portal volverán a mostrar
`ERROR_PERMISOS`. El script `--verify` sirve como comprobación rápida.