---
title: "Registro de Riesgos"
document: "HERMES Enterprise - Risk Register"
date: 2026-07-07
status: DRAFT
version: "1.0"
author: "Equipo HERMES Enterprise"
total_risks: 20
active_risks: 20
mitigated_risks: 0
cross_references:
  - "01_PROJECT_CHARTER.md"
  - "02_VISION_SCOPE.md"
  - "03_ARCHITECTURE.md"
  - "04_ROADMAP.md"
  - "05_SPRINT_D.md"
  - "07_BACKLOG.md"
  - "10_ACCEPTANCE_PLAN.md"
---

# Registro de Riesgos - HERMES Enterprise

## Navegación

| Documento Anterior | Índice General | Documento Siguiente |
|---|---|---|
| [07_BACKLOG.md](07_BACKLOG.md) | [04_ROADMAP.md](04_ROADMAP.md) | [10_ACCEPTANCE_PLAN.md](10_ACCEPTANCE_PLAN.md) |

---

## 1. Resumen Ejecutivo

| Métrica | Valor |
|---|---|
| Total de Riesgos Identificados | 20 |
| Riesgos Críticos (Score ≥ 15) | 5 |
| Riesgos Altos (Score 10-14) | 6 |
| Riesgos Medios (Score 5-9) | 6 |
| Riesgos Bajos (Score 1-4) | 3 |
| Riesgo Máximo del Proyecto | 20 (R-003) |
| Riesgo Promedio | 8.7 |

---

## 2. Matriz de Riesgos - Top Summary

### 2.1 Matriz Impacto × Probabilidad

```
                    Probabilidad
              1(Baja)   2       3       4       5(Alta)
Impacto   ┌───────┬───────┬───────┬───────┬───────┐
5(Crit.) │       │       │ R-003 │ R-001 │ R-009 │
         │       │       │  [20] │  [15] │  [25] │
         ├───────┼───────┼───────┼───────┼───────┤
4(Alto)  │       │ R-012 │ R-005 │ R-007 │ R-006 │
         │       │  [8]  │  [12] │  [12] │  [16] │
         ├───────┼───────┼───────┼───────┼───────┤
3(Medio) │       │ R-013 │ R-002 │ R-008 │ R-004 │
         │       │  [6]  │  [6]  │  [9]  │  [12] │
         ├───────┼───────┼───────┼───────┼───────┤
2(Bajo)  │ R-014 │ R-011 │ R-015 │ R-016 │       │
         │  [2]  │  [4]  │  [6]  │  [8]  │       │
         ├───────┼───────┼───────┼───────┼───────┤
1(Mín.)  │ R-017 │ R-018 │       │       │       │
         │  [1]  │  [2]  │       │       │       │
         └───────┴───────┴───────┴───────┴───────┘
```

### 2.2 Top 5 Riesgos

| Rank | ID | Nombre | Score | Categoría |
|---|---|---|---|---|
| 1 | R-009 | Vendor Lock-in con AI providers | 25 | Técnico |
| 2 | R-003 | Complejidad de PowerShell multi-plataforma | 20 | Técnico |
| 3 | R-006 | Sobrecarga del Sprint D | 16 | Cronograma |
| 4 | R-001 | Fallo del sandbox de seguridad | 15 | Seguridad |
| 5 | R-007 | Resistencia organizacional al cambio | 12 | Organizacional |

---

## 3. Riesgos Técnicos

### R-001: Fallo del Sandbox de Seguridad

| Campo | Valor |
|---|---|
| **ID** | R-001 |
| **Nombre** | Fallo del sandbox de seguridad permite ejecución de código malicioso |
| **Categoría** | Seguridad |
| **Impacto** | 5 (Crítico) |
| **Probabilidad** | 3 (Media) |
| **Risk Score** | 15 (Alto) |
| **Owner** | Lead de Seguridad |
| **Trigger** | Un comando ejecutado en sandbox escapa del aislamiento o un usuario malintencionado crafts un payload que bypasea las restricciones |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Implementar doble capa de aislamiento (container + restricted token)
2. Pen testing trimestral del sandbox
3. Allow-list estricta de comandos permitidos
4. Monitoreo en tiempo real de todas las acciones del sandbox
5. Kill switch automático ante comportamiento sospechoso

