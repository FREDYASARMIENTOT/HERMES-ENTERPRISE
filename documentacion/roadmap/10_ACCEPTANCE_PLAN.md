---
title: "Plan de Pruebas de Aceptación"
document: "HERMES Enterprise - Acceptance Test Plan"
date: 2026-07-07
status: DRAFT
version: "1.0"
author: "Equipo QA HERMES Enterprise"
total_tests: 50
categories: 7
cross_references:
  - "01_PROJECT_CHARTER.md"
  - "02_VISION_SCOPE.md"
  - "03_ARCHITECTURE.md"
  - "04_ROADMAP.md"
  - "05_SPRINT_D.md"
  - "07_BACKLOG.md"
  - "08_RISK_REGISTER.md"
---

# Plan de Pruebas de Aceptación - HERMES Enterprise

## Navegación

| Documento Anterior | Índice General | Próximo Documento |
|---|---|---|
| [08_RISK_REGISTER.md](08_RISK_REGISTER.md) | [04_ROADMAP.md](04_ROADMAP.md) | [01_PROJECT_CHARTER.md](01_PROJECT_CHARTER.md) |

---

## 1. Introducción

### 1.1 Propósito

Este documento define el **Plan de Pruebas de Aceptación** completo para el proyecto HERMES Enterprise. Contiene **50 pruebas de aceptación** organizadas en 7 categorías funcionales que cubren todos los componentes principales del sistema.

El objetivo principal es validar que el sistema cumple con los requisitos de negocio y técnicos definidos en el Project Charter y la Visión del Alcance antes de cada release al público.

### 1.2 Alcance del Testing

| Categoría | Tests | Rango | Sprint de Referencia |
|---|---|---|---|
| Sandbox | 10 | AT-001 a AT-010 | Sprint A |
| Supervisor | 10 | AT-011 a AT-020 | Sprint A |
| Developer Context | 8 | AT-021 a AT-028 | Sprint A-B |
| Project Wizard | 7 | AT-029 a AT-035 | Sprint B |
| VS Code Integration | 5 | AT-036 a AT-040 | Sprint B |
| Git Integration | 5 | AT-041 a AT-045 | Sprint B-C |
| Reports & Dashboard | 5 | AT-046 a AT-050 | Sprint C |
| **Total** | **50** | | |

### 1.3 Criterios de Aceptación Global

El proyecto se considera aceptado cuando cumple:

- [ ] Todos los tests AT-001 a AT-050 pasan con resultado "PASS" (100%)
- [ ] No pueden existir defectos abiertos de severidad "Critical" o "Blocker"
- [ ] Performance dentro de los umbrales definidos para cada test
- [ ] Seguridad validada para tests de sandbox y supervisor
- [ ] Documentación actualizada para cada feature testeada
- [ ] Smoke tests pasando en ambiente de producción

### 1.4 Ambiente de Pruebas

#### 1.4.1 Hardware

| Componente | Especificación Mínima | Recomendado |
|---|---|---|
| CPU | 4 cores | 8 cores |
| RAM | 8 GB | 16 GB |
| Disco | 50 GB SSD | 100 GB NVMe |
| Red | 100 Mbps | 1 Gbps |
| GPU | No requerido | Opcional para ML local |

#### 1.4.2 Software

| Componente | Versión | Notas |
|---|---|---|
| OS Primary | Windows 10/11 22H2+ | PowerShell 7.4+ |
| OS Secondary | Ubuntu 22.04 LTS | PowerShell 7.4+ cross-platform |
| Runtime | .NET 8.0 SDK | Requerido |
| Container | Docker Desktop 4.x | Para sandbox |
| IDE | VS Code 1.85+ | Con Extension Pack |
| Git | Git 2.40+, GitHub CLI 2.x | Multi-provider |
| AI Provider | OpenAI GPT-4 / Claude | Keys de test |
| Base de Datos | SQLite 3.x (embedded) | Para state |

#### 1.4.3 Datos de Prueba

| Tipo de Dato | Descripción | Ubicación |
|---|---|---|
| Proyectos Sample | 5 proyectos de muestra (.NET, Node, Python, Java, Go) | `tests/fixtures/projects/` |
| Templates | 10 templates de prueba | `tests/fixtures/templates/` |
| Config Files | Configuraciones válidas e inválidas | `tests/fixtures/configs/` |
| Mock APIs | Stubs de external APIs (AI, Git) | `tests/fixtures/mocks/` |
| Datos de Seguridad | Payloads maliciosos para testing de sandbox | `tests/fixtures/security/` |

### 1.5 Convenciones de Reporting

| Resultado | Código | Descripción |
|---|---|---|
| **PASS** | ✅ | Test ejecutado exitosamente con resultado esperado |
| **FAIL** | ❌ | Test ejecutado con resultado diferente al esperado |
| **BLOCK** | 🚫 | Test no pudo ejecutarse por dependencia no disponible |
| **SKIP** | ⏭️ | Test no aplica en este ambiente |
| **PARTIAL** | ⚠️ | Test ejecutado parcialmente (algunos steps no aplican) |

### 1.6 Severidad de Defectos

| Nivel | Definición | SLA de Resolución |
|---|---|---|
| **Blocker** | Sistema inutilizable, no hay workaround | < 4 horas |
| **Critical** | Feature principal no funciona, sin workaround | < 24 horas |
| **Major** | Feature parcialmente funcional, existe workaround | < 72 horas |
| **Minor** | Problema cosmético o de UX, no afecta funcionalidad | < 1 sprint |
| **Enhancement** | Mejora sugerida, no es un defecto | Backlog |

---

## 2. Categoría: Sandbox Tests (AT-001 a AT-010)

> Esta categoría valida el sistema de sandbox aislado que es la base de seguridad de todo el proyecto. Los tests cubren creación, ejecución segura, aislamiento, límites de recursos, persistencia, y recovery.

### Referencias Cruzadas

- **User Stories:** HERM-0001 (Sandbox System Core), HERM-0002 (Command Validation)
- **Sprint:** A (Semana 1-4)
- **Riesgos Asociados:** R-001 (Fallo del sandbox), R-005 (Complejidad técnica)

---

### AT-001: Creación de Sandbox Aislado

| Campo | Descripción |
|---|---|
| **Test ID** | AT-001 |
| **Nombre** | Creación de Sandbox Aislado |
| **Objetivo** | Verificar que Hermes puede crear un sandbox completamente aislado del sistema host para ejecución segura de comandos |
| **Categoría** | Sandbox / Seguridad |
| **Precondiciones** | Hermes instalado correctamente. Docker Desktop disponible y ejecutándose. Sistema host con recursos suficientes. Usuario con permisos de Docker. |
| **Inputs** | Comando `hermes sandbox create --name test-sandbox --resources cpu=1,memory=512MB` |

**Steps:**
1. Ejecutar `hermes sandbox create --name test-sandbox --resources cpu=1,memory=512MB`
2. Verificar que el comando retorna exitosamente (exit code 0)
3. Verificar que se crea el container/policy de aislamiento
4. Ejecutar `hermes sandbox list` y verificar que "test-sandbox" aparece
5. Verificar que los recursos asignados respetan los límites (CPU: 1 core, RAM: 512MB)
6. Verificar que el sandbox tiene policy de red restrictiva por defecto

| Campo | Descripción |
|---|---|
| **Expected Result** | Sandbox creado exitosamente, visible en listado, con recursos limitados correctamente |
| **Success Criteria** | Sandbox creado en < 10 segundos. Listado lo muestra con estado "running". Recursos < 50% del host. Red restringida por defecto. |
| **Failure Criteria** | Timeout > 30 segundos. Errores en creación. Sandbox no aparece en listado. Recursos ilimitados. Red abierta sin policy. |
| **Metrics** | Tiempo de creación (s), uso de memoria (MB), estado del container (string), policy de red (string) |

---

### AT-002: Ejecución de Comando Seguro dentro del Sandbox

| Campo | Descripción |
|---|---|
| **Test ID** | AT-002 |
| **Nombre** | Ejecución de Comando Seguro |
| **Objetivo** | Verificar que un comando clasificado como seguro se ejecuta correctamente dentro del sandbox y produce el output esperado |
| **Categoría** | Sandbox / Ejecución |
| **Precondiciones** | Sandbox AT-001 creado y activo. Comando de prueba clasificado como "seguro" en la base de políticas. |
| **Inputs** | Comando `hermes sandbox exec --sandbox test-sandbox --cmd "echo hello-world"` |

**Steps:**
1. Identificar un comando de prueba clasificado como seguro (ej: `echo hello-world`)
2. Ejecutar `hermes sandbox exec --sandbox test-sandbox --cmd "echo hello-world"`
3. Capturar stdout del comando
4. Verificar que exit code = 0
5. Verificar que output contiene "hello-world"
6. Verificar que stderr está vacío

| Campo | Descripción |
|---|---|
| **Expected Result** | Comando ejecutado con output correcto, exit code 0, sin errores |
| **Success Criteria** | Output exacto "hello-world" en stdout. Exit code = 0. Ejecución en < 5 segundos. |
| **Failure Criteria** | Timeout > 10s. Exit code ≠ 0. Output incorrecto o vacío. Error de permisos. |
| **Metrics** | Tiempo de ejecución (s), exit code (int), stdout bytes (int), stderr bytes (int) |

---

### AT-003: Bloqueo de Comando Peligroso

| Campo | Descripción |
|---|---|
| **Test ID** | AT-003 |
| **Nombre** | Bloqueo de Comando Peligroso |
| **Objetivo** | Verificar que comandos clasificados como peligrosos son bloqueados inmediatamente sin posibilidad de ejecución |
| **Categoría** | Sandbox / Seguridad |
| **Precondiciones** | Sandbox activo. Política de seguridad configurada con blacklist de comandos peligrosos. |
| **Inputs** | Intento de ejecutar: `rm -rf /`, `format C:`, `drop database` |

**Steps:**
1. Intentar ejecutar `hermes sandbox exec --cmd "rm -rf /"` (comando en blacklist)
2. Verificar que el sistema identifica el comando como riesgoso/crítico
3. Verificar que se bloquea la ejecución inmediatamente (no pasa al sandbox)
4. Verificar que aparece mensaje de error claro y descriptivo
5. Verificar que se genera una entrada en el audit log
6. Repetir con otros comandos peligrosos: `format C:`, `:(){ :\|:& };:` (fork bomb)
7. Verificar que TODOS los comandos peligrosos son bloqueados consistentemente

| Campo | Descripción |
|---|---|
| **Expected Result** | Todos los comandos peligrosos bloqueados sin excepción. Mensajes de alerta claro. Auditoría completa. |
| **Success Criteria** | Bloqueo en < 2 segundos. 100% de comandos peligrosos bloqueados. Mensaje claro con razón del bloqueo. Entrada en audit log. |
| **Failure Criteria** | Cualquier comando peligroso se ejecuta (parcial o completamente). No aparece en audit log. Sin mensaje de error. Bloqueo > 5s. |
| **Metrics** | Tiempo de detección (ms), severidad asignada (string), comando bloqueado (bool), log entry ID (string) |

---

### AT-004: Aislamiento de Red del Sandbox

| Campo | Descripción |
|---|---|
| **Test ID** | AT-004 |
| **Nombre** | Aislamiento de Red del Sandbox |
| **Objetivo** | Verificar que el sandbox no tiene acceso a red sin permisos explícitos, y que el acceso controlado funciona correctamente |
| **Categoría** | Sandbox / Seguridad / Red |
| **Precondiciones** | Sandbox activo SIN network policy configurada. Herramienta de testing de red disponible. |
| **Inputs** | (1) `curl http://example.com` sin permisos. (2) `curl http://example.com` con permiso explícito. |

**Steps:**
1. En sandbox sin permisos de red, intentar: `curl -s http://example.com`
2. Verificar que la conexión es denegada (timeout o connection refused)
3. Verificar que mensaje indica que red está restringida
4. Configurar permiso de red explícito: `hermes sandbox network allow --sandbox test-sandbox --host example.com`
5. Reintentar: `curl -s http://example.com`
6. Verificar que ahora la conexión es exitosa
7. Verificar que sigue bloqueado para hosts no permitidos: `curl -s http://malicious.example.com`

| Campo | Descripción |
|---|---|
| **Expected Result** | Red bloqueada por defecto, permite conexiones solo con policy explícita, sigue bloqueando hosts no autorizados |
| **Success Criteria** | 100% bloqueo sin permisos. Conectividad 100% con policy. Bloqueo para hosts no autorizados. |
| **Failure Criteria** | Conexión exitosa sin permisos. Conexión fallida con permisos. Posibilidad de conectarse a cualquier host. DNS leaks. |
| **Metrics** | Porcentaje bloqueo sin permisos (%), latencia de bloqueo (ms), throughput con policy (KB/s), hosts bloqueados (count) |

---

