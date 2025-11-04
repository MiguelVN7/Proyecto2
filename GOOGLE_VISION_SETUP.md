# 🤖 Implementación con Google Vision AI

## 📝 Resumen
Implementación rápida usando Google Cloud Vision API para clasificar residuos automáticamente.

## ✅ Ventajas
- ✨ **Precisión alta**: IA entrenada por Google
- 🚀 **Rápido**: Funcional en 1-2 horas
- 💰 **Gratis para demos**: 1000 llamadas/mes incluidas
- 🔧 **Fácil de implementar**: Solo configuración, sin entrenar modelo

## 📊 Plan de Costos (Referencia)
- **Primeras 1000 llamadas/mes**: GRATIS
- **Siguientes llamadas**: ~$1.50 USD por 1000
- **Para tu demo**: Completamente gratis

---

## 🔧 Paso 1: Activar Google Vision API (5 min)

### 1.1. Ir a Google Cloud Console
```
https://console.cloud.google.com/
```

### 1.2. Seleccionar tu proyecto EcoTrack
- Proyecto: `ecotrack-app-23a64`

### 1.3. Activar Vision API
1. Ve a: **APIs & Services** → **Library**
2. Busca: **"Cloud Vision API"**
3. Click en **"Enable"** (Habilitar)

### 1.4. Verificar que esté activa
```bash
# En terminal, verifica:
gcloud services list --enabled | grep vision
# Deberías ver: vision.googleapis.com
```

---

## 🔑 Paso 2: Crear Service Account (Opcional)

**Nota**: Si ya usas Firebase Admin, puedes saltarte esto. Firebase Admin incluye permisos de Vision API.

### Si necesitas crear una nueva:
```bash
# 1. Crear service account
gcloud iam service-accounts create vision-service \
  --display-name="Vision AI Service"

# 2. Dar permisos
gcloud projects add-iam-policy-binding ecotrack-app-23a64 \
  --member="serviceAccount:vision-service@ecotrack-app-23a64.iam.gserviceaccount.com" \
  --role="roles/cloudvision.admin"

# 3. Descargar credenciales
gcloud iam service-accounts keys create vision-credentials.json \
  --iam-account=vision-service@ecotrack-app-23a64.iam.gserviceaccount.com
```

---

## 💻 Paso 3: Implementar Cloud Function

Voy a crear la Cloud Function que:
1. Se activa cuando se sube una imagen a Storage
2. Llama a Vision API para analizar la imagen
3. Clasifica el residuo basado en las etiquetas detectadas
4. Actualiza el reporte en Firestore con la clasificación

### Archivos necesarios:
- `functions/classifyWaste.js` - Lógica principal
- `functions/package.json` - Dependencias
- `functions/.env` - Variables de entorno

---

## 🎯 Paso 4: Mapeo de Clasificación

Vision API devuelve etiquetas generales (ej: "plastic bottle", "paper", "food waste").
Necesitamos mapearlas a nuestras 3 categorías:

### Categorías EcoTrack:
1. **Orgánico** (Organic)
2. **Reciclable** (Recyclable)
3. **No Reciclable** (Non-Recyclable)

### Mapeo inteligente:
```javascript
const wasteMapping = {
  // Orgánico
  'food': 'Orgánico',
  'fruit': 'Orgánico',
  'vegetable': 'Orgánico',
  'plant': 'Orgánico',
  'compost': 'Orgánico',
  'organic': 'Orgánico',
  
  // Reciclable
  'plastic': 'Reciclable',
  'bottle': 'Reciclable',
  'can': 'Reciclable',
  'paper': 'Reciclable',
  'cardboard': 'Reciclable',
  'metal': 'Reciclable',
  'glass': 'Reciclable',
  'aluminum': 'Reciclable',
  
  // No Reciclable
  'trash': 'No Reciclable',
  'waste': 'No Reciclable',
  'garbage': 'No Reciclable',
  'styrofoam': 'No Reciclable',
};
```

---

## 🧪 Paso 5: Testing Local

