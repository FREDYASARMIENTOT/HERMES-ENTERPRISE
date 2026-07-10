# Fase 3.5C: Context Validation y BootstrapOrchestrator
## Guía de Continuación para Mañana

### Estado Actual (Post-Fase 3.5B)
- ✅ API Freeze completado (4 documentos generados)
- ✅ Namespace Cleanup completado (7 builders sin dependencias duplicadas)
- ✅ Helpers centralizados (6 archivos en motor/context/helpers/)
- ✅ Commit Fase 3.5B: `2a3e1ba`

### Próximos Pasos: Fase 3.5C

**Objetivo:** Validar que ContextEngine.ps1 orquesta correctamente los 7 builders y genera todos los artefactos esperados.

#### Tarea 1: Implementar ContextEngine.ps1 Orquestador
Ubicación: `motor/context/ContextEngine.ps1`

Debe:
- Cargar todos los helpers de `motor/context/helpers/`
- Cargar todos los builders de `motor/context/builders/`
- Ejecutar builders en orden correcto según PUBLIC_API.json
- Generar todos los artefactos en `.hermes/context/`:
  - CURRENT_STATE.md
  - NEXT_TASK.md
  - PROJECT_INDEX.json
  - WORKER_CONTEXT.json
  - CONTEXT_MANIFEST.json
  - SUMMARY.md
  - PROJECT_MEMORY.md

#### Tarea 2: Crear Test-ContextContracts.ps1
Ubicación: `pruebas/unitarias/context/Test-ContextContracts.ps1`

Debe validar:
- Firmas de los 7 builders coinciden con PUBLIC_API.json
- Helpers centralizados usan nombres correctos (-ProjectPath)
- Builder helpers no tienen colisiones de nombres
- Todos los builders ejecutan sin errores

#### Tarea 3: Crear Test-BootstrapOrchestrator.ps1
Ubicación: `pruebas/unitarias/context/Test-BootstrapOrchestrator.ps1`

Debe validar:
- ContextEngine.ps1 existe y se carga sin errores
- Ejecuta todos los builders correctamente
- Genera los 7 artefactos esperados
- Los artefactos son JSON/Markdown válidos

#### Tarea 4: Actualizar Documentación
Actualizar `.hermes/context/ArchitectureReport.md` con:
- Diagrama de flujo de ContextEngine
- Descripción del proceso de validación
- Referencias a los tests unitarios

### Archivos Clave para Mañana

1. **PUBLIC_API.json** (ya existe)
   - Contrato público de las APIs
   - Define firmas exactas de los 7 builders

2. **ContextContract.ps1** (ya existe, necesita refinamiento)
   - Define contratos de validación
   - Schema JSON para WORKER_CONTEXT.json

3. **ContextEngine.ps1** (necesita implementación completa)
   - Motor de orquestación
   - Ejecuta todos los builders en secuencia

4. **ContextValidator.ps1** (ya existe, necesita refinamiento)
   - Valida integridad de artefactos generados
   - Verifica JSON válido y contenido correcto

### Comandos Útiles

```powershell
# Verificar estado del repositorio
cd D:\HERMES-ENTERPRISE && git status

# Ver commit actualizado
git log --oneline -5

# Cargar helpers y builders en PowerShell
. D:\HERMES-ENTERPRISE\motor\context\helpers\ContextHelpers.ps1
. D:\HERMES-ENTERPRISE\motor\context\builders\CurrentStateBuilder.ps1

# Limpiar scripts de verificación temporales
Remove-Item C:\Users\FREDYA~1.SAR\AppData\Local\Temp\hermes-verify-*.ps1
```

### Criterios de Éxito Fase 3.5C

- [ ] ContextEngine.ps1 ejecuta sin errores
- [ ] Genera los 7 artefactos en `.hermes/context/`
- [ ] Todos los artefactos son JSON/Markdown válidos
- [ ] Tests unitarios pasan (100%)
- [ ] Commit de Fase 3.5C realizado

### Después de Fase 3.5C: Paso 4

**BootstrapOrchestrator.ps1** - Motor de orquestación completo del Bootstrap Engine

Requisitos previos:
- Fase 3.5C completada y verificada
- ContextEngine.ps1 funcionando correctamente
- Validación de contratos establecida

---

**Última actualización:** 2026-07-08 (sesión de hoy)
**Commit actual:** `2a3e1ba` (Fase 3.5B)
**Próximo commit esperado:** Fase 3.5C