### AT-005: Límites de Recursos del Sandbox

| Campo | Descripción |
|---|---|
| **Test ID** | AT-005 |
| **Nombre** | Límites de Recursos del Sandbox |
| **Objetivo** | Verificar que el sandbox respeta estrictamente los límites de CPU y memoria asignados |
| **Categoría** | Sandbox / Recursos |
| **Precondiciones** | Sandbox creado con límites estrictos: CPU: 1 core, RAM: 512MB. Script de stress disponible. |
| **Inputs** | Script que intenta consumir 1GB RAM y 4 cores CPU |

**Steps:**
1. Verificar métricas iniciales del sandbox: `hermes sandbox metrics --sandbox test-sandbox`
2. Ejecutar script de stress de memoria dentro del sandbox (intenta asignar 1GB)
3. Monitorear uso de recursos en tiempo real: `hermes sandbox metrics --watch`
4. Verificar que memory usage nunca excede 512MB + 10% tolerancia
5. Verificar que el proceso recibe OOM kill cuando excede el límite
6. Ejecutar script de stress de CPU (múltiples threads)
7. Verificar que CPU usage no excede 100% (1 core) del host

| Campo | Descripción |
|---|---|
| **Expected Result** | Recursos limitados estrictamente. Process terminado vía OOM kill si intenta exceder. CPU capped al límite. |
| **Success Criteria** | Memory usage nunca excede 512MB + 10% (563MB). OOM kill en < 5 segundos después de exceder. CPU capped a 1 core. |
| **Failure Criteria** | Uso de memoria sin límite que afecta al host. OOM kill no funciona. CPU sin límite. Cgroup no se respeta. |
| **Metrics** | Peak memory (MB), CPU usage promedio (%), tiempo de OOM kill (ms), impacto en host (bool: true/false) |

---

### AT-006: Persistencia de Estado del Sandbox

| Campo | Descripción |
|---|---|
| **Test ID** | AT-006 |
| **Nombre** | Persistencia de Estado del Sandbox |
| **Objetivo** | Verificar que el estado del sandbox persiste correctamente entre ciclos de stop/start |
| **Categoría** | Sandbox / Persistencia |
| **Precondiciones** | Sandbox activo con volumen persistente configurado en `/data`. |
| **Inputs** | Archivos de prueba creados dentro del sandbox, contenido verificable por checksum. |

**Steps:**
1. Crear archivo de prueba: `echo "test-content-$(date)" > /data/test.txt`
2. Registrar checksum del archivo: `sha256sum /data/test.txt`
3. Crear subdirectorio con múltiples archivos: `mkdir -p /data/subdir && echo "nested" > /data/subdir/nested.txt`
4. Detener elsandbox: `hermes sandbox stop --name test-sandbox`
5. Verificar que el sandbox está en estado "stopped"
6. Reiniciar el sandbox: `hermes sandbox start --name test-sandbox`
7. Verificar que `/data/test.txt` persiste con contenido idéntico
8. Verificar checksum idéntico al original
9. Verificar que `/data/subdir/nested.txt` persiste

| Campo | Descripción |
|---|---|
| **Expected Result** | Todos los archivos persisten entre ciclos start/stop con integridad intacta |
| **Success Criteria** | Archivos presentes post-restart. Contenido idéntico. Checksum verificado. Subdirectorios preservados. |
| **Failure Criteria** | Archivos desaparecen. Contenido corrupto. Checksum diferente. Subdirectorios perdidos. |
| **Metrics** | Tiempo de stop (s), tiempo de start (s), integridad de archivo (bool), # archivos preservados (int) |

---

### AT-007: Múltiples Sandboxes Simultáneos

| Campo | Descripción |
|---|---|
| **Test ID** | AT-007 |
| **Nombre** | Múltiples Sandboxes Simultáneos |
| **Objetivo** | Verificar que pueden coexistir múltiples sandboxes activas sin interferencia entre ellas |
| **Categoría** | Sandbox / Multi-tenancy |
| **Precondiciones** | Sistema con recursos suficientes (8GB+ RAM, 4+ cores). Docker con capacidad para múltiples containers. |
| **Inputs** | Creación de 3 sandboxes independientes con diferentes cargas de trabajo. |

**Steps:**
1. Crear sandbox A: `hermes sandbox create --name A --resources cpu=0.5,memory=256MB`
2. Crear sandbox B: `hermes sandbox create --name B --resources cpu=0.5,memory=256MB`
3. Crear sandbox C: `hermes sandbox create --name C --resources cpu=0.5,memory=256MB`
4. Verificar que todas aparecen en `hermes sandbox list` con estado "running"
5. Ejecutar comando distinto en cada sandbox: A→`echo "A"`, B→`echo "B"`, C→`echo "C"`
6. Verificar que cada output es correcto para su sandbox
7. Crear archivo `/tmp/data` en A con contenido "sandbox-A-data"
8. Verificar que NO existe en B ni en C
9. Detener solo sandbox B y verificar que A y C siguen funcionando

| Campo | Descripción |
|---|---|
| **Expected Result** | 3 sandboxes activas funcionando en paralelo, completamente aisladas, sin interferencia |
| **Success Criteria** | 3 sandboxes running. Comandos correctos por sandbox. No data bleeding. Independencia de lifecycle. |
| **Failure Criteria** | Alguna sandbox falla al crear. Comandos de A afectan B o C. Datos compartidos. Detener B afecta A/C. |
| **Metrics** | Memoria total usada (MB), tiempo total de setup (s), aislamiento verificado (pass/fail), uptime por sandbox (%) |

---

### AT-008: Limpieza de Sandbox

| Campo | Descripción |
|---|---|
| **Test ID** | AT-008 |
| **Nombre** | Limpieza Completa de Sandbox |
| **Objetivo** | Verificar que al destruir un sandbox se liberan completamente todos los recursos del sistema |
| **Categoría** | Sandbox / Lifecycle |
| **Precondiciones** | Sandbox existente con archivos, procesos y network rules configurados. |
| **Inputs** | Comando `hermes sandbox destroy --name test-sandbox --force` |

**Steps:**
1. Crear archivos y procesos activos en el sandbox
2. Configurar reglas de red custom
3. Registrar recursos del host ANTES de destroy (procesos, puertos, memoria, archivos Docker)
4. Ejecutar `hermes sandbox destroy --name test-sandbox --force`
5. Verificar que el container desaparece: `docker ps -a | grep test-sandbox` (0 resultados)
6. Verificar que procesos asociados terminan: `ps aux | grep test-sandbox` (0 resultados)
7. Verificar que puertos usados se liberan: `netstat -an | grep <puerto>`
8. Verificar que volúmenes de Docker se limpian (si `--purge-volumes`)
9. Comparar recursos del host POST destroy vs ANTES

| Campo | Descripción |
|---|---|
| **Expected Result** | Sandbox completamente destruido, 0 procesos remanentes, 0 puertos ocupados, memoria liberada |
| **Success Criteria** | 0 procesos asociados. 0 archivos Docker remanentes. Puertos liberados. Memoria del host al nivel pre-sandbox. |
| **Failure Criteria** | Procesos zombie. Archivos remanentes. Puertos ocupados. Memory leak detectable. |
| **Metrics** | Tiempo de destroy (s), procesos restantes (int), puertos ocupados (int), MB liberados (int) |

---

### AT-009: Sandbox en Modo ReadOnly

| Campo | Descripción |
|---|---|
| **Test ID** | AT-009 |
| **Nombre** | Sandbox en Modo ReadOnly |
| **Objetivo** | Verificar que el sandbox puede operar en modo solo-lectura bloqueando cualquier modificación |
| **Categoría** | Sandbox / Seguridad |
| **Precondiciones** | Sandbox creado con `--mode readonly`. Archivos preexistentes accesibles. |
| **Inputs** | Intentos de escritura en filesystem del sandbox. |

**Steps:**
1. Crear sandbox con `hermes sandbox create --name readonly-sb --mode readonly`
2. Verificar que lectura de archivos preexistentes funciona: `cat /etc/hostname`
3. Intentar crear archivo nuevo: `touch /tmp/test.txt`
4. Verificar que operación es bloqueada con error "read-only filesystem"
5. Intentar modificar archivo existente: `echo "x" > /etc/hostname`
6. Verificar que también se bloquea
7. Intentar eliminar archivo: `rm /etc/hostname`
8. Verificar que se bloquea
9. Verificar que mensajes de error son claros y consistentes

| Campo | Descripción |
|---|---|
| **Expected Result** | Modo readonly: 100% escrituras bloqueadas, 100% lecturas permitidas, mensajes claros |
| **Success Criteria** | Escritura bloqueada en todos los casos. Lectura funciona siempre. Error messages descriptivos. |
| **Failure Criteria** | Escritura exitosa en cualquier path. Lectura bloqueada. Error messages confusos o ausentes. |
| **Metrics** | % operaciones de escritura bloqueadas (100%), % lecturas exitosas (100%), claridad del error (survey 1-5) |

---

### AT-010: Sandbox Recovery Post-Fallo

| Campo | Descripción |
|---|---|
| **Test ID** | AT-010 |
| **Nombre** | Sandbox Recovery Post-Fallo |
| **Objetivo** | Verificar que el sandbox puede recuperarse de fallos inesperados del container sin pérdida de datos persistentes |
| **Categoría** | Sandbox / Recovery |
| **Precondiciones** | Sandbox activo con datos persistentes. Monitor de health habilitado. |
| **Inputs** | Simulación de crash del container con `docker kill -s SIGKILL` |

**Steps:**
1. Iniciar sandbox con tarea larga en background
2. Crear datos persistentes en `/data/recovery-test.txt`
3. Forzar crash del container: `docker kill -s SIGKILL <container-id>`
4. Esperar detección de fallo (monitoreo del supervisor)
5. Verificar que el supervisor detecta el estado "crashed"
6. Ejecutar `hermes sandbox recover --name test-sandbox`
7. Verificar que el sandbox se reinicia correctamente
8. Verificar que `/data/recovery-test.txt` persiste con contenido intacto
9. Verificar que el supervisor marca el sandbox como "healthy" nuevamente

| Campo | Descripción |
|---|---|
| **Expected Result** | Fallo detectado automáticamente, sandbox recuperado sin intervención manual, datos persistentes intactos |
| **Success Criteria** | Recovery < 30 segundos. Datos persistentes sin pérdida. Supervisor marca healthy. Sin intervención manual. |
| **Failure Criteria** | Fallo no detectado. Recovery requiere intervención manual. Datos persistentes se pierden. Corruption de estado. |
| **Metrics** | Tiempo de detección (s), tiempo de recovery (s), integridad de datos (%), intervención manual requerida (bool) |

---

## Nota de Ejecución: Categoría Sandbox

**Ambiente requerido:** Docker Desktop ejecutándose, 8GB+ RAM disponible, permisos de administrador para cgroups.

**Orden de ejecución recomendado:** AT-001 primero (setup), luego AT-002 a AT-010 en cualquier orden.

**Dependencias entre tests:**
- AT-001 es prerequisito de AT-002 a AT-010
- AT-006 requiere volumen persistente configurado
- AT-007 requiere recursos suficientes para 3 sandboxes

---

## 3. Categoría: Supervisor Tests (AT-011 a AT-020)

> Esta categoría valida el proceso supervisor que actúa como guardián del sistema, controlando el flujo de ejecución, aplicando policies y proporcionando monitoring en tiempo real. Es el segundo pilar de seguridad del proyecto.

### Referencias Cruzadas

- **User Stories:** HERM-0003 (Supervisor Process), HERM-0004 (Safe Execution Pipeline)
- **Sprint:** A (Semana 1-4)
- **Riesgos Asociados:** R-001 (Sandbox), R-006 (Sobrecarga D)

---

### AT-011: Supervisor Proceso Activo

| Campo | Descripción |
|---|---|
| **Test ID** | AT-011 |
| **Nombre** | Supervisor Proceso Activo |
| **Objetivo** | Verificar que el proceso supervisor se inicia correctamente y monitorea continuamente el sistema |
| **Categoría** | Supervisor / Lifecycle |
| **Precondiciones** | Hermes instalado y configurado. No hay instancia previa del supervisor corriendo. |
| **Inputs** | Comando `hermes supervisor start` |

**Steps:**
1. Verificar que no hay supervisor corriendo: `hermes supervisor status` → debe mostrar "stopped"
2. Iniciar supervisor: `hermes supervisor start`
3. Verificar que comando retorna con éxito (exit code 0)
4. Verificar status: `hermes supervisor status` → debe mostrar "running" + PID
5. Verificar que el proceso está activo en el sistema: `ps aux | grep hermes-supervisor`
6. Esperar 30 segundos y verificar heartbeat en logs: `hermes supervisor logs --last 30s`
7. Verificar que el supervisor está monitoreando recursos del sistema (CPU, RAM)
8. Verificar que el dashboard del supervisor responde: `curl http://localhost:8081/health`

