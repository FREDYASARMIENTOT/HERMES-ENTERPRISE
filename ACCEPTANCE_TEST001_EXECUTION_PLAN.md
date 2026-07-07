# HERMES ENTERPRISE - ACCEPTANCE TEST 001 EXECUTION PLAN

**Fecha:** 2026-07-07  
**Autor:** Architecture Review Board  
**Status:** DRAFT - Pendiente de aprobación  
**Proyecto:** PY_ENCUESTA_PERCEPCION_TEST  
**Ruta destino:** D:\PY_ENCUESTA_PERCEPCION_TEST  
**Decisión ARB:** GO WITH OBSERVATIONS (requiere 5 condiciones previas)

---

## 1. RESUMEN EJECUTIVO

```
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║   ACCEPTANCE TEST 001 - PLAN DE EJECUCIÓN                   ║
║                                                             ║
║   Proyecto: PY_ENCUESTA_PERCEPCION_TEST                     ║
║   Duración estimada: 45-60 minutos                          ║
║   Fases: 8                                                  ║
║   Riesgo: ALTO (mitigado por condiciones previas)          ║
║                                                             ║
║   CONDICIÓN PREVIA OBLIGATORIA:                             ║
║   Snapshot + Restore + Rollback implementados               ║
║   (47 SP / 188 horas / 6.5 semanas)                         ║
║                                                             ║
╚═════════════════════════════════════════════════════════════╝
```

---

## 2. OBJETIVO GENERAL

Demostrar que HERMES Enterprise puede:
1. Crear un sandbox aislado y seguro
2. Generar un proyecto profesional completo (Python + FastAPI)
3. Configurar automáticamente VS Code, Git, y documentación
4. Supervisar la ejecución con logs y métricas
5. Recuperarse de fallos usando Snapshot/Restore/Rollback
6. Limpiar completamente después del test

**Criterio de éxito global:**
- ✅ Sandbox creado sin errores
- ✅ Proyecto generado con estructura completa
- ✅ VS Code configurado y funcional
- ✅ Git inicializado con primera commit
- ✅ Documentación generada
- ✅ Tests de validación PASSED
- ✅ Reportes generados
- ✅ Sandbox limpiado completamente

---

## 3. FASES DEL TEST

### FASE 0: Pre-flight Validation

**Objetivo:** Verificar que todas las herramientas y dependencias están disponibles

**Entradas:**
- Sistema operativo Windows 10/11
- Permisos de administrador (o usuario con permisos de escritura en D:\)

**Salidas:**
- Reporte de validación (PRE-FLIGHT.md actualizado)
- Go/No-Go para proceder a Fase 1

**Tiempo esperado:** 5 minutos

**Responsable:** DevOps Lead

**Riesgos:**
- Herramientas faltantes (PowerShell, Python, Git, Node.js)
- Permisos insuficientes
- Espacio en disco limitado

**Rollback plan:**
- Si falla pre-flight, detener test y reportar
- No hay estado previo que restaurar

**Responsable de rollback:** QA Lead

**Criterios de éxito:**
```
✅ PowerShell 7.x instalado y en PATH
✅ Python 3.11+ instalado y en PATH
✅ Git 2.x instalado y configurado
✅ Node.js 18+ instalado (opcional)
✅ VS Code 1.80+ instalado
✅ Hermes CLI disponible
✅ OpenRouter API key configurada
✅ D:\HERMES-ENTERPRISE accesible
✅ D:\Sandbox accesible con permisos de escritura
✅ 500MB+ de espacio libre en D:\
```

**Criterios de fallo:**
```
❌ Cualquiera de las herramientas faltantes
❌ Error de permisos al escribir en D:\Sandbox
❌ Menos de 500MB de espacio libre
❌ API key de OpenRouter no válida
```

**Métricas:**
- Tiempo de ejecución
- Número de validaciones PASSED/FAILED
- Espacio en disco disponible

---

### FASE 1: Sandbox Creation

**Objetivo:** Crear sandbox aislado para PY_ENCUESTA_PERCEPCION_TEST

**Entradas:**
- Ruta destino: D:\PY_ENCUESTA_PERCEPCION_TEST
- Nombre del sandbox: Test_PY_ENCUESTA_Percepcion
- Escenario: ExistingProject (proyecto real a generar)

**Salidas:**
- Sandbox creado en D:\Sandbox\Test_PY_ENCUESTA_Percepcion
- sandbox.json con metadata
- Snapshot inicial del sandbox (si Snapshot Engine implementado)

