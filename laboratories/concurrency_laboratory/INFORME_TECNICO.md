# Informe Técnico — Laboratorio de Concurrencia
**Curso:** Sistemas Operativos  
**Tema:** Sistema Distribuido con Contenedores y Concurrencia en Base de Datos  

---

## 1. Arquitectura del Sistema

El sistema se compone de **7 contenedores** orquestados con Docker Compose, todos sobre una red interna compartida:

```
┌──────────────────────────────────────────────────────────────┐
│                        Docker Compose                        │
│                                                              │
│  ┌─────────────────┐   ┌──────────────────┐                 │
│  │      db          │   │     db-init       │                │
│  │  PostgreSQL 15   │◄──│  Verifica datos   │ (exit 0)       │
│  │  puerto 5432     │   │  y termina        │                │
│  └────────┬─────────┘   └──────────────────┘                │
│           │                                                  │
│           │  FOR UPDATE SKIP LOCKED + pg_advisory_lock       │
│           │                                                  │
│  ┌────────┴─────────────────────────────────────────────┐   │
│  │  worker-1  worker-2  worker-3  worker-4  worker-5     │   │
│  │        (Python 3.11 — concurrencia real)              │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

| Servicio | Imagen | Rol | Cantidad |
|---|---|---|---|
| `db` | `postgres:15-alpine` | Base de datos compartida | 1 |
| `db-init` | `postgres:15-alpine` | Inicialización y verificación de datos | 1 |
| `worker` | Imagen propia (Python 3.11) | Procesamiento concurrente | 5 |

El archivo `init.sql` crea las tablas `input` y `result`, e inserta 100 registros de prueba. El servicio `db-init` verifica que los datos existen antes de que los workers inicien, gracias a la dependencia `condition: service_completed_successfully`.

---

## 2. Distribución del Trabajo entre Contenedores

Cada worker ejecuta en bucle la siguiente lógica hasta que no quedan registros `pending`:

1. Consulta la tabla `input` buscando el próximo registro disponible.
2. PostgreSQL le asigna exclusivamente **un único registro** distinto al de los demás workers.
3. Lo procesa de forma independiente (simulado con un `sleep` aleatorio de 0.3 a 1.2 segundos).
4. Registra el resultado en la tabla `result` e indica el trabajo como `processed`.

La distribución **no es manual**: no se divide la tabla por rangos de ID ni se asignan lotes fijos. PostgreSQL actúa como scheduler natural mediante `FOR UPDATE SKIP LOCKED`, garantizando que cada registro sea procesado exactamente una vez, por exactamente un worker.

---

## 3. Mecanismos para Evitar Condiciones de Carrera

### 3.1 `FOR UPDATE SKIP LOCKED` — Selección exclusiva de filas

```sql
SELECT id, description
FROM input
WHERE status = 'pending'
ORDER BY id
LIMIT 1
FOR UPDATE SKIP LOCKED;
```

Cuando varios workers consultan simultáneamente, PostgreSQL bloquea la fila que un worker ya tomó. Los demás workers **saltan** ese registro (`SKIP LOCKED`) en lugar de esperar o leerlo también, tomando el siguiente disponible. Esto elimina la condición de carrera en la lectura sin necesidad de sincronización a nivel de aplicación.

### 3.2 Transacción Atómica

Toda la operación sobre un registro ocurre dentro de una transacción ACID gestionada por `psycopg2` (`autocommit=False`):

```
BEGIN (implícito)
  → UPDATE input SET status = 'in_process'    ← marca como ocupado
  → (procesamiento independiente fuera de la BD)
  → INSERT INTO result (...)                   ← escribe resultado
  → UPDATE input SET status = 'processed'      ← cierra el ciclo
