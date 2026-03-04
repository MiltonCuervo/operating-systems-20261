# Sistema de Registro de Tickets en C (Linux)

Este proyecto implementa un sistema de consola en lenguaje C para el registro y gestión de tickets de reclamación. El sistema está diseñado bajo el estándar **C11**, utilizando **memoria dinámica**, **punteros a estructuras** y **persistencia en archivos**.

```markdown
## Estructura del Proyecto

El proyecto sigue una arquitectura modular separando la interfaz (headers) de la implementación (sources):

```text
ticket_system/
├── assets/                 # Almacenamiento de tickets generados (.txt)
├── include/                # Archivos de cabecera (.h)
│   ├── ticket/             # Contratos del módulo Ticket
│   └── utils/              # Contratos de utilidades generales
├── src/                    # Código fuente (.c)
│   ├── main.c              # Punto de entrada
│   ├── ticket/             # Lógica de negocio (Ticket)
│   └── utils/              # Implementación de utilidades I/O
├── Makefile                # Automatización de compilación
└── README.md               # Documentación

```

## Requisitos

* **SO:** Linux (o entorno compatible POSIX).
* **Compilador:** GCC (GNU Compiler Collection).
* **Herramienta de construcción:** Make.

## Compilación y Ejecución

El proyecto incluye un `Makefile` para automatizar el ciclo de vida del software.

### 1. Compilar el proyecto

Genera el ejecutable `ticket_app` en la raíz:

```bash
make

```

### 2. Compilar y Ejecutar (Recomendado)

Compila (si es necesario) e inicia el programa inmediatamente:

```bash
make run

```

### 3. Limpiar el entorno

Elimina el ejecutable y archivos objeto para una compilación limpia:

```bash
make clean

```

---

## Explicación Técnica

### 1. Modularización y Punteros

El sistema evita el uso de variables globales. La comunicación entre módulos se realiza mediante **paso por referencia**.

* **Estructuras (`struct`):** Se define `Ticket` como un tipo de dato personalizado.
* **Punteros (`Ticket*`):** En lugar de copiar toda la estructura (lo cual es ineficiente en memoria), se pasan direcciones de memoria. Se utiliza el operador flecha (`->`) para acceder a los miembros de la estructura a través de su puntero.

### 2. Gestión de Memoria Dinámica (Heap vs Stack)

Para garantizar la escalabilidad, los tickets no se crean en el *Stack* (pila), sino en el *Heap* (montículo).

* **`malloc`:** Se utiliza para solicitar memoria al sistema operativo en tiempo de ejecución (`sizeof(Ticket)`).
* **Validación:** Se verifica estrictamente que el puntero retornado no sea `NULL` (caso de memoria llena).
* **`free`:** Se libera explícitamente la memoria al finalizar el proceso para evitar **Memory Leaks** (fugas de memoria).

### 3. Entrada Segura de Datos

Se prohíbe el uso de `gets` por su vulnerabilidad a *Buffer Overflows*.

* **`fgets`:** Se utiliza para limitar la lectura al tamaño del buffer.
* **Limpieza:** Se implementan utilidades (`strcspn`) para eliminar el salto de línea residual (`\n`) que `fgets` captura.

### 4. Persistencia (Archivos)

El sistema utiliza la biblioteca estándar `<stdio.h>` para I/O de archivos.

* Se genera dinámicamente el nombre del archivo basado en el radicado único.
* Se utiliza `fopen` en modo escritura (`"w"`).
* Se valida la apertura del archivo antes de escribir.

### 5. Generación del Radicado

El número de radicado se garantiza único mediante la función:

```c
(long)time(NULL) + (rand() % 1000);

```

Utiliza el *Unix Epoch Time* (segundos desde 1970) más un desplazamiento aleatorio, asegurando que cada ejecución produzca identificadores distintos.

## Flags de Compilación

El `Makefile` fuerza buenas prácticas utilizando:

* `-std=c11`: Estándar moderno de C.
* `-Wall -Wextra`: Activa todas las advertencias posibles para garantizar código limpio y seguro.

