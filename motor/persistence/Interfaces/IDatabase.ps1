<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : IDatabase.ps1
Propósito: Contrato para la gestión de base de datos SQLite
====================================================================================================
#>
class IDatabase {
    [string]$Name
    [string]$FilePath
    [string]$Status # 'Uninitialized','Connected','Disconnected','Faulted'

    IDatabase([string]$name) {
        $this.Name = $name
        $this.Status = 'Uninitialized'
    }

    [void] Connect() { throw 'Connect must be implemented by subclass' }
    [void] Disconnect() { throw 'Disconnect must be implemented by subclass' }
    [bool] TestConnection() { throw 'TestConnection must be implemented by subclass' }
    [int] ExecuteNonQuery([string]$sql) { throw 'ExecuteNonQuery must be implemented by subclass' }
    [System.Data.DataTable] ExecuteQuery([string]$sql) { throw 'ExecuteQuery must be implemented by subclass' }
    [object] ExecuteScalar([string]$sql) { throw 'ExecuteScalar must be implemented by subclass' }
    [void] BeginTransaction() { throw 'BeginTransaction must be implemented by subclass' }
    [void] CommitTransaction() { throw 'CommitTransaction must be implemented by subclass' }
    [void] RollbackTransaction() { throw 'RollbackTransaction must be implemented by subclass' }
}