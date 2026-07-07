# Fase 7.0 — Developer Context Framework

> **For Hermes:** Ejecutar este plan con TDD estricto, commits pequeños y validación continua.

**Goal:** Reorganizar la arquitectura de HERMES-ENTERPRISE para que el punto de entrada sea el `DeveloperContext`, dejando la `Session` como componente interno administrado automáticamente. Sin agregar capacidades funcionales nuevas.

**Architecture:** El flujo `Start-HermesEnterprise → Session → Kernel` evoluciona a `Start-HermesEnterprise → DeveloperContext → Workspace → Project → Git → GitHub → Provider → Plugins → Session → Kernel`. Los inspectores son de solo lectura, no persisten estado destructivo y reconstruyen el contexto cada vez. La única persistencia sigue siendo `Session`.

**Tech Stack:** PowerShell 7+, módulos existentes de `motor/`, sin dependencias externas. Se respeta el estilo actual: nombres largos descriptivos, comentarios de cabecera, `[pscustomobject][ordered]@{}`, `Set-StrictMode -Version Latest`.

---

## Subfase 7.1 — Inspectores de contexto (solo lectura)

### Task 1: WorkspaceInspector

**Objective:** Descubrir el workspace actual (carpeta abierta por VS Code o ruta por defecto) sin modificar nada.

**Files:**
- Create: `motor/context/WorkspaceInspector.ps1`
- Test: `pruebas/unitarias/Test-WorkspaceInspector.ps1`

**Step 1: Escribir test RED**

```powershell
function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada,[string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }
$RutaDirectorioPruebas = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebas)
. (Join-Path $RutaRaizRepositorio "motor/context/WorkspaceInspector.ps1")
$RutaTemporal = Join-Path $env:TEMP "HermesWorkspaceInspectorTest_$(Get-Random)"
New-Item -ItemType Directory -Path $RutaTemporal -Force | Out-Null
$Info = Get-HermesEnterpriseWorkspaceInfo -Ruta $RutaTemporal
Assert-HermesEnterpriseCondition ($Info.Ruta -eq $RutaTemporal) "WorkspaceInspector no devolvió la ruta."
Assert-HermesEnterpriseCondition ($Info.Existe -eq $true) "WorkspaceInspector no detectó existencia."
Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Test-WorkspaceInspector completado correctamente." -ForegroundColor Green
```

**Step 2: Run test RED**

```bash
pwsh pruebas/unitarias/Test-WorkspaceInspector.ps1
```

Expected: FAIL — `Get-HermesEnterpriseWorkspaceInfo` no existe.

**Step 3: Implementar WorkspaceInspector**

```powershell
<# motor/context/WorkspaceInspector.ps1 #>
Set-StrictMode -Version Latest
function Get-HermesEnterpriseWorkspaceInfo {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    $RutaAbsoluta = [System.IO.Path]::GetFullPath($Ruta)
    return [pscustomobject][ordered]@{
        Ruta = $RutaAbsoluta
        Existe = Test-Path $RutaAbsoluta
        Nombre = Split-Path $RutaAbsoluta -Leaf
        TieneWorkspaceVSCode = (Test-Path (Join-Path $RutaAbsoluta "*.code-workspace") -PathType Leaf)
    }
}
```

**Step 4: Run test GREEN**

```bash
pwsh pruebas/unitarias/Test-WorkspaceInspector.ps1
```

Expected: PASS.

**Step 5: Commit**

```bash
git add motor/context/WorkspaceInspector.ps1 pruebas/unitarias/Test-WorkspaceInspector.ps1
git commit -m "feat(fase7): WorkspaceInspector de solo lectura"
```

---

### Task 2: ProjectInspector

**Objective:** Descubrir el proyecto dentro de un workspace.

**Files:**
- Create: `motor/context/ProjectInspector.ps1`
- Test: `pruebas/unitarias/Test-ProjectInspector.ps1`

**Step 1: Escribir test RED**

