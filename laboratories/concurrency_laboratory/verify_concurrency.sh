#!/usr/bin/env bash
# =============================================================================
# verify_concurrency.sh — Demuestra que los workers operaron concurrentemente
# Uso: ./verify_concurrency.sh
# =============================================================================
set -euo pipefail

# Cargar variables de entorno (si existen)
source .env 2>/dev/null || true

# Tomamos las credenciales del .env o usamos las de por defecto
DB_USER="${POSTGRES_USER:-user}"
DB_NAME="${POSTGRES_DB:-lab_db}"
CONTAINER_NAME="concurrency_laboratory-db-1"

# Comando base: Ejecutar psql DENTRO del contenedor
# Usamos -i para que Docker pueda leer el bloque de texto <<'SQL'
PSQL_CMD="docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  EVIDENCIA DE CONCURRENCIA  "
echo "════════════════════════════════════════════════════════════════"

# ── 1. Estado final de la tabla input ────────────────────────────────────────
echo ""
echo "▶ 1. Resumen de estados en tabla INPUT:"
$PSQL_CMD -x <<'SQL'
SELECT
    status,
    COUNT(*) AS total
FROM input
GROUP BY status
ORDER BY status;
SQL

# ── 2. Cuántos registros procesó cada worker ──────────────────────────────────
echo ""
echo "▶ 2. Registros procesados por cada WORKER:"
$PSQL_CMD <<'SQL'
SELECT
    worker_identifier,
    COUNT(*)        AS registros_procesados,
    MIN(date)       AS primer_insercion,
    MAX(date)       AS ultima_insercion,
    ROUND(EXTRACT(EPOCH FROM (MAX(date) - MIN(date)))::NUMERIC, 3) AS duracion_seg
FROM result
GROUP BY worker_identifier
ORDER BY primer_insercion;
SQL

# ── 3. Evidencia de intercalado — 30 primeras inserciones ordenadas por tiempo ─
echo ""
echo "▶ 3. Primeras 30 inserciones (intercalado entre workers):"
$PSQL_CMD <<'SQL'
SELECT
    r.id,
    r.worker_identifier,
    TO_CHAR(r.date, 'HH24:MI:SS.MS') AS timestamp,
    r.input_id
FROM result r
ORDER BY r.date
LIMIT 30;
SQL

# ── 4. Verificación de integridad — sin duplicados ────────────────────────────
echo ""
echo "▶ 4. Verificación de integridad (debe estar vacío si no hay duplicados):"
$PSQL_CMD <<'SQL'
SELECT
    input_id,
    COUNT(*) AS veces_procesado
FROM result
GROUP BY input_id
HAVING COUNT(*) > 1
ORDER BY input_id;
SQL

# ── 5. Ventana de concurrencia real ───────────────────────────────────────────
echo ""
echo "▶ 5. Ventana de tiempo total del experimento:"
$PSQL_CMD <<'SQL'
SELECT
    MIN(date)  AS inicio,
    MAX(date)  AS fin,
    ROUND(EXTRACT(EPOCH FROM (MAX(date) - MIN(date)))::NUMERIC, 3) AS duracion_total_seg,
    COUNT(DISTINCT worker_identifier) AS workers_activos,
    COUNT(*) AS total_resultados
FROM result;
SQL

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  FIN DEL REPORTE"
echo "════════════════════════════════════════════════════════════════"
echo ""