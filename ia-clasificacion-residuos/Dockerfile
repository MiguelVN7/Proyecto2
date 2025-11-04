FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements e instalar
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código y modelo
COPY app/ ./app/
COPY models/ ./models/

# Usuario no-root para seguridad
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Exponer puerto
EXPOSE 8080

# Variables de entorno
ENV PYTHONUNBUFFERED=1
ENV PORT=8080

# Comando de inicio
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT}
