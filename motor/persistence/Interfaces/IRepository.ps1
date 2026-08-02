<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : IRepository.ps1
Propósito: Contrato genérico para repositorios del sistema de persistencia
====================================================================================================
#>
class IRepository {
    [string]$EntityName
    [string]$TableName

    IRepository([string]$entityName, [string]$tableName) {
        $this.EntityName = $entityName
        $this.TableName = $tableName
    }

    [void] Insert([hashtable]$data) { throw 'Insert must be implemented by subclass' }
    [void] Update([string]$id, [hashtable]$data) { throw 'Update must be implemented by subclass' }
    [void] Delete([string]$id) { throw 'Delete must be implemented by subclass' }
    [psobject] GetById([string]$id) { throw 'GetById must be implemented by subclass' }
    [System.Collections.ArrayList] GetAll() { throw 'GetAll must be implemented by subclass' }
    [int] Count() { throw 'Count must be implemented by subclass' }
    [bool] Exists([string]$id) { throw 'Exists must be implemented by subclass' }
}