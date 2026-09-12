<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-BootLoader.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida BootLoader y KernelHost del núcleo Core.
====================================================================================================
#>

Set-StrictMode -Version Latest

# ============================================================================
# Shared Setup - needs to be at script scope for BootLoader.ps1 compatibility
# ============================================================================
$global:HERMES_REPO_ROOT = "D:\HERMES-ENTERPRISE"

# ============================================================================
# BootLoader Tests
# ============================================================================
Describe "BootLoader" {

    It "Load-Descriptors debe retornar array vacío si no hay archivos JSON" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Contracts\IComponent.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\BootLoader.ps1")
        $tmpDir = Join-Path $env:TEMP "hermes-boot-empty-$([System.Guid]::NewGuid().ToString('N'))"
        New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
        try {
            $descs = Load-Descriptors -DescriptorsPath $tmpDir
            # Load-Descriptors returns @() which gets unwrapped to $null in pipeline
            # Accept both null and empty array as valid
            if ($null -eq $descs) { $descs = @() }
            ($descs.Count) | Should Be 0
        } finally {
            Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Validate-Descriptors debe validar descriptores correctos" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Contracts\IComponent.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\BootLoader.ps1")
        $descs = @(@{ id = "A" }, @{ id = "B" })
        Validate-Descriptors -Descriptors $descs | Should Be $true
    }

    It "Validate-Descriptors debe lanzar si falta propiedad id" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Contracts\IComponent.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\BootLoader.ps1")
        $descs = @(@{ id = "A" }, @{ name = "B" })
        { Validate-Descriptors -Descriptors $descs } | Should Throw
    }

    It "Build-ComponentFactory debe crear un scriptblock válido" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Contracts\IComponent.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\BootLoader.ps1")
        $desc = @{ id = "Demo" }
        $factory = Build-ComponentFactory -Descriptor $desc
        $factory | Should Not BeNullOrEmpty
        ($factory -is [scriptblock]) | Should Be $true
    }
}

# ============================================================================
# KernelHost Tests
# ============================================================================
Describe "KernelHost" {

    It "Debe crear una instancia con un ServiceContainer" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Contracts\IComponent.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\ServiceContainer.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\EventBus.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\ComponentRegistry.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\KernelHost.ps1")
        $container = [ServiceContainer]::new()
        $bus = [EventBus]::new()
        $container.Register("EventBus", { return $bus })
        $container.Register("Registry", { return [ComponentRegistry]::new() })
        $kernelInstance = [KernelHost]::new($container)
        $kernelInstance | Should Not BeNullOrEmpty
    }

    It "Emit debe publicar eventos en el EventBus" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Contracts\IComponent.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\ServiceContainer.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\EventBus.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\ComponentRegistry.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\KernelHost.ps1")
        $container = [ServiceContainer]::new()
        $bus = [EventBus]::new()
        $recibido = $null
        $bus.Subscribe("prueba.evento", { param($p) $script:recibido = $p })
        $container.Register("EventBus", { return $bus })
        $container.Register("Registry", { return [ComponentRegistry]::new() })
        $kernelInstance = [KernelHost]::new($container)
        $kernelInstance.Emit("prueba.evento", @{ valor = 123 })
        $script:recibido.emitter | Should Be "KernelHost"
        $script:recibido.payload.valor | Should Be 123
    }

    It "RunStartup debe lanzar si un componente falla en Initialize" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Contracts\IComponent.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\ServiceContainer.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\EventBus.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\ComponentRegistry.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\KernelHost.ps1")

        function New-FailingComponent {
            param([string]$Id)
            $comp = [PSCustomObject]@{
                Id            = $Id
                Version       = "1.0"
                Requires      = @()
                Capabilities  = @()
                KernelContext = $null
            }
            $comp | Add-Member -MemberType ScriptMethod -Name "Initialize" -Value {
                param([hashtable]$ctx)
                throw "Error en init"
            }
            $comp | Add-Member -MemberType ScriptMethod -Name "Validate" -Value {}
            $comp | Add-Member -MemberType ScriptMethod -Name "Start" -Value {}
            $comp | Add-Member -MemberType ScriptMethod -Name "Stop" -Value {}
            $comp | Add-Member -MemberType ScriptMethod -Name "Dispose" -Value {}
            return $comp
        }

        $container = [ServiceContainer]::new()
        $bus = [EventBus]::new()
        $container.Register("EventBus", { return $bus })
        $container.Register("Registry", { return [ComponentRegistry]::new() })

        $compDescFallido = @{
            id = "Fallido"
            factory = { return (New-FailingComponent -Id "Fallido") }
        }

        $kernelHostInstance = [KernelHost]::new($container)
        { $kernelHostInstance.RunStartup(@($compDescFallido)) } | Should Throw
    }
}

# ============================================================================
# Core Integration Tests
# ============================================================================
Describe "Core Integration" -Tag "Integration" {

    It "ServiceContainer + EventBus + ComponentRegistry deben funcionar juntos" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Contracts\IComponent.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\ServiceContainer.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\EventBus.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\ComponentRegistry.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Core\KernelHost.ps1")

        $container = [ServiceContainer]::new()
        $bus = [EventBus]::new()
        $registry = [ComponentRegistry]::new()

        $container.Register("EventBus", { return $bus })
        $container.Register("Registry", { return $registry })
        $registry.RegisterComponent("BootstrapOrchestrator", @{ version = "1.0"; tipo = "core" })
        $registry.RegisterComponent("CertificationEngine", @{ version = "1.0"; tipo = "core" })

        $componentes = $registry.ListComponents()
        ($componentes.Count) | Should Be 2

        $resolvedBus = $container.Resolve("EventBus")
        $resolvedReg = $container.Resolve("Registry")
        $resolvedBus | Should Be $bus
        $resolvedReg | Should Be $registry

        $recibido = $null
        $bus.Subscribe("sistema.iniciado", { param($p) $script:recibido = $p })
        $bus.Publish("sistema.iniciado", @{ servicios = @("EventBus", "Registry") })
        ($script:recibido.servicios.Count) | Should Be 2
    }
}