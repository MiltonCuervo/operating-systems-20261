# --- Variables ---
# El compilador que usaremos
CC = gcc
# Las banderas de compilación exigidas [cite: 108]
CFLAGS = -Wall -Wextra -std=c11 -I./include
# El nombre del ejecutable final [cite: 102]
TARGET = ticket_app

# --- Archivos fuente ---
# Aquí listamos todos nuestros archivos .c
SRCS = src/main.c src/ticket/ticket.c src/utils/utils.c

# --- Targets (Objetivos) ---

# 'all' es el target por defecto. Depende de $(TARGET) [cite: 104]
all: $(TARGET)

# Regla para construir el ejecutable.
# Toma los SRCS y los compila con las CFLAGS para generar el TARGET
$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) $(SRCS) -o $(TARGET)

# 'run' compila (si es necesario) y luego ejecuta el programa [cite: 106]
run: all
	./$(TARGET)

# 'clean' borra el ejecutable para limpiar el entorno [cite: 105, 114]
clean:
	rm -f $(TARGET)
