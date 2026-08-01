<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : IProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Contrato para proveedores (providers) del Kernel Enterprise.
    Define el ciclo de vida estándar y las capacidades que todo provider debe implementar.
====================================================================================================
#>

class IProvider {
    [string]$Id
    [string]$Name
    [string]$Version
    [string]$ProviderType  # 'Cloud', 'Storage', 'Auth', 'AI', etc.
    [string]$Status        # 'Stopped', 'Initialized', 'Running', 'Faulted'

    IProvider([string]$id, [string]$name, [string]$version, [string]$providerType) {
        $this.Id = $id
        $this.Name = $name
        $this.Version = $version
        $this.ProviderType = $providerType
        $this.Status = 'Stopped'
    }

    [void] Initialize([hashtable]$ProviderConfig) { throw 'Initialize must be implemented by subclass' }
    [void] Validate() { throw 'Validate must be implemented by subclass' }
    [void] Connect() { throw 'Connect must be implemented by subclass' }
    [void] Disconnect() { throw 'Disconnect must be implemented by subclass' }
    [void] Dispose() { throw 'Dispose must be implemented by subclass' }
    [bool] TestConnection() { throw 'TestConnection must be implemented by subclass' }
}