**Tiempo esperado:** 2 minutos

**Responsable:** QA Lead

**Riesgos:**
- Error al crear directorio
- Permisos insuficientes
- Sandbox con nombre duplicado

**Rollback plan:**
- Si falla, ejecutar: Remove-HermesEnterpriseSandbox -RutaSandbox Test_PY_ENCUESTA_Percepcion
- Si Snapshot disponible: Restore-HermesEnterpriseSandboxSnapshot -SnapshotId initial

**Responsable de rollback:** Engineering Manager

**Criterios de éxito:**
```
✅ Sandbox creado en D:\Sandbox\Test_PY_ENCUESTA_Percepcion
✅ sandbox.json existe con metadata correcta
✅ Directorio tiene estructura de carpetas (HermesEnterprise/, Workspace/)
✅ Estado del sandbox: CREATED
```

**Criterios de fallo:**
```
❌ Error al crear directorio
❌ sandbox.json no existe o está corrupto
❌ Sandbox ya existe (nombre duplicado)
❌ Permisos insuficientes
```

**Métricas:**
- Tiempo de creación
- Tamaño del sandbox en disco
- Estado del sandbox.json

---

### FASE 2: Bootstrap

**Objetivo:** Inicializar Hermes Engine dentro del sandbox

**Entradas:**
- Sandbox: D:\Sandbox\Test_PY_ENCUESTA_Percepcion
- DeveloperContext básico (obtenido de inspectores)

**Salidas:**
- Hermes Engine inicializado
- DeveloperContext parcial completado
- Snapshot del estado bootstrap (si Snapshot Engine implementado)

**Tiempo esperado:** 3 minutos

**Responsable:** Chief Architect

**Riesgos:**
- Bootstrap falla por DeveloperContext incompleto
- Errores de dependencias
- Timeouts en APIs externas

**Rollback plan:**
- Si falla bootstrap: Restore-HermesEnterpriseSandboxSnapshot -SnapshotId initial
- Si Snapshot no disponible: Remove y recrear sandbox

**Responsable de rollback:** Chief Architect

**Criterios de éxito:**
```
✅ Bootstrap completado sin errores
✅ DeveloperContext tiene al menos: Workspace, Project, Git, GitHub, Environment
✅ Logs de bootstrap presentes en execution.log
✅ Snapshot creado: bootstrap_complete
```

**Criterios de fallo:**
```
❌ Bootstrap falla con error crítico
❌ DeveloperContext incompleto (faltan inspectores básicos)
❌ Logs no se generan
❌ Snapshot no se crea (si Snapshot Engine implementado)
```

**Métricas:**
- Tiempo de bootstrap
- Número de inspectores ejecutados
- Tamaño del DeveloperContext
- Número de warnings/errores en logs

---

### FASE 3: Project Creation

**Objetivo:** Generar proyecto Python + FastAPI completo

**Entradas:**
- DeveloperContext con Project Inspector + Environment Inspector
- Template: python-fastapi
- Nombre del proyecto: py_encuesta_percepcion

**Salidas:**
- Estructura de proyecto generada:
  - /src/api/ (endpoints REST)
  - /src/models/ (modelos Pydantic)
  - /src/database/ (configuración SQLAlchemy)
  - /tests/ (tests unitarios)
  - /docs/ (documentación Sphinx)
  - requirements.txt
  - README.md
  - .gitignore
- Snapshot del proyecto creado (si Snapshot Engine implementado)

**Tiempo esperado:** 10 minutos

**Responsable:** Software Engineering Manager

**Riesgos:**
- Template Engine falla
- Errores en generación de código
- Dependencias faltantes
- DeveloperContext incompleto afecta generación

**Rollback plan:**
- Si falla: Restore-HermesEnterpriseSandboxSnapshot -SnapshotId bootstrap_complete
- Si Snapshot no disponible: Remove project files y reintentar

**Responsable de rollback:** Solution Architect

**Criterios de éxito:**
```
✅ Estructura de directorios creada correctamente
✅ Código Python válido (sin errores de sintaxis)
✅ requirements.txt con dependencias FastAPI, SQLAlchemy, Pydantic
✅ README.md con instrucciones de instalación
✅ .gitignore configurado para Python
✅ Snapshot creado: project_generated
```

**Criterios de fallo:**
```
❌ Estructura incompleta o corrupta
❌ Código Python con errores de sintaxis
❌ Dependencias faltantes en requirements.txt
❌ README.md ausente o incompleto
❌ Snapshot no se crea (si Snapshot Engine implementado)
```

