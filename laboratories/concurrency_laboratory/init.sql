-- init.sql — Inicialización de la base de datos
-- Se ejecuta automáticamente al levantar el contenedor de Postgres.

-- Tabla de entradas (datos a procesar)
CREATE TABLE IF NOT EXISTS input (
    id          SERIAL PRIMARY KEY,
    description TEXT        NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'in_process', 'processed'))
);

-- Índice en status para acelerar la query de selección de pendientes
-- (evita full-scan con 5+ workers compitiendo por el mismo índice)
CREATE INDEX IF NOT EXISTS idx_input_status ON input (status);

-- Tabla de resultados (escrituras concurrentes de los workers)
CREATE TABLE IF NOT EXISTS result (
    id                 SERIAL PRIMARY KEY,
    input_id           INT         NOT NULL REFERENCES input(id),
    worker_identifier  VARCHAR(100) NOT NULL,
    result             TEXT        NOT NULL,
    date               TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índice para consultas de evidencia de concurrencia (ordenar por tiempo)
CREATE INDEX IF NOT EXISTS idx_result_date ON result (date);

-- =============================================================================
-- Datos de prueba: 100 registros con estado 'pending'
-- =============================================================================
INSERT INTO input (description)
SELECT 'Dato de prueba #' || gs || ' — lote inicial'
FROM generate_series(1, 100) AS gs;