```powershell
. (Join-Path $RutaRaizRepositorio "motor/context/ProjectInspector.ps1")
$RutaTemporal = Join-Path $env:TEMP "HermesProjectInspectorTest_$(Get-Random)"
New-Item -ItemType Directory -Path $RutaTemporal -Force | Out-Null
$Info = Get-HermesEnterpriseProjectInfo -Ruta $RutaTemporal
Assert-HermesEnterpriseCondition ($Info.NombreProyecto -eq (Split-Path $RutaTemporal -Leaf)) "ProjectInspector no infirió nombre."
Assert-HermesEnterpriseCondition ($Info.RutaLocal -eq $RutaTemporal) "ProjectInspector no devolvió ruta."
Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue
```

**Step 2-4:** Implementar `Get-HermesEnterpriseProjectInfo` reutilizando `ProjectDescriptor.ps1`.

```powershell
<# motor/context/ProjectInspector.ps1 #>
Set-StrictMode -Version Latest
$RutaDirectorioProjectInspector = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioProjectInspector "../providers/ProjectDescriptor.ps1")
function Get-HermesEnterpriseProjectInfo {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    $RutaAbsoluta = [System.IO.Path]::GetFullPath($Ruta)
    $Nombre = Split-Path $RutaAbsoluta -Leaf
    return New-HermesEnterpriseProjectDescriptor -NombreProyecto $Nombre -RutaLocal $RutaAbsoluta
}
```

**Step 5: Commit**

```bash
git add motor/context/ProjectInspector.ps1 pruebas/unitarias/Test-ProjectInspector.ps1
git commit -m "feat(fase7): ProjectInspector de solo lectura"
```

---

### Task 3: GitInspector

**Objective:** Descubrir estado Git de un proyecto sin ejecutar operaciones destructivas.

**Files:**
- Create: `motor/context/GitInspector.ps1`
- Test: `pruebas/unitarias/Test-GitInspector.ps1`

**Step 1: Escribir test RED**

```powershell
. (Join-Path $RutaRaizRepositorio "motor/context/GitInspector.ps1")
$RutaTemporal = Join-Path $env:TEMP "HermesGitInspectorTest_$(Get-Random)"
New-Item -ItemType Directory -Path $RutaTemporal -Force | Out-Null
$Info = Get-HermesEnterpriseGitInfo -Ruta $RutaTemporal
Assert-HermesEnterpriseCondition ($Info.TieneGit -eq $false) "GitInspector mintió sobre .git."
New-Item -ItemType Directory -Path (Join-Path $RutaTemporal ".git") -Force | Out-Null
$Info2 = Get-HermesEnterpriseGitInfo -Ruta $RutaTemporal
Assert-HermesEnterpriseCondition ($Info2.TieneGit -eq $true) "GitInspector no detectó .git."
Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue
```

**Step 2-4:** Implementar `Get-HermesEnterpriseGitInfo`.

```powershell
<# motor/context/GitInspector.ps1 #>
Set-StrictMode -Version Latest
$RutaDirectorioGitInspector = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioGitInspector "../providers/GitManager.ps1")
function Get-HermesEnterpriseGitInfo {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    $RutaAbsoluta = [System.IO.Path]::GetFullPath($Ruta)
    $TieneGit = Test-HermesEnterpriseGitRepository -Ruta $RutaAbsoluta
    return [pscustomobject][ordered]@{
        Ruta = $RutaAbsoluta
        TieneGit = $TieneGit
        BranchActual = if ($TieneGit) { "main" } else { "" }
        Estado = if ($TieneGit) { "Detected" } else { "NoRepository" }
    }
}
```

**Step 5: Commit**

```bash
git add motor/context/GitInspector.ps1 pruebas/unitarias/Test-GitInspector.ps1
git commit -m "feat(fase7): GitInspector de solo lectura"
```

---

### Task 4: GitHubInspector

**Objective:** Descubrir información GitHub (modo MOCK) sin usar API reales.

**Files:**
- Create: `motor/context/GitHubInspector.ps1`
- Test: `pruebas/unitarias/Test-GitHubInspector.ps1`

**Step 1: Escribir test RED**

```powershell
. (Join-Path $RutaRaizRepositorio "motor/context/GitHubInspector.ps1")
$Info = Get-HermesEnterpriseGitHubInfo -NombreProyecto "TestProject"
Assert-HermesEnterpriseCondition ($Info.NombreProyecto -eq "TestProject") "GitHubInspector no conserva nombre."
Assert-HermesEnterpriseCondition ($Info.Modo -eq "MOCK") "GitHubInspector no indica modo MOCK."
```