**Métricas:**
- Tiempo de generación
- Número de archivos creados
- Tamaño del proyecto en disco
- Validación de sintaxis Python (py_compile)

---

### FASE 4: Git Initialization

**Objetivo:** Configurar Git con primera commit y ramas

**Entradas:**
- Proyecto generado en Fase 3
- Configuración Git global (nombre, email)

**Salidas:**
- Repositorio Git inicializado
- Primera commit: "Initial commit: PY_ENCUESTA_PERCEPCION_TEST scaffold"
- Rama principal: main (no master)
- Snapshot del estado Git (si Snapshot Engine implementado)

**Tiempo esperado:** 2 minutos

**Responsable:** DevOps Lead

**Riesgos:**
- Git no configurado correctamente
- Error al crear primera commit
- Conflictos con .gitignore

**Rollback plan:**
- Si falla: Restore-HermesEnterpriseSandboxSnapshot -SnapshotId project_generated
- Si Snapshot no disponible: Remove .git/ y reintentar

**Responsable de rollback:** DevOps Lead

**Criterios de éxito:**
```
✅ Directorio .git/ exists
✅ Primera commit presente (git log)
✅ Rama principal: main
✅ .gitignore respetado (no se commitean archivos ignored)
✅ Snapshot creado: git_initialized
```

**Criterios de fallo:**
```
❌ Error al inicializar repositorio Git
❌ Error al crear primera commit
❌ Rama principal no es main
❌ Snapshot no se crea (si Snapshot Engine implementado)
```

**Métricas:**
- Tiempo de inicialización Git
- Número de archivos commiteados
- Tamaño del repositorio .git/
- Validación de .gitignore

---

### FASE 5: Documentation Generation

**Objetivo:** Generar documentación completa del proyecto

**Entradas:**
- Proyecto generado en Fase 3
- DeveloperContext con Architecture Inspector (si implementado)

**Salidas:**
- /docs/architecture.md (diagrama C4, componentes)
- /docs/api.md (endpoints REST)
- /docs/deployment.md (instrucciones de despliegue)
- /docs/contributing.md (guía de contribución)
- Snapshot de documentación (si Snapshot Engine implementado)

**Tiempo esperado:** 5 minutos

**Responsable:** Product Owner

**Riesgos:**
- Documentation Generator incompleto
- Information faltante en DeveloperContext
- Templates de documentación ausentes

**Rollback plan:**
- Si falla: Restore-HermesEnterpriseSandboxSnapshot -SnapshotId git_initialized
- Si Snapshot no disponible: Remove /docs/ y reintentar

**Responsable de rollback:** Product Owner

**Criterios de éxito:**
```
✅ /docs/architecture.md generado con diagrama C4
✅ /docs/api.md generado con endpoints REST
✅ /docs/deployment.md generado con instrucciones
✅ /docs/contributing.md generado
✅ Snapshot creado: documentation_generated
```

**Criterios de fallo:**
```
❌ Archivos de documentación ausentes
❌ Diagrama C4 no se genera o está corrupto
❌ Información incorrecta en documentación
❌ Snapshot no se crea (si Snapshot Engine implementado)
```

**Métricas:**
- Tiempo de generación
- Número de archivos de documentación creados
- Tamaño total de documentación
- Validación de sintaxis Markdown

---

### FASE 6: Validation

**Objetivo:** Ejecutar tests de validación del proyecto generado

**Entradas:**
- Proyecto completo con documentación
- Scripts de test: test_validation.py, test_smoke.py

**Salidas:**
- Reporte de validación (validation_report.json)
- Resultados de tests unitarios
- Resultados de smoke tests
- Snapshot del estado validado (si Snapshot Engine implementado)

**Tiempo esperado:** 10 minutos

**Responsable:** QA Lead

**Riesgos:**
- Tests fallan por errores en código generado
- Dependencias faltantes
- Configuración de tests incorrecta

**Rollback plan:**
- Si tests fallan: Restore-HermesEnterpriseSandboxSnapshot -SnapshotId documentation_generated
- Corregir errores manualmente si son menores
- Re-ejecutar tests

**Responsable de rollback:** QA Lead

**Criterios de éxito:**
```
✅ Todos los tests unitarios PASSED (>95%)
✅ Smoke test de API responde correctamente
✅ Reporte de validación generado sin errores críticos
✅ Coverage de código > 80%
✅ Snapshot creado: validation_complete
```