| Campo | Descripción |
|---|---|
| **Expected Result** | Supervisor activo, monitoreando continuamente, heartbeats visibles, health endpoint responde |
| **Success Criteria** | Proceso running con PID. Heartbeat cada ≤ 5 segundos. Métricas de sistema visibles. Health endpoint retorna 200. |
| **Failure Criteria** | Supervisor no inicia. No hay heartbeat en 30s. Health endpoint no responde. Proceso muere sin razón. |
| **Metrics** | Uptime (%), heartbeat interval promedio (ms), CPU del supervisor (%), health response time (ms) |

---

### AT-012: Supervisión de Recursos del Sistema

| Campo | Descripción |
|---|---|
| **Test ID** | AT-012 |
| **Nombre** | Supervisión de Recursos del Sistema |
| **Objetivo** | Verificar que el supervisor monitorea con precisión CPU, RAM y disco del sistema |
| **Categoría** | Supervisor / Monitoring |
| **Precondiciones** | Supervisor activo (AT-011 pasado). Herramienta de stress disponible para validar métricas. |
| **Inputs** | Carga artificial de recursos mediante herramientas de stress. |

**Steps:**
1. Capturar métricas base del sistema sin carga: `hermes supervisor metrics`
2. Comparar con métricas del OS: `top`, `free -m`, `df -h`
3. Verificar que diferencia es ≤ 5% para todas las métricas
4. Generar carga de CPU: iniciar proceso `stress --cpu 4 --timeout 30s`
5. Verificar que el supervisor detecta el aumento de CPU en < 3 segundos
6. Verificar que el valor reportado corresponde al uso real (±10%)
7. Liberar carga de CPU (esperar a que stress termine)
8. Verificar que métricas regresan al nivel base en < 10 segundos
9. Verificar que datos históricos se grafican correctamente en dashboard

| Campo | Descripción |
|---|---|
| **Expected Result** | Métricas precisas en tiempo real con < 5% de diferencia vs. sistema operativo |
| **Success Criteria** | Accuracy de CPU ≤ 5%, accuracy de RAM ≤ 5%, actualización cada < 3s, gráficos funcionales |
| **Failure Criteria** | Diferencia > 10% vs. métricas reales. No detecta aumento de carga. Update interval > 10s. |
| **Metrics** | CPU accuracy (%), RAM accuracy (%), disk accuracy (%), update latency promedio (s) |

---

### AT-013: Approval Gate para Comandos Sensibles

| Campo | Descripción |
|---|---|
| **Test ID** | AT-013 |
| **Nombre** | Approval Gate para Comandos Sensibles |
| **Objetivo** | Verificar que comandos clasificados como sensibles requieren aprobación explícita antes de ejecutarse |
| **Categoría** | Supervisor / Policies |
| **Precondiciones** | Supervisor activo. Policy de approval configurada para comandos de clasificación "sensible". |
| **Inputs** | Comando `git push --force` (clasificado como sensible) |

**Steps:**
1. Configurar commando `git push --force` como "sensible" en las policies
2. Intentar ejecutar: `hermes run git push --force`
3. Verificar que la ejecución se pausa inmediatamente
4. Verificar que aparece solicitud de aprobación con detalles del comando
5. Verificar que se puede aprobar desde UI web: `http://localhost:8081/approvals`
6. Aprobar la acción desde la UI
7. Verificar que la ejecución procede correctamente
8. Verificar log de la aprobación (quién aprobó, cuándo, por qué)
9. Probar flujo inverso: rechazar la aprobación y verificar que NO se ejecuta

| Campo | Descripción |
|---|---|
| **Expected Result** | Comando pausado sin approval, solicitud visible, ejecución solo tras aprobación explícita |
| **Success Criteria** | Bloqueo 100% sin approval. Ejecución 100% post-approval. Log completo de la aprobación. Rechazo bloquea. |
| **Failure Criteria** | Comando se ejecuta sin approval. Solicitud no aparece. Comando falla tras approval. No hay log. |
| **Metrics** | Tiempo de bloqueo (s), tiempo de approval (s), log entries generados (int), aprobación/rechazo (bool) |

---

### AT-014: Auto-Reject de Comandos Prohibidos

| Campo | Descripción |
|---|---|
| **Test ID** | AT-014 |
| **Nombre** | Auto-Reject de Comandos Prohibidos |
| **Objetivo** | Verificar que comandos en la blacklist son rechazados automáticamente sin ofrecer oportunidad de aprobación |
| **Categoría** | Supervisor / Seguridad |
| **Precondiciones** | Supervisor activo. Blacklist configurada con comandos prohibidos (`rm -rf /`, `DROP TABLE`, `format C:`). |
| **Inputs** | Intento de ejecutar comando en blacklist |

**Steps:**
1. Verificar que lista negra contiene comandos objetivo: `hermes policy blacklist list`
2. Intentar ejecutar `hermes run "rm -rf /"`
3. Verificar que se rechaza INMEDIATAMENTE (sin approval gate intermedio)
4. Verificar que NO aparece opción de aprobar
5. Verificar notificación al usuario con razón específica
6. Verificar entrada en audit log con severidad "CRITICAL"
7. Repetir con otros comandos de blacklist
8. Verificar consistencia: TODOS los comandos en blacklist se manejan igual
9. Verificar que el sistema sugiere alternativas seguras cuando es aplicable

| Campo | Descripción |
|---|---|
| **Expected Result** | Rechazo inmediato sin approval, notificación clara, audit log completo |
| **Success Criteria** | Rechazo en < 1 segundo. 0 approval requests generados. Audit log con todos los datos. 100% de comandos en blacklist consistentes. |
| **Failure Criteria** | Se solicita approval para comandos prohibidos. Comando se ejecuta. No hay audit entry. Tiempo > 2s. |
| **Metrics** | Tiempo de rechazo (ms), approval requests (debe ser 0), audit entries generados (int), consistencia (bool) |

---

### AT-015: Detección de Comportamiento Anómalo

| Campo | Descripción |
|---|---|
| **Test ID** | AT-015 |
| **Nombre** | Detección de Comportamiento Anómalo |
| **Objetivo** | Verificar que el supervisor detecta patrones inusuales de comportamiento mediante análisis de baseline |
| **Categoría** | Supervisor / Anomaly Detection |
| **Precondiciones** | Supervisor activo. Baseline de comportamiento definido con ≥7 días de operaciones normales. |
| **Inputs** | Secuencias normales vs. anómalas de comandos. |

**Steps:**
1. Ejecutar secuencia normal: 10 comandos típicos de uso diario
2. Verificar que NO se generan alertas (baseline normal)
3. Ejecutar secuencia anómala: 100 requests similares en 5 segundos (rate spike)
4. Verificar que se genera alerta de "anómalo"
5. Verificar nivel de severidad correcto (Warning o Critical según desviación)
6. Verificar que se notifica al admin
7. Ejecutar otra secuencia anómala: acceso a 50 archivos sensibles consecutivos
8. Verificar detección del patrón
9. Ejecutar secuencia edge case: comportamiento nuevo pero legítimo
10. Calcular tasa de falsos positivos

| Campo | Descripción |
|---|---|
| **Expected Result** | Sin alertas en comportamiento normal, alerta generada en anómalo, tasa de falsos positivos baja |
| **Success Criteria** | < 5% false positives en secuencia normal. > 95% detección rate en anómalos. Alerta en < 3 segundos. |
| **Failure Criteria** | Alertas generadas en secuencia normal. No se detecta secuencia claramente anómala. Alerta tarda > 10s. |
| **Metrics** | True positive rate (%), false positive rate (%), latencia de detección (s), severidad asignada |

---

### AT-016: Kill Switch de Emergencia

| Campo | Descripción |
|---|---|
| **Test ID** | AT-016 |
| **Nombre** | Kill Switch de Emergencia |
| **Objetivo** | Verificar que existe un mecanismo de parada total inmediata que detiene todas las operaciones |
| **Categoría** | Supervisor / Emergency |
| **Precondiciones** | Supervisor activo con 5+ tareas paralelas en ejecución. |
| **Inputs** | Comando `hermes supervisor emergency-stop` |

**Steps:**
1. Iniciar 5 tareas paralelas de larga duración en Hermes
2. Verificar que todas están en estado "running": `hermes tasks list`
3. Medir tiempo antes de ejecutar emergency stop
4. Ejecutar `hermes supervisor emergency-stop --confirm`
5. Iniciar cronómetro
6. Verificar que todas las tareas se detienen
7. Verificar que supervisor muestra estado "EMERGENCY STOP"
8. Verificar que no quedan procesos hijos activos
9. Verificar que se genera log completo de la acción
10. Medir tiempo total desde comando hasta confirmación

| Campo | Descripción |
|---|---|
| **Expected Result** | 100% de tareas detenidas en < 5 segundos, 0 procesos remanentes |
| **Success Criteria** | Todas las tareas en estado "stopped" en < 5s. 0 procesos hijos. 0 conexiones pendientes. Log completo. |
| **Failure Criteria** | Tareas continúan > 10s. Procesos zombie. Conexiones abiertas. Comando falla. |
| **Metrics** | Tiempo total de parada (s), # tareas detenidas, # procesos remanentes, integridad de datos (%) |

---

### AT-017: Logging del Supervisor

| Campo | Descripción |
|---|---|
| **Test ID** | AT-017 |
| **Nombre** | Logging Completo e Inmutable del Supervisor |
| **Objetivo** | Verificar que todas las acciones del supervisor se loguean correctamente y los logs son inmutables |
| **Categoría** | Supervisor / Audit |
| **Precondiciones** | Supervisor activo. Sistema de logging configurado. |
| **Inputs** | Ejecución de 10+ comandos variados (seguros, sensibles, prohibidos) durante sesión. |

**Steps:**
1. Ejecutar secuencia de 10 comandos variados
2. Verificar que cada acción genera exactamente un log entry
3. Verificar formato: `{timestamp, user, command, classification, result, sandbox_id, duration_ms}`
4. Verificar validación de schema del log
5. Intentar modificar el archivo de log manualmente
6. Verificar que el sistema detecta la modificación (hash check)
7. Verificar que se puede exportar: `hermes supervisor logs export --format json`
8. Verificar export a CSV: `hermes supervisor logs export --format csv`
9. Verificar que logs incluyen información de correlación (trace ID)
10. Verificar retención configurada: logs > 90 días en archive

| Campo | Descripción |
|---|---|
| **Expected Result** | 100% acciones logueadas, formato consistente, inmutabilidad garantizada, exportable |
| **Success Criteria** | 0 acciones sin log. Schema válido 100%. Detección de modificaciones < 5s. Export funcional. |
| **Failure Criteria** | Acciones sin log. Formato inconsistente. Logs alterables sin detección. Export falla. |
| **Metrics** | % acciones logueadas, integridad por hash (bool), tamaño total (MB), tiempo de export (s) |

---

### AT-018: Policies Configurables del Supervisor

| Campo | Descripción |
|---|---|
| **Test ID** | AT-018 |
| **Nombre** | Policies Configurables y Aplicables Dinámicamente |
| **Objetivo** | Verificar que las policies del supervisor pueden configurarse, validarse y aplicarse sin reinicio |
| **Categoría** | Supervisor / Configuration |
| **Precondiciones** | Supervisor activo. Archivo YAML de policies válido preparado. |
| **Inputs** | Archivo `policies.yaml` con nueva configuración. |

**Steps:**
1. Generar archivo policies.yaml con nueva blacklist y thresholds
2. Validar formato: `hermes supervisor policy validate --file policies.yaml`
3. Cargar policy: `hermes supervisor policy load --file policies.yaml`
4. Verificar que se aplica inmediatamente (sin restart)
5. Ejecutar comando que era permitido antes y ahora está en blacklist
6. Verificar que se bloquea con la nueva policy
7. Modificar blacklist en caliente (agregar nuevo comando)
8. Verificar que el cambio toma efecto en < 5 segundos
9. Intentar cargar policy con formato inválido
10. Verificar que se rechaza y policy anterior se mantiene

| Campo | Descripción |
|---|---|
| **Expected Result** | Policies dinámicas sin restart, validación de formato, rollback automático en error |
| **Success Criteria** | Aplicación < 5s sin restart. Validación rechaza formatos inválidos. Policy anterior intacta si nuevo archivo falla. |
| **Failure Criteria** | Requiere restart. Policy inválida se acepta. Policy anterior se pierde en error. Timeout > 30s. |
| **Metrics** | Tiempo de aplicación (s), validación de formato (pass/fail), % comandos afectados, rollback success (bool) |

---

### AT-019: Notificaciones del Supervisor

