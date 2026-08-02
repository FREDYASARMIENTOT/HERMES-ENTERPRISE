<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : IMigration.ps1
Propósito: Contrato para el motor de migraciones
====================================================================================================
#>
class IMigration {
    [int]$Version
    [string]$Description
    [string]$Type # 'Schema', 'Data', 'Index', 'Seed'
    [string]$Status # 'Pending', 'Executed', 'Failed', 'RolledBack'

    IMigration([int]$version, [string]$description, [string]$type) {
        $this.Version = $version
        $this.Description = $description
        $this.Type = $type
        $this.Status = 'Pending'
    }

    [string] GetUpSql() { throw 'GetUpSql must be implemented by subclass' }
    [string] GetDownSql() { throw 'GetDownSql must be implemented by subclass' }
    [bool] Validate() { throw 'Validate must be implemented by subclass' }
}