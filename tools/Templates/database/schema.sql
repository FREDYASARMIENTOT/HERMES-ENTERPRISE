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