### Probar Cloud Function localmente:
```bash
cd functions
npm install
npm run serve

# En otra terminal:
curl -X POST http://localhost:5001/ecotrack-app-23a64/us-central1/classifyWaste \
  -H "Content-Type: application/json" \
  -d '{"imageUrl": "gs://ecotrack-app-23a64.appspot.com/reports/test.jpg"}'
```

---

## 🚀 Paso 6: Deploy

```bash
cd functions
firebase deploy --only functions:classifyWaste
```

### Verificar deployment:
```
✔  functions[us-central1-classifyWaste]: Successful create operation.
Function URL: https://us-central1-ecotrack-app-23a64.cloudfunctions.net/classifyWaste
```

---

## 📱 Paso 7: Testing End-to-End

1. **Tomar foto** en la app
2. **Esperar 2-3 segundos** (clasificación automática)
3. **Ver badge de IA** en HomeScreen
4. **Verificar confianza** en Environmental Reports

### Logs para debugging:
```bash
# Ver logs de Cloud Function
firebase functions:log --only classifyWaste

# Deberías ver:
# ✅ Image analyzed: 5 labels detected
# ✅ Classification: Reciclable (85% confidence)
# ✅ Report updated in Firestore
```

---

## 🔍 Paso 8: Monitoreo

### Ver llamadas a Vision API:
```
https://console.cloud.google.com/apis/api/vision.googleapis.com/metrics
```

### Ver costos:
```
https://console.cloud.google.com/billing
```

**Para demos**: Deberías estar completamente en el tier gratis.

---

## ⚡ Optimizaciones Opcionales

### 1. Caché de clasificaciones
```javascript
// Guardar clasificaciones previas para evitar llamadas repetidas
const cache = new Map();
```

### 2. Batch processing
```javascript
// Procesar múltiples imágenes en paralelo
const results = await Promise.all(images.map(analyzeImage));
```

### 3. Confidence threshold
```javascript
// Solo guardar si confianza > 70%
if (confidence > 0.70) {
  await updateFirestore(reportId, classification, confidence);
}
```

---

## 🐛 Troubleshooting

### Error: "Vision API not enabled"
```bash
gcloud services enable vision.googleapis.com
```

### Error: "Permission denied"
```bash
# Verificar permisos del service account
gcloud projects get-iam-policy ecotrack-app-23a64
```

### Error: "Quota exceeded"
```bash
# Ver cuota actual
gcloud alpha billing quotas list --service=vision.googleapis.com
```

### Clasificación incorrecta
- Ajustar mapeo de etiquetas en `wasteMapping`
- Aumentar umbral de confianza
- Usar más etiquetas (Vision devuelve top 10)

---

## 📚 Recursos

- [Vision API Docs](https://cloud.google.com/vision/docs)
- [Pricing Calculator](https://cloud.google.com/products/calculator)
- [Label Detection Guide](https://cloud.google.com/vision/docs/labels)
- [Firebase Functions](https://firebase.google.com/docs/functions)

---

## ✅ Checklist de Implementación

- [ ] Vision API activada en Google Cloud
- [ ] Service Account configurado (o usando Firebase Admin)
- [ ] Cloud Function creada (`classifyWaste.js`)
- [ ] Dependencias instaladas (`npm install`)
- [ ] Variables de entorno configuradas
- [ ] Mapeo de categorías ajustado
- [ ] Testing local exitoso
- [ ] Deploy a Firebase Functions
- [ ] Testing end-to-end en la app
- [ ] Monitoreo configurado

---

## 🎯 Resultado Final

Después de implementar:

1. **Usuario toma foto** 📸
2. **Imagen se sube a Firebase Storage** ☁️
3. **Cloud Function se activa automáticamente** ⚡
4. **Vision API analiza la imagen** 🤖
5. **Se clasifica el residuo** 🏷️
6. **Firestore se actualiza** 💾
7. **Badge aparece en la app** ✨

**Tiempo total**: 2-3 segundos por clasificación

---

¿Listo para empezar? Voy a crear los archivos de la Cloud Function ahora. 🚀
