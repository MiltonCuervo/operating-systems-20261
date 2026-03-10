# Simulador de Planificador MLFQ (Multi-Level Feedback Queue) en C

Este proyecto implementa un simulador en lenguaje C de un algoritmo de planificación de CPU **MLFQ** (Colas Multinivel con Retroalimentación). El sistema está diseñado utilizando **estructuras de datos personalizadas** (Colas Circulares), **paso por referencia mediante punteros**, gestión dinámica de prioridades y **persistencia de métricas** en formato CSV.


```markdown
## Estructura del Proyecto

El proyecto sigue una arquitectura modular y escalable, separando estrictamente la definición de interfaces (headers) de la lógica de implementación (sources):

```text
mlfq_reto/
├── assets/                 # Almacenamiento de métricas generadas (.csv)
├── include/                # Archivos de cabecera (.h)
│   ├── mlfq/               # Constantes y contratos del planificador
│   └── utils/              # Definición de estructuras (Process, Queue)
├── src/                    # Código fuente (.c)
│   ├── main.c              # Punto de entrada del simulador
│   ├── mlfq/               # Lógica del motor MLFQ y cálculo de métricas
│   └── utils/              # Implementación de Cola Circular (FIFO)
├── obj/                    # Archivos objeto compilados (autogenerados)
├── Makefile                # Automatización del proceso de compilación
└── README.md               # Documentación técnica

```

## Requisitos

* **SO:** Linux (o entorno compatible POSIX como Fedora/Ubuntu).
* **Compilador:** GCC (GNU Compiler Collection).
* **Herramienta de construcción:** Make.

## Compilación y Ejecución

El proyecto incluye un `Makefile` para automatizar el ciclo de vida del software, la creación de directorios dinámicos y el enlazado de binarios.

### 1. Compilar el proyecto

Genera los archivos objeto (`.o`) y el ejecutable final `mlfq_app` en la raíz:

```bash
make

```

### 2. Ejecutar la Simulación

Inicia el simulador del planificador:

```bash
./mlfq_app

```

### 3. Limpiar el entorno

Elimina el ejecutable y la carpeta de archivos objeto para garantizar una compilación limpia desde cero:

```bash
make clean

```

---

## Explicación Técnica

### 1. Estructuras de Datos y Paso por Referencia

El núcleo del simulador evita la redundancia de datos manejando los procesos en memoria centralizada y moviendo únicamente **punteros** entre las colas.

* **Estructuras (`struct`):** Se definen los tipos `Process` (almacena el PCB o Bloque de Control del Proceso) y `Queue`.
* **Colas Circulares (`Queue`):** Para la gestión de los niveles (Q0, Q1, Q2) se implementó una cola circular estática basada en arrays. Utiliza índices `front` y `rear` junto con aritmética modular (`% 100`) para lograr inserciones y extracciones en complejidad espacial $O(1)$ sin necesidad de desplazar elementos.

### 2. Reglas del Motor MLFQ

El algoritmo implementa las reglas clásicas de un planificador Multi-Level Feedback Queue:

1. **Llegadas (Prioridad Máxima):** Todo proceso nuevo ingresa siempre a la cola de mayor prioridad (`Q0`).
2. **Consumo de Quantum y Democión:** Si un proceso agota su *quantum* de tiempo asignado en su cola actual (`Q0=2`, `Q1=4`, `Q2=8` ciclos), es interrumpido (preempted) y degradado a la cola inferior inmediata.
3. **Prevención de Inanición (Priority Boost):** Para evitar que los procesos limitados por CPU en colas bajas sufran de *starvation*, el sistema ejecuta un "Boost" cada `20` ciclos de reloj, elevando todos los procesos activos de vuelta a `Q0`.

### 3. Simulación de Reloj (Ticks)

El sistema no depende de hilos del SO (`threads`), sino de un bucle determinista (`while`) que simula el avance del reloj del procesador (`current_time++`). En cada "tick", el planificador evalúa llegadas, finalizaciones, agotamiento de quantums e interrupciones por procesos de mayor prioridad.

### 4. Cálculo de Métricas y Persistencia I/O

Al finalizar la ejecución de todos los procesos, el sistema calcula las métricas clave de rendimiento del SO y utiliza `<stdio.h>` para la persistencia:

* **Fórmulas aplicadas:**
* `Turnaround Time = finish_time - arrival_time`
* `Waiting Time = turnaround_time - burst_time`
* `Response Time = start_time - arrival_time`


* **Exportación CSV:** Se utiliza `fopen` en modo escritura (`"w"`) y `fprintf` para estructurar la salida en `assets/results.csv`, permitiendo su posterior análisis en hojas de cálculo.

## Flags de Compilación

El `Makefile` impone seguridad en la compilación utilizando:

* `-Wall`: Activa todas las advertencias del compilador para garantizar código limpio (sin declaraciones implícitas ni variables sin uso).
* `-Iinclude`: Vincula dinámicamente el directorio de cabeceras para mantener los `#include` limpios y sin rutas relativas complejas.

```

---

¡Con esto tu proyecto queda a nivel profesional! Tienes un código C bien estructurado, un Makefile robusto, compilación sin errores, salida perfecta y ahora un README técnico excelente.

¿Quieres que te muestre rápidamente cómo crear un archivo `.gitignore` para que al hacer `git push` no subas los binarios (`mlfq_app` y los `.o`) por accidente?

```