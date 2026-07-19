class ComponentRegistry {
    hidden [hashtable] $registry
    ComponentRegistry() { $this.registry = @{} }
    [void] RegisterComponent([string]$name, [hashtable]$metadata) { $this.registry[$name] = $metadata }
    [object] GetComponent([string]$name) { return $this.registry[$name] }
    [string[]] ListComponents() { return $this.registry.Keys }
}