| Campo | Descripción |
|---|---|
| **Test ID** | AT-019 |
| **Nombre** | Notificaciones Multi-Canal del Supervisor |
| **Objetivo** | Verificar que el supervisor envía notificaciones configurables a través de múltiples canales |
| **Categoría** | Supervisor / Notifications |
| **Precondiciones** | Supervisor activo. Canales de notificación configurados (email, webhook). |
| **Inputs** | Generación de eventos de diferentes severidades. |

**Steps:**
1. Configurar canal de email: `hermes supervisor notify config --channel email --to admin@example.com`
2. Configurar canal de Slack webhook: `hermes supervisor notify config --channel slack --webhook https://hooks.slack.com/...`
3. Generar evento severidad "Info" (ej: tarea completada)
4. Verificar que se envía notificación por ambos canales
5. Generar evento severidad "Warning" (ej: threshold alcanzado)
6. Verificar prioridad y formato de notificación
7. Generar evento severidad "Critical" (ej: comando prohibido)
8. Verificar que notificación critical llega < 30 segundos
9. Verificar que el mensaje contiene toda la información relevante
10. Probar canal no disponible (simular error) y verificar retry

| Campo | Descripción |
|---|---|
| **Expected Result** | Notificaciones entregadas por todos los canales, formato correcto, priorización por severidad |
| **Success Criteria** | 100% entrega en < 30s. Formato consistente. Priorización correcta (Critical antes que Info). Retry en error. |
| **Failure Criteria** | Notificación no llega > 60s. Formato incorrecto. Critical no prioritario. Sin retry en errores. |
| **Metrics** | Tiempo de entrega promedio (s), % entrega exitosa por canal, integridad del mensaje (bool), retries (int) |

---

### AT-020: Supervisor Recovery Post-Crash

| Campo | Descripción |
|---|---|
| **Test ID** | AT-020 |
| **Nombre** | Auto-Recovery del Supervisor Post-Crash |
| **Objetivo** | Verificar que el supervisor se recupera automáticamente cuando su processo principal es terminado abruptamente |
| **Categoría** | Supervisor / Resilience |
| **Precondiciones** | Supervisor activo. Watchdog configurado. Tareas en ejecución. |
| **Inputs** | `kill -9 <supervisor-PID>` para simular crash abrupto |

**Steps:**
1. Iniciar tareas en Hermes y dejar supervisor monitoreando
2. Registrar PID actual: `hermes supervisor status | grep PID`
3. Forzar crash: `kill -9 <PID>` (no graceful)
4. Iniciar cronómetro
5. Esperar que el watchdog detecte la ausencia
6. Verificar que nuevo proceso del supervisor se inicia automáticamente
7. Verificar que nuevo PID ≠ antiguo PID
8. Verificar que tareas pendientes se recuperan correctamente
9. Verificar integridad del estado (no hay data corruption)
10. Verificar que monitoring continúa sin gaps > 30s

| Campo | Descripción |
|---|---|
| **Expected Result** | Supervisor auto-reinicia en < 30s, tareas se recuperan, sin pérdida ni corrupción |
| **Success Criteria** | Recovery < 30s. Nuevo PID asignado. Tareas restauradas sin pérdida. Estado íntegro. Monitoreo continuo. |
| **Failure Criteria** | Supervisor no reinicia. Tareas perdidas. Corrupción de estado. Gap de monitoreo > 60s. |
| **Metrics** | Tiempo de recovery (s), tasks recuperadas (int), tasks perdidas (int), integridad de estado (%), monitoring gap (s) |

---

## Nota de Ejecución: Categoría Supervisor

**Ambiente requerido:** supervisor activo, al menos 8GB RAM, acceso a sistema de notificaciones (email/webhook).

**Orden de ejecución recomendado:** AT-011 → AT-012 → (AT-013, AT-014, AT-015 en paralelo) → AT-016 → AT-017 → AT-018 → AT-019 → AT-020

**Consideraciones especiales:**
- AT-013 y AT-014 requieren configuración de políticas previa
- AT-015 requiere baseline de 7+ días de datos históricos para ser significativo
- AT-016 es destructivo - ejecutar en ambiente de staging

---

## 4. Categoría: Developer Context Tests (AT-021 a AT-028)

> Esta categoría valida la capacidad de Hermes para entender y manejar el contexto del proyecto actual, detectando automáticamente tecnologías, dependencias, patrones arquitectónicos y configuraciones.

### Referencias Cruzadas

- **User Stories:** HERM-0005 (Context Manager), HERM-0006 (Session Persistence)
- **Sprint:** A-B (Semana 1-10)
- **Riesgos Asociados:** R-002 (Performance), R-011 (Expertise DDD)

---

### AT-021: Detección Automática de Proyecto

| Campo | Descripción |
|---|---|
| **Test ID** | AT-021 |
| **Nombre** | Detección Automática de Tipo de Proyecto |
| **Objetivo** | Verificar que Hermes detecta automáticamente el tipo de proyecto, lenguaje y framework al abrir un directorio |
| **Categoría** | Context / Detection |
| **Precondiciones** | Proyecto existente con estructura reconocible (.csproj para .NET, package.json para Node, pyproject.toml para Python). |
| **Inputs** | Navegar a directorio del proyecto y ejecutar comando de detección. |

**Steps:**
1. Abrir terminal en directorio de proyecto .NET
2. Ejecutar `hermes context detect`
3. Verificar que detecta lenguaje: "C#" / ".NET"
4. Verificar que detecta framework: ".NET 8.0"
5. Verificar que detecta tipo de proyecto: "Web API" / "Console" / "Library"
6. Verificar que detecta dependencias principales (≥80%)
7. Cambiar a proyecto Node.js y repetir
8. Verificar detección correcta de Node.js, npm/yarn, framework (Express, Next.js, etc.)
9. Cambiar a proyecto Python y repetir
10. Verificar detección de Python versión, pip/poetry, framework (Django, Flask, FastAPI)

| Campo | Descripción |
|---|---|
| **Expected Result** | Proyecto detectado correctamente con metadata completa para cada lenguaje de prueba |
| **Success Criteria** | Lenguaje correcto 100%. Framework correcto 100%. >80% de deps detectadas. Tiempo < 5s por proyecto. |
| **Failure Criteria** | No detecta proyecto. Lenguaje incorrecto. Framework incorrecto. <50% deps detectadas. |
| **Metrics** | Accuracy de detección (%), tiempo de detección (s), completeza de deps (%), # lenguajes soportados |

---

### AT-022: Carga de Configuración del Proyecto

| Campo | Descripción |
|---|---|
| **Test ID** | AT-022 |
| **Nombre** | Carga de Configuración Específica del Proyecto |
| **Objetivo** | Verificar que Hermes carga correctamente la configuración específica de cada proyecto |
| **Categoría** | Context / Configuration |
| **Precondiciones** | Proyecto con archivo `.hermes/config.yaml` definido. |
| **Inputs** | Archivo config.yaml con settings personalizados del proyecto. |

**Steps:**
1. Crear archivo `.hermes/config.yaml` con settings específicos (ej: build-command, test-command, lint-rules)
2. Ejecutar `hermes context load`
3. Verificar que settings se cargan correctamente
4. Verificar que overrides de defaults funcionan
5. Verificar que variables de entorno se resuelven en los valores
6. Verificar que settings inválidos generan warning
7. Probar con proyecto sin config (debe usar defaults)
8. Probar con proyecto con config parcial (default + override)
9. Verificar orden de precedencia: cli-args > env-vars > config.yaml > defaults
10. Verificar que cambios en config se detectan sin restart

| Campo | Descripción |
|---|---|
| **Expected Result** | Configuración cargada correctamente con precedencia clara y validación de formato |
| **Success Criteria** | 100% settings cargadas. Precedencia correcta. Validación funciona. Hot-reload < 2s. |
| **Failure Criteria** | Settings ignoradas. Overrides no aplican. Formats inválidos aceptados. Precedencia incorrecta. |
| **Metrics** | % settings cargadas, tiempo de carga (ms), errores de validación (count), precedencia respectada (bool) |

---

### AT-023: Análisis de Dependencias

| Campo | Descripción |
|---|---|
| **Test ID** | AT-023 |
| **Nombre** | Análisis Completo de Dependencias |
| **Objetivo** | Verificar que Hermes analiza correctamente todas las dependencias del proyecto incluyendo vulnerabilidades |
| **Categoría** | Context / Analysis |
| **Precondiciones** | Proyecto con dependencias declaradas. Acceso a base de datos de vulnerabilidades. |
| **Inputs** | Comando `hermes context deps --full-scan` |

**Steps:**
1. Ejecutar análisis básico: `hermes context deps`
2. Verificar lista de dependencias directas con versiones
3. Ejecutar análisis completo: `hermes context deps --full-scan`
4. Verificar detección de dependencias transitivas
5. Verificar detección de vulnerabilidades conocidas (CVE)
6. Verificar que se sugieren versiones actualizadas disponibles
7. Verificar clasificación de severidad de vulnerabilidades
8. Probar con proyecto que tiene vulnerabilidad conocida
9. Verificar que la detecta y muestra advisory
10. Verificar generación de SBOM (Software Bill of Materials)

| Campo | Descripción |
|---|---|
| **Expected Result** | Lista completa de dependencias con metadata de seguridad y sugerencias de actualización |
| **Success Criteria** | >95% deps directas detectadas. >80% transitivas. Vulnerabilidades conocidas reportadas. SBOM válido. |
| **Failure Criteria** | <80% deps directas. Vulnerabilidades no detectadas. SBOM no generado. Datos outdated. |
| **Metrics** | % deps directas detectadas, % deps transitivas, vulnerabilidades encontradas (count), tiempo (s) |

---

### AT-024: Contexto Multi-Proyecto (Workspace)

| Campo | Descripción |
|---|---|
| **Test ID** | AT-024 |
| **Nombre** | Gestión de Contexto Multi-Proyecto |
| **Objetivo** | Verificar que Hermes maneja múltiples proyectos simultáneamente sin contaminación de contexto |
| **Categoría** | Context / Multi-tenancy |
| **Precondiciones** | Workspace con 3+ proyectos de diferentes tecnologías (.NET, Node.js, Python). |
| **Inputs** | Comandos `hermes context switch` entre proyectos. |

**Steps:**
1. Listar proyectos disponibles: `hermes context list`
2. Switch al proyecto A (.NET): `hermes context switch --project dotnet-app`
3. Verificar contexto correcto (lenguaje, build command, test command)
4. Ejecutar comando en proyecto A y capturar resultado
5. Switch al proyecto B (Node.js): `hermes context switch --project node-app`
6. Verificar que contexto cambió completamente
7. Verificar que comando anterior del proyecto A no produce efectos en B
8. Switch al proyecto C (Python): `hermes context switch --project python-app`
9. Verificar que A y B siguen operativos si tienen procesos en background
10. Verificar que no hay data bleed entre contextos (variables, state)

| Campo | Descripción |
|---|---|
| **Expected Result** | Cambio de contexto limpio entre proyectos, sin contaminación entre ellos |
| **Success Criteria** | Switch < 3s. Contexto 100% correcto. 0 data bleed. Proyectos independientes. |
| **Failure Criteria** | Switch lento >5s. Contexto incorrecto. Data de proyecto A aparece en B. Projects se interfieren. |
| **Metrics** | Tiempo de switch (s), accuracy del contexto (bool), memory overhead por proyecto (MB), data bleed check (pass/fail) |

---

### AT-025: Indexación de Código del Proyecto

| Campo | Descripción |
|---|---|
| **Test ID** | AT-025 |
| **Nombre** | Indexación de Código Fuente |
| **Objetivo** | Verificar que Hermes indexa el código fuente del proyecto para búsqueda inteligente rápida |
| **Categoría** | Context / Index |
| **Precondiciones** | Proyecto con ≥500 archivos y ≥50,000 LOC. |
| **Inputs** | Comando `hermes context index` y queries de búsqueda. |