**Step 2-4:** Implementar `Get-HermesEnterpriseGitHubInfo`.

```powershell
<# motor/context/GitHubInspector.ps1 #>
Set-StrictMode -Version Latest
function Get-HermesEnterpriseGitHubInfo {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$NombreProyecto)
    return [pscustomobject][ordered]@{
        NombreProyecto = $NombreProyecto
        Modo = "MOCK"
        TieneRemoto = $false
        UsuarioGitHub = $env:GITHUB_USER
        UrlRemota = ""
        Estado = "MockDetected"
    }
}
```

**Step 5: Commit**

```bash
git add motor/context/GitHubInspector.ps1 pruebas/unitarias/Test-GitHubInspector.ps1
git commit -m "feat(fase7): GitHubInspector de solo lectura modo MOCK"
```

---

### Task 5: EnvironmentInspector

**Objective:** Descubrir variables de entorno y preferencias locales sin secretos.

**Files:**
- Create: `motor/context/EnvironmentInspector.ps1`
- Test: `pruebas/unitarias/Test-EnvironmentInspector.ps1`

**Step 1: Escribir test RED**

```powershell
. (Join-Path $RutaRaizRepositorio "motor/context/EnvironmentInspector.ps1")
$Info = Get-HermesEnterpriseEnvironmentInfo
Assert-HermesEnterpriseCondition ($Info.VariablesEntorno.ContainsKey("PATH")) "EnvironmentInspector no capturó PATH."
Assert-HermesEnterpriseCondition ($Info.IdiomaPreferido -ne $null) "EnvironmentInspector no devolvió idioma."
```

**Step 2-4:** Implementar `Get-HermesEnterpriseEnvironmentInfo`.

```powershell
<# motor/context/EnvironmentInspector.ps1 #>
Set-StrictMode -Version Latest
function Get-HermesEnterpriseEnvironmentInfo {
    [CmdletBinding()][OutputType([pscustomobject])]
    param()
    $Variables = @{}
    foreach ($Clave in @("PATH", "USERNAME", "USERPROFILE", "HERMES_HOME", "GITHUB_USER", "VSCODE_CWD")) {
        $Variables[$Clave] = [Environment]::GetEnvironmentVariable($Clave)
    }
    return [pscustomobject][ordered]@{
        VariablesEntorno = $Variables
        IdiomaPreferido = if ([Environment]::GetEnvironmentVariable("HERMES_LANG")) { [Environment]::GetEnvironmentVariable("HERMES_LANG") } else { "es" }
        Region = [System.Globalization.CultureInfo]::CurrentCulture.Name
        Usuario = $env:USERNAME
    }
}
```

**Step 5: Commit**

```bash
git add motor/context/EnvironmentInspector.ps1 pruebas/unitarias/Test-EnvironmentInspector.ps1
git commit -m "feat(fase7): EnvironmentInspector de solo lectura"
```

---

## Subfase 7.2 — DeveloperContext, ContextBuilder y DeveloperContextManager

### Task 6: DeveloperContext

**Objective:** Definir el objeto raíz del contexto del desarrollador.

**Files:**
- Create: `motor/context/DeveloperContext.ps1`
- Test: `pruebas/unitarias/Test-DeveloperContext.ps1`

**Step 1: Escribir test RED**

```powershell
. (Join-Path $RutaRaizRepositorio "motor/context/DeveloperContext.ps1")
$Contexto = New-HermesEnterpriseDeveloperContext
Assert-HermesEnterpriseCondition ($null -ne $Contexto) "DeveloperContext no creado."
Assert-HermesEnterpriseCondition ($Contexto.PSObject.Properties.Name -contains "Workspace") "DeveloperContext no tiene Workspace."
Assert-HermesEnterpriseCondition ($Contexto.PSObject.Properties.Name -contains "Session") "DeveloperContext no tiene Session."
```

**Step 2-4:** Implementar `New-HermesEnterpriseDeveloperContext`.

