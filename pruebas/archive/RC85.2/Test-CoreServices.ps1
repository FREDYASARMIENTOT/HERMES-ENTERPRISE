using module ..\..\motor\kernel\Core\CoreServices.psm1

<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-CoreServices.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida los servicios del núcleo Core del Kernel:
    - ServiceContainer (DI container)
    - EventBus (sistema de eventos)
    - ComponentRegistry (registro de componentes)
    - IComponent contract (contrato base de componentes)
====================================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================================
# ServiceContainer Tests
# ============================================================================
Describe "ServiceContainer" {
    It "Debe crear una instancia vacía" {
        $c = [ServiceContainer]::new()
        $c | Should Not BeNullOrEmpty
    }

    It "Debe registrar y resolver un servicio" {
        $c = [ServiceContainer]::new()
        $c.Register("MiServicio", { return "Hola Mundo" })
        $resultado = $c.Resolve("MiServicio")
        $resultado | Should Be "Hola Mundo"
    }

    It "Debe lanzar excepción al resolver un servicio no registrado" {
        $c = [ServiceContainer]::new()
        { $c.Resolve("NoExiste") } | Should Throw
    }

    It "Has debe retornar true para servicio registrado" {
        $c = [ServiceContainer]::new()
        $c.Register("TestService", { return 42 })
        $c.Has("TestService") | Should Be $true
    }

    It "Has debe retornar false para servicio no registrado" {
        $c = [ServiceContainer]::new()
        $c.Has("NoExiste") | Should Be $false
    }

    It "Debe ejecutar factory cada vez que se resuelve" {
        $c = [ServiceContainer]::new()
        $c.Register("Contador", { return 1 })
        $v1 = $c.Resolve("Contador")
        $v2 = $c.Resolve("Contador")
        # Factory is invoked each time — both calls return 1
        $v1 | Should Be 1
        $v2 | Should Be 1
    }

    It "Debe permitir registrar múltiples servicios" {
        $c = [ServiceContainer]::new()
        $c.Register("A", { return "A" })
        $c.Register("B", { return "B" })
        $c.Register("C", { return "C" })
        $c.Resolve("A") | Should Be "A"
        $c.Resolve("B") | Should Be "B"
        $c.Resolve("C") | Should Be "C"
    }

    It "Debe sobrescribir un servicio existente" {
        $c = [ServiceContainer]::new()
        $c.Register("X", { return "original" })
        $c.Register("X", { return "sobrescrito" })
        $c.Resolve("X") | Should Be "sobrescrito"
    }
}

# ============================================================================
# EventBus Tests
# ============================================================================
Describe "EventBus" {
    It "Debe crear una instancia vacía" {
        $b = [EventBus]::new()
        $b | Should Not BeNullOrEmpty
    }

    It "Debe suscribirse y recibir eventos publicados" {
        $b = [EventBus]::new()
        $recibido = $null
        $b.Subscribe("test.event", { param($p) $script:_recibido = $p })
        $b.Publish("test.event", @{ mensaje = "Hola" })
        $script:_recibido.mensaje | Should Be "Hola"
    }

    It "Debe entregar payload a todos los suscriptores" {
        $b = [EventBus]::new()
        $script:_resultadosAE = @()
        $b.Subscribe("multi.event", { param($p) $script:_resultadosAE += "A:$($p.valor)" })
        $b.Subscribe("multi.event", { param($p) $script:_resultadosAE += "B:$($p.valor)" })
        $b.Publish("multi.event", @{ valor = 99 })
        ($script:_resultadosAE.Count) | Should Be 2
        $script:_resultadosAE[0] | Should Be "A:99"
        $script:_resultadosAE[1] | Should Be "B:99"
    }

    It "No debe fallar al publicar en evento sin suscriptores" {
        $b = [EventBus]::new()
        { $b.Publish("evento.sin.suscriptores", @{}) } | Should Not Throw
    }

    It "Debe ignorar eventos con nombre diferente" {
        $b = [EventBus]::new()
        $script:_ignorado = $null
        $b.Subscribe("evento.correcto", { param($p) $script:_ignorado = $p.valor })
        $b.Publish("evento.incorrecto", @{ valor = "no deberia llegar" })
        $script:_ignorado | Should BeNullOrEmpty
    }

    It "Debe listar las suscripciones activas" {
        $b = [EventBus]::new()
        $b.Subscribe("evt1", {})
        $b.Subscribe("evt2", {})
        $claves = $b.Subscriptions()
        ($claves.Count) | Should Be 2
        $claves -contains "evt1" | Should Be $true
        $claves -contains "evt2" | Should Be $true
    }

    It "Debe funcionar con múltiples eventos y suscripciones independientes" {
        $b = [EventBus]::new()
        $b.Subscribe("A", { param($p) $script:_valAA = $p })
        $b.Subscribe("B", { param($p) $script:_valBB = $p })
        $b.Publish("A", "valorA")
        $b.Publish("B", "valorB")
        $script:_valAA | Should Be "valorA"
        $script:_valBB | Should Be "valorB"
    }
}

