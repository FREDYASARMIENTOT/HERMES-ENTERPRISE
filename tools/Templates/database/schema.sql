-- SQLite Schema for {{PROJECT_NAME}}
-- Generated: {{TIMESTAMP}}
-- CorrelationId: {{CORRELATION_ID}}

CREATE TABLE IF NOT EXISTS Proyecto (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Nombre TEXT NOT NULL,
    Descripcion TEXT DEFAULT '',
    Version TEXT DEFAULT '1.0.0',
    CorrelationId TEXT NOT NULL UNIQUE,
    Estado TEXT DEFAULT 'CREADO',
    Repositorio TEXT DEFAULT '',
    Branch TEXT DEFAULT 'main',
    CommitHash TEXT DEFAULT '',
    UrlPublica TEXT DEFAULT '',
    Region TEXT DEFAULT '',
    DeploymentId TEXT DEFAULT '',
    EstadoAzure TEXT DEFAULT 'PENDIENTE',
    EstadoGitHub TEXT DEFAULT 'PENDIENTE',
    EstadoCI TEXT DEFAULT 'PENDIENTE',
    TiempoBuild REAL DEFAULT 0,
    TiempoDeploy REAL DEFAULT 0,
    TiempoSmokeTest REAL DEFAULT 0,
    FechaCreacion TEXT DEFAULT (datetime('now', 'localtime')),
    FechaActualizacion TEXT DEFAULT (datetime('now', 'localtime'))
);

CREATE TABLE IF NOT EXISTS Timeline (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    CorrelationId TEXT NOT NULL,
    Evento TEXT NOT NULL,
    Estado TEXT NOT NULL,
    Fecha TEXT DEFAULT (datetime('now', 'localtime')),
    Detalle TEXT DEFAULT '',
    Duracion REAL DEFAULT 0,
    FOREIGN KEY (CorrelationId) REFERENCES Proyecto(CorrelationId)
);

CREATE TABLE IF NOT EXISTS SmokeTestResults (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    CorrelationId TEXT NOT NULL,
    Endpoint TEXT NOT NULL,
    HTTPCode INTEGER DEFAULT 0,
    Estado TEXT DEFAULT 'PENDIENTE',
    TiempoRespuesta REAL DEFAULT 0,
    Fecha TEXT DEFAULT (datetime('now', 'localtime')),
    Detalle TEXT DEFAULT '',
    FOREIGN KEY (CorrelationId) REFERENCES Proyecto(CorrelationId)
);

CREATE TABLE IF NOT EXISTS BitacoraEventos (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    CorrelationId TEXT NOT NULL,
    Fecha TEXT DEFAULT (datetime('now', 'localtime')),
    Hora TEXT DEFAULT (strftime('%H:%M:%S', 'now', 'localtime')),
    Usuario TEXT DEFAULT '{{USER}}',
    Paso TEXT NOT NULL,
    Estado TEXT NOT NULL,
    Duracion REAL DEFAULT 0,
    Mensaje TEXT DEFAULT '',
    Resultado TEXT DEFAULT '',
    FOREIGN KEY (CorrelationId) REFERENCES Proyecto(CorrelationId)
);

-- ============================================================
-- REGISTRO DE IMPLEMENTACION — Trazabilidad completa del ciclo
-- de vida del proyecto Child: Factory → GitHub → CI → Control
-- Plane → OIDC → Azure → Deploy → Readiness → Tests → Evidence
-- ============================================================
CREATE TABLE IF NOT EXISTS Implementacion (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    CorrelationId TEXT NOT NULL UNIQUE,
    NombreProyecto TEXT NOT NULL,
    Repositorio TEXT DEFAULT '',
    CommitSolicitado TEXT DEFAULT '',
    CommitDesplegado TEXT DEFAULT '',
    DeploymentId TEXT DEFAULT '',
    EstadoGeneral TEXT DEFAULT 'PENDIENTE',
    PasosCompletados INTEGER DEFAULT 0,
    PasosFallidos INTEGER DEFAULT 0,
    PasosTotales INTEGER DEFAULT 0,
    DuracionTotalSegundos REAL DEFAULT 0,
    FechaInicio TEXT DEFAULT (datetime('now', 'localtime')),
    FechaFin TEXT,
    FOREIGN KEY (CorrelationId) REFERENCES Proyecto(CorrelationId)
);

CREATE TABLE IF NOT EXISTS PasoImplementacion (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    CorrelationId TEXT NOT NULL,
    NumeroPaso INTEGER NOT NULL,
    NombrePaso TEXT NOT NULL,
    NumeroSubpaso TEXT,          -- ej. "01.01", "02.03"
    NombreSubpaso TEXT,
    Estado TEXT DEFAULT 'PENDIENTE',   -- PENDIENTE | EN_PROCESO | COMPLETADO | FALLIDO | OMITIDO
    FechaInicio TEXT,
    FechaFin TEXT,
    DuracionSegundos REAL DEFAULT 0,
    Detalle TEXT DEFAULT '',
    Evidencia TEXT DEFAULT '',
    Resultado TEXT DEFAULT '',    -- PASS / FAIL / N/A
    FOREIGN KEY (CorrelationId) REFERENCES Proyecto(CorrelationId)
);

CREATE INDEX IF NOT EXISTS idx_paso_corr ON PasoImplementacion(CorrelationId);
CREATE INDEX IF NOT EXISTS idx_paso_numero ON PasoImplementacion(NumeroPaso, NumeroSubpaso);