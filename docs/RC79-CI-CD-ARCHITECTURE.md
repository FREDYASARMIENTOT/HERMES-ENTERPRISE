# RC79 - Arquitectura CI/CD (Limpieza Definitiva)

## 1. Resumen

Este documento describe la arquitectura final de CI/CD.


## 2. Diagrama de Arquitectura

`
                  FACTORY
                     |
                     v
                  CHILD
                     |
                     v
                    CI
                     |
                     v
                   SHA
                     |
                     v
              CONTROL PLANE
                     |
                     v
                   OIDC
                     |
                     v
                  AZURE
                     |
                     v
              APP SERVICE
                     |
                     v
                 READINESS
                     |
                     v
             FUNCTIONAL TESTS
                     |
                     v
                  EVIDENCE
`


---

## 3. Conceptos Fundamentales

### 3.1 Que es CI?

**Continuous Integration (CI)** es el proceso de validacion automatica del
codigo de un proyecto Child. Se ejecuta en **GitHub Actions** del repositorio
Child, sin acceso a Azure.

El CI puede:
- Hacer checkout del codigo
- Instalar dependencias
- Ejecutar linters y analisis estatico
- Ejecutar pruebas unitarias
- Validar importaciones y entrypoints
- Compilar y empaquetar artefactos

El CI **NO** puede:
- azure/login
- id-token: write
- az webapp deploy
- Azure/webapps-deploy
- Publicar directamente en Azure

### 3.2 Que es CD?

**Continuous Deployment (CD)** es el proceso de despliegue automatizado de
un proyecto Child en Azure App Service. Esta **centralizado** en el
**Control Plane** (HERMES-ENTERPRISE).

El CD ejecuta:
1. **Checkout** del repositorio Child (SHA especifico)
2. **OIDC** (Azure Login sin secrets)
3. **Creacion/Reutilizacion** de Web App en Azure
4. **Creacion de ZIP** del codigo
5. **az webapp deploy --type zip --clean true**
6. **Readiness** (HTTP 200 + contenido Hermes)
7. **Functional Tests** (health, version, proyecto, openapi, docs, root, 404)
8. **Evidence** (resultados estructurados)

### 3.3 Que es Control Plane?

El **Control Plane** es el repositorio HERMES-ENTERPRISE que orquesta
el CD de todos los proyectos Child. Contiene:

- **.github/workflows/deploy-child.yml** - Workflow de deployment parametrizado
  (recibe project_name, app_service_name,
epository, commit_sha)
- **	ools/generate_child_evidence.py** - Generacion de evidencia estructurada

El Control Plane **no se copia** a los proyectos Child.

### 3.4 Que hace el Child?

Cada proyecto Child es un repositorio independiente que contiene:

`
hermes-{nombre}/
\__ .github/workflows/ci.yml   <- SOLO CI
\__ backend/
\__ templates/
\__ data/
\__ requirements.txt
\__ startup.sh
\__ README.md
\__ .gitignore
`

El Child **solo ejecuta CI**. No tiene:
- id-token: write
- azure/login
- Azure/webapps-deploy
- Ningun workflow de deployment

### 3.5 Que hace la Factory?

La **Factory** (	ools/Crear-HermesProyecto.ps1) crea nuevos proyectos
Child con la estructura correcta:

1. Genera repo en GitHub
2. Crea .github/workflows/ci.yml (solo CI)
3. Configura secrets de solo-lectura
4. Opcionalmente dispara el Control Plane (-TriggerControlPlane)
5. Pasa el SHA al Control Plane

La Factory **no** genera:
- deploy.yml
- id-token: write
- azure/login
- Azure/webapps-deploy

### 3.6 Que hace Azure?

Azure provee la infraestructura de hosting:

- **App Service Plan**: ASP-IAUR (compartido entre todos los proyectos)
- **Resource Group**: RG-Datamining-SII2.0-Dev
- **Web App**: Por proyecto, as-{projectName}
- **OIDC**: Autenticacion sin secrets mediante Federated Identity Credential

---

## 4. Separacion de Responsabilidades

| Capa | Responsabilidad | Workflow | Ubicacion |
|------|----------------|----------|-----------|
| **CI** | Validacion de codigo | ci.yml | Repo Child |
| **CD** | Despliegue en Azure | deploy-child.yml | HERMES-ENTERPRISE |
| **INFRA** | Provisionamiento de infraestructura | Manual / Azure Portal | Admin |

---

## 5. Seguridad

### 5.1 Por que el Child no tiene OIDC?

Principio de **minimo privilegio**:
- El Child solo necesita validar codigo -> solo necesita contents: read
- El Control Plane necesita desplegar -> necesita id-token: write + OIDC

### 5.2 Por que el deployment esta centralizado?
- **Auditabilidad**: Un solo punto de control
- **Consistencia**: Mismo mecanismo, mismas validaciones
- **Seguridad**: Menos superficies de ataque
- **Mantenibilidad**: Un solo lugar para actualizar la logica

---
## 6. SHA Handoff

El SHA es el vinculo critico entre Factory y Control Plane.
El CD despliega exactamente el SHA recibido. No usa main, latest ni
HEAD sin demostrar equivalencia.

---

## 7. Mecanismo de Deployment

El unico mecanismo activo de CD es:

`ash
az webapp deploy \
  --name APP_SERVICE_NAME \
  --resource-group RG \
  --src-path deploy.zip \
  --type zip \
  --clean true
`

---
## 8. Readiness

La validacion de readiness debe verificar:
1. HTTP 200 en {url}/health
2. Contenido Hermes (no Azure default page)

No se acepta sleep 30 como mecanismo de readiness.

---

## 9. Evidence

La evidencia se genera desde resultados reales, no hardcodeados.
Contiene: project, commit_sha, method (az webapp deploy type zip clean true),
readiness, functional_tests, y result.

---
## 10. Workflows Activos

### En HERMES-ENTERPRISE (.github/workflows/)

| Workflow | Proposito | Trigger | OIDC |
|----------|-----------|---------|------|
| ci.yml | CI del repositorio principal | push/PR a main | No |
| deploy.yml | CD de la app principal (HERMES-ENTERPRISE) | push a main | Si |
| deploy-child.yml | Control Plane - CD de proyectos Child | workflow_dispatch | Si |

### En Child (.github/workflows/)

| Workflow | Proposito | Trigger | OIDC |
|----------|-----------|---------|------|
| ci.yml | CI del proyecto Child | push/PR | No |

---
## 11. Workflows Archivados

Los siguientes workflows se movieron a docs/archive/ o se eliminaron:

| Archivo | Accion | Razon |
|---------|--------|-------|
| provision-appservice.yml | Movido a docs/archive/ | Crea ASP individuales (conflicto con ASP-IAUR) |
| tools/Templates/github/deploy.yml | Eliminado | Marcado DEPRECATED, causa fallos en CI |

---

## 12. Reglas de Oro

1. Un solo CD: deploy-child.yml
2. Un solo mecanismo: az webapp deploy --type zip --clean true
3. SHA explicito
4. Child CI-only
5. Sin OIDC en Child
6. Sin secrets en codigo
7. Readiness con contenido
8. Evidence real
9. Git limpio
10. ASP-IAUR compartido
