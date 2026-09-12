# TestHelpers.psm1 — Provides IComponent type and test IComponent subclasses for Pester
# This module allows class inheritance at parse time via `using module`

# ============================================================================
# IComponent base class — defined inline for parse-time resolution
# This mirrors motor\kernel\Contracts\IComponent.ps1 so that class inheritance
# works at parse time when this module is imported via `using module`
# ============================================================================
class IComponent {
    [string]$Id
    [string]$Version
    [string[]]$Requires
    [string[]]$Capabilities
    IComponent([string]$id,[string]$ver,[string[]]$req,[string[]]$caps){
        $this.Id=$id; $this.Version=$ver; $this.Requires=$req; $this.Capabilities=$caps
    }
    [void] Initialize([hashtable]$KernelContext) { throw 'Initialize must be implemented by subclass' }
    [void] Validate() { throw 'Validate must be implemented by subclass' }
    [void] Start() { throw 'Start must be implemented by subclass' }
    [void] Stop() { throw 'Stop must be implemented by subclass' }
    [void] Dispose() { throw 'Dispose must be implemented by subclass' }
}

# ============================================================================
# Test IComponent implementations for BootLoader/KernelHost tests
# These must be defined here so `using module` makes them available at parse time
# ============================================================================
class CompA : IComponent {
    CompA() : base("CompA", "1.0", @(), @("Test")){}
    [void] Initialize([hashtable]$ctx) {}
    [void] Validate() {}
    [void] Start() {}
    [void] Stop() {}
    [void] Dispose() {}
}

class CompB : IComponent {
    CompB() : base("CompB", "1.0", @(), @("Test")){}
    [void] Initialize([hashtable]$ctx) {}
    [void] Validate() {}
    [void] Start() {}
    [void] Stop() {}
    [void] Dispose() {}
}

class CompFallido : IComponent {
    CompFallido() : base("Fallido", "1.0", @(), @()){}
    [void] Initialize([hashtable]$ctx) { throw "Error en init" }
    [void] Validate() {}
    [void] Start() {}
    [void] Stop() {}
    [void] Dispose() {}
}

class ExitComp : IComponent {
    ExitComp() : base("ExitComp", "1.0", @(), @("Prueba")){}
    [void] Initialize([hashtable]$ctx) {}
    [void] Validate() {}
    [void] Start() {}
    [void] Stop() {}
    [void] Dispose() {}
}

class CompContextual : IComponent {
    CompContextual() : base("CompContextual", "1.0", @(), @("Contextual")){}
    [void] Initialize([hashtable]$ctx) { $this.KernelContext = $ctx }
    [void] Validate() {}
    [void] Start() {
        if ($this.KernelContext -and $this.KernelContext.ContainsKey("Emit")) {
            & $this.KernelContext["Emit"]("CompContextual.Listo", @{})
        }
    }
    [void] Stop() {}
    [void] Dispose() {}
}

Export-ModuleMember -Function * -Variable * -Alias *