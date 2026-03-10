# Compilador y flags
CC = gcc
CFLAGS = -Wall -Iinclude

# Carpetas
SRC_DIR = src
INC_DIR = include
OBJ_DIR = obj

# Archivos
SRCS = $(SRC_DIR)/main.c $(SRC_DIR)/mlfq/mlfq.c $(SRC_DIR)/utils/queue.c
OBJS = $(SRCS:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
EXEC = mlfq_app

# Regla principal
all: build_dirs $(EXEC)

# Compilar ejecutable
$(EXEC): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

# Compilar objetos
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# Crear directorios necesarios
build_dirs:
	@mkdir -p $(OBJ_DIR)
	@mkdir -p assets

# Limpiar compilación
clean:
	rm -rf $(OBJ_DIR) $(EXEC)

.PHONY: all build_dirs clean
