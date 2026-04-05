#!/bin/bash
# ============================================================
#  run_lab.sh — Construye y levanta el contenedor del lab
#  Ejecutar en Fedora desde la carpeta del proyecto
# ============================================================

IMAGE_NAME="lab-useradmin"
CONTAINER_NAME="lab-usuarios"

echo "▸ Construyendo imagen Docker..."
docker build -t "$IMAGE_NAME" .

if [[ $? -ne 0 ]]; then
    echo "✖ Error al construir la imagen. Verifica el Dockerfile."
    exit 1
fi

echo ""
echo "▸ Iniciando contenedor interactivo..."
echo "  (Escribe 'exit' para salir del contenedor)"
echo ""

docker run -it --rm \
    --name "$CONTAINER_NAME" \
    --hostname "lab-linux" \
    "$IMAGE_NAME"
