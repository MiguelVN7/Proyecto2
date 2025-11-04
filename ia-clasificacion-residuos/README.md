# EcoTrack AI Waste Classifier Microservice

Microservicio de clasificación automática de residuos usando Deep Learning (TensorFlow/Keras).

## 🎯 Características

- Clasificación en 3 categorías: **Orgánico**, **Aprovechable**, **No Aprovechable**
- Modelo TensorFlow/Keras optimizado
- API RESTful con FastAPI
- Listo para despliegue en Google Cloud Run
- Health checks y monitoreo
- Modelo dummy para testing sin modelo real

## 📦 Instalación Local

```bash
# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar servidor
uvicorn app.main:app --reload --port 8080
```

## 🧪 Testing

Visita: `http://localhost:8080/docs` para ver la documentación interactiva (Swagger UI)

## 🚀 Despliegue en Google Cloud Run

```bash
# Autenticar con Google Cloud
gcloud auth login
gcloud config set project TU_PROJECT_ID

# Construir imagen
gcloud builds submit --tag gcr.io/TU_PROJECT_ID/waste-classifier

# Desplegar
gcloud run deploy waste-classifier \
  --image gcr.io/TU_PROJECT_ID/waste-classifier \
  --platform managed \
  --region us-central1 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 60s \
  --concurrency 10 \
  --min-instances 0 \
  --max-instances 10 \
  --allow-unauthenticated
```

## 📊 Endpoints

### `GET /` o `/health`
Health check del servicio

### `POST /classify`
Clasificar residuo desde URL de imagen

**Request Body:**
```json
{
  "image_url": "https://storage.googleapis.com/bucket/image.jpg",
  "report_id": "ECO-12345678",
  "user_id": "user_abc123"
}
```

**Response:**
```json
{
  "classification": "Orgánico",
  "confidence": 0.95,
  "report_id": "ECO-12345678",
  "processing_time_ms": 450,
  "model_version": "1.0.0"
}
```

## 🔧 Desarrollo

Para entrenar tu propio modelo, coloca el archivo `.h5` en la carpeta `models/` con el nombre `waste_classifier_v1.h5`.

## 📝 Notas

- El modelo dummy se usa automáticamente si no hay modelo real
- El modelo se carga en memoria al iniciar (warm-up)
- Timeout configurado para 60 segundos
- Límite de imagen: 10MB
