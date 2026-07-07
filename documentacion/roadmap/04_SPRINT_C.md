---
# ============================================================================
# HERMES-ENTERPRISE
# Sprint C: Memory & Learning
# ============================================================================
titulo: "Sprint C — Memoria y Aprendizaje"
proyecto: "HERMES-ENTERPRISE"
version_doc: "1.0.0"
estado: "Propuesta de Diseño"
autor: "Fredy Alejandro Sarmiento Torres"
fecha_creacion: "2026-07-07"
sprint_id: "SC-001"
duracion_semanas: 8
story_points_totales: 45
equipo: "3-5 Ingenieros Senior"
dependencias:
  - "02_SPRINT_A.md (Safe Sandbox)"
  - "03_SPRINT_B.md (Project Generator)"
bloquea: null
clasificacion: "Diseño Estratégico"
criterio_exito: "Hermes recuerda, aprende y mejora su comportamiento con cada ejecución"
# ============================================================================
---

# Sprint C — Memoria y Aprendizaje

## Navegación

| Documento | Estado |
|---|---|
| [← Sprint A: Safe Sandbox](02_SPRINT_A.md) | Prerequisito |
| [← Sprint B: Project Generator](03_SPRINT_B.md) | Prerequisito |
| [← ROADMAP_EVOLUTIVO_INCREMENTAL.md](../ROADMAP_EVOLUTIVO_INCREMENTAL.md) | Línea base |

---

## 1. Visión General

### 1.1 Objetivo del Sprint

Dotar a Hermes de memoria persistente que aprenda de sus ejecuciones: qué funcionó, qué falló, qué decisiones se tomaron y por qué. Esto permite mejora continua del sistema sin intervención manual.

### 1.2 Alcance

**Incluye:** 11 motores y subsistemas de memoria persistente.
**Fuera de alcance:** Fine-tuning de LLM, RAG contra conocimiento externo, multi-agent consensus memory.

### 1.3 Motivación

Actualmente, Hermes olvida entre sesiones. Errores recurrentes no se capturan, decisiones de diseño no se justifican, patrones no se reconocen. Sprint C construye la memoria a largo plazo del sistema.

### 1.4 Métricas de éxito

| Métrica | Objetivo |
|---|---|
| Tasa de memoria útil aplicada | > 60% de ejecuciones usan al menos 1 learned lesson |
| Tiempo hasta pattern detection | < 5 ejecuciones con mismo escenario |
| Tasa de reducción de errores recurrentes | ≥ 40% entre mes 1 y mes 3 |
| Tasa de falsos positivos en pattern recognition | < 15% |
| Performance overhead del learning engine | < 5% del tiempo total de ejecución |

---

## 2. Arquitectura del Sistema de Memoria

```
┌────────────────────────────────────────────────────────────┐
│                  MEMORY ORCHESTRATOR                        │
│           (Orquesta memoria + aprendizaje)                   │
└─────────────────────────┬──────────────────────────────────┘
                          │
     ┌────────────────────┼────────────────────┐
     ▼                    ▼                    ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│ LEARNING    │   │ PATTERN     │   │ KNOWLEDGE   │
│ ENGINE      │   │ RECOGNITION │   │ BASE        │
│             │   │             │   │             │
│ • Observe   │   │ • Identify  │   │ • Store     │
│ • Extract   │   │ • Cluster   │   │ • Retrieve  │
│ • Score     │   │ • Match     │   │ • Link      │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │                  │                  │
       ▼                  ▼                  ▼
┌──────────────────────────────────────────────────────────┐
│                 MEMORY STORAGE LAYER                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │ DECISION │  │ LESSONS  │  │ EXPERI.  │  │GRAPH   │ │
│  │ MEMORY   │  │ LEARNED  │  │ DB       │  │        │ │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘ │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ SUCCESS  │  │ FAILURE  │  │ LIFECY.  │             │
│  │ METRICS  │  │ ANALYSIS │  │ MANAGER  │             │
│  └──────────┘  └──────────┘  └──────────┘             │
└──────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│              PERSISTENCE + CONTINUOUS IMPROVEMENT        │
│  • SQLite / JSON files                                   │
│  • Feedback loops                                        │
│  • Memory lifecycle (create → use → archive → forget)    │
└──────────────────────────────────────────────────────────┘
```

---

## 3. Modelo de Datos

### 3.1 Entidades Principales

