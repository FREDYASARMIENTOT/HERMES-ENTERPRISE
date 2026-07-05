# Roadmap Evolutivo Incremental HERMES-ENTERPRISE

| Campo | Valor |
|---|---|
| NombreDocumento | Roadmap Evolutivo Incremental |
| Proyecto | HERMES-ENTERPRISE |
| AutorPrincipal | Fredy Alejandro Sarmiento Torres |
| Estado | Borrador operativo controlado |
| Proposito | Definir la evolución incremental del proyecto sin rediseñar la arquitectura base |
| LineaBase | Arquitectura construida hasta Fase 0.5 |

---

## 1. Propósito del documento

Este documento convierte el texto pegado por el usuario en un prompt maestro operativo para HERMES-ENTERPRISE.

Su objetivo no es iniciar inmediatamente las fases 1 a 6, sino fijar reglas de ejecución para que cada fase crezca de forma incremental, verificable y sin desbordar memoria, contexto, tiempo ni alcance.

Regla central:

> HERMES-ENTERPRISE debe evolucionar como plataforma Enterprise real: incrementos pequeños, compatibles, documentados, probados y fáciles de continuar.

---

## 2. Texto base pegado por el usuario

```text
# HERMES-ENTERPRISE
# Roadmap Evolutivo Incremental
# Arquitectura Enterprise
# Autor: Fredy Alejandro Sarmiento Torres

A partir del estado actual del repositorio NO debes rediseñar la arquitectura existente.

La arquitectura construida hasta la Fase 0.5 constituye la línea base oficial del proyecto.

Todos los cambios deberán cumplir estrictamente estas reglas:

• No romper compatibilidad.
• No eliminar módulos existentes.
• No renombrar directorios.
• No cambiar la estructura del Kernel.
• No modificar contratos públicos.
• Toda mejora debe ser incremental.
• Toda mejora debe incluir documentación.
• Toda mejora debe incluir pruebas.
• Todo nuevo componente deberá registrarse automáticamente.
• Mantener la nomenclatura del proyecto:
      objetos en español,
      nombres largos,
      altamente descriptivos,
      comentarios extremadamente detallados.

Cada fase deberá terminar con:

✓ Código
✓ Documentación
✓ Tests
✓ Commit
✓ Actualización del CHANGELOG
✓ Actualización del SRS
✓ Actualización de la Arquitectura

Desarrollar las siguientes fases.

FASE 1: Observabilidad del Kernel.
FASE 2: Robustez del sistema de plugins.
FASE 3: Infraestructura de proveedores.
FASE 4: Integración base con Azure AI Foundry.
FASE 5: Automatización y calidad de la documentación.
FASE 6: Primer servicio de IA completamente funcional.
```

---

## 3. Ajuste obligatorio al modo de trabajo del agente

A partir de este roadmap, Hermes no debe trabajar en modo masivo.

Queda prohibido el patrón:

```text
Fase completa
↓
Leer todo el repositorio
↓
Modificar muchos módulos
↓
Regenerar toda la documentación
↓
Ejecutar toda la suite
↓
Generar diff enorme
```

El patrón obligatorio será:

```text
Fase
↓
Subfase pequeña
↓
Matriz de impacto
↓
Lectura focalizada
↓
Cambio incremental
↓
Pruebas focalizadas
↓
Documentación focalizada
↓
Punto de parada
↓
Confirmación del usuario
```

---

## 4. Presupuesto máximo por subtarea

Cada subtarea debe detenerse cuando ocurra cualquiera de estas condiciones:

| Límite | Valor máximo | Acción |
|---|---:|---|
| Tiempo transcurrido | 5 minutos | STOP obligatorio |
| Archivos modificados | 15 archivos | STOP obligatorio |
| Módulos afectados | 3 módulos | STOP obligatorio |
| Líneas modificadas aproximadas | 1000 líneas | STOP obligatorio |
| Intentos sobre el mismo error | 3 intentos | STOP y diagnóstico |
| Contexto conversacional | 60 % | STOP, resumen técnico y nueva sesión recomendada |
| Comando sin progreso claro | 5 minutos | Cancelar o pedir autorización |

Si una subtarea se desproporciona, Hermes debe parar antes de seguir.

Mensaje obligatorio:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PUNTO DE PARADA OBLIGATORIO

Motivo:
- Tiempo superior a 5 minutos, o
- Más de 15 archivos, o
- Más de 3 módulos, o
- Más de 1000 líneas, o
- Riesgo de desbordamiento de contexto.

Estado actual:
- Código:
- Tests:
- Documentación:
- Archivos modificados:
- Tiempo invertido:

Siguiente acción propuesta:

¿Continuar?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 5. Reglas de lectura y contexto

Antes de leer archivos, Hermes debe construir una matriz de impacto.

Formato obligatorio:

| Subfase | Módulos impactados | Archivos a leer | Tests previstos | Docs previstas |
|---|---|---|---|---|
| 1.1 Health Monitor | kernel, runtime, logging | rutas exactas | pruebas exactas | docs exactas |

Reglas:

1. No usar búsquedas globales amplias salvo para localizar archivos puntuales.
2. No leer todo el repositorio.
3. No abrir archivos no relacionados con la matriz de impacto.
4. No regenerar todos los documentos si solo cambió uno.
5. No ejecutar toda la suite en cada subtarea.
6. Ejecutar la suite completa solo al cierre de fase.
7. Si hace falta ampliar el impacto, documentarlo y parar si supera límites.

---

## 6. Prompt maestro operativo optimizado

```text
Eres Hermes trabajando dentro del repositorio HERMES-ENTERPRISE.

Objetivo:
Evolucionar la arquitectura de forma incremental, sin rediseñar ni romper la línea base oficial construida hasta la Fase 0.5.

Reglas arquitectónicas obligatorias:
- No romper compatibilidad.
- No eliminar módulos existentes.
- No renombrar directorios.
- No cambiar la estructura pública del Kernel.
- No modificar contratos públicos sin fase explícita y migración documentada.
- No agregar IA antes de la fase indicada.
- No hacer refactorizaciones masivas.
- Toda mejora debe extender, no reemplazar.
- Todo nuevo componente debe registrarse automáticamente cuando aplique.
- Mantener nombres largos, descriptivos y en español para objetos del dominio.
- Mantener comentarios técnicos detallados en PowerShell Enterprise.

Reglas operativas anti-desborde:
- Dividir cada fase en subfases de máximo 5 minutos.
- Antes de tocar código, generar matriz de impacto.
- Leer únicamente archivos de la matriz de impacto.
- Modificar máximo 15 archivos por subtarea.
- Afectar máximo 3 módulos por subtarea.
- Modificar máximo 1000 líneas por subtarea.
- Ejecutar pruebas focalizadas por subtarea.
- Regenerar solo documentación afectada cuando sea posible.
- Ejecutar suite completa únicamente al cierre de fase.
- Si una subtarea supera límites, detenerse y pedir autorización.
- Si el contexto supera 60 %, generar resumen técnico y recomendar nueva sesión.

Cierre de cada subfase:
- Código ejecutable.
- Pruebas focalizadas ejecutadas.
- Documentación afectada actualizada.
- Reporte de archivos modificados.
- Punto de parada antes de continuar.

Cierre de cada fase:
- Código completo de la fase.
- Documentación actualizada.
- Tests focalizados y suite completa OK.
- CHANGELOG actualizado.
- SRS actualizado.
- Arquitectura actualizada.
- Commit atómico con Conventional Commit.
- Repositorio limpio o estado explicado.
```

---

## 7. Descomposición por fases y subfases

### Fase 1: Observabilidad del Kernel

Objetivo: fortalecer el Kernel sin agregar IA.

Capacidades:

1. Health Monitor del Kernel.
2. Métricas internas del Kernel.

Subfases obligatorias:

| Subfase | Objetivo | Punto de parada |
|---|---|---|
| 1.1 | Matriz de impacto y prueba inicial de Health Monitor | Antes de implementar producción |
| 1.2 | Implementar Get-HermesEnterpriseKernelHealth | Después de pruebas focalizadas |
| 1.3 | Agregar métricas internas mínimas | Después de validar Logger |
| 1.4 | Documentar Kernel Health y Metrics | Después de regenerar docs afectadas |
| 1.5 | Ejecutar suite completa y commit | Cierre de fase |

Resultado esperado:

```text
Kernel Enterprise
        │
        ├── Runtime
        ├── Logger
        ├── Metrics
        ├── Health
        └── EventBus
```

### Fase 2: Robustez del sistema de plugins

Objetivo: fortalecer plugins sin detener el Kernel ante fallos aislados.

Capacidades:

1. Versionado semántico de plugins.
2. Plugin Sandbox con recuperación.

Subfases obligatorias:

| Subfase | Objetivo | Punto de parada |
|---|---|---|
| 2.1 | Matriz de impacto del sistema de plugins | Antes de modificar contratos |
| 2.2 | SemVer Major/Minor/Patch y validación focalizada | Después de pruebas de compatibilidad |
| 2.3 | Sandbox inicial para aislamiento de errores | Después de prueba con plugin fallido |
| 2.4 | Documentación de sandbox y recovery | Antes de suite completa |
| 2.5 | Suite completa y commit | Cierre de fase |

Resultado esperado:

```text
PluginManager
↓
Sandbox
↓
Lifecycle
↓
Recovery
```

### Fase 3: Provider Framework Enterprise

Objetivo: construir infraestructura de providers sin implementar Azure real.

Capacidades:

1. ProviderFactory.
2. ProviderPool con prioridad y failover.

Subfases obligatorias:

