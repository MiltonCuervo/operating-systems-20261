# Laboratorio de Concurrencia — Sistemas Operativos

Sistema distribuido en contenedores que demuestra concurrencia, sincronización y consistencia de datos usando PostgreSQL, Docker Compose y Python.

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                   Docker Compose                     │
│                                                      │
│  ┌──────────┐   ┌─────────┐                         │
│  │  db      │   │ db-init │  (verifica datos, exit 0)│
│  │ Postgres │◄──│         │                         │
│  │ :5432    │   └─────────┘                         │
│  └────┬─────┘                                       │
│       │ FOR UPDATE SKIP LOCKED + pg_advisory_lock    │
│  ┌────┴──────────────────────────────────────────┐  │
│  │  worker_1  worker_2  worker_3  worker_4  worker_5 │
│  │  (Python — concurrencia a nivel de contenedor)│  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## Mecanismos de Concurrencia Implementados

| Mecanismo | Propósito |
|---|---|
| `FOR UPDATE SKIP LOCKED` | Cada worker toma un registro distinto sin bloquear a los demás |
| `pg_advisory_lock` | Exclusión mutua cross-container para el log compartido |
| Transacción atómica | `SELECT + UPDATE + INSERT + UPDATE` = operación indivisible |
| Backoff exponencial | El worker reintenta la conexión a la BD hasta 10 veces |
| `AUTOINCREMENT` en BD | Nunca se calcula el `id` manualmente → sin condiciones de carrera |

## Estructura del Proyecto

```
concurrency_laboratory/
├── docker-compose.yml     # Orquestación: db + db-init + 5 workers
├── Dockerfile             # Imagen del worker
├── worker.py              # Lógica principal del worker
├── init.sql               # Schema + 100 registros de prueba
├── requirements.txt       # Dependencias Python
├── verify_concurrency.sh  # Script de evidencia de concurrencia
├── .env                   # Credenciales (NO subir a git)
└── .gitignore
```

## Cómo Ejecutar

### 1. Levantar el sistema con 5 workers

```bash
# Construir las imágenes
docker compose build

# Levantar con exactamente 5 workers concurrentes
docker compose up --scale worker=5
```

### 2. Ver logs en tiempo real (en otra terminal)

```bash
docker compose logs -f worker
```

### 3. Ver logs intercalados con timestamps

```bash
docker compose logs --timestamps worker | sort -k1
```

### 4. Generar evidencia de concurrencia

```bash
# Cuando todos los workers hayan finalizado:
chmod +x verify_concurrency.sh
./verify_concurrency.sh
```

### 5. Consultas manuales de evidencia

Postgres corre dentro de Docker, por lo que las consultas se ejecutan con `docker exec`:

```bash
# Abrir sesión interactiva en el contenedor de BD
docker exec -it concurrency_laboratory-db-1 psql -U lab_user -d lab_db
```

```bash
# Ver inserciones intercaladas (evidencia clave de concurrencia)
docker exec -i concurrency_laboratory-db-1 psql -U lab_user -d lab_db -c \
  "SELECT worker_identifier, input_id, TO_CHAR(date,'HH24:MI:SS.MS') AS ts FROM result ORDER BY date LIMIT 20;"

# Verificar que no hay duplicados
docker exec -i concurrency_laboratory-db-1 psql -U lab_user -d lab_db -c \
  "SELECT input_id, COUNT(*) FROM result GROUP BY input_id HAVING COUNT(*) > 1;"

# Estadísticas por worker
docker exec -i concurrency_laboratory-db-1 psql -U lab_user -d lab_db -c \
  "SELECT worker_identifier, COUNT(*) FROM result GROUP BY worker_identifier;"
```

### 6. Limpiar el entorno

```bash
docker compose down -v   # -v elimina los volúmenes (reset completo)
```

## Esquema de la Base de Datos

```sql
-- Entradas a procesar
CREATE TABLE input (
    id          SERIAL PRIMARY KEY,
    description TEXT        NOT NULL,
    status      VARCHAR(20) DEFAULT 'pending'  -- pending | in_process | processed
);

-- Resultados (escrituras concurrentes)
CREATE TABLE result (
    id                SERIAL PRIMARY KEY,
    input_id          INT REFERENCES input(id),
    worker_identifier VARCHAR(100) NOT NULL,
    result            TEXT         NOT NULL,
    date              TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);
```

## Troubleshooting

**Los workers terminan inmediatamente sin procesar nada**
```bash
# Verificar que la BD tiene datos (Postgres corre en Docker)
docker exec -i concurrency_laboratory-db-1 psql -U lab_user -d lab_db \
  -c "SELECT COUNT(*) FROM input WHERE status='pending';"
```

**`deploy.replicas` no levanta 5 workers**
> `deploy.replicas` solo aplica en Docker Swarm. Usar siempre `--scale worker=5`.

**Error de conexión a la BD**
> El worker reintenta automáticamente hasta 10 veces con backoff exponencial. Si falla, revisar que `db` esté corriendo: `docker compose ps`.
