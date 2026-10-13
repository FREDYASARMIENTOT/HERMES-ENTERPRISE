# Asistente IA de configuración — Portal Fábrica de Proyectos UR

> **Sprint:** A.39 · **Estado:** ✅ COMPLETED
> **Proveedor de referencia:** Microsoft Foundry (Azure AI Foundry)
> **Deployment de prueba:** `Proyecto-ia-ur`

---

## 1. Qué se entregó

Al crear un **proyecto hijo** en el portal, el operador ya no configura el modelo
de IA "a ciegas". Un **chatbot con IA** (`Asistente IA`, botón junto a
*Crear Proyecto*) solicita de forma guiada los cuatro datos necesarios y
**verifica la credencial contra el proveedor antes** de crear el proyecto.

| Dato | Ejemplo (MS Foundry) |
|------|----------------------|
| Proveedor de modelo | `msfoundry` |
| URL base | `https://<recurso>.services.ai.azure.com/models` |
| API Key | `sk-…` (se muestra siempre enmascarada) |
| Modelo / Deployment | `Proyecto-ia-ur` |

Proveedores soportados: `msfoundry`, `azure-openai`, `openai`, `openrouter`,
`ollama` (sin API key) y `custom` (cualquier endpoint compatible con OpenAI).

---

## 2. Flujo del usuario en el portal

1. Pulsar **Asistente IA** en la tarjeta *Fábrica de Proyectos*.
2. El asistente pide, en este orden: **proveedor → URL base → API Key → modelo**.
   * Se puede responder paso a paso **o** pegar todo de una vez:
     ```
     proveedor: msfoundry
     url_base: https://mi-recurso.services.ai.azure.com/models
     api_key: sk-xxxxxxxx
     modelo: Proyecto-ia-ur
     ```
   * El botón **Ejemplo MS Foundry** inserta una plantilla editable.
   * Comandos: `reiniciar` y `cancelar`.
3. El panel derecho **Configuración capturada** marca cada campo (`pendiente` /
   *activo* / capturado). La API Key nunca se muestra completa.
4. Con los 4 campos completos se habilita **Validar conexión**, que hace una
   llamada **real** de `chat completions` al proveedor.
   * **OK** → `Conexión verificada` con HTTP, latencia y endpoint.
   * **Fallo** → se muestra el **estado semántico**, el **motivo real del
     proveedor** (`error.message` / `detail` / `reason`) y el endpoint probado.
5. **Usar esta configuración** habilita el envío: el indicador
   `IA validada: msfoundry / Proyecto-ia-ur` queda visible junto al botón
   *Crear Proyecto*.
6. Al crear el proyecto, el `POST /api/fabrica/proyectos` incluye el bloque `ia`
   y el borrador local se limpia para no reutilizarlo por accidente.

---

## 3. Contrato de la API

| Método | Ruta | Descripción |
|--------|------|-------------|
| `GET` | `/api/asistente/proveedores` | Catálogo de proveedores |
| `GET` | `/api/asistente/campos` | Campos obligatorios y su orden |
| `GET` | `/api/asistente/estado` | Salud (`httpx`, LLM interna, TTL de validación) |
| `POST` | `/api/asistente/chat` | Un turno de conversación |
| `POST` | `/api/asistente/validar` | Validación **real** de la credencial |
| `POST` | `/api/fabrica/proyectos` | Creación del proyecto hijo (ahora acepta `ia`) |

`POST /api/asistente/validar` devuelve, entre otros campos:

```json
{
  "ok": false,
  "estado": "ERROR_SOLICITUD_INVALIDA",
  "proveedor": "msfoundry",
  "endpoint": "https://…/models/chat/completions",
  "modelo": "Proyecto-ia-ur",
  "api_key_enmascarada": "sk-x******abcd",
  "http_status": 400,
  "latencia_ms": 412,
  "error": "El proveedor rechazo la solicitud (400/422). Detalle del proveedor: MODEL_DOES_NOT_SUPPORT_IMAGES",
  "detalle": "MODEL_DOES_NOT_SUPPORT_IMAGES"
}
```

Estados posibles: `CONECTADO`, `ERROR_AUTENTICACION` (401), `ERROR_PERMISOS` (403),
`ERROR_MODELO_NO_ENCONTRADO` (404), `ERROR_CUOTA` (429),
`ERROR_SOLICITUD_INVALIDA` (400/422), `ERROR_PROVEEDOR` (5xx),
`ERROR_TIMEOUT`, `ERROR_CONEXION`, `ERROR_URL_INVALIDA`, `ERROR_SIN_MODELO`,
`ERROR_SIN_API_KEY`, `ERROR_PROVEEDOR_DESCONOCIDO`, `ERROR_LIBRERIA`.

---

## 4. Seguridad del secreto