**Plan de Contingencia (Plan B):**
- Desactivar ejecución automática inmediatamente
- Fallback a modo "solo sugerencias" sin ejecución real
- Auditoría forense completa del incidente
- Rollback a versión anterior estable del sandbox

---

### R-002: Performance Degradation con muchos plugins

| Campo | Valor |
|---|---|
| **ID** | R-002 |
| **Nombre** | Degradación significativa de performance con >20 plugins activos |
| **Categoría** | Técnico |
| **Impacto** | 3 (Medio) |
| **Probabilidad** | 3 (Media) |
| **Risk Score** | 9 (Medio) |
| **Owner** | Lead de Arquitectura |
| **Trigger** | Usuario instala >20 plugins simultáneamente y el tiempo de respuesta se degrada >3x |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Arquitectura de lazy-loading para plugins
2. Sistema de cache multi-nivel
3. Límite configurable de plugins simultáneos
4. Profiling continuo del runtime
5. Benchmark de performance en CI

**Plan de Contingencia (Plan B):**
- Implementar plugin sandbox aislado en proceso separado
- Auto-desactivación de plugins no usados en 30 días
- Modo seguro con <5 plugins críticos

---

### R-003: Complejidad de PowerShell Multi-Plataforma

| Campo | Valor |
|---|---|
| **ID** | R-003 |
| **Nombre** | Incompatibilidades de PowerShell entre Windows, macOS y Linux |
| **Categoría** | Técnico |
| **Impacto** | 5 (Crítico) |
| **Probabilidad** | 4 (Alta) |
| **Risk Score** | 20 (Crítico) |
| **Owner** | Lead de Desarrollo |
| **Trigger** | Funcionalidad crítica falla en alguna de las 3 plataformas soportadas durante testing |
| **Status** | Abierto |

**Plan de Mitigación:**
1. CI multi-platform obligatorio (GitHub Actions matrix)
2. Abstracción de APIs del sistema operativo
3. Tests de integración en las 3 plataformas
4. Documentación de diferencias conocidas
5. Wrapper layer para operaciones OS-specific

**Plan de Contingencia (Plan B):**
- Soporte oficial solo para Windows como primary platform
- macOS/Linux como "experimental" hasta estabilizar
- Considerar reescritura de módulos problemáticos en .NET puro

---

### R-004: Integration Failures con AI Model Updates

| Campo | Valor |
|---|---|
| **ID** | R-004 |
| **Nombre** | Cambios breaking en APIs de AI providers rompen funcionalidad |
| **Categoría** | Técnico |
| **Impacto** | 3 (Medio) |
| **Probabilidad** | 3 (Media) |
| **Risk Score** | 9 (Medio) |
| **Owner** | Lead de Integraciones |
| **Trigger** | Un provider de AI cambia su API, depreca un endpoint, o cambia el formato de respuesta |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Abstract interfaces con versionado explícito
2. Version pinning en configuraciones de provider
3. Automated testing contra todos los providers
4. Monitoring de changelogs de APIs
5. Circuit breakers con graceful degradation

**Plan de Contingencia (Plan B):**
- Fallback automático a provider alternativo
- Modo offline con capacidades locales
- Cache de última respuesta válida

---

## 4. Riesgos de Cronograma

### R-005: Subestimación de Complejidad en Self Evolution

| Campo | Valor |
|---|---|
| **ID** | R-005 |
| **Nombre** | Self Evolution Framework resulta mucho más complejo de lo planificado |
| **Categoría** | Cronograma |
| **Impacto** | 4 (Alto) |
| **Probabilidad** | 3 (Media) |
| **Risk Score** | 12 (Alto) |
| **Owner** | Product Owner |
| **Trigger** | Sprint 1 de D muestra que la velocidad en Self Evolution es <50% de lo planificado |
| **Status** | Abierto |

