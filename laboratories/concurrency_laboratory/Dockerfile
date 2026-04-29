FROM python:3.11-slim

# Etiquetas de metadatos
LABEL description="Worker de concurrencia — Laboratorio de Sistemas Operativos"
LABEL version="2.0"

WORKDIR /app

# Instalar dependencias primero (capa cacheada si requirements.txt no cambia)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código fuente
COPY worker.py .

# -u: sin buffering en stdout/stderr → logs inmediatos en docker compose logs
CMD ["python", "-u", "worker.py"]