```
┌────────────────────────────────────────────┐
│ ExecutionRecord                            │
├────────────────────────────────────────────┤
│ execution_id: uuid                         │
│ timestamp: datetime                        │
│ scenario: string                           │
│ project_name: string                       │
│ outcome: (SUCCESS|FAILURE|PARTIAL)         │
│ duration_seconds: int                      │
│ steps_completed: int                       │
│ errors_summary: string                     │
└────────────────┬───────────────────────────┘
                 │ 1:N
    ┌────────────┼────────────┬───────────────┐
    ▼            ▼            ▼               ▼
Decision     LessonLearned  SuccessMetric  FailureAnalysis
──────────   ─────────────  ─────────────  ─────────────
why          what_worked    metric_name    root_cause
alternatives what_failed    value          severity
context      applicability  unit           category
confidence   reuse_count    threshold      frequency
expires_at   last_used_at   trend          recommendation
```

### 3.2 Knowledge Graph

```json
{
  "node_id": "knw_go_fastapi_pattern_001",
  "node_type": "pattern",
  "label": "Go + Gin API pattern",
  "relationships": [
    {"target": "knw_language_go", "rel": "USES_LANGUAGE"},
    {"target": "knw_framework_gin", "rel": "USES_FRAMEWORK"},
    {"target": "knw_lesson_avoid_global_state", "rel": "IMPLIES"},
    {"target": "knw_project_myapi", "rel": "APPLIED_TO"}
  ],
  "first_seen": "2026-07-07",
  "last_seen": "2026-08-15",
  "occurrences": 12,
  "confidence": 0.92,
  "tags": ["backend", "api", "go", "best-practice"]
}
```

### 3.3 Memory Lifecycle

```
[CREATED] ──use──► [ACTIVE] ──unused──► [DORMANT] ──age──► [ARCHIVED] ──obsolete──► [FORGOTTEN]
     │                 ▲                      │
     │                 │                      │
     │                 └──reuse───────────────┘
     │
     └───error──► [INVALIDATED]
```

**Reglas de transición:**
- CREATED → ACTIVE: después de primera aplicación exitosa
- ACTIVE → DORMANT: si no se usa en 90 días
- DORMANT → ARCHIVED: si no se usa en 180 días
- DORMANT → ACTIVE: cuando se reutiliza
- ARCHIVED → FORGOTTEN: si no se usa en 1 año
- Cualquier estado → INVALIDATED: si causa fallo confirmado

---

## 4. Épicas

### SC-E1: Learning Engine (8 SP / 16h)
Observa ejecuciones, extrae lecciones, las califica.

### SC-E2: Knowledge Base (5 SP / 10h)
Almacén estructurado de conocimiento con indexación y búsqueda.

### SC-E3: Decision Memory (3 SP / 6h)
Por qué se tomaron decisiones técnicas específicas.

### SC-E4: Pattern Recognition (6 SP / 12h)
Identifica escenarios recurrentes y propone soluciones.

### SC-E5: Lessons Learned & Post-Mortem (5 SP / 10h)
Automatiza análisis post-mortem después de fallos significativos.

### SC-E6: Experience Database (3 SP / 6h)
Almacenamiento a largo plazo con indexing eficiente.

### SC-E7: Success Metrics & Failure Analysis (5 SP / 10h)
Mide qué funciona y captura root causes de fallos.

### SC-E8: Continuous Improvement & Feedback Loops (4 SP / 8h)
Retroalimentación automática al motor de ejecución.

### SC-E9: Memory Lifecycle Manager (3 SP / 6h)
Crea → usa → archiva → olvida.

### SC-E10: Knowledge Graph (3 SP / 6h)
Relaciones entre conocimientos, patterns, decisiones.

**Total: 45 SP / 90h**

---

## 5. Historias de Usuario

### SC-US-01: Learning Engine
**Como** Hermes, **quiero** observar cada ejecución y extraer lecciones **para** mejorar en el futuro.
**Aceptación:**
1. Al finalizar cada ejecución, `Observe-HermesExecution` analiza steps, errors, warnings
2. Extrae lecciones tipo: "X funcionó en contexto Y", "Z falló en contexto W"
3. Califica confianza de cada lección (0.0-1.0) basado en repetición
4. Las guarda en Experience Database

**SP: 5 / Horas: 10h / Prioridad: Crítica**

---

