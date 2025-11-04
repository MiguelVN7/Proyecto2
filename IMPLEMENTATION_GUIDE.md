# 🤖 Guía de Implementación: Clasificación Automática de Residuos con IA

## 📋 Resumen de Implementación

Esta guía documenta la implementación completa de la funcionalidad de clasificación automática de residuos usando IA para la aplicación EcoTrack.

## ✅ Estado Actual

### Frontend (Flutter) ✅ COMPLETADO

- [x] Modelo `Reporte` actualizado con campos de IA
  - `aiConfidence`: Nivel de confianza (0.0 - 1.0)
  - `aiProcessingTimeMs`: Tiempo de procesamiento
  - `aiClassifiedAt`: Timestamp de clasificación
  - `aiModelVersion`: Versión del modelo
  - Getter `isAiClassified`: Indica si fue clasificado por IA

- [x] Widget `AIConfidenceIndicator` creado
  - Modo compacto para listas
  - Modo extendido para detalles
  - Indicadores visuales (colores, iconos)
  - Niveles: Alta (≥85%), Media (≥70%), Baja (<70%)

- [x] `HomeScreen` actualizado
  - `_LatestReportCard`: Muestra badge de confianza IA
  - `_ReportListTile`: Muestra badge en lista de actividad reciente

### Microservicio IA (FastAPI) ✅ ESTRUCTURA CREADA

- [x] Estructura de proyecto creada
- [x] Schemas definidos (requests/responses)
- [x] Model loader implementado (con fallback dummy)
- [x] Classifier implementado
- [x] API FastAPI con endpoints:
  - `GET /` y `/health`: Health check
  - `POST /classify`: Clasificación de residuos
- [x] Dockerfile para Cloud Run
- [x] Requirements.txt con dependencias

## 🔧 Próximos Pasos

### 1. Probar el Microservicio Localmente

```bash
cd "/Users/miguelvillegas/Proyecto 2/ia-clasificacion-residuos"

# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar servidor
uvicorn app.main:app --reload --port 8080
```

Luego visitar: http://localhost:8080/docs

### 2. Entrenar/Obtener Modelo ML

**Opción A: Usar modelo pre-entrenado**
- Buscar modelo de clasificación de residuos
- Formatos soportados: `.h5` (Keras/TensorFlow)
- Colocar en: `models/waste_classifier_v1.h5`

**Opción B: Entrenar modelo propio**
- Dataset: Imágenes etiquetadas de residuos
- Categorías: Orgánico, Aprovechable, No Aprovechable
- Framework: TensorFlow/Keras
- Input size: 224x224 RGB

**Opción C: Usar modelo dummy (testing)**
- Ya implementado, se activa automáticamente
- Retorna predicciones aleatorias para pruebas

### 3. Probar Clasificación con Postman/cURL

```bash
curl -X POST "http://localhost:8080/classify" \
  -H "Content-Type: application/json" \
  -d '{
    "image_url": "https://ejemplo.com/imagen-residuo.jpg",
    "report_id": "ECO-TEST123",
    "user_id": "test_user"
  }'
```

### 4. Desplegar en Google Cloud Run

```bash
# Configurar proyecto
gcloud config set project TU_PROJECT_ID

# Build & Deploy
gcloud builds submit --tag gcr.io/TU_PROJECT_ID/waste-classifier

gcloud run deploy waste-classifier \
  --image gcr.io/TU_PROJECT_ID/waste-classifier \
  --platform managed \
  --region us-central1 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 60s \
  --min-instances 0 \
  --max-instances 10 \
  --allow-unauthenticated

# Obtener URL del servicio
gcloud run services describe waste-classifier \
  --platform managed \
  --region us-central1 \
  --format 'value(status.url)'
```

### 5. Crear Cloud Function (Orquestador)

**Pendiente: Implementar Cloud Function que:**
- Se activa cuando se sube imagen a Firebase Storage
- Obtiene URL firmada de la imagen
- Llama al microservicio de IA
- Actualiza Firestore con la clasificación

### 6. Actualizar Security Rules de Firestore