**Criterios de fallo:**
```
❌ Tests unitarios con coverage < 80%
❌ Smoke test de API falla
❌ Errores críticos en validación_report.json
❌ Snapshot no se crea (si Snapshot Engine implementado)
```

**Métricas:**
- Tiempo de ejecución de tests
- Coverage de código (%)
- Número de tests PASSED/FAILED/SKIPPED
- Tamaño del reporte de validación

---

### FASE 7: Reporting

**Objetivo:** Generar reportes finales del test

**Entradas:**
- Todos los snapshots previos
- Logs de ejecución (execution.log, execution.json, current_state.json)
- Resultados de validación

**Salidas:**
- TestReport.json (resumen del test)
- FinalSnapshot.json (estado final del sandbox)
- Timeline de ejecución (timeline.json)
- Métricas de performance
- Snapshot final del sandbox (si Snapshot Engine implementado)

**Tiempo esperado:** 3 minutos

**Responsable:** Technical Auditor

**Riesgos:**
- Reporte incompleto
- Métricas faltantes
- Errores al escribir archivos JSON

**Rollback plan:**
- Si falla: Retry con Retry-FinalReport.ps1
- Si persiste: Extraer datos manualmente de logs

**Responsable de rollback:** Technical Auditor

**Criterios de éxito:**
```
✅ TestReport.json generado con todas las secciones
✅ FinalSnapshot.json generado
✅ Timeline.json con todas las fases
✅ Métricas de performance calculadas
✅ Snapshot creado: test_finalized
```

**Criterios de fallo:**
```
❌ Reportes JSON faltantes o corruptos
❌ Métricas incompletas
❌ Timeline incompleto
❌ Snapshot no se crea (si Snapshot Engine implementado)
```

**Métricas:**
- Tiempo de generación de reportes
- Tamaño de reportes
- Completitud de métricas (%)
- Validación de JSON schema

---

### FASE 8: Cleanup

**Objetivo:** Eliminar completamente el sandbox del test

**Entradas:**
- Sandbox: D:\Sandbox\Test_PY_ENCUESTA_Percepcion
- Confirmación de éxito/fallo del test

**Salidas:**
- Sandbox eliminado completamente
- Confirmación de limpieza (cleanup_confirmation.json)
- Reporte final de AT001 (AT001_final_report.md)

**Tiempo esperado:** 2 minutos

**Responsable:** DevOps Lead

**Riesgos:**
- Error al eliminar sandbox
- Archivos bloqueados
- Permisos insuficientes

**Rollback plan:**
- Si falla: Reintentar con Remove-HermesEnterpriseSandbox -Force
- Si persiste: Eliminar manualmente D:\Sandbox\Test_PY_ENCUESTA_Percepcion

**Responsable de rollback:** DevOps Lead

**Criterios de éxito:**
```
✅ Sandbox eliminado (D:\Sandbox\Test_PY_ENCUESTA_Percepcion no existe)
✅ cleanup_confirmation.json generado
✅ AT001_final_report.md generado
✅ No quedan archivos temporales
✅ Espacio en disco liberado
```

**Criterios de fallo:**
```
❌ Sandbox no se elimina completamente
❌ Archivos bloqueados o en uso
❌ cleanup_confirmation.json no se genera
❌ AT001_final_report.md no se genera
```

**Métricas:**
- Tiempo de limpieza
- Espacio en disco recuperado
- Número de archivos eliminados
- Validación de eliminación completa

---

## 4. ESCENARIOS DE FALLO Y ROLLBACK

### Escenario A: Fallo en Fase 1 (Sandbox Creation)

**Causa:** Error de permisos o nombre duplicado  
**Acción:** Corregir permisos/renombrar, reintentar Fase 1  
**Tiempo adicional:** 2 minutos  

### Escenario B: Fallo en Fase 3 (Project Creation)

**Causa:** Template Engine incompleto o DeveloperContext insuficiente  
**Acción:** 
- Si Snapshot disponible: Restore a Fase 2
- Si Snapshot no disponible: Reintentar con DeveloperContext manual  
**Tiempo adicional:** 5-10 minutos  

### Escenario C: Fallo en Fase 6 (Validation - tests fallan)

**Causa:** Errores en código generado  
**Acción:** 
- Si Snapshot disponible: Restore a Fase 5
- Corregir errores manualmente
- Re-ejecutar tests  
**Tiempo adicional:** 15-20 minutos  

### Escenario D: Fallo crítico en cualquier fase