### SC-US-02: Knowledge Base
**Como** sistema, **quiero** un store estructurado de conocimiento **para** recuperación rápida.
**Aceptación:**
1. `Get-HermesKnowledgeItem -Query "X"` retorna conocimiento relevante
2. Indexación por tags, tipo, fecha, confianza
3. Soporta queries complejas: `AND`, `OR`, `NOT`
4. Score de relevancia en resultados

**SP: 5 / Horas: 10h / Prioridad: Crítica**

---

### SC-US-03: Decision Memory (Rationale)
**Como** maintainer, **quiero** justificar por qué se eligió opción A sobre B **para** no repetir el análisis.
**Aceptación:**
1. `Record-HermesDecision -Topic X -Decision A -Rationale "..." -Alternatives @(B,C)`
2. `Query-HermesDecision -Topic X` retorna historia de decisiones
3. Incluye: contexto, fecha, autor, confidence, estado (active/superseded)
4. Decisiones se marcan `superseded` cuando se reemplazan

**SP: 3 / Horas: 6h / Prioridad: Alta**

---

### SC-US-04: Pattern Recognition
**Como** sistema, **quiero** identificar escenarios recurrentes **para** sugerir mejores caminos.
**Aceptación:**
1. Después de 3 ejecuciones similares, detecta patrón
2. Score basado en: frecuencia, recencia, éxito en usos previos
3. Expone: `Find-HermesPatterns -SimilarTo <execution_id>`
4. Sugiere: "En escenarios similares, este approach funcionó N veces"

**SP: 6 / Horas: 12h / Prioridad: Alta**

---

### SC-US-05: Lessons Learned
**Como** equipo, **quiero** post-mortem automático después de fallos graves **para** aprender sin overhead manual.
**Aceptación:**
1. Al fallar un paso crítico, genera lección automáticamente
2. Estructura: `Qué pasó`, `Por qué pasó`, `Cómo prevenir`, `Aplicabilidad`
3. `Get-HermesLessonsLearned -ExecutionId <id>` lista lecciones
4. Lecciones se indexan en Knowledge Base

**SP: 5 / Horas: 10h / Prioridad: Alta**

---

### SC-US-06: Experience Database
**Como** sistema, **quiero** almacenamiento persistente a largo plazo **para** retener aprendizajes entre sesiones.
**Aceptación:**
1. SQLite como backend primario (`hermes_memory.db`)
2. Esquema versionado para migraciones futuras
3. Queries optimizadas por casos de uso comunes
4. Backup/restore soportado con snapshot

**SP: 3 / Horas: 6h / Prioridad: Crítica**

---

### SC-US-07: Success Metrics
**Como** sistema, **quiero** medir qué funciona y qué no **para** ajustar comportamiento.
**Aceptación:**
1. Cada ejecución registra métricas: tiempo, éxito/paso, warnings, errores
2. Agrega por: language, framework, escenario, time range
3. `Get-HermesSuccessMetrics -Scenario X` retorna dashboard
4. Identify tendencias: mejorando/empeorando

**SP: 3 / Horas: 6h**

---

### SC-US-08: Failure Analysis
**Como** sistema, **quiero** capturar root cause de fallos **para** evitarlos en el futuro.
**Aceptación:**
1. Cada error se categoriza: TRANSIENT, ENVIRONMENT, BUG, CONFIGURATION, UNKNOWN
2. `Analyze-HermesFailure -ErrorRecord <e>` produce análisis estructurado
3. Si existe pattern de fallos similares, sugiere fix known
4. Actualiza Failure Frequency counters

**SP: 2 / Horas: 4h**

---

### SC-US-09: Continuous Improvement
**Como** sistema, **quiero** aplicar lecciones automáticamente en próximas ejecuciones **para** mejorar sin intervención humana.
**Aceptación:**
1. Antes de ejecutar, busca lecciones aplicables al escenario
2. Ajusta parámetros defaults según lecciones aprendidas
3. Sugerencias aparecen en dashboard al usuario
4. Aprende de si sugerencias fueron aceptadas

**SP: 4 / Horas: 8h**

---

### SC-US-10: Memory Lifecycle
**Como** sistema, **quiero** gestionar el ciclo de vida de memorias **para** no saturarme con info obsoleta.
**Aceptación:**
1. `Invoke-HermesMemoryMaintenance` aplica reglas de lifecycle
2. ACTIVE → DORMANT tras 90 días sin uso
3. DORMANT → ARCHIVED tras 180 días
4. Archivos marcados `is_invalidated = 1` nunca se usan para decisiones
5. Estadísticas: activas, durmientes, archivadas, olvidadas