**Pendiente: Agregar reglas para campos de IA**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /reports/{reportId} {
      allow read: if request.auth != null;
      
      allow create: if request.auth != null;
      
      // Permitir que Cloud Functions actualice campos de IA
      allow update: if request.auth != null || 
                       (request.resource.data.diff(resource.data)
                         .affectedKeys()
                         .hasOnly(['ai_confidence', 'ai_processing_time_ms', 
                                   'ai_classified_at', 'ai_model_version']));
    }
  }
}
```

### 7. Pruebas de Integración

- [ ] Subir imagen desde app Flutter
- [ ] Verificar que Cloud Function se activa
- [ ] Confirmar clasificación en Firestore
- [ ] Verificar que app muestra indicador de confianza

## 📊 Arquitectura Completa

```
┌──────────────┐
│ Flutter App  │ ──[1]──> Firebase Storage (sube imagen)
└──────────────┘              │
                              │
                              ▼
                    ┌──────────────────┐
                    │ Cloud Function   │ ──[2]──> Obtiene URL
                    │  (Orquestador)   │          de imagen
                    └──────────────────┘
                              │
                              │ [3] POST /classify
                              ▼
                    ┌──────────────────┐
                    │ Microservicio IA │
                    │  (Cloud Run)     │
                    │  - FastAPI       │
                    │  - TensorFlow    │
                    └──────────────────┘
                              │
                              │ [4] Clasificación
                              ▼
                    ┌──────────────────┐
                    │    Firestore     │
                    │  (actualización) │
                    └──────────────────┘
                              │
                              │ [5] Real-time update
                              ▼
                    ┌──────────────────┐
                    │   Flutter App    │
                    │ (muestra badge)  │
                    └──────────────────┘
```

## 🧪 Testing Local (Sin Cloud)

1. **Probar Widget de Confianza:**
   ```dart
   // En Flutter DevTools o en código de prueba
   AIConfidenceIndicator(confidence: 0.95)
   AIConfidenceIndicator(confidence: 0.75, compact: true)
   AIConfidenceIndicator(confidence: 0.50)
   ```

2. **Probar con Datos Mock:**
   - Crear reportes con `aiConfidence` manual en Firestore
   - Verificar visualización en app

3. **Probar Microservicio:**
   - Usar imagen de prueba
   - Verificar respuesta JSON

## 📝 Checklist de Implementación

### Frontend
- [x] Modelo actualizado
- [x] Widget de confianza creado
- [x] HomeScreen actualizado
- [ ] ReportsScreen actualizado (opcional)
- [ ] Pruebas unitarias

### Backend
- [x] Microservicio creado
- [x] Dockerfile creado
- [ ] Modelo ML obtenido/entrenado
- [ ] Desplegado en Cloud Run
- [ ] Cloud Function implementada
- [ ] Security Rules actualizadas

### Testing
- [ ] Test local microservicio
- [ ] Test despliegue Cloud Run
- [ ] Test integración completa
- [ ] Test performance (latencia <2s)

## 🎯 Criterios de Aceptación

✅ **Historia de Usuario:** Como ciudadano quiero que el sistema clasifique automáticamente el residuo para simplificar mi reporte.

- [ ] Debe clasificarse en: Orgánico, Aprovechable o No Aprovechable
- [x] Mostrar el porcentaje de confianza de la IA
- [ ] Clasificación automática en <2 segundos
- [ ] Funciona con imágenes desde la app

## 🚀 Comandos Útiles

```bash
# Flutter: Hot reload para ver cambios
r

# Flutter: Ver logs
flutter logs

# Backend: Ver logs en tiempo real
gcloud run services logs read waste-classifier --follow

# Backend: Probar endpoint
curl http://localhost:8080/health

# Git: Ver cambios
git status
git diff
```

## 📚 Recursos

- FastAPI Docs: https://fastapi.tiangolo.com/
- TensorFlow: https://www.tensorflow.org/
- Cloud Run: https://cloud.google.com/run
- Firebase Storage: https://firebase.google.com/docs/storage

---

**Última actualización:** 22 de octubre de 2025
**Estado:** ✅ Frontend completo | ⏳ Backend en desarrollo