**Causa:** Error no recuperable  
**Acción:** 
- Si Snapshot disponible: Restore a último snapshot válido
- Si Snapshot no disponible: Abort test, Remove sandbox, reportar  
**Tiempo adicional:** 10-15 minutos  

---

## 5. MATRIZ DE ROLES Y RESPONSABILIDADES

| Fase | Responsable | Backup | Revisor |
|------|-------------|--------|---------|
| 0. Pre-flight | DevOps Lead | QA Lead | Technical Auditor |
| 1. Sandbox Creation | QA Lead | DevOps Lead | Solution Architect |
| 2. Bootstrap | Chief Architect | Solution Architect | Technical Auditor |
| 3. Project Creation | Software Engineering Manager | Solution Architect | Product Owner |
| 4. Git Init | DevOps Lead | QA Lead | Technical Auditor |
| 5. Documentation | Product Owner | Solution Architect | Technical Auditor |
| 6. Validation | QA Lead | Software Engineering Manager | Technical Auditor |
| 7. Reporting | Technical Auditor | Chief Architect | Product Owner |
| 8. Cleanup | DevOps Lead | QA Lead | Technical Auditor |

---

## 6. CHECKLIST PREVIO AL TEST

Antes de ejecutar AT001, verificar:

```
Pre-flight:
☐ Herramientas instaladas (PowerShell, Python, Git, VS Code)
☐ OpenRouter API key válida
☐ D:\HERMES-ENTERPRISE accesible
☐ D:\Sandbox accesible con permisos de escritura
☐ 500MB+ de espacio libre

Snapshot/Restore (CONDICIÓN OBLIGATORIA):
☐ Snapshot Engine implementado
☐ Restore Engine implementado
☐ Rollback Engine implementado
☐ Transaction Log implementado
☐ Recovery Engine implementado

Roadmap (CONDICIÓN OBLIGATORIA):
☐ Inconsistencias de roadmap resueltas
☐ Velocidad del equipo definida
☐ Timeline recalculado

AT001 Plan (CONDICIÓN OBLIGATORIA):
☐ Este documento aprobado por ARB
☐ Roles asignados
☐ Rollback plans validados
☐ Criterios de éxito documentados
```

---

## 7. CRITERIOS DE ACEPTACIÓN GLOBAL

### GO (Test exitoso)
- ✅ Las 8 fases completadas sin errores críticos
- ✅ Todos los snapshots creados (si Snapshot Engine implementado)
- ✅ Validación pasada: tests unitarios >95% PASSED
- ✅ Smoke test de API responde correctamente
- ✅ Reportes generados sin errores
- ✅ Sandbox limpiado completamente

### NO GO (Test fallido)
- ❌ Más de 2 fases con errores críticos
- ❌ Snapshot/Restore/Rollback no funcionan
- ❌ Validación: tests unitarios <80% PASSED
- ❌ Smoke test de API falla
- ❌ Sandbox no puede eliminarse completamente

### GO WITH OBSERVATIONS (Test exitoso con limitaciones)
- ✅ Las 8 fases completadas con errores menores
- ⚠️ DeveloperContext incompleto (limitación conocida)
- ⚠️ VS Code configuration manual (limitación conocida)
- ⚠️ Git remote no configurado automáticamente
- ⚠️ Algunas métricas faltantes

---

## 8. PLAN DE COMUNICACIÓN

### Durante el test:
- **Inicio:** Notificar a ARB: "AT001 iniciado"
- **Fase completada:** Actualizar dashboard en tiempo real
- **Fallo crítico:** Alertar inmediatamente a responsables
- **Finalización:** Notificar a ARB: "AT001 completado (éxito/fallo)"

### Después del test:
- **Éxito:** Enviar AT001_final_report.md a stakeholders
- **Fallo:** Enviar Incident Report con análisis de causa raíz
- **GO WITH OBSERVATIONS:** Enviar reporte con limitaciones documentadas

---

## 9. APROBACIÓN DEL PLAN

| Nombre | Rol | Firma | Fecha |
|--------|-----|-------|-------|
| [Nombre] | Chief Architect | ⏳ Pendiente | - |
| [Nombre] | QA Lead | ⏳ Pendiente | - |
| [Nombre] | DevOps Lead | ⏳ Pendiente | - |
| [Nombre] | Product Owner | ⏳ Pendiente | - |

---

**Fin del Acceptance Test 001 Execution Plan**  
**Próximo paso:** Implementar condiciones previas (Snapshot/Restore/Rollback)
