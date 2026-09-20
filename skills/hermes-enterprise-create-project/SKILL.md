# CLINE SKILL — HERMES-ENTERPRISE
## Maduración del ciclo E2E "Crear Proyecto"

**Proyecto:** HERMES-ENTERPRISE  
**Repositorio:** FREDYASARMIENTOT/HERMES-ENTERPRISE  
**Propósito:** gobernar a Cline durante el ciclo completo de crear, desplegar, validar y recuperar un proyecto Hermes hijo.

---

# 1. PROPÓSITO

Esta skill existe para evitar comportamientos repetitivos o desalineados durante tareas largas de CI/CD, especialmente cuando una ejecución tarda más que los tiempos normales de una herramienta.

Cline debe tratar el ciclo como una **máquina de estados operacional**, no como una secuencia de comandos aislados.

Objetivo:

```text
Usuario
  ↓
Portal canónico
  ↓
Solicitud persistida
  ↓
Factory Runner
  ↓
Repositorio hijo
  ↓
Commit SHA real
  ↓
Child CI
  ↓
Control Plane
  ↓
OIDC federado
  ↓
Azure
  ↓
App Service Plan seleccionado
  ↓
Web App
  ↓
Deploy
  ↓
Readiness
  ↓
Functional Tests
  ↓
Evidence
  ↓
Portal
  ↓
Persistencia
  ↓
Recuperación E2E
```

La finalización no se determina por una sola llamada HTTP ni por el éxito de un workflow aislado.

---

# 2. PRINCIPIOS NO NEGOCIABLES

## 2.1 No olvidar contexto

Antes de modificar código, Cline debe recuperar:

- arquitectura;
- último commit;
- último workflow;
- último run;
- estado de Azure;
- estado del Portal;
- estado del Factory;
- estado del Child CI;
- estado del Control Plane;
- estado OIDC;
- App Service Plan;
- deployment_id;
- correlation_id;
- child SHA.

No asumir que una etapa está pendiente solamente porque no aparece en la última salida.

## 2.2 OIDC federado es infraestructura estable

Si Azure Login (OIDC) ya pasó, **NO rediseñar autenticación para resolver un error posterior**.

No modificar sin evidencia:

- FIC;
- App Registration;
- Service Principal;
- RBAC;
- client ID;
- tenant;
- subscription;
- federated subject.

Si OIDC falla, diagnosticar primero:

1. permissions;
2. environment;
3. client-id;
4. tenant-id;
5. subscription;
6. federated subject;
7. timestamp/run;
8. error exacto de azure/login.

No hacer cambios especulativos.
---

# 3. AS-HERMESENTERPRISE ESTÁ ELIMINADO

Restricción permanente:

```text
NO crear AS-HermesEnterprise
NO restaurar AS-HermesEnterprise
NO usar AS-HermesEnterprise como fallback
NO redirigir el Portal hacia AS-HermesEnterprise
NO cambiar el Portal canónico
```

Portal canónico:

```text
AS-HermesPortal
https://as-hermesportal.azurewebsites.net/

Resource Group:
RG-Hermes-Proyectos

Plan:
ASP-HERMES-PORTAL
```

El **Control Plane lógico** es HERMES-ENTERPRISE/GitHub Actions.

No confundir:

```text
Control Plane lógico
        ≠
App Service AS-HermesEnterprise
```

---

# 4. MÁQUINA DE ESTADOS

```text
AUDIT
 ↓
DIAGNOSIS
 ↓
IMPLEMENT
 ↓
TEST
 ↓
COMMIT
 ↓
PUSH
 ↓
CI
 ↓
DEPLOY
 ↓
READINESS
 ↓
FUNCTIONAL
 ↓
EVIDENCE
 ↓
PERSISTENCE
 ↓
E2E
 ↓
ACCEPTANCE
```

Un fallo en una etapa no permite saltar artificialmente a una etapa posterior.

---

# 5. GESTIÓN DE TIEMPOS

## Regla crítica

**30 segundos NO es un timeout universal del sistema.**

Una herramienta puede tardar 30 segundos mientras el workflow real continúa.

No cancelar ni reiniciar automáticamente un deploy porque supere 30 segundos.

### Operaciones rápidas

- git status
- git diff
- tests unitarios pequeños
- compile
- YAML parse
- API local

### Operaciones de duración variable

- GitHub Actions
- Azure Web App deployment
- Oryx build
- pip install
- az webapp deploy
- Factory Runner
- Child CI
- Control Plane
- readiness
- functional tests

### Supervisión

Preferir:

```bash
gh run watch RUN_ID --interval 15
```

No hacer polling manual agresivo.

---

# 6. WATCHDOG DE DEPLOYMENT

Si un proceso tarda más de lo esperado:

**NO concluir FAIL solamente por tiempo.**

