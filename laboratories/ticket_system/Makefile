# --- Variables ---
CC = gcc
# Las banderas de compilacion
CFLAGS = -Wall -Wextra -std=c11 -I./include
# El nombre del ejecutable final
TARGET = ticket_app

# --- Archivos fuente ---
SRCS = src/main.c src/ticket/ticket.c src/utils/utils.c

# --- Targets ----
all: $(TARGET)
$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) $(SRCS) -o $(TARGET)

# Compila y luego ejecuta el programa 
run: all
	./$(TARGET)

# Borrar el ejecutable para limpiar el entorno 
clean:
	rm -f $(TARGET)
