<#
.SYNOPSIS
    Pruebas unitarias Pester para la clase Context (WP-010) - Compatible Pester 3.x.

.DESCRIPTION
    Verifica el cumplimiento del contrato IContext según KERNEL_CONTRACT_SPECIFICATION.md
    Sección 5. Incluye validación de:
    - Constructor y propiedades predeterminadas
    - Métodos del contrato (GetProperty, SetProperty, HasProperty, GetAllProperties)
    - Métodos de acceso directo (GetContextId, GetVersion, etc.)
    - Validación (Validate)
    - Ciclo de vida (Dispose, IsDisposed)
    - Eventos (Context.Created, Context.PropertyChanged, Context.Validated)
    - Manejo de errores
    - Invariantes del contrato
#>

# Cargar la clase Context una sola vez
. "$PSScriptRoot\..\..\motor\kernel\Context.ps1"

$TestRoot = "D:\HERMES-ENTERPRISE"
$TestProjectName = "HermesEnterprise"
$TestVersion = "1.0.0"
$TestEnvironment = "Desarrollo"

# --------------------------------------------------------------------------
# Grupo 1: Constructor y propiedades predeterminadas
# --------------------------------------------------------------------------
Describe "Context - Constructor" {

    It "Debe crear una instancia con el constructor de 4 parámetros" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx | Should Not BeNullOrEmpty
        $ctx.IsDisposed() | Should Be $false
    }

    It "Debe crear una instancia con el constructor de 7 parámetros" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment, "D:\custom\motor", "D:\custom\config", "D:\custom\logs")
        $ctx | Should Not BeNullOrEmpty
        $ctx.GetMotorPath() | Should Be "D:\custom\motor"
        $ctx.GetConfigurationPath() | Should Be "D:\custom\config"
        $ctx.GetLogsPath() | Should Be "D:\custom\logs"
    }

    It "Debe generar un ContextId GUID único" {
        $ctx1 = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx2 = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx1.GetContextId() | Should Not Be $ctx2.GetContextId()
    }

    It "Debe establecer FechaCreacion como UTC" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $createdAt = $ctx.GetCreatedAt()
        $createdAt.Kind | Should Be "Utc"
    }

    It "Debe tener todas las propiedades predeterminadas" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx.HasProperty("NombreProyecto") | Should Be $true
        $ctx.HasProperty("VersionKernel") | Should Be $true
        $ctx.HasProperty("NombreEntorno") | Should Be $true
        $ctx.HasProperty("RutaRaizRepositorio") | Should Be $true
        $ctx.HasProperty("RutaMotor") | Should Be $true
        $ctx.HasProperty("RutaConfiguracion") | Should Be $true
        $ctx.HasProperty("RutaLogs") | Should Be $true
        $ctx.HasProperty("FechaCreacion") | Should Be $true
        $ctx.HasProperty("IdentificadorContexto") | Should Be $true
    }

    It "Debe tener 13 propiedades en total (9 estándar + 4 adicionales)" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $props = $ctx.GetAllProperties()
        $props.Count | Should Be 13
    }
}