```powershell
<# motor/context/DeveloperContext.ps1 #>
Set-StrictMode -Version Latest
function New-HermesEnterpriseDeveloperContext {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$false)][psobject]$Workspace = $null,
        [Parameter(Mandatory=$false)][psobject]$Proyecto = $null,
        [Parameter(Mandatory=$false)][psobject]$Git = $null,
        [Parameter(Mandatory=$false)][psobject]$GitHub = $null,
        [Parameter(Mandatory=$false)][psobject]$Provider = $null,
        [Parameter(Mandatory=$false)][string]$Modelo = "ur-hermes-mini",
        [Parameter(Mandatory=$false)][string[]]$Plugins = @(),
        [Parameter(Mandatory=$false)][psobject]$Session = $null,
        [Parameter(Mandatory=$false)][hashtable]$Preferencias = @{},
        [Parameter(Mandatory=$false)][psobject]$VariablesEntorno = $null,
        [Parameter(Mandatory=$false)][psobject]$EstadoKernel = $null
    )
    return [pscustomobject][ordered]@{
        Workspace = $Workspace
        Proyecto = $Proyecto
        Git = $Git
        GitHub = $GitHub
        Provider = $Provider
        Modelo = $Modelo
        Plugins = $Plugins
        Session = $Session
        Preferencias = $Preferencias
        VariablesEntorno = $VariablesEntorno
        EstadoKernel = $EstadoKernel
    }
}
```

**Step 5: Commit**

```bash
git add motor/context/DeveloperContext.ps1 pruebas/unitarias/Test-DeveloperContext.ps1
git commit -m "feat(fase7): DeveloperContext objeto raíz"
```

---

### Task 7: ContextBuilder

**Objective:** Orquestar inspectores para construir un DeveloperContext completo.

**Files:**
- Create: `motor/context/ContextBuilder.ps1`
- Modify: `motor/context/DeveloperContext.ps1` (ya creado)

**Step 1: Escribir test RED**

```powershell
. (Join-Path $RutaRaizRepositorio "motor/context/ContextBuilder.ps1")
$RutaTemporal = Join-Path $env:TEMP "HermesContextBuilderTest_$(Get-Random)"
New-Item -ItemType Directory -Path $RutaTemporal -Force | Out-Null
$Contexto = Build-HermesEnterpriseDeveloperContext -RutaWorkspace $RutaTemporal -NombreProyecto "TestProject"
Assert-HermesEnterpriseCondition ($Contexto.Workspace.Existe -eq $true) "ContextBuilder no incluyó workspace."
Assert-HermesEnterpriseCondition ($Contexto.Proyecto.NombreProyecto -eq "TestProject") "ContextBuilder no incluyó proyecto."
Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue
```

**Step 2-4:** Implementar `Build-HermesEnterpriseDeveloperContext`.