**SP: 3 / Horas: 6h**

---

### SC-US-11: Knowledge Graph
**Como** sistema, **quiero** relaciones entre memorias **para** navegación contextual del conocimiento.
**Aceptación:**
1. Nodos: ejecución, lección, patrón, decisión, métrica, proyecto
2. Relaciones: APLICA_A, IMPLICA, REQUIERE, DERIVA_DE, SUPERSEDE
3. `Get-HermesKnowledgeGraph -From <node>` retorna vecinos
4. Visualización en Mermaid opcional

**SP: 3 / Horas: 6h**

---

## 6. Tareas Detalladas

### SC-E1: Learning Engine (8 SP / 16h)

| ID | Tarea | SP | Horas | Deps |
|---|---|---|---|---|
| SC-T1.1 | Diseño del observador de ejecución | 2 | 4h | - |
| SC-T1.2 | `Observe-HermesExecution` | 3 | 6h | T1.1 |
| SC-T1.3 | Extraction de lecciones | 2 | 4h | T1.2 |
| SC-T1.4 | Sistema de scoring/confianza | 1 | 2h | T1.3 |

**Total: 8 SP / 16h**

### SC-E2: Knowledge Base (5 SP / 10h)

| ID | Tarea | SP | Horas | Deps |
|---|---|---|---|---|
| SC-T2.1 | Diseño de schema Knowledge Base | 1 | 2h | - |
| SC-T2.2 | `Get-HermesKnowledgeItem` (query) | 2 | 4h | T2.1 |
| SC-T2.3 | Indexación por tags + relevancia score | 2 | 4h | T2.2 |

**Total: 5 SP / 10h**

### SC-E3: Decision Memory (3 SP / 6h)

| ID | Tarea | SP | Horas | Deps |
|---|---|---|---|---|
| SC-T3.1 | `Record-HermesDecision` | 1.5 | 3h | T2.1 |
| SC-T3.2 | `Query-HermesDecision` | 1.5 | 3h | T3.1 |

**Total: 3 SP / 6h**

### SC-E4: Pattern Recognition (6 SP / 12h)

| ID | Tarea | SP | Horas | Deps |
|---|---|---|---|---|
| SC-T4.1 | Diseño del algoritmo de clustering | 2 | 4h | - |
| SC-T4.2 | `Find-HermesPatterns` | 2 | 4h | T4.1, T2.2 |
| SC-T4.3 | Score de similitud entre ejecuciones | 2 | 4h | T4.2 |

**Total: 6 SP / 12h**

### SC-E5: Lessons Learned & Post-Mortem (5 SP / 10h)

| ID | Tarea | SP | Horas | Deps |
|---|---|---|---|---|
| SC-T5.1 | `Invoke-HermesPostMortem` | 2 | 4h | T1.2 |
| SC-T5.2 | `Get-HermesLessonsLearned` | 2 | 4h | T5.1 |
| SC-T5.3 | Indexar lecciones en Knowledge Base | 1 | 2h | T5.2, T2.2 |

**Total: 5 SP / 10h**

### SC-E6: Experience Database (3 SP / 6h)

| ID | Tarea | SP | Horas | Deps |
|---|---|---|---|---|
| SC-T6.1 | Setup SQLite + schema versionado | 2 | 4h | - |
| SC-T6.2 | Backup/restore de memoria | 1 | 2h | T6.1 |

**Total: 3 SP / 6h**

### SC-E7: Success Metrics + Failure Analysis (5 SP / 10h)

| ID | Tarea | SP | Horas | Deps |
|---|---|---|---|---|
| SC-T7.1 | `Get-HermesSuccessMetrics` | 2 | 4h | T6.1 |
| SC-T7.2 | `Analyze-HermesFailure` | 2 | 4h | T1.2 |
| SC-T7.3 | Failure frequency counters | 1 | 2h | T7.2 |

**Total: 5 SP / 10h**

### SC-E8: Continuous Improvement (4 SP / 8h)

| ID | Tarea | SP | Horas | Deps |
|---|---|---|---|---|
| SC-T8.1 | Búsqueda de lecciones aplicables | 2 | 4h | T2.2 |
| SC-T8.2 | Ajuste de defaults basado en lecciones | 1 | 2h | T8.1 |
| SC-T8.3 | Tracking de aceptación de sugerencias | 1 | 2h | T8.2 |