# --------------------------------------------------------------------------
# Grupo 2: Validación de parámetros del constructor (Fail Fast)
# --------------------------------------------------------------------------
Describe "Context - Validación de parámetros del constructor" {

    It "Debe rechazar ProjectName vacío" {
        { [Context]::new("", $TestRoot, $TestVersion, $TestEnvironment) } | Should Throw
    }

    It "Debe rechazar ProjectName con menos de 3 caracteres" {
        { [Context]::new("AB", $TestRoot, $TestVersion, $TestEnvironment) } | Should Throw
    }

    It "Debe rechazar ProjectName con más de 64 caracteres" {
        $longName = "A" * 65
        { [Context]::new($longName, $TestRoot, $TestVersion, $TestEnvironment) } | Should Throw
    }

    It "Debe rechazar RepositoryRoot vacío" {
        { [Context]::new($TestProjectName, "", $TestVersion, $TestEnvironment) } | Should Throw
    }

    It "Debe rechazar RepositoryRoot que no sea ruta absoluta" {
        { [Context]::new($TestProjectName, "relative/path", $TestVersion, $TestEnvironment) } | Should Throw
    }

    It "Debe rechazar KernelVersion vacío" {
        { [Context]::new($TestProjectName, $TestRoot, "", $TestEnvironment) } | Should Throw
    }

    It "Debe rechazar KernelVersion sin formato semántico" {
        { [Context]::new($TestProjectName, $TestRoot, "1.0", $TestEnvironment) } | Should Throw
        { [Context]::new($TestProjectName, $TestRoot, "v1.0.0", $TestEnvironment) } | Should Throw
        { [Context]::new($TestProjectName, $TestRoot, "1.0.0-beta", $TestEnvironment) } | Should Throw
    }

    It "Debe aceptar KernelVersion con formato X.Y.Z válido" {
        { [Context]::new($TestProjectName, $TestRoot, "0.0.1", $TestEnvironment) } | Should Not Throw
        { [Context]::new($TestProjectName, $TestRoot, "2.5.10", $TestEnvironment) } | Should Not Throw
        { [Context]::new($TestProjectName, $TestRoot, "99.99.99", $TestEnvironment) } | Should Not Throw
    }

    It "Debe rechazar EnvironmentName vacío" {
        { [Context]::new($TestProjectName, $TestRoot, $TestVersion, "") } | Should Throw
    }
}

# --------------------------------------------------------------------------
# Grupo 3: Métodos del contrato IContext
# --------------------------------------------------------------------------
Describe "Context - Métodos IContext" {

    BeforeEach {
        $script:ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
    }

    AfterEach {
        $script:ctx.Dispose()
    }

    It "GetProperty debe retornar el valor correcto" {
        $name = $script:ctx.GetProperty("NombreProyecto")
        $name | Should Be $TestProjectName
    }

    It "GetProperty debe lanzar error para propiedad inexistente" {
        { $script:ctx.GetProperty("NoExiste") } | Should Throw
    }

    It "GetProperty debe lanzar error para nombre vacío" {
        { $script:ctx.GetProperty("") } | Should Throw
    }

    It "SetProperty debe actualizar el valor de una propiedad existente" {
        $script:ctx.SetProperty("NombreProyecto", "NuevoNombre")
        $script:ctx.GetProperty("NombreProyecto") | Should Be "NuevoNombre"
    }

    It "SetProperty debe agregar una propiedad nueva" {
        $script:ctx.SetProperty("NuevaPropiedad", "ValorNuevo")
        $script:ctx.HasProperty("NuevaPropiedad") | Should Be $true
        $script:ctx.GetProperty("NuevaPropiedad") | Should Be "ValorNuevo"
    }

    It "SetProperty debe lanzar error para nombre vacío" {
        { $script:ctx.SetProperty("", "valor") } | Should Throw
    }

    It "HasProperty debe retornar true para propiedad existente" {
        $script:ctx.HasProperty("NombreProyecto") | Should Be $true
    }

    It "HasProperty debe retornar false para propiedad inexistente" {
        $script:ctx.HasProperty("NoExiste") | Should Be $false
    }

    It "HasProperty debe retornar false para nombre vacío" {
        $script:ctx.HasProperty("") | Should Be $false
    }

    It "GetAllProperties debe retornar un hashtable con todas las propiedades" {
        $props = $script:ctx.GetAllProperties()
        ($props -is [hashtable]) | Should Be $true
        $props.Count | Should BeGreaterThan 0
        $props.ContainsKey("NombreProyecto") | Should Be $true
    }

    It "GetAllProperties debe retornar una copia (no la referencia interna)" {
        $props = $script:ctx.GetAllProperties()
        $props["NombreProyecto"] = "Modificado"
        $original = $script:ctx.GetProperty("NombreProyecto")
        $original | Should Be $TestProjectName
    }
}