**Plan de Mitigación:**
1. MVP simplificado: solo métricas + reportes, sin auto-optimización
2. Spike técnico de 1 semana antes de comprometer implementación full
3. Consultar con expertos externos en ML/evolución de sistemas

**Plan de Contingencia (Plan B):**
- Reducir Self Evolution a "manual tuning dashboard"
- Deferir auto-optimización a versión 2.0
- Subcontratar componente específica

---

### R-006: Sobrecarga del Sprint D (55 SP en D5)

| Campo | Valor |
|---|---|
| **ID** | R-006 |
| **Nombre** | Sprint D5 planificado con 55 SP excede capacidad del equipo |
| **Categoría** | Cronograma |
| **Impacto** | 4 (Alto) |
| **Probabilidad** | 4 (Alta) |
| **Risk Score** | 16 (Crítico) |
| **Owner** | Scrum Master |
| **Trigger** | Velocity tracking muestra que en Sprints D1-D4 no se alcanza 40 SP |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Re-planificar para extender Sprint D a 12 semanas
2. Mover 2-3 items de D5 al backlog extendido
3. Contratar 1-2 contractors temporales
4. Reducir scope de items complejos a MVP

**Plan de Contingencia (Plan B):**
- Priorizar solo P0 y P1 del Sprint D
- Release parcial con funcionalidad core de plataforma
- Items P2/P2 pospuestos a fase de mantenimiento

---

### R-007: Resistencia Organizacional al Cambio

| Campo | Valor |
|---|---|
| **ID** | R-007 |
| **Nombre** | Equipos se resisten a adoptar Hermes como herramienta estándar |
| **Categoría** | Organizacional |
| **Impacto** | 4 (Alto) |
| **Probabilidad** | 3 (Media) |
| **Risk Score** | 12 (Alto) |
| **Owner** | Change Manager |
| **Trigger** | <30% de adopción tras 2 meses de disponibilidad en equipo piloto |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Programa de champions en cada equipo
2. Onboarding guiado con soporte dedicado
3. Quick wins demostrables en las primeras 2 semanas
4. Executive sponsorship visible
5. Gamificación de adopción

**Plan de Contingencia (Plan B):**
- Hacer Hermes opt-in con casos de uso claros
- Focar en team que tenga más pain points
- Presentar ROI medible a leadership

---

### R-016: Demo Stakeholders sin features mínimas

| Campo | Valor |
|---|---|
| **ID** | R-016 |
| **Nombre** | Demo planificada con stakeholders sin features core implementadas |
| **Categoría** | Cronograma |
| **Impacto** | 2 (Bajo) |
| **Probabilidad** | 4 (Alta) |
| **Risk Score** | 8 (Medio) |
| **Owner** | Product Owner |
| **Trigger** | A 2 semanas de la demo, items P0 del sprint no están en status "Done" |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Feature freeze 1 semana antes de demo
2. Demo script pre-preparado con fallback paths
3. Buffer de 1 semana de contingencia post-desarrollo
4. Demo parcial con focus en lo que SÍ funciona

**Plan de Contingencia (Plan B):**
- Demo de conceptos con mockups/wireframes
- Postergar demo 1-2 semanas con comunicación transparente
- Re-enfocar demo en visión más que en funcionalidad

---

## 5. Riesgos de Recursos

### R-008: Pérdida de Desarrolladores Clave

