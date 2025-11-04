# 🔥 Firebase Cloud Functions - EcoTrack

## 📋 Descripción

Cloud Functions para clasificación automática de residuos usando Google Vision AI.

## 🚀 Funciones Disponibles

### 1. `classifyWaste` (Storage Trigger)
**Trigger**: Se activa automáticamente cuando se sube una imagen a Firebase Storage  
**Propósito**: Clasificar residuos usando Google Vision AI

**Flujo**:
1. Usuario sube foto → Firebase Storage
2. Function se activa automáticamente
3. Vision AI analiza la imagen
4. Clasifica en: Orgánico, Reciclable, o No Reciclable
5. Actualiza Firestore con la clasificación

**Configuración automática**: No requiere configuración adicional

---

### 2. `classifyWasteManual` (HTTP Endpoint)
**Trigger**: Endpoint HTTP para clasificación manual  
**Propósito**: Testing y clasificación bajo demanda

**Uso**:
```bash
# POST request
curl -X POST https://us-central1-ecotrack-app-23a64.cloudfunctions.net/classifyWasteManual \
  -H "Content-Type: application/json" \
  -d '{
    "imageUrl": "gs://ecotrack-app-23a64.appspot.com/reports/test.jpg",
    "reportId": "ECO-12345"
  }'
```

**Response**:
```json
{
  "success": true,
  "classification": "Reciclable",
  "confidence": 0.92,
  "processingTime": 1847,
  "labels": [
    { "label": "Plastic bottle", "score": 0.96 },
    { "label": "Container", "score": 0.89 }
  ]
}
```

---

## 📦 Instalación

### 1. Instalar dependencias
```bash
cd functions
npm install
```

### 2. Verificar configuración de Firebase
```bash
firebase use ecotrack-app-23a64
```

### 3. Habilitar Vision API
```bash
gcloud services enable vision.googleapis.com
```

---

## 🧪 Testing Local

### Iniciar emulador
```bash
npm run serve
```

### Probar función HTTP
```bash
# En otra terminal
curl -X POST http://localhost:5001/ecotrack-app-23a64/us-central1/classifyWasteManual \
  -H "Content-Type: application/json" \
  -d '{"imageUrl": "gs://ecotrack-app-23a64.appspot.com/reports/test.jpg"}'
```

---

## 🚀 Deployment

### Deploy todas las funciones
```bash
npm run deploy
```

### Deploy solo classifyWaste
```bash
firebase deploy --only functions:classifyWaste
```

### Deploy solo classifyWasteManual
```bash
firebase deploy --only functions:classifyWasteManual
```

---

## 📊 Monitoreo

### Ver logs en tiempo real
```bash
npm run logs
# o
firebase functions:log --only classifyWaste
```

### Ver logs en Google Cloud Console
```
https://console.cloud.google.com/functions/list
```

### Métricas de Vision API
```
https://console.cloud.google.com/apis/api/vision.googleapis.com/metrics
```

---

## 🎯 Categorización de Residuos

### Orgánico
- Frutas, verduras
- Restos de comida
- Plantas, hojas
- Café, té

### Reciclable
- Plástico (botellas, envases)
- Papel, cartón
- Metal (latas, aluminio)
- Vidrio
- Tetrapak

### No Reciclable
- Icopor/Styrofoam
- Bolsas plásticas no reciclables
- Envoltorios
- Pitillos
- Basura general

---

## 🔧 Configuración Avanzada

### Ajustar umbral de confianza
Editar en `classifyWaste.js`:
```javascript
// Línea ~120
if (classification.confidence < 0.60) {
  console.log('⚠️  Confidence too low, skipping classification');
  return null;
}
```

### Agregar nuevas categorías
Editar `labelMapping` en `classifyWaste.js`:
```javascript
const labelMapping = {
  'nueva_palabra_clave': 'Nueva Categoría',
  // ...
};
```

### Cambiar región de deployment
Editar `firebase.json`:
```json
{
  "functions": {
    "region": "us-east1"
  }
}
```

---

## 💰 Costos Estimados

### Tier Gratuito (Suficiente para demos)
- **Cloud Functions**: 2M invocaciones/mes gratis
- **Vision API**: 1,000 llamadas/mes gratis
- **Firestore**: 50k lecturas + 20k escrituras/día gratis

### Después del Tier Gratuito
- **Vision API**: $1.50 USD por 1,000 llamadas adicionales
- **Cloud Functions**: $0.40 USD por millón de invocaciones

**Para tu demo**: Completamente gratis ✅

---

## 🐛 Troubleshooting

### Error: "Vision API not enabled"
```bash
gcloud services enable vision.googleapis.com
```

### Error: "Permission denied"
```bash
# Verificar permisos
gcloud projects get-iam-policy ecotrack-app-23a64
```

### Error: "Function timeout"
Aumentar timeout en `classifyWaste.js`:
```javascript
exports.classifyWaste = functions
  .runWith({ timeoutSeconds: 120 })
  .storage.object().onFinalize(async (object) => {
    // ...
  });
```

### Clasificación incorrecta
1. Revisar labels detectados en logs
2. Ajustar `labelMapping` para incluir nuevas keywords
3. Aumentar número de labels analizados

### No se activa la función
1. Verificar que la imagen esté en carpeta `reports/`
2. Verificar que sea un archivo de imagen
3. Revisar logs: `firebase functions:log`

---

## 📚 Referencias

- [Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [Vision API Guide](https://cloud.google.com/vision/docs)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Firestore API](https://firebase.google.com/docs/firestore)

---

## ✅ Checklist de Deployment

- [ ] `npm install` ejecutado
- [ ] Vision API habilitada
- [ ] Firebase configurado (`firebase use`)
- [ ] Testing local exitoso
- [ ] Deploy completado sin errores
- [ ] Logs verificados
- [ ] Testing end-to-end en la app

---

## 🎉 ¿Todo listo?

Después del deployment, las clasificaciones se ejecutarán **automáticamente** cada vez que un usuario suba una foto. No se requiere ninguna acción adicional en el frontend. ✨