# --------------------------------------------------------------------------
# Grupo 4: Métodos de acceso directo
# --------------------------------------------------------------------------
Describe "Context - Métodos de acceso directo" {

    BeforeEach {
        $script:ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
    }

    AfterEach {
        $script:ctx.Dispose()
    }

    It "GetContextId debe retornar un GUID" {
        $id = $script:ctx.GetContextId()
        ($id -is [guid]) | Should Be $true
    }

    It "GetContextId nunca cambia durante la vida del contexto" {
        $id1 = $script:ctx.GetContextId()
        $script:ctx.SetProperty("NombreProyecto", "Otro")
        $id2 = $script:ctx.GetContextId()
        $id1 | Should Be $id2
    }

    It "GetCreatedAt debe retornar un DateTime" {
        $date = $script:ctx.GetCreatedAt()
        ($date -is [datetime]) | Should Be $true
    }

    It "GetVersion debe retornar la versión del Kernel" {
        $script:ctx.GetVersion() | Should Be $TestVersion
    }

    It "GetEnvironment debe retornar el nombre del entorno" {
        $script:ctx.GetEnvironment() | Should Be $TestEnvironment
    }

    It "GetRepositoryRoot debe retornar la ruta raíz" {
        $script:ctx.GetRepositoryRoot() | Should Be $TestRoot
    }

    It "GetMotorPath debe retornar la ruta al directorio motor" {
        $expectedPath = [System.IO.Path]::Combine($TestRoot, "motor")
        $script:ctx.GetMotorPath() | Should Be $expectedPath
    }

    It "GetConfigurationPath debe retornar la ruta de configuración" {
        $expectedPath = [System.IO.Path]::Combine($TestRoot, "configuracion")
        $script:ctx.GetConfigurationPath() | Should Be $expectedPath
    }

    It "GetLogsPath debe retornar la ruta de logs" {
        $expectedPath = [System.IO.Path]::Combine($TestRoot, "logs")
        $script:ctx.GetLogsPath() | Should Be $expectedPath
    }
}

# --------------------------------------------------------------------------
# Grupo 5: Validación (Validate)
# --------------------------------------------------------------------------
Describe "Context - Validate" {

    It "Debe retornar true para un contexto válido" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx.Validate() | Should Be $true
        $ctx.Dispose()
    }

    It "Debe retornar false si VersionKernel se cambia a un formato inválido" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx.SetProperty("VersionKernel", "invalido")
        $ctx.Validate() | Should Be $false
        $ctx.Dispose()
    }

    It "Debe retornar false si NombreProyecto se acorta a menos de 3 caracteres" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx.SetProperty("NombreProyecto", "AB")
        $ctx.Validate() | Should Be $false
        $ctx.Dispose()
    }

    It "Debe retornar false si una ruta se vuelve relativa" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx.SetProperty("RutaRaizRepositorio", "relative/path")
        $ctx.Validate() | Should Be $false
        $ctx.Dispose()
    }
}

# --------------------------------------------------------------------------
# Grupo 6: Ciclo de vida (Dispose)
# --------------------------------------------------------------------------
Describe "Context - Ciclo de vida" {

    It "IsDisposed debe retornar false antes de Dispose" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx.IsDisposed() | Should Be $false
        $ctx.Dispose()
    }

    It "IsDisposed debe retornar true después de Dispose" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx.Dispose()
        $ctx.IsDisposed() | Should Be $true
    }

    It "Dispose múltiple no debe lanzar error" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx.Dispose()
        { $ctx.Dispose() } | Should Not Throw
    }

    It "Debe lanzar error al operar sobre un contexto disposed" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx.Dispose()
        { $ctx.GetProperty("NombreProyecto") } | Should Throw
        { $ctx.SetProperty("NombreProyecto", "valor") } | Should Throw
        { $ctx.HasProperty("NombreProyecto") } | Should Throw
        { $ctx.GetAllProperties() } | Should Throw
        { $ctx.GetContextId() } | Should Throw
        { $ctx.GetVersion() } | Should Throw
        { $ctx.Validate() } | Should Throw
    }
}