```powershell
<# motor/context/ContextBuilder.ps1 #>
Set-StrictMode -Version Latest
$RutaDirectorioContextBuilder = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioContextBuilder "WorkspaceInspector.ps1")
. (Join-Path $RutaDirectorioContextBuilder "ProjectInspector.ps1")
. (Join-Path $RutaDirectorioContextBuilder "GitInspector.ps1")
. (Join-Path $RutaDirectorioContextBuilder "GitHubInspector.ps1")
. (Join-Path $RutaDirectorioContextBuilder "EnvironmentInspector.ps1")
. (Join-Path $RutaDirectorioContextBuilder "DeveloperContext.ps1")

function Build-HermesEnterpriseDeveloperContext {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$true)][string]$RutaWorkspace,
        [Parameter(Mandatory=$false)][string]$NombreProyecto = "",
        [Parameter(Mandatory=$false)][string]$Modelo = "ur-hermes-mini",
        [Parameter(Mandatory=$false)][string]$ProveedorIA = "AzureFoundryProvider",
        [Parameter(Mandatory=$false)][string[]]$Plugins = @(),
        [Parameter(Mandatory=$false)][psobject]$Session = $null
    )
    $Workspace = Get-HermesEnterpriseWorkspaceInfo -Ruta $RutaWorkspace
    $Nombre = if ([string]::IsNullOrWhiteSpace($NombreProyecto)) { $Workspace.Nombre } else { $NombreProyecto }
    $Proyecto = Get-HermesEnterpriseProjectInfo -Ruta $Workspace.Ruta
    $Git = Get-HermesEnterpriseGitInfo -Ruta $Workspace.Ruta
    $GitHub = Get-HermesEnterpriseGitHubInfo -NombreProyecto $Nombre
    $Entorno = Get-HermesEnterpriseEnvironmentInfo
    return New-HermesEnterpriseDeveloperContext `
        -Workspace $Workspace `
        -Proyecto $Proyecto `
        -Git $Git `
        -GitHub $GitHub `
        -Provider $ProveedorIA `
        -Modelo $Modelo `
        -Plugins $Plugins `
        -Session $Session `
        -Preferencias @{ Idioma = $Entorno.IdiomaPreferido; Region = $Entorno.Region } `
        -VariablesEntorno $Entorno.VariablesEntorno `
        -EstadoKernel $null
}
```

**Step 5: Commit**

```bash
git add motor/context/ContextBuilder.ps1 pruebas/unitarias/Test-DeveloperContext.ps1
git commit -m "feat(fase7): ContextBuilder orquesta inspectores"
```

---

### Task 8: DeveloperContextManager

**Objective:** Servicio de alto nivel para obtener o crear un DeveloperContext, integrando Session automáticamente.

**Files:**
- Create: `motor/context/DeveloperContextManager.ps1`
- Test: modificar `pruebas/unitarias/Test-DeveloperContext.ps1`

**Step 1: Escribir test RED**

```powershell
. (Join-Path $RutaRaizRepositorio "motor/context/DeveloperContextManager.ps1")
$RutaTemporal = Join-Path $env:TEMP "HermesDCMTest_$(Get-Random)"
New-Item -ItemType Directory -Path $RutaTemporal -Force | Out-Null
$Manager = New-HermesEnterpriseDeveloperContextManager -RutaRaizRepositorio $RutaTemporal
$Contexto = $Manager.BuildContext("TestProject")
Assert-HermesEnterpriseCondition ($null -ne $Contexto.Session) "DeveloperContextManager no creó session automáticamente."
Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue
```

**Step 2-4:** Implementar `New-HermesEnterpriseDeveloperContextManager`.

```powershell
<# motor/context/DeveloperContextManager.ps1 #>
Set-StrictMode -Version Latest
$RutaDirectorioDCM = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioDCM "ContextBuilder.ps1")
. (Join-Path $RutaDirectorioDCM "../session/SessionManager.ps1")

function New-HermesEnterpriseDeveloperContextManager {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$RutaRaizRepositorio)
    return [pscustomobject][ordered]@{
        RutaRaizRepositorio = [System.IO.Path]::GetFullPath($RutaRaizRepositorio)
        BuildContext = {
            param([string]$NombreProyecto = "", [string]$RutaWorkspace = "")
            $Ruta = if ([string]::IsNullOrWhiteSpace($RutaWorkspace)) { $this.RutaRaizRepositorio } else { $RutaWorkspace }
            $Session = Open-HermesEnterpriseSession -RutaRaizRepositorio $this.RutaRaizRepositorio
            if ($null -eq $Session) {
                $Nombre = if ([string]::IsNullOrWhiteSpace($NombreProyecto)) { "HermesProject" } else { $NombreProyecto }
                $Session = New-HermesEnterpriseSessionFromContext -RutaRaizRepositorio $this.RutaRaizRepositorio -NombreProyecto $Nombre -RutaWorkspace $Ruta
            }
            return Build-HermesEnterpriseDeveloperContext -RutaWorkspace $Ruta -NombreProyecto $Nombre -Session $Session
        }.GetNewClosure()
    }
}
```

Nota: `New-HermesEnterpriseSessionFromContext` se añade en Subfase 7.4. Hasta entonces, el test usará un stub temporal o se ejecutará tras refactorizar SessionManager.

**Step 5: Commit**

```bash
git add motor/context/DeveloperContextManager.ps1 pruebas/unitarias/Test-DeveloperContext.ps1
git commit -m "feat(fase7): DeveloperContextManager orquesta contexto y session"
```

---

## Subfase 7.3 — Wizards separados

### Task 9: FirstRunWizard

**Objective:** Configurar preferencias globales la primera vez que se ejecuta HERMES. No crea proyectos.

**Files:**
- Create: `motor/wizards/FirstRunWizard.ps1`
- Test: `pruebas/unitarias/Test-FirstRunWizard.ps1` (opcional si no se pide explícitamente, pero recomendado)

**Implementación:**

```powershell
<# motor/wizards/FirstRunWizard.ps1 #>
Set-StrictMode -Version Latest
function Start-HermesEnterpriseFirstRunWizard {
    [CmdletBinding()][OutputType([pscustomobject])]
    param()
    return [pscustomobject][ordered]@{
        Idioma = "es"
        ProveedorIA = "AzureFoundryProvider"
        ModeloIA = "ur-hermes-mini"
        UbicacionPorDefecto = (Join-Path $env:USERPROFILE "HermesProjects")
        GitHubUsuario = $env:GITHUB_USER
        Configurado = $true
    }
}
```

**Commit:** `feat(fase7): FirstRunWizard sin crear proyectos`

---

### Task 10: ProjectWizard

**Objective:** Resolver qué hacer cuando no hay proyecto: crear, abrir o clonar.

**Files:**
- Create: `motor/wizards/ProjectWizard.ps1`
- Test: `pruebas/unitarias/Test-ProjectWizard.ps1`

**Implementación:**

```powershell
<# motor/wizards/ProjectWizard.ps1 #>
Set-StrictMode -Version Latest
$RutaDirectorioProjectWizard = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioProjectWizard "../providers/ProjectManager.ps1")
. (Join-Path $RutaDirectorioProjectWizard "../providers/GitManager.ps1")
. (Join-Path $RutaDirectorioProjectWizard "../providers/GitHubManagers.ps1")
. (Join-Path $RutaDirectorioProjectWizard "../providers/VSCodeManager.ps1")