# ============================================================================
# ComponentRegistry Tests
# ============================================================================
Describe "ComponentRegistry" {
    It "Debe crear una instancia vacía" {
        $r = [ComponentRegistry]::new()
        $r | Should Not BeNullOrEmpty
    }

    It "Debe registrar y obtener un componente" {
        $r = [ComponentRegistry]::new()
        $metadata = @{ version = "1.0"; descripcion = "Componente de prueba" }
        $r.RegisterComponent("TestComp", $metadata)
        $obtenido = $r.GetComponent("TestComp")
        $obtenido.version | Should Be "1.0"
        $obtenido.descripcion | Should Be "Componente de prueba"
    }

    It "Debe retornar null al obtener componente inexistente" {
        $r = [ComponentRegistry]::new()
        $r.GetComponent("NoExiste") | Should BeNullOrEmpty
    }

    It "Debe listar los componentes registrados" {
        $r = [ComponentRegistry]::new()
        $r.RegisterComponent("Comp1", @{})
        $r.RegisterComponent("Comp2", @{})
        $lista = $r.ListComponents()
        ($lista.Count) | Should Be 2
        $lista -contains "Comp1" | Should Be $true
        $lista -contains "Comp2" | Should Be $true
    }

    It "Debe sobrescribir metadata de un componente existente" {
        $r = [ComponentRegistry]::new()
        $r.RegisterComponent("Actualizable", @{ estado = "v1" })
        $r.RegisterComponent("Actualizable", @{ estado = "v2" })
        $obtenido = $r.GetComponent("Actualizable")
        $obtenido.estado | Should Be "v2"
    }
}

# ============================================================================
# IComponent Contract Tests
# ============================================================================
Describe "IComponent contract" {
    BeforeAll {
        . (Join-Path $PSScriptRoot "..\..\motor\kernel\Contracts\IComponent.ps1")
    }

    It "Debe crear una instancia de IComponent base" {
        $comp = [IComponent]::new("TestId", "1.0.0", @("Dep1"), @("Cap1"))
        $comp.Id | Should Be "TestId"
        $comp.Version | Should Be "1.0.0"
        ($comp.Requires.Count) | Should Be 1
        $comp.Requires[0] | Should Be "Dep1"
        ($comp.Capabilities.Count) | Should Be 1
        $comp.Capabilities[0] | Should Be "Cap1"
    }

    It "Initialize debe lanzar en clase base" {
        $comp = [IComponent]::new("Base", "1.0.0", @(), @())
        { $comp.Initialize(@{}) } | Should Throw
    }

    It "Validate debe lanzar en clase base" {
        $comp = [IComponent]::new("Base", "1.0.0", @(), @())
        { $comp.Validate() } | Should Throw
    }

    It "Start debe lanzar en clase base" {
        $comp = [IComponent]::new("Base", "1.0.0", @(), @())
        { $comp.Start() } | Should Throw
    }

    It "Stop debe lanzar en clase base" {
        $comp = [IComponent]::new("Base", "1.0.0", @(), @())
        { $comp.Stop() } | Should Throw
    }

    It "Dispose debe lanzar en clase base" {
        $comp = [IComponent]::new("Base", "1.0.0", @(), @())
        { $comp.Dispose() } | Should Throw
    }

    It "Debe aceptar Requires y Capabilities vacíos" {
        $comp = [IComponent]::new("Minimo", "0.0.1", @(), @())
        ($comp.Requires.Count) | Should Be 0
        ($comp.Capabilities.Count) | Should Be 0
    }
}