Protocolo:

```text
T0 = inicio
T1 = duración esperada
T2 = duración extendida
T3 = diagnóstico
```

A los 30 segundos:

```text
CONTINÚA
```

Al superar el tiempo normal:

```text
OBSERVAR JOB / STEP / LOGS
```

Solo cancelar/reintentar si:

- existe failure explícito;
- existe timeout real de plataforma;
- existe evidencia de bloqueo;
- el run terminó.

Evitar deployments paralelos innecesarios.
---

# 7. NO REPETIR POLLING

Nunca ejecutar indefinidamente el mismo comando:

```bash
gh run view RUN_ID --json jobs
```

Si el estado no cambia:

```text
usar gh run watch
```

o esperar un intervalo razonable.

Si la herramienta detecta llamadas idénticas consecutivas:

```text
detener polling
cambiar estrategia
```

---

# 8. MATRIZ DE DIAGNÓSTICO

| Síntoma | Diagnóstico inicial |
|---|---|
| OIDC PASS + deploy FAIL | No tocar OIDC |
| Azure Login FAIL | revisar federación |
| Build PASS + Azure deploy FAIL | revisar Azure/deploy |
| Web App existe + readiness FAIL | revisar startup/aplicación |
| Readiness PASS + functional FAIL | revisar endpoints |
| Functional PASS + evidence FAIL | revisar evidencia |
| Evidence PASS + Portal vacío | revisar persistencia/API |
| Portal API 200 + dato vacío | revisar fuente real |
| Child SHA mismatch | revisar Factory |
| CP FAIL por shell | corregir shell, no arquitectura |
| Kudu 502 | revisar paquete/deploy |
| workflow >30 s | supervisar, no cancelar |
| commit no despliega Portal | revisar triggers |
| metadata no llega Portal | revisar contrato/PUT |

---

# 9. CONTROL DE CAMBIOS

Flujo obligatorio:

```text
AUDIT
→ DIFF
→ CHANGESET
→ VALIDATE
→ COMMIT
→ PUSH
→ RUN
→ EVIDENCE
```

Antes de cada commit:

```bash
git status --short
git diff --stat
git diff --check
git diff
```

No incluir:

- temporales;
- logs;
- ZIP;
- artefactos;
- secretos;
- dumps;
- bases temporales.

## Commits atómicos

Preferir:

```text
fix(control-plane): quote app settings safely
fix(portal-deploy): remove oversized package
fix(traceability): persist child sha
fix(readiness): improve deployment supervision
fix(factory): preserve deployment correlation
test(e2e): validate persistence after reload
```

Evitar commits vagos como:

```text
fix everything
```

---

# 10. NO VERSIONAR ERRORES DE CI/CD

Antes de modificar un workflow fallido:

1. leer log;
2. localizar línea;
3. reproducir sintaxis si es posible;
4. corregir;
5. validar YAML;
6. validar shell;
7. revisar diff;
8. commit;
9. push;
10. esperar workflow.

No cambiar arquitectura basándose en una impresión.

---

# 11. YAML NO ES BASH

Un YAML válido no garantiza Bash válido.

Toda modificación a:

```yaml
run: |
```

debe revisarse como Bash real.

Error típico:

```bash
echo "=== Deployment ===
az webapp deploy ...
```

puede producir:

```text
unexpected EOF while looking for matching `"'
```

Preferir:

- `env:`;
- variables simples;
- quoting seguro;
- evitar JSON complejo dentro de shell;
- evitar concatenaciones de comillas;
- no imprimir secretos.

---

# 12. VARIABLES DE TRAZABILIDAD

Preservar:

```text
PROJECT_NAME
DEPLOYMENT_ID
CORRELATION_ID
APP_SERVICE_PLAN_ID
AZURE_RESOURCE_GROUP
SUBSCRIPTION_ID
REPOSITORY
COMMIT_SHA
```

y, cuando corresponda:

```text
HERMES_PROJECT_NAME
HERMES_DEPLOYMENT_ID
HERMES_CORRELATION_ID
HERMES_REPOSITORY
HERMES_COMMIT_SHA
HERMES_APP_SERVICE_PLAN_ID
HERMES_REGION
```

Nunca exponer:

```text
OIDC token
Azure token
GitHub token
client secret
API key
password
```

---

# 13. SHA — IDENTIDAD DEL CHILD

El SHA del Child debe ser real.

Cadena obligatoria:

```text
Factory
 ↓
Child SHA
 ↓
GitHub remoto
 ↓
Checkout
 ↓
Deploy
 ↓
