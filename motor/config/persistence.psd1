@{
    # ──────────────────────────────────────────────────────────────────────────
    # Hermes Enterprise — Persistence Configuration
    # All persistence modules consume this configuration.
    # Nothing is hardcoded.
    # ──────────────────────────────────────────────────────────────────────────

    Provider       = 'SQLite'

    SQLite         = @{
        DatabasePath = './data/hermes.db'
        JournalMode  = 'WAL'
        BusyTimeout  = 30000
        CacheSize    = 20000
        ForeignKeys  = $true
    }

    HermesSQLiteProvider = @{
        AssemblyPath = './lib/HermesSQLiteProvider.dll'
    }

    Initialize     = @{
        EnableTelemetry = $true
        EnableAudit     = $true
        SeedData        = $true
        TestData        = $false
    }
}