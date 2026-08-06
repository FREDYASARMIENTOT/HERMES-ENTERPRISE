# Smoke Test — Hermes Enterprise RC71

## Propósito
Validar que el Runtime Python, el backend FastAPI, el middleware y la documentación canónica están operativos tras la refactorización arquitectónica RC70-D / RC71.

---

## 1. Validación del Runtime Python

```powershell
# Verificar que Hermes.Python.json existe y es válido
$config = Get-Content config/Hermes.Python.json | ConvertFrom-Json
Write-Host "Python: $($config.VersionPython)"
Write-Host "Ruta: $($config.RutaEntornoVirtual)"
Write-Host "Exe: $($config.RutaPython)"
```

### Criterios de éxito
| # | Verificación | Esperado |
|---|-------------|----------|
| 1 | `Hermes.Python.json` existe | `True` |
| 2 | `RutaPython` apunta a `HermesEnterprise\Scripts\python.exe` | `True` |
| 3 | `RutaPip` apunta a `HermesEnterprise\Scripts\pip.exe` | `True` |
| 4 | El directorio del venv existe en `D:\HermesRuntime\Environments\HermesEnterprise` | `True` |
| 5 | `pyvenv.cfg` existe dentro del venv | `True` |

---

## 2. Validación de Dependencias

```bash
D:\HermesRuntime\Environments\HermesEnterprise\Scripts\python.exe -m pip install -r Hermes.Web/requirements.txt
```

### Criterios de éxito
| # | Verificación | Esperado |
|---|-------------|----------|
| 1 | Instalación exitosa sin errores | Exit code 0 |
| 2 | `fastapi` importable | `True` |
| 3 | `uvicorn` importable | `True` |
| 4 | `jinja2` importable | `True` |
| 5 | `pydantic` importable | `True` |

---

## 3. Validación de Importaciones del Backend

```bash
D:\HermesRuntime\Environments\HermesEnterprise\Scripts\python.exe -c "
import sys
sys.path.insert(0, '.')
from Hermes.Web.backend.main import app
print('Backend OK')
"
```

### Criterios de éxito
| # | Verificación | Esperado |
|---|-------------|----------|
| 1 | Importación sin errores de `Hermes.Web.backend.main` | `True` |
| 2 | `app` es instancia de `FastAPI` | `True` |
| 3 | Middleware se carga sin advertencias críticas | `True` |

---

## 4. Validación del Servidor Uvicorn

```bash
D:\HermesRuntime\Environments\HermesEnterprise\Scripts\python.exe -m uvicorn Hermes.Web.backend.main:app --host 127.0.0.1 --port 8000 &
# Esperar 3 segundos
curl http://127.0.0.1:8000/health
```

### Criterios de éxito
| # | Verificación | Esperado |
|---|-------------|----------|
| 1 | Servidor inicia sin errores | `True` |
| 2 | `GET /health` retorna 200 | `True` |
| 3 | Respuesta contiene `"estado": "saludable"` | `True` |
| 4 | Respuesta contiene `"python_version"` | `True` |

---

## 5. Validación de la Landing Page

```bash
curl http://127.0.0.1:8000/
```

### Criterios de éxito
| # | Verificación | Esperado |
|---|-------------|----------|
| 1 | Respuesta HTTP 200 | `True` |
| 2 | Contiene HTML `<title>Hermes Enterprise</title>` | `True` |

---

## 6. Validación de API Endpoints

```bash
curl http://127.0.0.1:8000/api/version
curl http://127.0.0.1:8000/api/proyecto
curl http://127.0.0.1:8000/api/entorno
curl http://127.0.0.1:8000/api/bootstrap
curl http://127.0.0.1:8000/api/azure
curl http://127.0.0.1:8000/api/sqlite
curl http://127.0.0.1:8000/api/despliegue
```

### Criterios de éxito
| # | Verificación | Esperado |
|---|-------------|----------|
| 1 | Cada endpoint retorna HTTP 200 o 422 (si espera parámetros) | `True` |
| 2 | Respuestas en formato JSON válido | `True` |

---

## 7. Validación de Documentación Canónica

| # | Archivo | Esperado |
|---|---------|----------|
| 1 | `README.md` | Existe y contiene enlaces funcionales |
| 2 | `CURRENT_STATE.md` | Existe y refleja el estado RC71 |
| 3 | `CHANGELOG.md` | Existe y contiene entrada RC71 |
| 4 | `docs/ArchitectureState.md` | Existe y documenta el Runtime |
| 5 | `Hermes.Web/requirements.txt` | Existe y contiene solo dependencias reales |

---

## 8. Validación de CI/CD

| # | Verificación | Esperado |
|---|-------------|----------|
| 1 | `python -m pytest` pasa en pruebas existentes | `True` |
| 2 | `PSScriptAnalyzer` no reporta errores críticos | `True` |
| 3 | Workflow `ci.yml` se ejecuta sin errores en GitHub Actions | `True` |

---

## 9. Validación de Azure App Service (Pre-despliegue)

```bash
# Verificar startup.sh
grep -c "python3 -m " Hermes.Web/deployment/startup.sh  # Debe ser > 0
grep -c "^uvicorn " Hermes.Web/deployment/startup.sh     # Debe ser 0
```

### Criterios de éxito
| # | Verificación | Esperado |
|---|-------------|----------|
| 1 | `startup.sh` usa `python3 -m pip` | `True` |
| 2 | `startup.sh` usa `python3 -m gunicorn` | `True` |
| 3 | `startup.sh` NO usa `uvicorn` directo | `True` |
| 4 | `requirements.txt` contiene `gunicorn` | `True` |

---

## Resultado Final

| Fase | Estado |
|------|--------|
| 1. Runtime Python | ✅ / ❌ |
| 2. Dependencias | ✅ / ❌ |
| 3. Importaciones Backend | ✅ / ❌ |
| 4. Servidor Uvicorn | ✅ / ❌ |
| 5. Landing Page | ✅ / ❌ |
| 6. API Endpoints | ✅ / ❌ |
| 7. Documentación | ✅ / ❌ |
| 8. CI/CD | ✅ / ❌ |
| 9. Azure App Service | ✅ / ❌ |
| **Resultado Global** | **✅ / ❌** |

---

*Documento generado para RC71 — 2026-08-07*