Portal
```

Nunca sustituir child SHA por:

```text
HERMES-ENTERPRISE github.sha
```

Validar remotamente y localmente:

```bash
gh api /repos/OWNER/REPO/git/commits/SHA
git rev-parse HEAD
```

Deben coincidir.

---

# 14. APP SERVICE PLAN

La selección del usuario debe mantenerse:

```text
Portal selection
=
Factory input
=
Control Plane input
=
Azure Web App serverFarmId
=
Portal persisted value
```

Si:

```text
requested_plan != actual_plan
```

resultado:

```text
FAIL
```

No hacer fallback silencioso.
---

# 15. DEPLOY

Tratar el deploy como operación asíncrona:

```text
Provision
 ↓
Package
 ↓
Azure Login
 ↓
Deploy
 ↓
Startup
 ↓
Readiness
```

No declarar PASS solamente porque `az webapp deploy` terminó.

Después verificar:

```text
Web App
State
Hostname
ServerFarmId
Startup
Health
Version
Deployment identity
```

---

# 16. READINESS

Readiness no significa solamente HTTP 200.

Debe verificarse:

```text
HTTP 200
+
respuesta válida
+
identidad Hermes
+
estado saludable
```

Si tarda:

```text
esperar
```

No reiniciar automáticamente.

Registrar:

```text
attempt
timestamp
HTTP
response
duration
```

---

# 17. FUNCTIONAL TESTS

Como mínimo:

```text
/health
/api/version
/
/api/proyecto
/openapi.json
/swagger
404 negativo
identity
```

No confundir endpoint accesible con funcionalidad completa.

---

# 18. EVIDENCE

La evidencia debe derivarse de datos reales.

Debe contener, cuando corresponda:

```text
repository
SHA
verified SHA
Azure Web App
Plan
URL
OIDC
Deploy
Readiness
Functional
User-facing
timestamps
```

No usar fallbacks falsos como:

```text
unknown.azurewebsites.net
```

Si un dato real todavía no existe:

```text
NO_DISPONIBLE
```

con:

```text
motivo
fuente esperada
paso donde debía capturarse
```

---

# 19. PORTAL Y FUENTE DE VERDAD

Arquitectura:

```text
Fuente real
 ↓
Persistencia
 ↓
API
 ↓
UI
```

SSE:

```text
NO es source of truth
```

Debe servir para actualización en tiempo real.

Después de reload:

```text
GET deployment
GET events
SSE
```

deben reconstruir el estado.

---

# 20. PERSISTENCIA

Un deployment terminado debe sobrevivir:

```text
reload
cierre de pestaña
cierre de navegador
reapertura
reinicio del Portal
finalización de GitHub Actions
```

Si desaparece información:

```text
FAIL
```

---

# 21. EVENT STORE

Cada evento debe persistirse antes de emitirse por SSE.

Mantener:

```text
Last-Event-ID
heartbeat
reconnect
deduplication
```

No usar SSE como sustituto de persistencia.

---

# 22. ESTADOS VS RESULTADOS

Separar:

```text
estado:
EN_PROCESO
COMPLETADO
FALLIDO
OMITIDO
```

de:

```text
resultado:
PASS
FAIL
```

No mezclar:

```text
OK
SUCCESS
PASS
COMPLETADO
```

en el mismo campo.

---

# 23. FALSE PASS

No aceptar como E2E:

```text
pytest PASS
HTTP 200
Factory PASS
Azure Web App exists
```

La E2E requiere:

```text
Portal
Factory
GitHub
Child CI
Control Plane
OIDC
Azure
Child App
Readiness
Functional
Evidence
Persistence
Reload
Browser restart
```

---

# 24. PRUEBAS ADVERSARIALES

Mantener:

```text
Factory OK + CP no ejecutado
→ NO PASS

CP OK + readiness FAIL
→ FAIL

Readiness OK + functional FAIL
→ FAIL

Functional OK + evidence FAIL
→ FAIL

Todos OK
→ PASS

SSE desconectado
→ datos permanecen

Portal reload
→ datos permanecen

Browser restart
→ datos permanecen
```
---

# 25. PROYECTOS HUÉRFANOS

No borrar históricos.

No convertir automáticamente:

```text
EN_PROCESO
```

en:

```text
COMPLETADO
```

Clasificar:

```text
ACTIVO
FINALIZADO
HUÉRFANO
SIN_ACTIVIDAD
FALLIDO
```

Los históricos no sustituyen una E2E nueva.

---

# 26. ERRORES DE HERRAMIENTA VS SISTEMA

### Error de herramienta

Ejemplos:

```text
Cline dejó de esperar
terminal abortó
polling repetitivo
```

No implica que el workflow haya fallado.

### Error de sistema

Ejemplos:

```text
GitHub conclusion=failure
Azure ResourceNotFound
shell syntax error
readiness timeout
functional test failure
```

Requiere diagnóstico técnico.

---

# 27. CHECKPOINT OBLIGATORIO

Antes de cada cambio importante:

```text
CHECKPOINT

Repositorio:
Commit:
Branch:

Portal:
URL:
Estado:

Factory:
Run:
Estado:

Child:
Repo:
SHA:
Estado:

Control Plane:
Run:
Estado:

OIDC:
Estado:

Azure:
WebApp:
Plan:
RG:
Estado:

Readiness:
Estado:

Functional:
Estado:

Evidence:
Estado:

Persistencia:
Estado:

Siguiente acción:
```

No continuar si el estado crítico es desconocido.

---

# 28. TRIGGERS DE CI/CD

Antes de asumir que un commit desplegará algo, verificar:

```text
workflow
on.push.paths
on.workflow_dispatch
branch
```

Un cambio en `tools/` no necesariamente dispara Portal CI/CD.

No crear commits artificiales solamente para provocar un workflow.

---

# 29. NO MEZCLAR PIPELINES

Distinguir:

```text
Portal CI/CD
Factory Runner
Child CI
Control Plane
```

No corregir un fallo de Child CI modificando Portal CI/CD.

No corregir un fallo OIDC cambiando Factory.

---

# 30. CUANDO CLINE SE DESALINEE

Si Cline:

- repite el mismo comando;
- olvida OIDC;
- intenta recrear recursos eliminados;
- cambia arquitectura sin necesidad;
- reinicia un deploy que todavía corre;
- mezcla Portal y Control Plane;
- pierde deployment_id;
- pierde correlation_id;
- usa SHA incorrecto;
- crea commits masivos;
- declara PASS prematuramente;

debe volver a:

```text
ESTADO ACTUAL
→ EVIDENCIA
→ SIGUIENTE ESTADO
```

No continuar con una hipótesis.

---

# 31. REGLA PARA DEPLOYMENTS LARGOS

Si el deployment tarda más de 30 segundos:

```text
NO CANCELAR
NO REINICIAR
NO DUPLICAR
```

Primero:

```text
watch
logs
job status
step status
Azure deployment state
```

Solo iniciar una nueva ejecución cuando la anterior:

```text
terminó
```

o existe evidencia de que quedó bloqueada/fallida.

---

# 32. CRITERIO DE MADUREZ

"Crear Proyecto" está maduro cuando:

```text
1. usuario entra al Portal
2. selecciona plan
3. crea proyecto
4. solicitud queda persistida
5. Factory ejecuta
6. repositorio hijo existe
7. SHA real queda registrado
8. Child CI ejecuta
9. Control Plane ejecuta
10. OIDC autentica
11. Azure despliega
12. App Service usa el plan correcto
13. readiness pasa
14. functional tests pasan
15. evidence se genera
16. Portal recibe trazabilidad
17. Portal recarga
18. navegador se cierra
19. Portal vuelve a abrir
20. el mismo deployment recupera toda la información
```

---

# 33. FORMATO FINAL DE REPORTE

Nunca responder únicamente:

```text
PASS
```

Usar:

```text
HERMES ENTERPRISE — CREATE PROJECT

Portal:
Commit:

Factory:
Run:
Estado:

Child:
Repository:
SHA:
CI:

Control Plane:
Run:
Estado:

OIDC:
PASS/FAIL

Azure:
Web App:
Plan:
RG:
Hostname:

Readiness:
PASS/FAIL

Functional:
PASS/FAIL
Pass:
Fail:

Evidence:
PASS/FAIL

Persistence:
PASS/FAIL

Reload:
PASS/FAIL

Browser restart:
PASS/FAIL

Traceability:
PASS/FAIL

Secrets exposed:
YES/NO

Mock production data:
YES/NO

Final:
PASS/FAIL

Fallas:
...

Siguiente acción:
...
```

---

# 34. REGLA MAESTRA

> **No optimizar para terminar comandos. Optimizar para cerrar estados verificables.**

La unidad de trabajo no es:

```text
comando
```

La unidad de trabajo es:

```text
estado + evidencia + persistencia + siguiente transición
```

Cuando una operación tarda:

```text
supervisar
```

Cuando falla:

```text
diagnosticar
```

Cuando pasa:

```text
verificar
```

Cuando se modifica código:

```text
validar + versionar
```

Cuando se despliega:

```text
esperar + comprobar
```

Cuando se declara PASS:

```text
demostrar
```

---

# 35. SEGURIDAD FINAL

Nunca sacrificar trazabilidad para conseguir un PASS.

Nunca sacrificar control de cambios para avanzar rápido.

Nunca sacrificar OIDC estable para solucionar un error de otra capa.

Nunca sacrificar persistencia por SSE.

Nunca sacrificar evidencia por velocidad.

Nunca declarar PASS sin evidencia suficiente.

**Esta skill existe para que Cline mantenga contexto, respete la arquitectura, supervise operaciones largas, preserve control de cambios y lleve "Crear Proyecto" hasta una E2E reproducible.**