| Campo | Valor |
|---|---|
| **ID** | R-008 |
| **Nombre** | Desarrolladores clave dejan el proyecto (baja rotación) |
| **Categoría** | Recurso |
| **Impacto** | 3 (Medio) |
| **Probabilidad** | 3 (Media) |
| **Risk Score** | 9 (Medio) |
| **Owner** | Engineering Manager |
| **Trigger** | Renuncia de >1 desarrollador con conocimiento crítico no compartido |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Pair programming obligatorio en módulos críticos
2. Documentación técnica obligatoria (ADR por componente)
3. Knowledge sharing sessions quincenales
4. Bus factor ≥ 2 para cada módulo
5. Cross-training rotativo

**Plan de Contingencia (Plan B):**
- Contractor temporal para remplazar velocidad perdida
- Re-priorizar backlog para minimizar impacto
- Redistribution de tareas con sobre-exposición controlada

---

### R-011: Falta de Expertise en DDD/Microservices

| Campo | Valor |
|---|---|
| **ID** | R-011 |
| **Nombre** | Equipo no tiene suficiente expertise en DDD y microservicios |
| **Categoría** | Recurso |
| **Impacto** | 2 (Bajo) |
| **Probabilidad** | 2 (Baja) |
| **Risk Score** | 4 (Bajo) |
| **Owner** | Tech Lead |
| **Trigger** | Retrospectiva de Sprint D2 muestra dificultades recurrentes con patrones DDD |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Workshops de DDD antes de Sprint D
2. Consultoría externa para diseño inicial
3. Templates y ejemplos bien documentados
4. Guild/MoT para DDD interno

**Plan de Contingencia (Plan B):**
- Simplificar implementación de DDD (no purista)
- Contratar experto DDD temporal
- Adoptar enfoque CRUD con modularización en lugar de DDD completo

---

## 6. Riesgos de Calidad

### R-009: Vendor Lock-in con AI Providers

| Campo | Valor |
|---|---|
| **ID** | R-009 |
| **Nombre** | Dependencia excesiva de un solo AI provider crea vendor lock-in |
| **Categoría** | Técnico |
| **Impacto** | 5 (Crítico) |
| **Probabilidad** | 5 (Muy Alta) |
| **Risk Score** | 25 (Crítico) |
| **Owner** | Lead de Arquitectura |
| **Trigger** | >70% de las capacidades de AI dependen de un solo provider |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Abstract provider interface desde día 1
2. Soporte mínimo para 3 providers de AI simultáneos
3. Modelo de datos agnóstico al provider
4. Tests de integración con cada provider
5. Plan de escape documentado por provider

**Plan de Contingencia (Plan B):**
- Migración inmediata a provider secundario si el primario falla
- Soporte local (Ollama, llama.cpp) como fallback
- Modelo propio fine-tuned para funcionalidad crítica
- Implementar caching para reducir dependencia de API calls

---

### R-010: Deuda Técnica Acumulada en Sprint A

| Campo | Valor |
|---|---|
| **ID** | R-010 |
| **Nombre** | Sprint A de recovery acumula deuda técnica que impacta sprints posteriores |
| **Categoría** | Calidad |
| **Impacto** | 3 (Medio) |
| **Probabilidad** | 3 (Media) |
| **Risk Score** | 9 (Medio) |
| **Owner** | Tech Lead |
| **Trigger** | Code review muestra >20% de código sin tests o con debt markers |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Definir definición de done que incluya tests obligatorios
2. Tech debt budget del 20% en cada sprint
3. Static analysis en CI pipeline
4. Refactoring sprints periódicos
5. Code review obligatorio con enfoque en calidad

**Plan de Contingencia (Plan B):**
- Sprint de estabilización entre C y D
- Reducir scope para mejorar calidad
- Contratar consultor de calidad externa

---

## 7. Riesgos de Seguridad

### R-012: Exposición de Secrets en Logs o Config