COMMIT
```

Si el worker falla en cualquier punto, el `rollback` automático devuelve el registro a su estado anterior, sin corrupción ni pérdida de datos.

### 3.3 `pg_advisory_lock` — Mutex Cross-Container

```python
cur.execute("SELECT pg_advisory_lock(%s)", (LOG_ADVISORY_KEY,))
# sección crítica: escritura en log compartido
cur.execute("SELECT pg_advisory_unlock(%s)", (LOG_ADVISORY_KEY,))
```

Los advisory locks de PostgreSQL son semáforos de exclusión mutua visibles para **todos los clientes conectados a la BD**, independientemente del host o contenedor. A diferencia de `fcntl.flock()` (que solo funciona entre procesos del mismo sistema operativo), este mecanismo funciona correctamente entre contenedores distintos sobre la red.

---

## 4. Manejo Autoincremental de la Base de Datos

Ambas tablas definen su clave primaria como `SERIAL`:

```sql
CREATE TABLE input  (id SERIAL PRIMARY KEY, ...);
CREATE TABLE result (id SERIAL PRIMARY KEY, ...);
```

`SERIAL` en PostgreSQL es equivalente a una **secuencia atómica interna**. Cada `INSERT` solicita el siguiente valor de la secuencia, que PostgreSQL entrega de forma atómica sin importar cuántos clientes inserten en paralelo.

> **Por qué esto importa:** calcular el ID en la aplicación con `SELECT MAX(id) + 1` sería una condición de carrera clásica: dos workers podrían leer el mismo `MAX(id)` y generar el mismo ID siguiente, causando colisión o `UNIQUE CONSTRAINT` error.

---

## 5. Manejo de la Concurrencia sobre la Base de Datos

El sistema implementa **tres capas de protección** apiladas:

| Capa | Mecanismo | Protege contra |
|---|---|---|
| BD — nivel de fila | `FOR UPDATE SKIP LOCKED` | Dos workers leyendo el mismo registro pendiente |
| BD — nivel de transacción | Transacciones ACID | Corrupción, pérdida de datos ante fallo parcial |
| BD — nivel de sesión | `pg_advisory_lock` | Escrituras simultáneas al log compartido |
| Aplicación — conexiones | `SimpleConnectionPool(minconn=1, maxconn=2)` | Saturación de conexiones (máx. 10 para 5 workers) |
| Aplicación — inicio | Backoff exponencial (10 reintentos) | Condición de carrera al arrancar todos los workers juntos |

---

## 6. Resultados Obtenidos

Tras ejecutar `docker compose up --scale worker=5` con 100 registros de prueba:

| Métrica | Resultado |
|---|---|
| Registros procesados | 100 / 100 |
| Registros duplicados | 0 |
| Workers activos simultáneamente | 5 |
| Duración total del experimento | ~17 segundos |
| `worker_identifier` distintos en `result` | 5 |

**Evidencia de concurrencia:** los `input_id` en la tabla `result` aparecen fuera de orden cronológico (ej: `1, 2, 4, 3, 5, 7, 6, 9...`), lo que demuestra que múltiples workers procesaban registros en paralelo y escribían resultados de forma intercalada, no secuencial.

Los resultados se obtuvieron con el script `verify_concurrency.sh`, que ejecuta 5 consultas SQL directamente sobre el contenedor de BD:

```bash
./verify_concurrency.sh
```

---

## 7. Dificultades Encontradas

### `deploy.replicas` ignorado por Docker Compose
La directiva `deploy.replicas: 5` en `docker-compose.yml` solo tiene efecto en **Docker Swarm** (`docker stack deploy`). Con `docker compose up` estándar es ignorada silenciosamente, levantando únicamente 1 worker. La solución fue usar `docker compose up --scale worker=5`.

### `fcntl.flock()` no funciona entre contenedores
La implementación inicial usaba `fcntl.flock()` para la exclusión mutua del log compartido. Este mecanismo garantiza exclusión mutua solo entre **procesos del mismo host físico**. En contenedores distintos —aunque monten el mismo volumen Docker— no tiene efecto. Se reemplazó por `pg_advisory_lock` de PostgreSQL.

### Doble transacción rota en `psycopg2`
El código original llamaba `cur.execute("BEGIN")` manualmente luego de un `conn.commit()`. En `psycopg2`, cada `commit()` cierra la transacción activa y la siguiente operación abre una nueva de forma implícita; llamar `BEGIN` explícitamente deja el cursor en estado indefinido. Se eliminaron todas las llamadas manuales a `BEGIN` y `ROLLBACK`, delegando el ciclo de vida de la transacción completamente al driver.

### Identificación de workers
Con `--scale worker=5`, todos los contenedores compartían el mismo valor de `WORKER_NAME: "worker"` definido en el compose, haciendo que los 5 workers aparecieran como uno solo en la tabla `result`. Se eliminó esa variable de entorno para que cada contenedor usara su `HOSTNAME`, que Docker Compose diferencia automáticamente (`...-worker-1`, `-2`, etc.).

---

## 8. Orquestación y Redes en Docker

Para que un sistema distribuido funcione correctamente, la concurrencia en código debe ir acompañada de una buena orquestación de infraestructura. En este laboratorio, Docker Compose aporta dos soluciones vitales:

### 8.1 Aislamiento de Red y Resolución DNS
Docker Compose crea automáticamente una red virtual tipo `bridge`. Los workers no se conectan a una IP estática, sino al hostname `db`. El DNS interno de Docker resuelve `db` a la IP dinámica del contenedor de PostgreSQL. Esto permite que el sistema sea portátil y que la base de datos se mantenga completamente aislada del exterior, recibiendo conexiones únicamente de los contenedores de su misma red.

### 8.2 Control de Flujo de Inicio (Healthchecks)
En sistemas distribuidos, la condición de carrera no solo ocurre en los datos, sino en **el tiempo de arranque**. Si los 5 workers inician antes de que PostgreSQL termine de cargar sus archivos internos, el sistema colapsaría. 
Para solucionarlo, el `docker-compose.yml` implementa:
1.  **Healthchecks:** Un script interno en el contenedor de BD que ejecuta `pg_isready` cada 3 segundos.
2.  **Depends_on (service_healthy):** Docker bloquea el inicio de los workers hasta que el healthcheck de la BD devuelva un estado verde (sano). Esto, sumado al *backoff exponencial* en Python, garantiza tolerancia a fallos total en el arranque.