**Total: 4 SP / 8h**

### SC-E9: Memory Lifecycle (3 SP / 6h)

| ID | Tarea | SP | Horas | Deps |
|---|---|---|---|---|
| SC-T9.1 | `Invoke-HermesMemoryMaintenance` | 2 | 4h | T6.1 |
| SC-T9.2 | Estadísticas de lifecycle | 1 | 2h | T9.1 |

**Total: 3 SP / 6h**

### SC-E10: Knowledge Graph (3 SP / 6h)

| ID | Tarea | SP | Horas | Deps |
|---|---|---|---|---|
| SC-T10.1 | `Get-HermesKnowledgeGraph` | 2 | 4h | T2.2 |
| SC-T10.2 | Visualización en Mermaid | 1 | 2h | T10.1 |

**Total: 3 SP / 6h**

---

## 7. Resumen Story Points

| Épica | SP | Horas | % |
|---|---:|---:|---:|
| SC-E1: Learning Engine | 8 | 16h | 18% |
| SC-E2: Knowledge Base | 5 | 10h | 11% |
| SC-E3: Decision Memory | 3 | 6h | 7% |
| SC-E4: Pattern Recognition | 6 | 12h | 13% |
| SC-E5: Lessons Learned | 5 | 10h | 11% |
| SC-E6: Experience Database | 3 | 6h | 7% |
| SC-E7: Metrics + Failure | 5 | 10h | 11% |
| SC-E8: Continuous Improvement | 4 | 8h | 9% |
| SC-E9: Lifecycle Manager | 3 | 6h | 7% |
| SC-E10: Knowledge Graph | 3 | 6h | 7% |
| **TOTAL** | **45** | **90h** | **100%** |

---

## 8. Cronograma (8 Semanas)

### Semanas 1-2: Foundation
- Experience Database schema + SQLite (T6.1, T6.2)
- Knowledge Base schema + queries (T2.1, T2.2, T2.3)
- Learning Engine core (T1.1, T1.2)

### Semanas 3-4: Core Features
- Decision Memory (T3.1, T3.2)
- Lessons Learned + Post-Mortem (T5.1, T5.2, T5.3)
- Learning Engine scoring (T1.3, T1.4)

### Semanas 5-6: Advanced Features
- Pattern Recognition (T4.1, T4.2, T4.3)
- Success Metrics + Failure Analysis (T7.1, T7.2, T7.3)
- Memory Lifecycle Manager (T9.1, T9.2)

### Semanas 7-8: Orchestration
- Continuous Improvement (T8.1, T8.2, T8.3)
- Knowledge Graph + Mermaid viz (T10.1, T10.2)
- Integración con Sprint A (recovery usa lessons) y Sprint B (Project Generator usa patterns)
- Pruebas de integración completas
- Performance optimization
- Documentación final
- Demo + Sprint Review

---

## 9. Dependencies

| Tipo | Dependencia | Estado |
|---|---|---|
| Externa | Sprint A (Safe Sandbox para recuperación) | Prerequisito |
| Externa | Sprint B (Project Generator provee ejecuciones) | Prerequisito |
| Externa | SQLite (librería disponible en Windows) | Verificar |
| Externa | PowerShell 7.4+ | Existente |
| Interna | Experience Database (T6.1) es prerequisito de todo | Crítico path |
| Interna | Learning Engine alimenta a todos los demás motores | Crítico path |

**Critical Path:** T6.1 → T2.1 → T1.1/T2.2 → T1.2/T2.3/T3.1 → T4.1/T5.1/T7.1 → T8.1/T10.1

---

## 10. Definición de Done

### Por Historia
- ✅ Feature implementada
- ✅ Pruebas unitarias pasan
- ✅ Documentación de API pública incluida
- ✅ Datos de prueba en fixtures

### Del Sprint
- ✅ Learning Engine opera en cada ejecución
- ✅ Knowledge Base tiene queries funcionales con relevancia
- ✅ Decision Memory registra y consulta decisiones
- ✅ Pattern Recognition detecta escenarios tras 3 usos
- ✅ Post-Mortem genera lecciones automáticas en fallos
- ✅ Experience Database persistente y versionada
- ✅ Metrics dashboard muestra tendencias
- ✅ Failure Analysis categoriza correctamente
- ✅ Continuous Improvement aplica lecciones automáticamente
- ✅ Memory Lifecycle ejecuta transiciones correctamente
- ✅ Knowledge Graph muestra relaciones en Mermaid
- ✅ Performance overhead < 5% del tiempo de ejecución
- ✅ Zero data loss en migration de schema
- ✅ Coverage ≥ 80% en componentes del sprint