| Campo | Valor |
|---|---|
| **ID** | R-012 |
| **Nombre** | Secrets (API keys, tokens) se exponen accidentalmente en logs o archivos |
| **Categoría** | Seguridad |
| **Impacto** | 4 (Alto) |
| **Probabilidad** | 2 (Baja) |
| **Risk Score** | 8 (Medio) |
| **Owner** | Lead de Seguridad |
| **Trigger** | Auditoría encuentra secrets en logs plaintext o repos |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Secret scanning en CI (GitLeaks, TruffleHog)
2. Encriptación de secrets en config con keychain/credential manager
3. Log masking automático de patrones sensibles
4. .gitignore exhaustivo con templates
5. Vault/key management desde día 1

**Plan de Contingencia (Plan B):**
- Rotación inmediata de todos los secrets expuestos
- Auditoría de acceso y blast radius
- Comunicación a stakeholders si hay datos personales afectados

---

### R-013: Supply Chain Attack vía Plugins

| Campo | Valor |
|---|---|
| **ID** | R-013 |
| **Nombre** | Plugin malicioso del marketplace compromete el sistema |
| **Categoría** | Seguridad |
| **Impacto** | 3 (Medio) |
| **Probabilidad** | 2 (Baja) |
| **Risk Score** | 6 (Medio) |
| **Owner** | Lead de Seguridad |
| **Trigger** | Plugin publicado en marketplace contiene código malicioso o dependencias vulnerables |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Sandboxing aislado para cada plugin
2. Code scanning y dependencia audit antes de publicación
3. Revisión manual de plugins nuevos
4. Sistema de reputación y ratings
5. Auto-update con rollback capability

**Plan de Contingencia (Plan B):**
- Despublicación inmediata del plugin comprometido
- Scan de todos los usuarios del plugin
- Security advisory público

---

## 8. Riesgos de Integración

### R-014: Incompatibilidad con Herramientas Legacy

| Campo | Valor |
|---|---|
| **ID** | R-014 |
| **Nombre** | Integración con herramientas legacy de la organización falla |
| **Categoría** | Integración |
| **Impacto** | 2 (Bajo) |
| **Probabilidad** | 1 (Muy Baja) |
| **Risk Score** | 2 (Bajo) |
| **Owner** | Lead de Integraciones |
| **Trigger** | APIs legacy no siguen patrones modernos (SOAP, formatos propietarios) |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Discovery completo de integraciones necesarias antes de Sprint A
2. Adapter pattern para sistemas legacy
3. Documentación de limitaciones conocidas
4. Prototipos de integración temprana

**Plan de Contingencia (Plan B):**
- Implementar integración manual/semi-automática
- Wrapper de legacy como API moderna
- Desestimar integración si el costo es demasiado alto

---

### R-015: Git Provider Migration Complexity

| Campo | Valor |
|---|---|
| **ID** | R-015 |
| **Nombre** | Migración entre Git providers (GitHub → GitLab, etc.) rompe funcionalidad |
| **Categoría** | Integración |
| **Impacto** | 3 (Medio) |
| **Probabilidad** | 2 (Baja) |
| **Risk Score** | 6 (Medio) |
| **Owner** | Lead de Integraciones |
| **Trigger** | Organización cambia de Git provider y las integraciones dejen de funcionar |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Abstract Git provider interface (Git abstraction layer)
2. Tests de integración con cada provider soportado
3. Documentación de migration guides
4. Configurable provider switching

**Plan de Contingencia (Plan B):**
- Herramientas de migración semi-automáticas
- Scripts de configuración para el nuevo provider
- Soporte temporal de ambos providers durante transición

---

## 9. Riesgos Organizacionales

### R-017: Falta de Sponsorship Ejecutivo Continuo

| Campo | Valor |
|---|---|
| **ID** | R-017 |
| **Nombre** | Sponsor ejecutivo pierde interés o cambia prioridades |
| **Categoría** | Organizacional |
| **Impacto** | 1 (Mínimo) |
| **Probabilidad** | 1 (Muy Baja) |
| **Risk Score** | 1 (Bajo) |
| **Owner** | Project Manager |
| **Trigger** | Cambio de liderazgo en la organización o re-direction estratégica |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Reportes mensuales de progreso al sponsor
2. Demo quincenal con métricas de negocio
3. Multi-sponsor (no depender de una sola persona)
4. Alinear roadmap con objetivos estratégicos de la empresa

