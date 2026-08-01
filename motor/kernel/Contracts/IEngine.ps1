<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : IEngine.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Contrato para motores (engines) del Kernel Enterprise.
    Define el ciclo de vida estándar que todo motor debe implementar.
====================================================================================================
#>

class IEngine {
    [string]$Id
    [string]$Name
    [string]$Version
    [string]$Status  # 'Stopped', 'Starting', 'Running', 'Stopping', 'Faulted'

    IEngine([string]$id, [string]$name, [string]$version) {
        $this.Id = $id
        $this.Name = $name
        $this.Version = $version
        $this.Status = 'Stopped'
    }

    [void] Initialize([hashtable]$EngineContext) { throw 'Initialize must be implemented by subclass' }
    [void] Validate() { throw 'Validate must be implemented by subclass' }
    [void] Start() { throw 'Start must be implemented by subclass' }
    [void] Stop() { throw 'Stop must be implemented by subclass' }
    [void] Dispose() { throw 'Dispose must be implemented by subclass' }
}