### Integración
- ✅ Sprint B usa patterns para sugerir opciones
- ✅ Sprint A usa lecciones para recovery inteligente
- ✅ Memory se exporta/importa entre usuarios
- ✅ Memory no contamina entre proyectos no relacionados

---

## 11. Riesgos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Memory DB crece sin control | Media | Alto | Lifecycle manager + auto-archive + size caps |
| Pattern recognition con falsos positivos | Alta | Medio | Score mínimo 0.7 + feedback negativo del usuario |
| Performance degradation con memoria grande | Alta | Alto | Indexación + caching en memoria + pagination |
| Lecciones obsoletas aplicarse incorrectamente | Media | Crítico | Confidence decay + auto-invalidation |
| Dificultad para extraer lecciones del contexto | Media | Alto | Hooks explícitos en ExecutionSupervisor + Sandbox |
| Complejidad cognitiva del knowledge graph | Media | Bajo | Visualización + queries con límites |
| SQL injection en queries | Baja | Alto | Parameterized queries + validación |

---

## 12. Decisiones de Diseño

### D-SC-01: Storage Backend
**Opciones:**
- A: JSON files (simple, legible, lento en queries)
- B: SQLite (rápido, robusto, requiere DLL)
- C: In-memory + JSON dump al cierre (rápido, riesgo de pérdida)

**Decisión:** SQLite (B)
**Justificación:** Balance performance/robustez. SQLite en Windows via `System.Data.SQLite` es nativo. Fallback a JSON para portabilidad si falla la DLL.

### D-SC-02: Algoritmo de Pattern Recognition
**Opciones:**
- A: Clustering por tags (rápido, preciso)
- B: Embeddings + cosine similarity (flexible, caro)
- C: Reglas explícitas (determinista, requiere mantenimiento)

**Decisión:** A + C hibridado. Tags + reglas heurísticas para casos claros, cosine fallback si disponible.

### D-SC-03: Confidence Scoring
**Decisión:** Score = (éxitos / usos totales) × factor de recencia
**Fórmula:** `confidence = (successes/occurrences) * exp(-days_since_last_use / 180)`
**Justificación:** Memoria reciente y exitosa tiene prioridad

---

## 13. Equipo

| Rol | Responsabilidad | Carga |
|---|---|---|
| Chief Architect | Diseño esquema + knowledge graph | 30% |
| Enterprise Engineer | Learning Engine core + integración | 100% |
| Senior Eng (x2) | Motores específicos en paralelo | 100% + 75% |
| QA Lead | Suite de tests + fixtures | 50% |
| Product Owner | Aceptación + prioridades | 15% |

---

## 14. Criterios de Éxito

### Funcionales
- [ ] Cada ejecución genera al menos 1 lección en memoria
- [ ] Knowledge Base responde queries en < 500ms
- [ ] Patterns detectados son aplicables > 60% del tiempo
- [ ] Post-mortem genera lecciones útiles en < 10 segundos

### Cuantitativos
- [ ] Tasa de reducción de errores recurrentes ≥ 40% (mes 3 vs mes 1)
- [ ] Performance overhead < 5%
- [ ] Memory DB < 500MB por usuario
- [ ] Coverage ≥ 80%

### Cualitativos
- [ ] Hermes "aprende" de verdad entre sesiones
- [ ] Sugerencias son contextualmente relevantes
- [ ] Memory lifecycle auto-gestiona sin intervención
- [ ] Visualización del knowledge graph es útil

---

## 15. Roadmap Post-Sprint C

Después del Sprint C, Hermes tendrá:
- Sandbox seguro (A)
- Generador profesional (B)
- Memoria persistente (C)

**Próximos sprints sugeridos:**
- Sprint D: Provider Framework real (Azure AI Foundry integration)
- Sprint E: Plugin Marketplace (distribución y descubrimiento)
- Sprint F: Multi-tenant support (compartir memoria entre equipos)

---

*Documento de Diseño — Sprint C: Memoria y Aprendizaje*
*Versión 1.0.0 — 2026-07-07*
*HERMES-ENTERPRISE Roadmap*