**Plan de Contingencia (Plan B):**
- Presentar business case actualizado a nuevo sponsor
- Demostrar ROI tangible con pilotos existentes
- Buscar nuevo sponsor interno con casos de éxito

---

### R-018: Scope Creep por Feedback de Usuarios

| Campo | Valor |
|---|---|
| **ID** | R-018 |
| **Nombre** | Feedback de usuarios pilotos genera nuevos requests que desvían del plan |
| **Categoría** | Organizacional |
| **Impacto** | 1 (Mínimo) |
| **Probabilidad** | 2 (Baja) |
| **Risk Score** | 2 (Bajo) |
| **Owner** | Product Owner |
| **Trigger** | >5 requests "urgentes" de usuarios pilotos que no estaban en el backlog |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Proceso formal de intake de requests con priorización
2. Feedback loop estructurado (no ad-hoc)
3. Roadmap visible para que usuarios sepan qué esperar
4. Time-box para exploration de nuevas ideas

**Plan de Contingencia (Plan B):**
- Agregar al backlog extendido con prioridad realista
- Dedicar 10% de sprint capacity a requests urgentes
- Comunicar timeline ajustado honestamente

---

### R-019: Comunicación Deficiente entre Equipos

| Campo | Valor |
|---|---|
| **ID** | R-019 |
| **Nombre** | Malos entendidos entre dev, QA y producto causan re-work |
| **Categoría** | Organizacional |
| **Impacto** | 3 (Medio) |
| **Probabilidad** | 2 (Baja) |
| **Risk Score** | 6 (Medio) |
| **Owner** | Scrum Master |
| **Trigger** | Retrospectiva muestra >30% de tiempo perdido por malentendidos |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Three Amigos meetings para cada user story
2. Definition of Ready checklist obligatorio
3. Daily standups enfocados en blockers
4. Documentation as code (docs versionadas con código)

**Plan de Contingencia (Plan B):**
- Facilitator externo para resolution de conflicts
- Workshop de alignment de equipo
- Revisión de procesos de comunicazione

---

### R-020: Compliance y Regulación (Data Privacy)

| Campo | Valor |
|---|---|
| **ID** | R-020 |
| **Nombre** | Hermes procesa datos de clientes sin cumplir regulaciones (GDPR, etc.) |
| **Categoría** | Seguridad |
| **Impacto** | 5 (Crítico) |
| **Probabilidad** | 2 (Baja) |
| **Risk Score** | 10 (Alto) |
| **Owner** | Data Protection Officer |
| **Trigger** | Hermes accede a datos personales de clientes en repos o logs |
| **Status** | Abierto |

**Plan de Mitigación:**
1. Privacy by design en toda la arquitectura
2. Data classification y handling policies
3. Consent management para datos personales
4. Data retention policies automáticas
5. Legal review antes de features que toquen datos

**Plan de Contingencia (Plan B):**
- Desactivar la feature hasta cumplir compliance
- Anonimización automática de datos
- Consultar con legal y DPO para plan de remediación
- Reportar a autoridades si hay breach de datos

---

## 10. Tabla Resumen de Todos los Riesgos