# --------------------------------------------------------------------------
# Grupo 7: Eventos
# --------------------------------------------------------------------------
Describe "Context - Eventos" {

    It "Debe encolar evento Context.Created al crear el contexto" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $events = $ctx.DrainEventQueue()
        $events.Count | Should BeGreaterThan 0
        $events[0].eventName | Should Be "Context.Created"
        $events[0].source | Should Be "Context"
        $ctx.Dispose()
    }

    It "Debe encolar evento Context.PropertyChanged al modificar una propiedad existente" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $null = $ctx.DrainEventQueue() # Limpiar evento Created
        $ctx.SetProperty("NombreProyecto", "NuevoValor")
        $events = $ctx.DrainEventQueue()
        $evt = $events | Where-Object { $_.eventName -eq "Context.PropertyChanged" } | Select-Object -First 1
        $evt | Should Not BeNullOrEmpty
        ($evt.payload.PropertyName -eq "NombreProyecto") | Should Be $true
        ($evt.payload.NewValue -eq "NuevoValor") | Should Be $true
        $ctx.Dispose()
    }

    It "Debe encolar evento Context.Validated al llamar Validate()" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $null = $ctx.DrainEventQueue() # Limpiar evento Created
        $null = $ctx.Validate()
        $events = $ctx.DrainEventQueue()
        $evt = $events | Where-Object { $_.eventName -eq "Context.Validated" } | Select-Object -First 1
        $evt | Should Not BeNullOrEmpty
        ($evt.payload.IsValid -eq $true) | Should Be $true
        $ctx.Dispose()
    }

    It "DrainEventQueue debe limpiar la cola de eventos" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $events1 = $ctx.DrainEventQueue()
        $events2 = $ctx.DrainEventQueue()
        $events1.Count | Should BeGreaterThan 0
        $events2.Count | Should Be 0
        $ctx.Dispose()
    }

    It "Los eventos deben tener todos los campos requeridos" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $events = $ctx.DrainEventQueue()
        $evt = $events[0]
        $evt.ContainsKey("id") | Should Be $true
        $evt.ContainsKey("eventName") | Should Be $true
        $evt.ContainsKey("timestamp") | Should Be $true
        $evt.ContainsKey("source") | Should Be $true
        $evt.ContainsKey("payload") | Should Be $true
        $ctx.Dispose()
    }
}

# --------------------------------------------------------------------------
# Grupo 8: Normalización de rutas
# --------------------------------------------------------------------------
Describe "Context - Normalización de rutas" {

    It "Debe resolver rutas con separadores mixtos" {
        $mixedRoot = "D:/HERMES-ENTERPRISE"
        $ctx = [Context]::new($TestProjectName, $mixedRoot, $TestVersion, $TestEnvironment)
        $ctx.GetRepositoryRoot() | Should BeExactly $TestRoot
        $ctx.Dispose()
    }

    It "Debe resolver rutas con puntos relativos" {
        $relativeRoot = "D:\HERMES-ENTERPRISE\..\HERMES-ENTERPRISE"
        $ctx = [Context]::new($TestProjectName, $relativeRoot, $TestVersion, $TestEnvironment)
        $ctx.GetRepositoryRoot() | Should BeExactly $TestRoot
        $ctx.Dispose()
    }
}

# --------------------------------------------------------------------------
# Grupo 9: Invariantes del contrato
# --------------------------------------------------------------------------
Describe "Context - Invariantes" {

    It "El IdentificadorContexto nunca cambia durante la vida del contexto" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $originalId = $ctx.GetContextId()
        $ctx.SetProperty("NombreProyecto", "Cambio")
        $ctx.SetProperty("VersionKernel", "2.0.0")
        $ctx.GetContextId() | Should Be $originalId
        $ctx.Dispose()
    }

    It "Las rutas base nunca son null o vacías" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        $ctx.GetRepositoryRoot() | Should Not BeNullOrEmpty
        $ctx.GetMotorPath() | Should Not BeNullOrEmpty
        $ctx.GetConfigurationPath() | Should Not BeNullOrEmpty
        $ctx.GetLogsPath() | Should Not BeNullOrEmpty
        $ctx.Dispose()
    }

    It "El contexto mantiene su estado interno consistente después de múltiples operaciones" {
        $ctx = [Context]::new($TestProjectName, $TestRoot, $TestVersion, $TestEnvironment)
        
        # Realizar múltiples operaciones
        1..10 | ForEach-Object {
            $ctx.SetProperty("Prop_$_", "Valor_$_")
        }
        
        # Verificar consistencia
        $ctx.HasProperty("Prop_1") | Should Be $true
        $ctx.HasProperty("Prop_10") | Should Be $true
        $ctx.GetProperty("Prop_5") | Should Be "Valor_5"
        $ctx.GetProperty("NombreProyecto") | Should Be $TestProjectName
        $ctx.GetContextId().ToString() | Should Not BeNullOrEmpty
        
        $ctx.Dispose()
    }
}