# Hermes Enterprise

Enterprise-grade PowerShell framework for system automation, persistence, and observability.

## Status

**RC50.1 — Persistence Layer Finalized**

- SQLite integration via HermesSQLiteProvider (C# custom DLL)
- 75/75 integration tests passing
- Full CRUD, migrations, repositories, seed data, telemetry, backup/recovery

## Quick Start

```powershell
Import-Module .\motor\persistence\HermesPersistence.psm1 -Force
$mgr = New-HermesDatabaseManager -Path ".\data\hermes.db"
Connect-HermesDatabase -Manager $mgr
Initialize-HermesPersistence -Manager $mgr
Disconnect-HermesDatabase -Manager $mgr
```

## Key Components

| Module | Description |
|--------|-------------|
| `HermesPersistence.psm1` | Database manager, SQL execution, schema, migrations |
| `HermesSQLiteProvider.dll` | Custom C# ADO.NET provider for SQLite |
| `Test-PersistenceLayer.ps1` | 75 integration tests across 11 groups |

## Test Results

```
Total Tests : 75
Passed      : 75
Failed      : 0
Pass Rate   : 100%
```

## Documentation

See `/documentacion/` for full architecture, contracts, and design decisions.