| ID | Nombre | Categoría | Impacto | Prob. | Score | Owner | Status |
|---|---|---|---|---|---|---|---|
| R-001 | Fallo del sandbox de seguridad | Seguridad | 5 | 3 | 15 | Lead Seguridad | Abierto |
| R-002 | Performance con muchos plugins | Técnico | 3 | 3 | 9 | Lead Arquitectura | Abierto |
| R-003 | PowerShell multi-plataforma | Técnico | 5 | 4 | 20 | Lead Desarrollo | Abierto |
| R-004 | AI model updates breaking | Técnico | 3 | 3 | 9 | Lead Integraciones | Abierto |
| R-005 | Self Evolution complejo | Cronograma | 4 | 3 | 12 | Product Owner | Abierto |
| R-006 | Sobrecarga Sprint D | Cronograma | 4 | 4 | 16 | Scrum Master | Abierto |
| R-007 | Resistencia al cambio | Organizacional | 4 | 3 | 12 | Change Manager | Abierto |
| R-008 | Pérdida de dev clave | Recurso | 3 | 3 | 9 | Eng. Manager | Abierto |
| R-009 | Vendor lock-in AI | Técnico | 5 | 5 | 25 | Lead Arquitectura | Abierto |
| R-010 | Deuda técnica Sprint A | Calidad | 3 | 3 | 9 | Tech Lead | Abierto |
| R-011 | Falta expertise DDD | Recurso | 2 | 2 | 4 | Tech Lead | Abierto |
| R-012 | Secrets en logs/config | Seguridad | 4 | 2 | 8 | Lead Seguridad | Abierto |
| R-013 | Supply chain attack plugins | Seguridad | 3 | 2 | 6 | Lead Seguridad | Abierto |
| R-014 | Herramientas legacy | Integración | 2 | 1 | 2 | Lead Integraciones | Abierto |
| R-015 | Git provider migration | Integración | 3 | 2 | 6 | Lead Integraciones | Abierto |
| R-016 | Demo sin features | Cronograma | 2 | 4 | 8 | Product Owner | Abierto |
| R-017 | Falta sponsorship | Organizacional | 1 | 1 | 1 | Project Manager | Abierto |
| R-018 | Scope creep | Organizacional | 1 | 2 | 2 | Product Owner | Abierto |
| R-019 | Mala comunicación | Organizacional | 3 | 2 | 6 | Scrum Master | Abierto |
| R-020 | Compliance GDPR | Seguridad | 5 | 2 | 10 | DPO | Abierto |

---

## 11. Gestión de Riesgos por Sprint

| Sprint | Riesgos Principales | Mitigación Enfocada |
|---|---|---|
| Sprint A | R-001, R-003, R-010 | Sandbox robusto, CI multi-platform, quality gates |
| Sprint B | R-004, R-014, R-015 | Integration testing, adapter patterns, abstraction |
| Sprint C | R-005, R-008, R-010 | Spike pre-commitment, pair programming, refactoring |
| Sprint D | R-006, R-009, R-005 | Re-planificación, multi-provider, MVP simple |
| Post-D | R-007, R-016, R-017 | Change management, demos, stakeholder engagement |

---

## 12. Métricas de Seguimiento

### 12.1 KPIs de Gestión de Riesgos

| Métrica | Objetivo | Frecuencia |
|---|---|---|
| Riesgos activos | <15 abiertos al final de Sprint A | Semanal |
| Riesgos mitigados | ≥2 por sprint | Quincenal |
| Risk Score promedio | <8 al final del proyecto | Mensual |
| Riesgos materializados | <10% del total | Por sprint |
| Tiempo de respuesta a trigger | <48h desde detección | Por evento |

### 12.2 Risk Review Cadence

| Reunión | Attendees | Frecuencia |
|---|---|---|
| Risk Standup | Equipo técnico | Diario (5 min) |
| Risk Review | Equipo + PM | Quincenal (30 min) |
| Risk Board Review | Leadership | Mensual (1h) |
| Retrospective + Risks | Todo el equipo | Por sprint |

---

## Navegación Inferior

| Documento Anterior | Índice General | Documento Siguiente |
|---|---|---|
| [07_BACKLOG.md](07_BACKLOG.md) | [04_ROADMAP.md](04_ROADMAP.md) | [10_ACCEPTANCE_PLAN.md](10_ACCEPTANCE_PLAN.md) |

---

*Documento generado como parte del roadmap HERMES Enterprise. Status: DRAFT. Última actualización: 2026-07-07.*