| Regla | Implementación |
|-------|----------------|
| La API key nunca se devuelve al navegador | `resumen_borrador()` solo expone `api_key_enmascarada` |
| La API key nunca se registra en logs | Solo máscara y huella SHA-256 |
| La API key no vive en la fila de la solicitud | Tabla dedicada `ia_credenciales` |
| `a_dict()` no puede filtrarla | No contiene la key; el secreto está en otra tabla |
| El Event Store no la registra | El detalle incluye `ia_api_key_huella=<12 chars>…` |
| La validación no se puede falsificar | `validacion_reciente()` audita server-side (TTL 900 s) |
| Sin secretos en código | Bootstrap opcional del asistente por entorno (`HERMES_ASISTENTE_*`) |

Recuperación server-side para el Factory:

```python
from Hermes.Web.backend.servicio_fabrica import obtener_servicio_fabrica
credencial = obtener_servicio_fabrica().obtener_credencial_ia(deployment_id)
# {"proveedor": "msfoundry", "url_base": "...", "modelo": "Proyecto-ia-ur",
#  "api_key": "sk-...", "api_key_enmascarada": "sk-x******abcd", ...}
```

---

## 5. Prueba LOCAL antes de producción (obligatoria)

No requiere desplegar nada: valida la credencial real y todo el flujo
(chat, persistencia, auditoría) contra una base de datos temporal.

### 5.1 Ciclo rápido — suite sin red

```powershell
python -m pytest Hermes.Web/tests/test_asistente_ia.py -q
# 96 passed
```

### 5.2 Prueba live contra Microsoft Foundry (recomendada)

```powershell
python pruebas\asistente-ia\Probar-AsistenteIA.py `
  --url-base "https://<recurso>.services.ai.azure.com/models" `
  --api-key  "<api-key>" `
  --modelo   "Proyecto-ia-ur" `
  --proveedor msfoundry
```

O mediante el wrapper PowerShell (mismas opciones + variables de entorno):

```powershell
$env:HERMES_IA_URL_BASE  = "https://<recurso>.services.ai.azure.com/models"
$env:HERMES_IA_API_KEY   = "<api-key>"
$env:HERMES_IA_MODELO    = "Proyecto-ia-ur"     # opcional
$env:HERMES_IA_PROVEEDOR = "msfoundry"          # opcional

pwsh -NoProfile -File pruebas\asistente-ia\Test-AsistenteIAMyFoundry.ps1
```

Secciones de la prueba: *(1)* contrato y catálogo · *(2)* conversación de 4 turnos ·
*(3)* validación real de la credencial · *(4)* creación de la solicitud Child con
auditoría · *(5)* caso negativo (modelo inexistente).

**Criterio de aceptación:** `RESULTADO: N PASS / 0 FAIL` y código de salida `0`.
Códigos: `0` = OK, `1` = fallos, `2` = falta configuración.

### 5.3 Test live vía pytest

```powershell
$env:HERMES_IA_URL_BASE = "https://<recurso>.services.ai.azure.com/models"
$env:HERMES_IA_API_KEY  = "<api-key>"
$env:HERMES_IA_MODELO   = "Proyecto-ia-ur"
python -m pytest Hermes.Web/tests/test_asistente_ia_myfoundry_live.py -v -s
```

Sin credenciales estos 7 casos se **saltan** (`skipped`), por lo que CI sigue
siendo determinista y libre de secretos.

### 5.4 Interpretación de resultados

| Síntoma en la prueba local | Causa probable | Acción |
|---|---|---|
| `ERROR_CONEXION` / `getaddrinfo failed` | URL base o DNS incorrectos | Verificar el recurso y la ruta `/models` |
| `ERROR_AUTENTICACION` (401) | API key de otro recurso | Regenerar la key en el recurso correcto |
| `ERROR_MODELO_NO_ENCONTRADO` (404) | Deployment mal escrito | Usar el nombre exacto del deployment |
| `ERROR_SOLICITUD_INVALIDA` (400/422) | El modelo no soporta el payload | El mensaje muestra el `detalle` real del proveedor |
| `ERROR_PERMISOS` (403) | Key sin permisos / RBAC | Revisar el rol del recurso Foundry |
| `ERROR_CUOTA` (429) | Límite de tasa o cuota | Esperar o ampliar la cuota |

---

## 6. Trazabilidad del proyecto hijo

La tabla `solicitudes_proyecto` guarda, por proyecto:
`ia_proveedor`, `ia_url_base`, `ia_modelo`, `ia_api_key_enmascarada`,
`ia_api_key_huella`, `ia_configurada` (`SI`/`NO`), `ia_validado`
(`CONECTADO`/`NO_VERIFICADO`), `ia_validado_en` e `ia_validacion_detalle`.

La vista `/proyectos/{deployment_id}` muestra la tarjeta **Modelo de IA del
proyecto** con estos valores.

---

## 7. Rollback

Ninguna migración es destructiva: las 9 columnas son aditivas (`TEXT DEFAULT`)
y la tabla `ia_credenciales` se crea con `IF NOT EXISTS`. Revertir el sprint
consiste en desplegar la revisión anterior; los campos `ia_*` quedan inertes y
`SolicitudCrear.ia` se ignora al ser opcional.