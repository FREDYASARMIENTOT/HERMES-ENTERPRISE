class ServiceContainer {
    hidden [hashtable] $services
    ServiceContainer() { $this.services = @{} }
    [void] Register([string]$name, [scriptblock]$factory) { $this.services[$name] = $factory }
    [object] Resolve([string]$name) {
        if (-not $this.services.ContainsKey($name)) { throw "Service '$name' not registered" }
        return & $this.services[$name]
    }
    [bool] Has([string]$name) { return $this.services.ContainsKey($name) }
}
