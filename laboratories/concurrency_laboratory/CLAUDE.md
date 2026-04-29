# Laboratorio de Concurrencia — Guía de Comandos Rápidos

Este archivo es una referencia rápida para Claude y para el estudiante.

## Comandos esenciales

```bash
# Levantar 5 workers concurrentes
docker compose up --scale worker=5

# Seguir logs en tiempo real
docker compose logs -f --timestamps worker | sort -k1

# Generar reporte de evidencia
./verify_concurrency.sh

# Limpiar todo (reset completo)
docker compose down -v
```

## Archivos del proyecto

| Archivo | Propósito |
|---|---|
| `worker.py` | Worker principal — transacciones atómicas + advisory locks |
| `docker-compose.yml` | Orquestación: db + db-init + N workers |
| `init.sql` | Schema + 100 registros de prueba |
| `Dockerfile` | Imagen del worker |
| `verify_concurrency.sh` | Script de evidencia de concurrencia |
| `.env` | Credenciales (no versionar) |
| `README.md` | Documentación completa |

## Mecanismos de sincronización implementados

1. **`FOR UPDATE SKIP LOCKED`** — PostgreSQL asigna un registro distinto a cada worker  
2. **`pg_advisory_lock`** — Exclusión mutua cross-container para el log compartido  
3. **Transacción atómica única** — Sin `BEGIN`/`ROLLBACK` manuales; psycopg2 gestiona el ciclo  
4. **Backoff exponencial** — 10 reintentos espaciados antes de fallar  