function Start-HermesEnterpriseProjectWizard {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$false)][string]$RutaBase = ".",
        [Parameter(Mandatory=$false)][string]$NombreProyecto = "HermesProject",
        [Parameter(Mandatory=$false)][switch]$CrearGit,
        [Parameter(Mandatory=$false)][switch]$CrearGitHub
    )
    $Ruta = New-HermesEnterpriseWorkspaceFolder -RutaBase $RutaBase -NombreCarpeta $NombreProyecto
    $Proyecto = New-HermesEnterpriseProject -NombreProyecto $NombreProyecto -RutaBase $RutaBase
    $Workspace = New-HermesEnterpriseVSCodeWorkspaceFile -Ruta $Ruta -NombreWorkspace $NombreProyecto
    $Git = if ($CrearGit.IsPresent) { Initialize-HermesEnterpriseGitRepository -Ruta $Ruta } else { $null }
    $GitHub = if ($CrearGitHub.IsPresent) { New-HermesEnterpriseGitHubRepository -Nombre $NombreProyecto } else { $null }
    return [pscustomobject][ordered]@{
        Proyecto = $Proyecto
        Workspace = $Workspace
        Git = $Git
        GitHub = $GitHub
        Ruta = $Ruta
    }
}
```

**Commit:** `feat(fase7): ProjectWizard crear/abrir/clonar estructura`

---

## Subfase 7.4 — Refactorizar SessionManager

### Task 11: Eliminar SessionWizard y añadir New-HermesEnterpriseSessionFromContext

**Files:**
- Modify: `motor/session/SessionManager.ps1`
- Delete/deprecate: `motor/session/SessionWizard.ps1` (conservar vacío o eliminar referencias)

**Cambios en SessionManager.ps1:**
- Eliminar la línea `. (Join-Path $RutaDirectorioSessionManager "SessionWizard.ps1")`.
- Eliminar `New-HermesEnterpriseSession` viejo.
- Añadir `New-HermesEnterpriseSessionFromContext` que reciba `RutaRaizRepositorio`, `NombreProyecto`, `RutaWorkspace`, `ModeloIA`, `ProveedorIA`.
- Modificar `Open-HermesEnterpriseSession` para que sea compatible (ya lo es).

```powershell
function New-HermesEnterpriseSessionFromContext {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory=$false)][string]$NombreProyecto = "HermesProject",
        [Parameter(Mandatory=$false)][string]$RutaWorkspace = "",
        [Parameter(Mandatory=$false)][string]$ModeloIA = "ur-hermes-mini",
        [Parameter(Mandatory=$false)][string]$ProveedorIA = "AzureFoundryProvider"
    )
    $IdentificadorSesion = [guid]::NewGuid().ToString("N").Substring(0, 12)
    $Sesion = New-HermesEnterpriseSessionDescriptor `
        -IdentificadorSesion $IdentificadorSesion `
        -NombreProyecto $NombreProyecto `
        -RutaWorkspace $RutaWorkspace `
        -RepositorioGit (Test-HermesEnterpriseGitRepository -Ruta $RutaWorkspace) `
        -BranchActual "main" `
        -ProveedorIA $ProveedorIA `
        -ModeloIA $ModeloIA `
        -PluginsInstalados @() `
        -ConfiguracionActiva @{} `
        -EstadoSesion "Active"
    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $Sesion -Operacion "SessionCreatedFromContext" -Mensaje "Sesión creada automáticamente desde DeveloperContext."
    $null = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $Sesion
    return $Sesion
}
```

**Commit:** `refactor(fase7): SessionManager recibe DeveloperContext, elimina SessionWizard`

---

## Subfase 7.5 — Refactorizar Start-HermesEnterprise.ps1

### Task 12: Punto de entrada basado en DeveloperContext

**Files:**
- Modify: `scripts/Start-HermesEnterprise.ps1`

**Nuevo flujo:**

```powershell
. (Join-Path $RutaRaizRepositorio "motor/bootstrap/Bootstrap.ps1")
. (Join-Path $RutaRaizRepositorio "motor/kernel/KernelValidator.ps1")
. (Join-Path $RutaRaizRepositorio "motor/context/DeveloperContextManager.ps1")

