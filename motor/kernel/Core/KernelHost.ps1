. 'D:/HERMES-ENTERPRISE/motor/kernel/Core/ServiceContainer.ps1'
. 'D:/HERMES-ENTERPRISE/motor/kernel/Core/EventBus.ps1'
. 'D:/HERMES-ENTERPRISE/motor/kernel/Core/ComponentRegistry.ps1'

class KernelHost {
    hidden [ServiceContainer] $container
    hidden [EventBus] $eventBus
    hidden [ComponentRegistry] $registry
    KernelHost([ServiceContainer]$container){
        $this.container=$container
        $this.eventBus = $this.container.Resolve('EventBus')
        $this.registry = $this.container.Resolve('Registry')
    }
    [void] Emit([string]$event,[object]$payload){
        # KernelHost audits and publishes
        $enriched = @{ timestamp=(Get-Date).ToString('o'); emitter='KernelHost'; payload=$payload }
        $this.eventBus.Publish($event,$enriched)
    }
    [void] RunStartup([object[]]$components){
        foreach ($cdesc in $components) {
            $id = $cdesc.id
            $factory = $cdesc.factory
            $this.container.Register($id,$factory)
        }
        foreach ($cdesc in $components) {
            $id = $cdesc.id
            $comp = $this.container.Resolve($id)
            $KernelContext = @{ Emit = { param($e,$p) $this.Emit($e,$p) }; ResolveDependency = { param($name) $this.container.Resolve($name) } }
            $comp.Initialize($KernelContext)
            $comp.Validate()
            $comp.Start()
            $this.Emit("$id.STARTED", @{component=$id})
        }
    }
}
