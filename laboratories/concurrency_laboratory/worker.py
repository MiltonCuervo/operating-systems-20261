import os
import time
import random
import logging
import psycopg2
from psycopg2 import pool, OperationalError

# ──────────────────────────────────────────────────────────────────────────────
# Configuración
# ──────────────────────────────────────────────────────────────────────────────
WORKER_ID   = os.environ.get('WORKER_NAME', os.environ.get('HOSTNAME', 'worker_unknown'))
DB_DSN      = os.environ.get('DATABASE_URL', 'postgresql://user:pass@db:5432/lab_db')

# Advisory lock key único para el log compartido (constante arbitraria de 64 bits)
LOG_ADVISORY_KEY = 123456789

# ──────────────────────────────────────────────────────────────────────────────
# Logging con formato enriquecido
# ──────────────────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s.%(msecs)03d [%(name)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
)
logger = logging.getLogger(WORKER_ID)


# ──────────────────────────────────────────────────────────────────────────────
# Conexión con reintentos y backoff exponencial
# ──────────────────────────────────────────────────────────────────────────────
def create_pool(dsn: str, retries: int = 10, base_delay: float = 1.0) -> pool.SimpleConnectionPool:
    """Intenta crear el connection pool con backoff exponencial."""
    for attempt in range(1, retries + 1):
        try:
            db_pool = pool.SimpleConnectionPool(1, 2, dsn)
            logger.info(f"Conexión a la BD establecida (intento {attempt}).")
            return db_pool
        except OperationalError as e:
            delay = base_delay * (2 ** (attempt - 1)) + random.uniform(0, 0.5)
            logger.warning(f"BD no disponible (intento {attempt}/{retries}): {e}. Reintentando en {delay:.1f}s…")
            time.sleep(delay)
    logger.error("No se pudo conectar a la BD tras todos los intentos. Abortando.")
    raise SystemExit(1)


db_pool = create_pool(DB_DSN)


# ──────────────────────────────────────────────────────────────────────────────
# Log compartido protegido por pg_advisory_lock (cross-container safe)
# ──────────────────────────────────────────────────────────────────────────────
def write_shared_log(conn, message: str):
    """
    Escribe en el log compartido usando un PostgreSQL advisory lock para
    garantizar exclusión mutua entre contenedores distintos.
    fcntl.flock() solo funciona entre procesos del mismo host; los advisory
    locks de Postgres son seguros a través de la red y entre contenedores.
    """
    with conn.cursor() as cur:
        cur.execute("SELECT pg_advisory_lock(%s)", (LOG_ADVISORY_KEY,))
        try:
            logger.info(message)
        finally:
            cur.execute("SELECT pg_advisory_unlock(%s)", (LOG_ADVISORY_KEY,))


# ──────────────────────────────────────────────────────────────────────────────
# Procesamiento principal
# ──────────────────────────────────────────────────────────────────────────────
def process_next_record() -> bool:
    """
    Obtiene y procesa UN registro pendiente de forma atómica.

    Patrón: una única transacción que:
      1. Selecciona el registro con FOR UPDATE SKIP LOCKED        → exclusión
      2. Lo marca como 'in_process'                               → visibilidad
      3. Simula el procesamiento (fuera de la sección crítica)
      4. Inserta el resultado en `result`
      5. Marca el registro como 'processed'
      6. Hace COMMIT atómico de los pasos 2-5

    Retorna True si procesó un registro, False si no quedaban pendientes.
    """
    conn = db_pool.getconn()
    try:
        # autocommit=False es el default en psycopg2; nunca llamar BEGIN/ROLLBACK
        # directamente con cur.execute ya que el driver gestiona las transacciones.
        conn.autocommit = False

        with conn.cursor() as cur:
            # ── TRANSACCIÓN ÚNICA ─────────────────────────────────────────────
            # Paso 1: Adquirir el siguiente registro pendiente de forma exclusiva.
            # SKIP LOCKED evita que dos workers compitan por el mismo registro.
            cur.execute("""
                SELECT id, description
                FROM input
                WHERE status = 'pending'
                ORDER BY id
                LIMIT 1
                FOR UPDATE SKIP LOCKED;
            """)
            record = cur.fetchone()

            if record is None:
                conn.rollback()
                return False

            input_id, description = record

            # Paso 2: Marcar como en proceso dentro de la misma transacción.
            cur.execute(
                "UPDATE input SET status = 'in_process' WHERE id = %s",
                (input_id,)
            )

        # Commit parcial: libera el lock de fila para que otros workers avancen
        # mientras este worker "procesa" (simula trabajo independiente).
        conn.commit()

        logger.info(f"Obtuvo lote ID={input_id} | desc='{description}' → procesando…")

        # ── PROCESAMIENTO (fuera de sección crítica) ──────────────────────────
        processing_time = random.uniform(0.3, 1.2)
        time.sleep(processing_time)
        result_text = (
            f"[{WORKER_ID}] Procesado en {processing_time:.3f}s | "
            f"original='{description}' | ÉXITO"
        )

        # ── TRANSACCIÓN FINAL ─────────────────────────────────────────────────
        # Paso 4+5: Registrar resultado y marcar como processed atómicamente.
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO result (input_id, worker_identifier, result)
                VALUES (%s, %s, %s)
            """, (input_id, WORKER_ID, result_text))

            cur.execute(
                "UPDATE input SET status = 'processed' WHERE id = %s",
                (input_id,)
            )

        conn.commit()
        logger.info(f"Guardó resultado para ID={input_id} | tiempo={processing_time:.3f}s")
        return True

    except Exception as exc:
        conn.rollback()
        logger.error(f"ERROR procesando: {exc}", exc_info=True)
        return False
    finally:
        db_pool.putconn(conn)


# ──────────────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    logger.info(f"Worker '{WORKER_ID}' iniciado y listo.")

    processed = 0
    while True:
        has_more = process_next_record()
        if not has_more:
            logger.info(
                f"No hay más datos pendientes. "
                f"Este worker procesó {processed} registro(s). Finalizando."
            )
            break
        processed += 1
        # Breve pausa para no saturar CPU y dar visibilidad a la concurrencia en logs
        time.sleep(0.05)