| Subfase | Objetivo | Punto de parada |
|---|---|---|
| 3.1 | Matriz de impacto Provider Registry / Factory | Antes de crear nuevos componentes |
| 3.2 | ProviderFactory con providers abstractos/mock | Después de pruebas unitarias |
| 3.3 | ProviderPool con principal, respaldo, prioridad y estado | Después de prueba de failover |
| 3.4 | Documentación Provider Framework | Antes de suite completa |
| 3.5 | Suite completa y commit | Cierre de fase |

Resultado esperado:

```text
Kernel
↓
Provider Registry
↓
Provider Factory
↓
Provider Pool
```

### Fase 4: Infraestructura para Azure AI Foundry

Objetivo: preparar Azure sin lógica de negocio.

Capacidades:

1. Azure Provider Base.
2. Configuration Binding desde archivos JSON.

Subfases obligatorias:

| Subfase | Objetivo | Punto de parada |
|---|---|---|
| 4.1 | Matriz de impacto configuración/providers | Antes de crear Azure base |
| 4.2 | Azure Provider Base sin llamadas reales | Después de tests de construcción |
| 4.3 | Binding desde configuracion/providers.json | Después de tests sin valores hardcoded |
| 4.4 | Documentación Azure base y configuración | Antes de suite completa |
| 4.5 | Suite completa y commit | Cierre de fase |

Resultado esperado:

```text
Configuration
↓
Azure Provider
↓
Deployment Resolver
```

### Fase 5: Motor Enterprise de Documentación

Objetivo: fortalecer automatización y validación documental.

Capacidades:

1. Soporte documental para Mermaid, tablas, diagramas, referencias e índices.
2. Documentation Validator.

Subfases obligatorias:

| Subfase | Objetivo | Punto de parada |
|---|---|---|
| 5.1 | Matriz de impacto del motor documental | Antes de tocar builder |
| 5.2 | Extender plantillas/utilidades sin romper documentos actuales | Después de pruebas del builder |
| 5.3 | Documentation Validator para links, archivos, diagramas, metadatos | Después de prueba focalizada |
| 5.4 | Documentar validator y flujo antes de commit | Antes de suite completa |
| 5.5 | Suite completa y commit | Cierre de fase |

Resultado esperado:

```text
Template Engine
↓
Builder
↓
Validator
↓
Documentation
```

### Fase 6: Primer proveedor funcional Azure AI Foundry

Objetivo: iniciar IA real usando la infraestructura previa.

Capacidades:

1. AzureFoundryProvider funcional.
2. HermesAIService como fachada oficial.

Subfases obligatorias:

| Subfase | Objetivo | Punto de parada |
|---|---|---|
| 6.1 | Matriz de impacto IA / ProviderPool / configuración | Antes de llamadas reales |
| 6.2 | AzureFoundryProvider Chat/Responses mínimo | Después de tests mockeados |
| 6.3 | Streaming, Embeddings, Vision y Tool Calling por incrementos separados | STOP por capacidad si supera 5 min |
| 6.4 | HermesAIService como única fachada oficial | Después de pruebas de fachada |
| 6.5 | Documentación, suite completa y commit | Cierre de fase |

Resultado esperado:

```text
Kernel
↓
HermesAIService
↓
Provider Pool
↓
Azure Provider
↓
Azure AI Foundry
```

---

## 8. Criterios de aceptación por fase

Una fase solo puede declararse completada si cumple:

- El proyecto compila y ejecuta sin errores.
- Los módulos existentes permanecen compatibles.
- Solo se agregaron capacidades incrementales.
- Cada nuevo componente queda registrado en el Kernel o gestor correspondiente.
- Existen pruebas unitarias para la nueva funcionalidad.
- La documentación afectada está actualizada.
- CHANGELOG está actualizado.
- SRS está actualizado.
- Arquitectura está actualizada.
- Existe commit atómico con Conventional Commit.
- El repositorio queda listo para continuar sin refactorización masiva.

---

## 9. Reporte obligatorio al cerrar una subtarea

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUBFASE COMPLETADA

Subfase:
Objetivo:

Estado:
✔ Código:
✔ Tests:
✔ Documentación:

Archivos modificados:
- 

Pruebas ejecutadas:
- 

Tiempo invertido:

Límites:
- Tiempo <= 5 min:
- Archivos <= 15:
- Módulos <= 3:
- Líneas <= 1000:

Siguiente subtarea propuesta:

¿Continuar?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 10. Regla de arranque para la próxima sesión o turno

La próxima ejecución de desarrollo no debe intentar implementar las fases 1 a 6 completas.

Debe comenzar únicamente con:

```text
FASE 1.1: Matriz de impacto y prueba inicial de Health Monitor del Kernel.
```

Al completar Fase 1.1, Hermes debe detenerse y pedir autorización antes de continuar con Fase 1.2.