$KernelEnterprise = Start-HermesEnterpriseBootstrap -RutaRaizRepositorio $RutaRaizRepositorio -NombreEntorno $NombreEntorno
$ResultadoValidacionKernel = Test-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise
if (-not $ResultadoValidacionKernel.EsValido) { throw ... }

$RutaWorkspace = $RutaRaizRepositorio
$Manager = New-HermesEnterpriseDeveloperContextManager -RutaRaizRepositorio $RutaRaizRepositorio
$DeveloperContext = $Manager.BuildContext("HermesProject", $RutaWorkspace)
$DeveloperContext.EstadoKernel = $KernelEnterprise

Write-Host "Hermes Enterprise Kernel iniciado correctamente." -ForegroundColor Green
Write-Host "Estado  : $($KernelEnterprise.EstadoKernel)"
Write-Host "Runtime : $($KernelEnterprise.Runtime.EstadoRuntime)"
Write-Host "Sesión  : $($DeveloperContext.Session.IdentificadorSesion)"
Write-Host "Proyecto: $($DeveloperContext.Proyecto.NombreProyecto)"

if ($DevolverContexto.IsPresent) { return $DeveloperContext }
if ($DevolverKernel.IsPresent) { return $KernelEnterprise }
```

Añadir parámetro `[switch]$DevolverContexto` y conservar `$DevolverKernel`. Eliminar `$DevolverSesion` o marcarlo como obsoleto.

**Commit:** `refactor(fase7): Start-HermesEnterprise usa DeveloperContext`

---

## Subfase 7.6 — Actualizar pruebas existentes

### Task 13: Test-SessionFramework.ps1

**Objective:** Validar compatibilidad de SessionManager refactorizado.

**Files:**
- Modify: `pruebas/unitarias/Test-SessionFramework.ps1`

**Cambios:**
- Reemplazar `New-HermesEnterpriseSession` por `New-HermesEnterpriseSessionFromContext`.
- Asegurar que `Open-HermesEnterpriseSession` sigue funcionando.

**Commit:** `test(fase7): ajustar Test-SessionFramework a SessionManager refactorizado`

---

### Task 14: Test-DeveloperWorkspaceFlow.ps1

**Objective:** Validar el flujo completo con DeveloperContext.

**Files:**
- Modify: `pruebas/aceptacion/Test-DeveloperWorkspaceFlow.ps1`

**Nuevo flujo esperado:**

```text
Abrir VS Code -> Crear Workspace -> Crear Proyecto -> Crear Git -> Crear GitHub MOCK -> Crear Session -> Construir DeveloperContext -> Iniciar Kernel
```

Añadir al final:

```powershell
. (Join-Path $RutaRaizRepositorio "motor/context/ContextBuilder.ps1")
$Contexto = Build-HermesEnterpriseDeveloperContext -RutaWorkspace $Proyecto.RutaLocal -NombreProyecto $NombreProyecto -Session $Sesion
Assert-HermesEnterpriseCondition ($Contexto.Proyecto.NombreProyecto -eq $NombreProyecto) "DeveloperContext no construido correctamente."
```

**Commit:** `test(fase7): Test-DeveloperWorkspaceFlow valida DeveloperContext`

---

### Task 15: Smoke Test Enterprise

**Files:**
- Modify: `scripts/Test-HermesEnterprise.ps1`

**Cambios:**
- Añadir las nuevas pruebas unitarias a la lista requerida:
  - `Test-DeveloperContext.ps1`
  - `Test-WorkspaceInspector.ps1`
  - `Test-ProjectInspector.ps1`
  - `Test-GitInspector.ps1`
  - `Test-GitHubInspector.ps1`
  - `Test-EnvironmentInspector.ps1`

**Commit:** `test(fase7): Smoke Test incluye pruebas de Developer Context`

---

## Subfase 7.7 — Documentación

### Task 16: DEVELOPER_CONTEXT.md

**Files:**
- Create: `documentacion/DEVELOPER_CONTEXT.md`

**Contenido mínimo:**
- Propósito.
- Arquitectura: DeveloperContext contiene Session.
- Componentes y responsabilidades.
- Flujo de inicio.
- Contrato del DeveloperContext.
- Persistencia.

**Commit:** `docs(fase7): DEVELOPER_CONTEXT.md`

---

### Task 17: Actualizar documentos existentes

**Files:**
- Modify: `documentacion/DEVELOPER_ASSISTANT.md`
- Modify: `documentacion/FIRST_RUN_EXPERIENCE.md`
- Modify: `documentacion/SESSION_FRAMEWORK.md`
- Modify: `documentacion/ARCHITECTURE_DECISIONS.md`
- Modify: `documentacion/SRS_HERMES_ENTERPRISE.md`
- Modify: `CHANGELOG.md`

**Cambios mínimos:**
- `FIRST_RUN_EXPERIENCE.md`: separar FirstRunWizard y ProjectWizard.
- `SESSION_FRAMEWORK.md`: indicar que Session es componente interno, no raíz.
- `ARCHITECTURE_DECISIONS.md`: añadir ADR sobre DeveloperContext.
- `CHANGELOG.md`: añadir entrada `[0.9.0] - YYYY-MM-DD` con Fase 7.0.

**Commit:** `docs(fase7): actualiza documentación de arquitectura y experiencia`

---

## Validación final

1. Ejecutar `scripts/Test-HermesEnterprise.ps1` completo.
2. Ejecutar `pruebas/aceptacion/Test-DeveloperWorkspaceFlow.ps1`.
3. Verificar que `scripts/Start-HermesEnterprise.ps1` inicia sin errores.
4. Revisar `git status` y confirmar que no hay archivos no deseados.

---

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|--------|------------|
| Romper SessionManager | Mantener `Open-HermesEnterpriseSession`, solo cambiar creación |
| Romper Start-HermesEnterprise | Conservar parámetros, añadir DevolverContexto |
| Tests antiguos fallan | Actualizar `Test-SessionFramework` y Smoke Test |
| Exceder 25 archivos | Es previsto; ejecutar por subfases con commits pequeños |
| Acoplamiento con providers | Inspectores solo lectura, no modifican providers |

---

## Estimación

- Subfase 7.1: 5 tareas × 10 min = 50 min
- Subfase 7.2: 3 tareas × 10 min = 30 min
- Subfase 7.3: 2 tareas × 10 min = 20 min
- Subfase 7.4: 1 tarea × 15 min = 15 min
- Subfase 7.5: 3 tareas × 10 min = 30 min
- Subfase 7.6: 2 tareas × 15 min = 30 min
- Validación final: 15 min

**Total estimado: ~3 horas.**
