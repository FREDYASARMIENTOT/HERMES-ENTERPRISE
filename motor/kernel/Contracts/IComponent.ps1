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