**Steps:**
1. Ejecutar indexación: `hermes context index --full`
2. Verificar barra de progreso visible
3. Verificar que completion message muestra stats (# archivos, # símbolos)
4. Verificar que el index se guarda en `.hermes/index/`
5. Buscar símbolo específico: `hermes context search --symbol "UserService"`
6. Verificar que resultados son relevantes y localización correcta
7. Verificar tiempo de búsqueda < 2 segundos
8. Buscar por texto: `hermes context search --text "authentication"`
9. Verificar resultados relevantes con context lines
10. Verificar que el index se actualiza incrementalmente cuando cambia código

| Campo | Descripción |
|---|---|
| **Expected Result** | Index completo y actualizable, búsquedas rápidas (< 2s) con resultados relevantes |
| **Success Criteria** | Index < 30s para 50K LOC. Búsqueda < 2s. >90% relevancia de resultados. Update incremental funcional. |
| **Failure Criteria** | Index falla o > 5 minutos. Búsqueda > 10s. Resultados irrelevantes. Index no se actualiza. |
| **Metrics** | Tiempo de index (s), tiempo de búsqueda (s), tamaño del index (MB), recall (% relevancia) |

---

### AT-026: Detección de Patrones Arquitectónicos

| Campo | Descripción |
|---|---|
| **Test ID** | AT-026 |
| **Nombre** | Detección Automática de Patrones Arquitectónicos |
| **Objetivo** | Verificar que Hermes identifica patrones arquitectónicos comunes en el código del proyecto |
| **Categoría** | Context / Architecture |
| **Precondiciones** | Proyecto que usa patrones reconocibles (MVC, Repository, CQRS, etc.). |
| **Inputs** | Comando `hermes context analyze-architecture` |

**Steps:**
1. Ejecutar análisis: `hermes context analyze-architecture --deep`
2. Verificar que detecta el patrón principal (ej: MVC si hay Models, Views, Controllers)
3. Verificar detección de capas (Controllers/Services/Repositories)
4. Verificar detección de DI (Dependency Injection)
5. Verificar detección de patterns específicos (Repository, Unit of Work, etc.)
6. Verificar generación de diagrama de arquitectura (C4 o similar)
7. Verificar generación de lista de patrones con confidence score
8. Probar con proyecto microservicios (debe detectar múltiples contextos)
9. Verificar que el diagrama es exportable (PNG, SVG, Mermaid)
10. Verificar consistencia entre detección y realidad del código

| Campo | Descripción |
|---|---|
| **Expected Result** | Patrones detectados correctamente con confidence score y visualización |
| **Success Criteria** | Patrón principal detectado con > 90% confidence. Capas correctas. Diagrama preciso. Export funcional. |
| **Failure Criteria** | No detecta patrones obvios. Confidence < 50% en patrón principal. Diagrama incorrecto. |
| **Metrics** | Patrones detectados (int), confidence promedio (%), tiempo (s), accuracy (survey) |

---

### AT-027: Variables de Entorno del Proyecto

| Campo | Descripción |
|---|---|
| **Test ID** | AT-027 |
| **Nombre** | Gestión de Variables de Entorno por Proyecto |
| **Objetivo** | Verificar que Hermes gestiona variables de entorno de forma segura y específica por proyecto |
| **Categoría** | Context / Environment |
| **Precondiciones** | Proyecto con variables definidas en `.hermes/env`. Secrets en Vault. |
| **Inputs** | Comandos `hermes context env list`, ejecución de comandos con variables. |

**Steps:**
1. Definir variables en `.hermes/env`: `DATABASE_URL=...`, `API_KEY=...`, `ENV=development`
2. Ejecutar `hermes context env list`
3. Verificar que variables aparecen con valores enmascarados para secrets
4. Ejecutar comando dentro del contexto: `hermes context exec -- "echo $DATABASE_URL"`
5. Verificar que variable está disponible
6. Configurar ambiente staging: `hermes context env set --env staging DATABASE_URL="..."`
7. Switch al ambiente staging y verificar valor cambia
8. Verificar que secrets NO aparecen en logs
9. Verificar que variables se cargan desde Vault si están marcadas como secret
10. Verificar que `.hermes/env` está en `.gitignore` automáticamente

| Campo | Descripción |
|---|---|
| **Expected Result** | Variables disponibles, secrets enmascarados, ambientes separados, gitignore automático |
| **Success Criteria** | 100% vars disponibles. 0 secrets en texto plano en output/logs. Ambientes separados. .gitignore actualizado. |
| **Failure Criteria** | Variables no disponibles. Secrets expuestos. Ambientes se mezclan. .env en git. |
| **Metrics** | % vars disponibles, secrets expuestos en output (count), ambientes configurados (int), .gitignore status |

---

### AT-028: Sugerencias Context-Aware

| Campo | Descripción |
|---|---|
| **Test ID** | AT-028 |
| **Nombre** | Sugerencias Inteligentes Basadas en Contexto |
| **Objetivo** | Verificar que Hermes ofrece sugerencias relevantes y específicas al contexto del proyecto |
| **Categoría** | Context / Intelligence |
| **Precondiciones** | Proyecto indexado. Contexto activo. Knowledge base inicial poblada. |
| **Inputs** | Solicitud de sugerencia en contexto específico del proyecto. |

**Steps:**
1. Abrir archivo de servicio en proyecto .NET
2. Ejecutar: `hermes suggest --context current-file`
3. Verificar que la sugerencia es relevante al archivo abierto
4. Verificar que incluye patrones observados en el proyecto
5. Verificar que código sugerido compila correctamente
6. Cambiar a archivo de test y pedir sugerencia
7. Verificar que ahora la sugerencia es relevante a testing
8. Pedir sugerencia de refactor para método complejo
9. Verificar que respeta convenciones del proyecto (naming, estructura)
10. Evaluar calidad con métricas de compilación y convención

| Campo | Descripción |
|---|---|
| **Expected Result** | Sugerencias relevantes, compilables, que siguen patrones y convenciones del proyecto |
| **Success Criteria** | >70% relevancia subjetiva. <5% errores de compilación. >80% sigue convenciones. |
| **Failure Criteria** | Sugerencias genéricas sin contexto. Código no compila. Ignora convenciones del proyecto. |
| **Metrics** | Relevancia (%) (survey), % código compilable, % sigue patrones, tiempo de sugerencia (s) |

---

## Nota de Ejecución: Categoría Developer Context

**Ambiente requerido:** 3+ proyectos de diferentes tecnologías, 50K+ LOC en al menos uno, .hermes/config.yaml configurado.

**Orden de ejecución recomendado:** AT-021 → AT-022 → AT-023 → AT-027 → AT-024 → AT-025 → AT-026 → AT-028

**Preparación de fixtures:**
- Copiar proyectos de muestra de `tests/fixtures/projects/`
- Configurar `.hermes/config.yaml` según templates
- Asegurar API keys de vulnerabilidad DB disponibles

---

## 5. Categoría: Project Wizard Tests (AT-029 a AT-035)

> Esta categoría valida el wizard interactivo y el motor de generación de proyectos. Es el producto principal en el Sprint B y un diferenciador clave del sistema.

### Referencias Cruzadas

- **User Stories:** HERM-0008 (Template Engine), HERM-0009 (Multi-Language), HERM-0013 (Project Wizard)
- **Sprint:** B (Semana 5-10)
- **Riesgos Asociados:** R-003 (PowerShell multi-plataforma), R-011 (Expertise DDD)

---

### AT-029: Wizard Interactivo Paso a Paso

| Campo | Descripción |
|---|---|
| **Test ID** | AT-029 |
| **Nombre** | Wizard Interactivo de Creación de Proyecto |
| **Objetivo** | Verificar que el wizard guía al usuario paso a paso con preguntas claras y lógicas |
| **Categoría** | Wizard / UX |
| **Precondiciones** | Hermes instalado. Terminal interactivo disponible. |
| **Inputs** | Comando `hermes new` (modo interactivo). Respuestas simuladas. |

**Steps:**
1. Ejecutar `hermes new` sin argumentos (modo interactivo)
2. Verificar primera pregunta: nombre del proyecto
3. Verificar validación del nombre (no vacío, caracteres válidos)
4. Verificar segunda pregunta: lenguaje/framework
5. Verificar lista de opciones disponibles
6. Verificar tercera pregunta: tipo de proyecto (web, api, library, cli)
7. Verificar cuarta pregunta: features opcionales (testing, CI/CD, docker, etc.)
8. Verificar quinta pregunta: opciones de configuración avanzada
9. Verificar resumen final antes de crear
10. Verificar que permite editar antes de confirmar

| Campo | Descripción |
|---|---|
| **Expected Result** | Wizard con 5+ pasos, preguntas claras, validación, resumen editable |
| **Success Criteria** | Wizard completo en < 2 min. Todas las preguntas relevantes. Validación funciona. Resumen editable. |
| **Failure Criteria** | Wizard se cuelga. Preguntas confusas. Sin validación. No hay resumen. No se puede editar. |
| **Metrics** | Tiempo de wizard (s), # pasos completados, validaciones triggers (count), completion rate (%) |

---

### AT-030: Generación de Proyecto desde Template

| Campo | Descripción |
|---|---|
| **Test ID** | AT-030 |
| **Nombre** | Generación Completa de Proyecto |
| **Objetivo** | Verificar que se genera un proyecto funcional con estructura correcta y compilable |
| **Categoría** | Wizard / Generation |
| **Precondiciones** | Wizard completado o parámetros CLI completos. Template válido seleccionado. |
| **Inputs** | `hermes new --name MyApp --lang csharp --template web-api --features testing,docker` |

**Steps:**
1. Ejecutar comando de generación con parámetros completos
2. Verificar que el directorio del proyecto se crea
3. Contar archivos generados (debe ser > 10 para un proyecto funcional)
4. Verificar estructura de directorios (.src, tests, docs, etc.)
5. Ejecutar build: `dotnet build` (o equivalente según lenguaje)
6. Verificar que build es exitoso (exit code 0)
7. Ejecutar tests: `dotnet test` (o equivalente)
8. Verificar que tests base pasan
9. Verificar que README se genera con información correcta
10. Verificar que archivo de configuración de Hermes se genera

| Campo | Descripción |
|---|---|
| **Expected Result** | Proyecto generado con estructura correcta, compilable y con tests verdes |
| **Success Criteria** | Generación < 30s. > 10 archivos. Build exitoso. Tests verdes. README generado. |
| **Failure Criteria** | Archivos faltantes (<5). Build falla. Tests fallan. Sin README. Configuración missing. |
| **Metrics** | Tiempo (s), # archivos generados, build result (pass/fail), tests result (pass/fail), README presente (bool) |

---

### AT-031: Selección de Múltiples Lenguajes

| Campo | Descripción |
|---|---|
| **Test ID** | AT-031 |
| **Nombre** | Soporte Multi-Lenguaje |
| **Objetivo** | Verificar que el wizard soporta y genera proyectos correctos en al menos 5 lenguajes |
| **Categoría** | Wizard / Multi-Language |
| **Precondiciones** | Runtimes correspondientes instalados (dotnet, java, node, python, go). |
| **Inputs** | Comandos `hermes new --lang <lang>` para cada lenguaje soportado. |

**Steps:**
1. Generar proyecto C#: `hermes new --lang csharp --name DemoApp`
2. Verificar que estructura es idiomática (.csproj, Program.cs, etc.)
3. Ejecutar build y verificar éxito
4. Generar proyecto Java: `hermes new --lang java --name DemoApp`
5. Verificar estructura (pom.xml/build.gradle, src/main/java, etc.)
6. Generar proyecto Node: `hermes new --lang node --name demo-app`
7. Verificar estructura (package.json, src/, etc.) y npm install funciona
8. Generar proyecto Python: `hermes new --lang python --name demo_app`
9. Verificar estructura (pyproject.toml, src/, tests/, etc.)
10. Generar proyecto Go: `hermes new --lang go --name demoapp`
11. Verificar estructura (go.mod, cmd/, pkg/, etc.) y go build funciona

| Campo | Descripción |
|---|---|
| **Expected Result** | 5 lenguajes soportados con estructuras idiomáticas y builds funcionales |
| **Success Criteria** | 5/5 proyectos generados. Todos compilan. Estructuras idiomáticas correctas. |
| **Failure Criteria** | < 3 lenguajes funcionando. Build falla en alguno. Estructuras no idiomáticas. |
| **Metrics** | Lenguajes soportados exitosos (5 máximo), % builds exitosos, tiempo total (s), idiomaticidad (survey) |

---

### AT-032: Templates con CI/CD Incluido

| Campo | Descripción |
|---|---|
| **Test ID** | AT-032 |
| **Nombre** | CI/CD Pipeline Automático |
| **Objetivo** | Verificar que los templates incluyen pipelines de CI/CD funcionales desde el inicio |
| **Categoría** | Wizard / CI-CD |
| **Precondiciones** | Proyecto generado desde template incluye archivos de CI/CD. |
| **Inputs** | Archivos de pipeline en el proyecto generado. Ejecución local. |

**Steps:**
1. Verificar que existe `.github/workflows/ci.yml` (o equivalente Azure DevOps)
2. Verificar contenido mínimo: trigger en push/PR
3. Verificar stages: checkout, setup, build, test, lint
4. Verificar que cada stage tiene pasos ejecutables
5. Ejecutar pipeline localmente: `act` (GitHub Actions local runner)
6. Verificar que pipeline pasa completo
7. Verificar que caching de dependencias está configurado
8. Verificar que artifact upload está configurado
9. Verificar que matrix de versiones funciona (ej: .NET 6 y 8)
10. Verificar que environment variables están configuradas

| Campo | Descripción |
|---|---|
| **Expected Result** | Pipeline funcional, stages correctas, ejecutable local y remotamente |
| **Success Criteria** | Pipeline definido correctamente. Stages completas. Ejecución local exitosa. Cache configurado. |
| **Failure Criteria** | Sin archivo de pipeline. Stages faltantes. Pipeline falla local o remotamente. Sin cache. |
| **Metrics** | # stages presentes, runtime local (s), % pass rate, caching effectiveness (%) |

---

### AT-033: Config Options del Wizard

| Campo | Descripción |
|---|---|
| **Test ID** | AT-033 |
| **Nombre** | Opciones de Configuración del Wizard |
| **Objetivo** | Verificar que el wizard ofrece opciones suficientes de configuración y defaults razonables |
| **Categoría** | Wizard / Configuration |
| **Precondiciones** | Wizard accesible en modo interactivo. |
| **Inputs** | Exploración completa del wizard. |

**Steps:**
1. Ejecutar wizard paso a paso
2. Contar total de opciones de configuración presentadas
3. Verificar opciones: nombre, descripción, autor, license
4. Verificar opciones: CI/CD provider, testing framework, code style
5. Verificar opciones: Docker, deployment target, database
6. Verificar opciones: features (auth, logging, monitoring)
7. Verificar que defaults son razonables para proyecto promedio
8. Verificar que se puede saltar opciones (usar defaults)
9. Verificar que opciones se guardan correctamente en config
10. Verificar que config se puede reutilizar: `hermes new --from-config .hermes/config.yaml`

| Campo | Descripción |
|---|---|
| **Expected Result** | 8+ opciones de config, defaults razonables, config persistible y reusable |
| **Success Criteria** | ≥ 8 opciones de config. Defaults aceptables. Config guardada. Reuso funcional. |
| **Failure Criteria** | < 4 opciones. Defaults incorrectos. Config no se guarda. No hay reuso. |
| **Metrics** | # opciones disponibles, tiempo promedio por opción (s), config guardada (bool), reuso funcional (bool) |

---

### AT-034: Dry Run del Wizard

| Campo | Descripción |
|---|---|
| **Test ID** | AT-034 |
| **Nombre** | Previsualización sin Crear Archivos |
| **Objetivo** | Verificar que el wizard puede mostrar qué haría sin modificar el filesystem |
| **Categoría** | Wizard / Safety |
| **Precondiciones** | Directorio de prueba vacío. |
| **Inputs** | `hermes new --dry-run --name TestProject --lang csharp` |

**Steps:**
1. Ejecutar `hermes new --dry-run --name TestProject --lang csharp`
2. Verificar que muestra lista completa de archivos que crearía
3. Verificar que muestra contenido/resumen de cada archivo
4. Verificar que muestra estructura de directorios
5. Verificar que muestra total de archivos y directorios
6. Verificar que NO se crean archivos en disco: `ls TestProject` → debe dar error
7. Verificar que el dry run toma el mismo tiempo que la ejecución real (aprox)
8. Verificar que dry run valida parámetros igual que ejecución real
9. Probar con parámetros inválidos + dry-run: debe dar error también
10. Verificar que el output indica claramente que es un preview

| Campo | Descripción |
|---|---|
| **Expected Result** | Preview completo sin tocar filesystem, valida parámetros igual que ejecución real |
| **Success Criteria** | Preview visible y completo. 0 archivos creados. Validación funciona. Label de "preview" visible. |
| **Failure Criteria** | Archivos creados durante dry-run. Preview incompleto. Sin validación. Sin label de preview. |
| **Metrics** | Archivos en preview (int), archivos creados (debe ser 0), tiempo vs ejecución real (ratio), label presente (bool) |

---

### AT-035: Custom Templates del Usuario

| Campo | Descripción |
|---|---|
| **Test ID** | AT-035 |
| **Nombre** | Creación y Uso de Templates Personalizados |
| **Objetivo** | Verificar que el usuario puede crear, guardar y reutilizar templates personalizados |
| **Categoría** | Wizard / Extensibility |
| **Precondiciones** | Proyecto generado previamente que servirá como base del template. |
| **Inputs** | `hermes template create` y `hermes new --template <custom>` |

**Steps:**
1. Ejecutar `hermes template create --from-project ./existing-project`
2. Verificar wizard de creación de template (nombre, descripción, variables)
3. Verificar que variables marcables para parametrización
4. Guardar template: `hermes template save --name my-company-api`
5. Verificar que aparece en lista: `hermes template list`
6. Crear nuevo proyecto usando el template: `hermes new --template my-company-api`
7. Verificar que estructura coincide con definición del template
8. Verificar que variables se reemplazan correctamente
9. Verificar que se puede versionar template: `hermes template save --name X --version 1.1.0`
10. Verificar que se puede exportar/compartir: `hermes template export --template X --output my-template.zip`

| Campo | Descripción |
|---|---|
| **Expected Result** | Template custom creado y usable, versionado, exportable para compartir |
| **Success Criteria** | Template created 100%. Projects from template match definition. Variables replaced. Versionado funcional. |
| **Failure Criteria** | No puede crear template. Proyectos no coinciden. Variables no se reemplazan. Sin versionado. |
| **Metrics** | Tiempo de creación (s), match del template (%), tiempo de generación (s), variables correctamente reemplazadas (%) |

---

## Nota de Ejecución: Categoría Project Wizard

**Ambiente requerido:** Runtimes de los 5 lenguajes instalados, directorio de escritura, Git disponible.

**Orden de ejecución recomendado:** AT-029 → AT-030 → AT-031 → AT-032 → AT-033 → AT-034 → AT-035

**Cleanup necesario:** Cada test genera archivos - limpiar entre ejecuciones para no tener falsos resultados.

---

## 6. Categoría: VS Code Integration Tests (AT-036 a AT-040)

> Esta categoría valida la integración con VS Code como IDE principal. La extensión debe proporcionar funcionalidad equivalente al CLI pero integrada en el flujo de trabajo del desarrollador.

### Referencias Cruzadas

- **User Stories:** HERM-0011 (VS Code Extension)
- **Sprint:** B (Semana 5-10)
- **Riesgos Asociados:** R-002 (Performance), R-014 (Legacy tools)

---

### AT-036: Instalación de Extensión VS Code

| Campo | Descripción |
|---|---|
| **Test ID** | AT-036 |
| **Nombre** | Instalación y Activación de Extensión |
| **Objetivo** | Verificar que la extensión se instala, activa y muestra correctamente en VS Code |
| **Categoría** | VS Code / Setup |
| **Precondiciones** | VS Code 1.85+ instalado. Archivo .vsix disponible. |
| **Inputs** | Instalación via `code --install-extension hermes-x.x.x.vsix` |

**Steps:**
1. Cerrar VS Code si está abierto
2. Ejecutar `code --install-extension hermes-x.x.x.vsix`
3. Abrir VS Code
4. Ir a Extensiones panel y verificar que "Hermes Enterprise" aparece
5. Verificar icono en Activity Bar (sidebar)
6. Verificar que extensión está activa: output channel "Hermes" accesible
7. Abrir Command Palette (Ctrl+Shift+P) y buscar "Hermes:"
8. Verificar que ≥10 comandos aparecen
9. Verificar status bar item (indicador de estado)
10. Verificar que no hay errores en Developer Tools console

| Campo | Descripción |
|---|---|
| **Expected Result** | Extensión instalada, activa, con comandos y status bar visible, sin errores |
| **Success Criteria** | Instalación exitosa. ≥10 comandos en palette. Status bar visible. 0 errores en console. Activation < 5s. |
| **Failure Criteria** | Error de instalación. Comandos no aparecen. Crash de VS Code. Errores en console. |
| **Metrics** | Tiempo de instalación (s), # comandos disponibles, tiempo de activación (ms), errores en console (count) |

---

### AT-037: Command Palette Integration

| Campo | Descripción |
|---|---|
| **Test ID** | AT-037 |
| **Nombre** | Comandos desde Command Palette |
| **Objetivo** | Verificar que los comandos de Hermes funcionan desde la command palette de VS Code |
| **Categoría** | VS Code / Commands |
| **Precondiciones** | Extensión instalada (AT-036). Proyecto abierto. |
| **Inputs** | Ctrl+Shift+P > "Hermes: ..." commands |

**Steps:**
1. Abrir Command Palette (Ctrl+Shift+P)
2. Buscar "Hermes: New Project"
3. Seleccionar y verificar que wizard interactivo inicia
4. Completar wizard y verificar creación
5. Buscar "Hermes: Run Action"
6. Verificar listado de acciones disponibles para el contexto actual
7. Ejecutar una acción y verificar resultado
8. Buscar "Hermes: Context Switch"
9. Verificar que muestra proyectos disponibles
10. Verificar que keybindings funcionan (si están definidos)

| Campo | Descripción |
|---|---|
| **Expected Result** | Todos los comandos principales accesibles y funcionales desde la palette |
| **Success Criteria** | >90% de comandos funcionando. Wizard desde palette OK. Acciones ejecutables. Context switch OK. |
| **Failure Criteria** | Comandos no aparecen. Error al ejecutar. Wizard no se abre. Sin acciones disponibles. |
| **Metrics** | # comandos funcionando, tiempo de respuesta (ms), errores de ejecución, user satisfaction (1-5) |

---

### AT-038: Status Bar y Notificaciones

| Campo | Descripción |
|---|---|
| **Test ID** | AT-038 |
| **Nombre** | Indicadores de Estado y Notificaciones |
| **Objetivo** | Verificar que la extensión muestra estado en StatusBar y notificaciones apropiadas |
| **Categoría** | VS Code / UI |
| **Precondiciones** | Extensión activa. Proyecto abierto. |
| **Inputs** | Ejecución de comandos que generan eventos de estado. |

**Steps:**
1. Ejecutar comando corto (`hermes context detect`)
2. Verificar notification popup aparece
3. Verificar StatusBar muestra "running" → "completed"
4. Ejecutar comando largo (ej: `hermes generate` en proyecto grande)
5. Verificar progress indicator (spinner con texto)
6. Verificar porcentaje de progreso si aplica
7. Verificar que StatusBar vuelve a "idle" post-completion
8. Ejecutar comando que falla
9. Verificar notificación de error con opción de ver detalles
10. Verificar que iconos de StatusBar cambian según estado correcto

| Campo | Descripción |
|---|---|
| **Expected Result** | StatusBar refleja estado real-time, notificaciones informativas y no intrusivas |
| **Success Criteria** | StatusBar actualizado. Progress indicador en tareas largas. Notificaciones no-intrusivas. Error con detalles. |
| **Failure Criteria** | StatusBar no actualiza. Sin progress para tareas largas. Notificaciones molestas. Errors sin info. |
| **Metrics** | Status updates correctos (%), time to update (ms), notification delivery (%), non-intrusiveness (survey 1-5) |

---

### AT-039: Integración con Terminal Integrado

| Campo | Descripción |
|---|---|
| **Test ID** | AT-039 |
| **Nombre** | Funcionalidad en Terminal Integrado de VS Code |
| **Objetivo** | Verificar que Hermes funciona correctamente dentro del terminal integrado de VS Code |
| **Categoría** | VS Code / Terminal |
| **Precondiciones** | Extensión instalada. Terminal integrado abierto en VS Code. |
| **Inputs** | Comandos de Hermes ejecutados en terminal integrado. |

**Steps:**
1. Abrir terminal integrado (Ctrl+`)
2. Verificar que Hermes está disponible en PATH
3. Ejecutar `hermes context detect` y verificar output
4. Verificar que output tiene formato rico (colores, tablas si aplican)
5. Ejecutar comando interactivo (ej: `hermes new`)
6. Verificar que el prompt interactivo funciona en terminal integrado
7. Ejecutar comando con output largo
8. Verificar que scroll funciona correctamente
9. Verificar que autocompletado funciona (TAB con hermes CLI)
10. Ejecutar comando que requiere input del usuario y verificar respuesta

| Campo | Descripción |
|---|---|
| **Expected Result** | Comandos funcionan normalmente con output formateado y prompts interactivos funcionales |
| **Success Criteria** | Output formateado. Prompts interactivos funcionales. Scroll OK. Autocompletado OK. No encoding errors. |
| **Failure Criteria** | Output sin formato. Prompts no responden. Scroll falla. Encoding errors. Command fails. |
| **Metrics** | Formato correcto (%), prompt responsive (bool), scroll smoothness (1-5), errores de encoding (count) |

---

### AT-040: Settings Sincronizados con VS Code

| Campo | Descripción |
|---|---|
| **Test ID** | AT-040 |
| **Nombre** | Sincronización de Configuración con VS Code Settings |
| **Objetivo** | Verificar que las settings del usuario se sincronizan con settings.json de VS Code |
| **Categoría** | VS Code / Settings |
| **Precondiciones** | Extensión instalada. acceso a settings.json. |
| **Inputs** | Cambios en settings.json y en UI de VS Code settings. |

**Steps:**
1. Abrir settings.json de VS Code (Ctrl+, → Open settings.json)
2. Buscar "hermes." settings disponibles
3. Cambiar setting: `"hermes.theme": "dark"`
4. Verificar que extensión detecta el cambio automáticamente
5. Verificar que la UI refleja el cambio
6. Abrir UI de settings (Ctrl+,): buscar "Hermes"
7. Cambiar setting desde UI
8. Verificar que settings.json se actualiza
9. Verificar que setting se aplica sin necesidad de restart
10. Verificar sincronización bidireccional completa

| Campo | Descripción |
|---|---|
| **Expected Result** | Settings bidireccionales entre UI y settings.json, aplicables sin restart |
| **Success Criteria** | Settings sincrónizadas < 1s. Sin restart necesario. Ambas direcciones funcionan. |
| **Failure Criteria** | Settings no se leen. Requiere restart. Solo una dirección funciona. Settings se pierden. |
| **Metrics** | % settings sincronizados, tiempo de sync (ms), bidireccional (bool), persistence tras restart (bool) |

---

## Nota de Ejecución: Categoría VS Code

**Ambiente requerido:** VS Code 1.85+, archivo .vsix compilado, proyecto de muestra.

**Orden de ejecución recomendado:** AT-036 → AT-037 → AT-038 → AT-039 → AT-040

**Consideraciones especiales:**
- AT-036 requiere reinstalación limpia en cada iteración
- AT-039 puede necesitar ajuste de encoding/terminal según OS
- Limpiar extensiones de VS Code entre ejecuciones si se requiere estado limpio

---

## 7. Categoría: Git Integration Tests (AT-041 a AT-045)

> Esta categoría valida la integración con sistemas de control de版本 (Git) y sus proveedores (GitHub, GitLab, Azure DevOps). Los tests cubren desde operaciones básicas hasta workflows avanzados.

### Referencias Cruzadas

- **User Stories:** HERM-0012 (Git Integration Layer), HERM-0022 (CI/CD Integration)
- **Sprint:** B-C (Semana 5-18)
- **Riesgos Asociados:** R-015 (Git provider migration), R-004 (Integration failures)

---

### AT-041: Git Init Automático

| Campo | Descripción |
|---|---|
| **Test ID** | AT-041 |
| **Nombre** | Inicialización Automática de Repositorio Git |
| **Objetivo** | Verificar que Hermes inicializa correctamente Git al crear un nuevo proyecto |
| **Categoría** | Git / Initialization |
| **Precondiciones** | Git instalado. Proyecto nuevo generado con flag `--git-init`. |
| **Inputs** | `hermes new --name TestProject --git-init` |

**Steps:**
1. Ejecutar `hermes new --name TestProject --lang csharp --git-init`
2. Verificar que el directorio `.git` existe dentro del proyecto
3. Verificar que `git log --oneline` muestra al menos 1 commit ("Initial commit")
4. Verificar que `.gitignore` está presente y apropiado para el lenguaje
5. Inspeccionar contenido de `.gitignore`: verifica exclusión de build/, bin/, obj/, node_modules/
6. Verificar que hay un remote configurado (si se especificó `--remote`): `git remote -v`
7. Verificar que el branch es "main" (o configuración por defecto)
8. Hacer un cambio, verificar que `git status` funciona
9. Verificar que `.hermes` está en `.gitignore` (datos sensibles)
10. Verificar que `git ls-files` no incluye archivos de build o temporales

| Campo | Descripción |
|---|---|
| **Expected Result** | Repo Git inicializado con commit, .gitignore correcto, branch main |
| **Success Criteria** | `.git` existente. ≥1 commit. .gitignore adecuado. Branch "main". Archivos correctos tracked. |
| **Failure Criteria** | `.git` no existe. 0 commits. .gitignore faltante o incompleto. Branch incorrecto. Archivos no-deseados tracked. |
| **Metrics** | Tiempo de init (s), # commits, % covered por .gitignore, branch name (string), tracked files (int) |

---

### AT-042: Multi-Provider Git Support

| Campo | Descripción |
|---|---|
| **Test ID** | AT-042 |
| **Nombre** | Soporte para Múltiples Proveedores Git |
| **Objetivo** | Verificar que Hermes soporta push y operaciones en GitHub, GitLab y Azure DevOps |
| **Categoría** | Git / Multi-Provider |
| **Precondiciones** | Credenciales configuradas para los 3 providers. Repos vacíos creados en cada uno. |
| **Inputs** | Comandos `hermes git push --provider <provider>` para cada uno. |

**Steps:**
1. Configurar credenciales GitHub (PAT o SSH key)
2. Configurar credenciales GitLab (PAT o SSH key)
3. Configurar credenciales Azure DevOps (PAT)
4. Ejecutar `hermes git push --provider github --repo user/demo`
5. Verificar que push es exitoso en GitHub (ver en UI web)
6. Ejecutar `hermes git push --provider gitlab --repo user/demo`
7. Verificar que push es exitoso en GitLab
8. Ejecutar `hermes git push --provider azure --org org --project demo`
9. Verificar que push es exitoso en Azure DevOps
10. Verificar que contenido idéntico en los 3 repos

| Campo | Descripción |
|---|---|
| **Expected Result** | Push exitoso a los 3 providers con contenido idéntico |
| **Success Criteria** | 3/3 push exitosos. Contenido idéntico (md5sum). Config persistida. Auth functiona. |
| **Failure Criteria** | Push falla en algún provider. Contenido diverge. Auth error. Config no persiste. |
| **Metrics** | Providers exitosos (3/3), tiempo por push (s), integridad hash (%), config persistida (bool) |

---

### AT-043: Branch Strategy Automática

| Campo | Descripción |
|---|---|
| **Test ID** | AT-043 |
| **Nombre** | Gestión Automática de Branches según Estrategia |
| **Objetivo** | Verificar que Hermes crea y gestiona branches según la estrategia seleccionada (gitflow, trunk-based, github-flow) |
| **Categoría** | Git / Branching |
| **Precondiciones** | Repo Git inicializado. Estrategia de branching configurada. |
| **Inputs** | `hermes git branch --strategy gitflow` y operaciones de feature branches. |

**Steps:**
1. Configurar estrategia: `hermes git config --strategy gitflow`
2. Verificar que branches de gitflow se crean: develop, main, release/, hotfix/
3. Crear feature branch: `hermes git feature start add-auth`
4. Verificar que branch se crea desde develop
5. Realizar commit en feature branch
6. Finalizar feature: `hermes git feature finish add-auth`
7. Verificar que merge a develop es exitoso
8. Crear release: `hermes git release start 1.0.0`
9. Verificar que release branch se crea desde develop
10. Verificar que protection rules se aplican si se configura

| Campo | Descripción |
|---|---|
| **Expected Result** | Branches creados según estrategia gitflow, merges correctos, protection rules aplicadas |
| **Success Criteria** | Branches correctas. Merges exitosos. Naming convention respetada. Protection rules aplicadas. |
| **Failure Criteria** | Branches incorrectas. Merge conflicts no manejados. Sin convention. Sin protection. |
| **Metrics** | % branches correctas, merge success (%), naming convention respectada (bool), # rules aplicadas |

---

### AT-044: PR Automático con Code Review

| Campo | Descripción |
|---|---|
| **Test ID** | AT-044 |
| **Nombre** | Pull Request Automático con Asignación de Reviewers |
| **Objetivo** | Verificar que Hermes puede crear PRs con metadata relevante y asignación automática de reviewers |
| **Categoría** | Git / Pull Requests |
| **Precondiciones** | Feature branch con cambios. Repo en provider (GitHub/GitLab). |
| **Inputs** | `hermes git create-pr` |

**Steps:**
1. Crear feature branch con cambios significativos
2. Hacer 3+ commits con mensajes descriptivos
3. Ejecutar `hermes git create-pr`
4. Verificar que genera título auto-descriptivo
5. Verificar que genera descripción con resumen de cambios
6. Verificar que detecta archivos afectados
7. Verificar que sugiere reviewers basado en OWNERS/CODEOWNERS
8. Verificar que asigna labels apropiados
9. Verificar que PR se crea exitosamente en el provider
10. Verificar que aparece en la UI del provider con metadata completa

| Campo | Descripción |
|---|---|
| **Expected Result** | PR creada con título, descripción, labels y reviewers apropiados |
| **Success Criteria** | PR creada < 30s. Descripción relevante. Reviewers asignados. Labels correctos. Metadata completa. |
| **Failure Criteria** | PR no se crea. Título/descripción vacía. Sin reviewers. Labels incorrectos. Error de API. |
| **Metrics** | Tiempo de creación (s), calidad de descripción (AI score 1-10), # reviewers asignados, # labels |

---

### AT-045: Conflict Resolution Assistida

| Campo | Descripción |
|---|---|
| **Test ID** | AT-045 |
| **Nombre** | Asistencia en Resolución de Conflictos de Merge |
| **Objetivo** | Verificar que Hermes detecta conflictos y sugiere resoluciones apropiadas |
| **Categoría** | Git / Merge |
| **Precondiciones** | Repo con merge conflict intencionalmente creado. |
| **Inputs** | `hermes git resolve-conflicts` |

**Steps:**
1. Crear situación de merge conflict (cambios en mismo archivo en 2 branches)
2. Intentar merge: `git merge feature-x` → falla con conflict
3. Ejecutar `hermes git resolve-conflicts`
4. Verificar que detecta archivos con conflictos
5. Verificar que muestra los conflictos con contexto
6. Verificar que sugiere resolución para cada conflicto (AI-based si es posible)
7. Aceptar sugerencia de resolución para primer conflicto
8. Verificar que el marker de conflicto se resuelve correctamente
9. Ejecutar `git add` y `git commit` para completar merge
10. Verificar que el merge se completó exitosamente

| Campo | Descripción |
|---|---|
| **Expected Result** | Conflictos detectados, resoluciones sugeridas, merge completado exitosamente |
| **Success Criteria** | > 80% conflictos detectados. Resoluciones correctas > 70%. Merge completo. Sin pérdida de cambios. |
| **Failure Criteria** | No detecta conflictos. Sugiere resolución incorrecta que pierde código. Merge falla. |
| **Metrics** | % conflictos detectados, accuracy de resolución (%), tiempo total (s), cambios preservados (bool) |

---

## Nota de Ejecución: Categoría Git

**Ambiente requerido:** Git 2.40+, credenciales configuradas para al menos un provider (GitHub para tests básicos, los 3 para AT-042), acceso a internet.

**Orden de ejecución recomendado:** AT-041 → AT-043 → AT-045 → AT-044 → AT-042

**Limpieza entre tests:**
- Eliminar repos temporales entre tests
- Reset de remotes y branches en provider
- Limpiar credenciales cacheadas al finalizar

---

## 8. Categoría: Reports & Dashboard Tests (AT-046 a AT-050)

> Esta categoría valida el sistema de reportes y dashboard web que proporciona visibilidad sobre el estado del sistema, métricas de actividad y exportación de datos.

### Referencias Cruzadas

- **User Stories:** HERM-0019 (Report Generator), HERM-0020 (Dashboard Web), HERM-0029 (Performance Profiler)
- **Sprint:** C (Semana 9-18)
- **Riesgos Asociados:** R-002 (Performance con datos), R-016 (Demo sin features)

---

### AT-046: Reporte de Actividad del Proyecto

| Campo | Descripción |
|---|---|
| **Test ID** | AT-046 |
| **Nombre** | Generación de Reporte de Actividad |
| **Objetivo** | Verificar que se genera un reporte completo de actividad del proyecto con métricas relevantes |
| **Categoría** | Reports / Activity |
| **Precondiciones** | Proyecto con actividad registrada: commits, builds, tests, issues resueltos. |
| **Inputs** | `hermes report activity --period 30d --output ./reports/` |

**Steps:**
1. Asegurar que hay actividad registrada en los últimos 30 días
2. Ejecutar generación de reporte: `hermes report activity --period 30d`
3. Verificar que el reporte se genera en < 10 segundos
4. Verificar sección "Commits": count, autores por semana, líneas cambiadas
5. Verificar sección "Builds": success rate, tiempos promedio, tendencias
6. Verificar sección "Tests": pass rate, coverage, tiempo de ejecución
7. Verificar sección "Issues": abiertos, cerrados, tiempo promedio de resolución
8. Verificar que gráficos/visualizaciones son correctos (si aplica)
9. Verificar export a PDF: `hermes report activity --period 30d --format pdf`
10. Verificar export a HTML: `hermes report activity --period 30d --format html`

| Campo | Descripción |
|---|---|
| **Expected Result** | Reporte completo con métricas de actividad en todas las secciones y formatos exportables |
| **Success Criteria** | Generación < 10s. ≥4 secciones presentes. Gráficos visibles. PDF y HTML exportados correctamente. |
| **Failure Criteria** | Generación > 30s. Secciones faltantes. Gráficos ausentes. Export falla. Datos incorrectos. |
| **Metrics** | Tiempo de generación (s), secciones presentes (int), file size (KB), integridad de datos (%) |

---

### AT-047: Dashboard Web con Métricas

| Campo | Descripción |
|---|---|
| **Test ID** | AT-047 |
| **Nombre** | Dashboard Web con Métricas en Tiempo Real |
| **Objetivo** | Verificar que el dashboard web se carga rápidamente y muestra métricas actualizadas en tiempo real |
| **Categoría** | Dashboard / Web |
| **Precondiciones** | Dashboard desplegado. Datos disponibles. Supervisor activo. |
| **Inputs** | Navegar a http://localhost:8080 en navegador |

**Steps:**
1. Iniciar dashboard: `hermes dashboard start`
2. Abrir http://localhost:8080 en navegador
3. Verificar que la página carga en < 3 segundos
4. Verificar que muestra métricas generales (CPU, RAM, disco)
5. Verificar que muestra estado de sandboxes activos
6. Verificar que muestra lista de proyectos gestionados
7. Generar actividad en el sistema (ejecutar comandos)
8. Verificar que el dashboard se actualiza sin refresh manual (push/websocket)
9. Verificar que actualización ocurre en < 5 segundos
10. Verificar responsive design en viewport mobile (< 768px)

| Campo | Descripción |
|---|---|
| **Expected Result** | Dashboard funcional, rápido, con métricas en tiempo real y responsive |
| **Success Criteria** | Load < 3s. Métricas visibles. Update automático < 5s. Responsive mobile. 0 errores JS. |
| **Failure Criteria** | No carga o > 10s. Métricas no se muestran. No se actualiza. No responsive. Errores JS. |
| **Metrics** | Load time (s), update frequency (s), # métricas visibles, responsive score (1-5), JS errors (count) |

---

### AT-048: Export de Datos

| Campo | Descripción |
|---|---|
| **Test ID** | AT-048 |
| **Nombre** | Exportación de Datos en Múltiples Formatos |
| **Objetivo** | Verificar que los datos del sistema se pueden exportar en formatos estándar |
| **Categoría** | Reports / Export |
| **Precondiciones** | Datos disponibles (actividad, métricas, configuración). |
| **Inputs** | Comandos `hermes report export --format <format>` |

**Steps:**
1. Ejecutar export a JSON: `hermes report export --format json --output data.json`
2. Verificar que archivo JSON es válido: validar schema
3. Verificar que contiene todos los datos esperados
4. Ejecutar export a CSV: `hermes report export --format csv --output data.csv`
5. Verificar que archivo CSV se abre correctamente en Excel
6. Verificar headers y separadores correctos
7. Ejecutar export a PDF: `hermes report export --format pdf --output report.pdf`
8. Verificar que PDF es legible y contiene información
9. Verificar export con filtros: `hermes report export --format json --filter "project=main"`
10. Verificar que archivos no contienen data sensible (secrets enmascarados)

| Campo | Descripción |
|---|---|
| **Expected Result** | 3+ formatos exportables, datos íntegros, sin secrets expuestos |
| **Success Criteria** | 3 formatos válidos. Datos íntegros en cada uno. Secrets enmascarados. Filtros funcionan. |
| **Failure Criteria** | < 2 formatos. Datos corruptos. Secrets expuestos. Filtros no aplican. |
| **Metrics** | Formatos soportados (≥3), integridad (%), secrets expuestos (count), tiempo export (s) |

---

### AT-049: Alertas y Thresholds

| Campo | Descripción |
|---|---|
| **Test ID** | AT-049 |
| **Nombre** | Sistema de Alertas con Thresholds Configurables |
| **Objetivo** | Verificar que el sistema genera alertas cuando se superan thresholds configurados |
| **Categoría** | Dashboard / Alerting |
| **Precondiciones** | Dashboard activo. Threshold configurado: build failures > 3/día. |
| **Inputs** | Generar condición que dispara el threshold. |

**Steps:**
1. Configurar threshold: `hermes alert config --metric build-failures --threshold 3 --window 1d`
2. Verificar que threshold se guarda: `hermes alert list`
3. Generar condiciones para llegar al threshold: 3 builds fallados en el día
4. Verificar que NO hay alerta cuando está en 2 failures (bajo threshold)
5. Generar el tercer failure
6. Verificar que alerta visual aparece inmediatamente en dashboard
7. Verificar que notificación se envía (email/webhook configurado)
8. Verificar que alerta aparece en sección dedicada del dashboard
9. Verificar que alerta tiene severity level correcto
10. Resolver condición y verificar que alerta se marca como resuelta

| Campo | Descripción |
|---|---|
| **Expected Result** | Alerta generada solo al superar threshold, notificación enviada, marca como resuelta al normalizar |
| **Success Criteria** | Alerta visual < 10s de触发. Notificación < 30s. Log entry. No alerta prematuramente. Resolve auto. |
| **Failure Criteria** | Alerta no se genera al superar threshold. Alerta prematura. Notificación no llega. No se resuelve. |
| **Metrics** | Tiem de alerta (s), tiempo de notificación (s), % delivered, alertas prematuras (count) |

---

### AT-050: Reporte de ROI y Métricas de Negocio

| Campo | Descripción |
|---|---|
| **Test ID** | AT-050 |
| **Nombre** | Reporte de Retorno de Inversión (ROI) |
| **Objetivo** | Verificar que se genera un reporte de ROI con métricas de negocio claras y cuantificables |
| **Categoría** | Reports / Business |
| **Precondiciones** | Sistema en uso con datos históricos de al menos 1 mes. |
| **Inputs** | `hermes report roi --period 30d` |

**Steps:**
1. Verificar que hay al menos 30 días de datos históricos
2. Ejecutar: `hermes report roi --period 30d`
3. Verificar que se muestra "Horas ahorradas" vs método manual
4. Verificar que se muestra "Proyectos generados" y tiempo promedio
5. Verificar que se calcula ROI en términos monetarios (si config de costo)
6. Verificar gráficos de tendencia: horas ahorradas por semana
7. Verificar comparativa: manual vs automatizado por tarea
8. Verificar export a PDF ejecutivo
9. Verificar que el PDF es presentable a ejecutivos (formato, branding)
10. Verificar que los cálculos son verificables y transparentes

| Campo | Descripción |
|---|---|
| **Expected Result** | Reporte de ROI con métricas de negocio verificables, presentable a ejecutivos |
| **Success Criteria** | Métricas presentes. Cálculos verificables. PDF ejecutivo generado. Formato presentable. |
| **Failure Criteria** | Sin métricas de negocio. Cálculos incorrectos. PDF no genera. Formato pobre. |
| **Metrics** | Métricas de negocio mostradas (int), accuracy verificada (bool), calidad PDF (survey), tiempo generación (s) |

---

## Nota de Ejecución: Categoría Reports & Dashboard

**Ambiente requerido:** Dashboard desplegable, al menos 30 días de datos históricos (o datos seed), acceso a sistema de notificaciones.

**Orden de ejecución recomendado:** AT-047 (dashboard setup) → AT-046 → AT-048 → AT-049 → AT-050

**Datos seed necesarios:**
- 30+ commits en diferentes branches
- 10+ builds (mix de success/failure)
- 50+ tests ejecutados
- 5+ issues resueltos
- Configuración de thresholds

---

## 9. Resumen de Ejecución

### 9.1 Matriz de Cobertura por Sprint

| Sprint | Tests Asociados | % del Total | Sprint Duration |
|---|---|---|---|
| Sprint A | AT-001 a AT-028 | 56% (28 tests) | 4 semanas |
| Sprint B | AT-029 a AT-040 | 24% (12 tests) | 6 semanas |
| Sprint C | AT-041 a AT-050 | 20% (10 tests) | 8 semanas |
| Sprint D | Integración completa | 100% (regresión) | 10+ semanas |

### 9.2 Estimación de Tiempo de Ejecución

| Categoría | Tests | Tiempo Manual | Tiempo Automated | # Ejecutor |
|---|---|---|---|---|
| Sandbox | 10 | 8 horas | 1 hora | 1 |
| Supervisor | 10 | 10 horas | 2 horas | 1 |
| Developer Context | 8 | 6 horas | 1 hora | 1 |
| Project Wizard | 7 | 6 horas | 1 hora | 1 |
| VS Code | 5 | 4 horas | 0.5 horas | 1 |
| Git | 5 | 4 horas | 0.5 horas | 1 |
| Reports & Dashboard | 5 | 4 horas | 1 hora | 1 |
| **Total** | **50** | **42 horas** | **7 horas** | **1-2** |

### 9.3 Dependencias entre Tests

```
AT-001 → {AT-002, AT-003, AT-004, AT-005, AT-006, AT-007, AT-008, AT-009, AT-010}
AT-011 → {AT-012, AT-013, AT-014, AT-015, AT-016, AT-017, AT-018, AT-019, AT-020}
AT-021 → {AT-022, AT-023, AT-024, AT-025, AT-026, AT-027, AT-028}
AT-029 → {AT-030, AT-033, AT-034}
AT-030 → {AT-031, AT-032, AT-035}
AT-036 → {AT-037, AT-038, AT-039, AT-040}
AT-041 → {AT-042, AT-043, AT-044, AT-045}
AT-047 → {AT-046, AT-048, AT-049, AT-050}
```

---

## 10. Estrategia de Automatización

### 10.1 Enfoque de Automatización

| Nivel | % Automatizado | Herramienta |
|---|---|---|
| Smoke tests (setup, health) | 100% | Pester |
| Regression tests | 90% | Pester + Docker API |
| Acceptance tests (este doc) | 60% | Mixto |
| UX / Usability tests | 20% | Manual |
| Performance tests | 80% | benchmarker + Pester |

### 10.2 Framework de Automatización

```powershell
# Estructura de tests de aceptación
tests/
├── acceptance/
│   ├── sandbox/
│   │   ├── AT-001.sandbox.create.Tests.ps1
│   │   ├── AT-002.sandbox.execute.Tests.ps1
│   │   └── ... (10 files)
│   ├── supervisor/
│   │   ├── AT-011.supervisor.active.Tests.ps1
│   │   └── ... (10 files)
│   ├── context/
│   │   └── ... (8 files)
│   ├── wizard/
│   │   └── ... (7 files)
│   ├── vscode/
│   │   └── ... (5 files)
│   ├── git/
│   │   └── ... (5 files)
│   └── reports/
│       └── ... (5 files)
```

### 10.3 CI Integration

```yaml
# .github/workflows/acceptance.yml
name: Acceptance Tests
on:
  release:
    types: [created]
  schedule:
    - cron: '0 2 * * *'  # Nightly at 2am
jobs:
  acceptance:
    runs-on: [self-hosted, windows]
    steps:
      - uses: actions/checkout@v4
      - name: Install Hermes
        run: ./install.ps1
      - name: Run Acceptance Tests
        run: |
          Invoke-Pester -Path ./tests/acceptance/sandbox -Output Detailed
          Invoke-Pester -Path ./tests/acceptance/supervisor -Output Detailed
          # ... each category
      - name: Generate Report
        run: hermes report test-coverage --format junit
```

---

## 11. Criterios de Aceptación Final

### 11.1 Entrada en Sprint Review

| Criterio | Requisito |
|---|---|
| Tests PASSED del sprint | 100% |
| Tests BLOCKED | 0 |
| Bugs Críticos abiertos | 0 |
| Bugs Mayores abiertos | ≤ 2 (con workaround) |
| Documentación actualizada | Sí |
| Demo funcional | Sí |
| Performance dentro de SLA | Sí |

### 11.2 Entrada en General Availability (GA)

| Criterio | Requisito |
|---|---|
| Tests PASSED (total) | ≥ 98% (49/50) |
| Tests BLOCKED | 0 |
| Bugs Críticos resueltos | 100% |
| Performance benchmarks passing | 100% |
| Security audit | Pass |
| Documentation completa | 100% |
| Stakeholder sign-off | Obtenido |
| Runbooks de operación | Actualizados |
| Smoke tests en prod | PASSED |

### 11.3 KPIs de Calidad

| KPI | Objetivo | Medición |
|---|---|---|
| Test Coverage | 100% features | Feature tracking |
| Pass Rate | ≥ 98% en release | CI automático |
| MTTR Critical | < 24h | Incident mgmt |
| MTTR Major | < 72h | Incident mgmt |
| Regression Rate | < 5% / sprint | Post-fix testing |
| Defect Escape Rate | < 2% | Post-release |

---

## Navegación Inferior

| Documento Anterior | Índice General | Próximo Documento |
|---|---|---|
| [08_RISK_REGISTER.md](08_RISK_REGISTER.md) | [04_ROADMAP.md](04_ROADMAP.md) | [01_PROJECT_CHARTER.md](01_PROJECT_CHARTER.md) |

---

*Documento generado como parte del roadmap HERMES Enterprise. Status: DRAFT. Última actualización: 2026-07-07.*
