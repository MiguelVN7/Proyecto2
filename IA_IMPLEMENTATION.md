# 🤖 Implementación de Clasificación Automática con IA - EcoTrack

## 📋 Descripción

Sistema completo de clasificación automática de residuos usando Inteligencia Artificial. Cuando un usuario toma una foto de un residuo, la IA clasifica automáticamente en:
- **Orgánico**
- **Aprovechable** 
- **No Aprovechable**

Y muestra el nivel de confianza de la predicción.

## 🏗️ Arquitectura

```
[Usuario toma foto en Flutter App]
           ↓
[Sube imagen a Firebase Storage]
           ↓
[Cloud Function detecta nueva imagen]
           ↓
[Llama a Microservicio IA en Cloud Run]
           ↓
[IA clasifica y guarda resultado en Firestore]
           ↓
[Flutter App muestra clasificación en tiempo real]
```

## 📱 Frontend (Flutter)

### Cambios Realizados

1. **Modelo Reporte actualizado** (`lib/models/reporte.dart`)
   - Nuevos campos: `aiConfidence`, `aiProcessingTimeMs`, `aiClassifiedAt`, `aiModelVersion`
   - Getter `isAiClassified` para verificar si fue clasificado por IA

2. **Widget de Confianza IA** (`lib/widgets/ai_confidence_indicator.dart`)
   - `AIConfidenceIndicator`: Widget completo con detalles
   - `AIConfidenceBadge`: Badge compacto para listas
   - `AIClassificationDetails`: Detalles expandidos
   - Colores según nivel de confianza:
     - Verde (≥85%): Alta confianza
     - Naranja (70-85%): Confianza media
     - Rojo (<70%): Baja confianza

3. **HomeScreen actualizado** (`lib/screens/home_screen.dart`)
   - Tarjeta de último reporte muestra badge de IA
   - Lista de actividad reciente muestra badge de IA
   - Indicadores visuales de confianza

### Vista Previa

```dart
// Ejemplo de uso en cualquier pantalla
if (report.isAiClassified && report.aiConfidence != null) {
  AIConfidenceBadge(confidence: report.aiConfidence!)
}
```

## 🤖 Backend (Microservicio IA)

### Estructura del Proyecto

```
ia-clasificacion-residuos/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app
│   ├── model_loader.py      # Cargador del modelo
│   ├── classifier.py        # Lógica de clasificación
│   └── schemas.py           # Modelos Pydantic
├── models/
│   └── .gitkeep             # Placeholder para modelo
├── Dockerfile               # Docker para Cloud Run
├── requirements.txt         # Dependencias Python
└── README.md
```

### Componentes

1. **FastAPI Application** (`app/main.py`)
   - Endpoints RESTful
   - Health checks
   - Manejo de errores
   - CORS configurado

2. **Model Loader** (`app/model_loader.py`)
   - Carga modelo TensorFlow/Keras
   - Warm-up automático
   - Modelo dummy para testing
   - Preprocesamiento de imágenes

3. **Classifier** (`app/classifier.py`)
   - Descarga segura de imágenes
   - Validación de tamaño y tipo
   - Medición de tiempo de procesamiento

### API Endpoints

#### `GET /` o `/health`
Health check del servicio

**Response:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "version": "1.0.0",
  "uptime_seconds": 123.45
}
```

#### `POST /classify`
Clasificar residuo desde URL

**Request:**
```json
{
  "image_url": "https://storage.googleapis.com/...",
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

## 🚀 Despliegue

### Paso 1: Desplegar Microservicio en Cloud Run

```bash
cd ia-clasificacion-residuos

# Configurar proyecto
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

# Obtener URL del servicio
gcloud run services describe waste-classifier \
  --platform managed \
  --region us-central1 \
  --format 'value(status.url)'
```

### Paso 2: Configurar Firebase Functions (Próximo)

```javascript
// functions/index.js
// Cloud Function que orquesta la clasificación
// Se activa automáticamente cuando se sube una imagen
```

## 🧪 Testing Local

### Microservicio IA

```bash
cd ia-clasificacion-residuos

# Crear entorno virtual
python -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar servidor
uvicorn app.main:app --reload --port 8080

# Abrir documentación interactiva
open http://localhost:8080/docs
```

### Flutter App

```bash
cd frontend

# Ejecutar app
flutter run

# Verificar que se muestran los badges de IA
# en reportes que tengan el campo ai_confidence
```

## 📊 Métricas y Monitoreo

### Latencia Esperada
- Descarga de imagen: ~100-300ms
- Clasificación IA: ~200-500ms
- Total: **~0.5-1 segundo**

### Costos Estimados (Google Cloud)
- Cloud Run: $0 en free tier (2M requests/mes)
- Con tráfico: ~$0.00024 por request
- Storage: ~$0.026/GB/mes

### Escalado
- Min instances: 0 (escala a cero cuando no hay uso)
- Max instances: 10
- Concurrency: 10 requests por instancia

## 🔒 Seguridad

### Firestore Security Rules (Actualizar)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /reports/{reportId} {
      // Permitir lectura a usuarios autenticados
      allow read: if request.auth != null;
      
      // Permitir actualización de campos IA desde Cloud Functions
      allow update: if request.auth != null && 
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['ai_confidence', 'ai_processing_time_ms', 
                    'ai_classified_at', 'ai_model_version', 'clasificacion']);
    }
  }
}
```

## 📝 Próximos Pasos

1. ✅ **Frontend Flutter**: Modelo y widgets creados
2. ✅ **Microservicio IA**: Estructura completa lista
3. ⏳ **Cloud Function**: Orquestador pendiente
4. ⏳ **Modelo ML**: Entrenar modelo real
5. ⏳ **Testing E2E**: Pruebas completas del flujo
6. ⏳ **Monitoreo**: Cloud Monitoring y alertas

## 🎓 Recursos

- [TensorFlow Lite para Flutter](https://www.tensorflow.org/lite/guide/flutter)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Firebase Functions](https://firebase.google.com/docs/functions)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

## 👥 Equipo

**Historia de Usuario**: Como ciudadano quiero que el sistema clasifique automáticamente el residuo para simplificar mi reporte.

**Criterios de Aceptación**:
- ✅ Clasificación en 3 categorías (Orgánico, Aprovechable, No Aprovechable)
- ✅ Mostrar porcentaje de confianza de la IA
- ⏳ Tiempo de respuesta < 2 segundos
- ⏳ Precisión > 85% con el modelo entrenado

---

**Última actualización**: 22 de octubre de 2025
**Versión**: 1.0.0
