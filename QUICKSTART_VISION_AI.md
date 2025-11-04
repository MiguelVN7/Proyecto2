# ⚡ Inicio Rápido - Google Vision AI

## 🎯 Resumen
Clasificación automática de residuos usando Google Vision AI.  
**Tiempo de implementación**: 10-15 minutos

---

## ✅ Prerequisitos

Antes de empezar, verifica que tengas:

- [ ] **Firebase CLI** instalado
  ```bash
  npm install -g firebase-tools
  ```

- [ ] **Google Cloud CLI** instalado
  - [Descargar aquí](https://cloud.google.com/sdk/docs/install)

- [ ] **Node.js 18+** instalado
  ```bash
  node --version  # Debe ser >= 18
  ```

- [ ] **Acceso** al proyecto Firebase `ecotrack-app-23a64`

---

## 🚀 Deployment Automático (Recomendado)

### Opción más fácil - Un solo comando:

```bash
cd "/Users/miguelvillegas/Proyecto 2"
./deploy-vision-ai.sh
```

El script hará todo automáticamente:
1. ✅ Verificar prerequisitos
2. ✅ Autenticar con Firebase
3. ✅ Habilitar Vision API
4. ✅ Instalar dependencias
5. ✅ Desplegar Cloud Functions

---

## 🛠️ Deployment Manual (Paso a Paso)

Si prefieres hacerlo manualmente:

### 1. Autenticar con Firebase
```bash
firebase login
```

### 2. Seleccionar proyecto
```bash
cd "/Users/miguelvillegas/Proyecto 2"
firebase use ecotrack-app-23a64
```

### 3. Habilitar Vision API
```bash
gcloud services enable vision.googleapis.com --project=ecotrack-app-23a64
```

### 4. Instalar dependencias
```bash
cd functions
npm install
```

### 5. Desplegar
```bash
cd ..
firebase deploy --only functions
```

---

## 🧪 Testing

### Probar localmente (Opcional)
```bash
cd functions
npm run serve
```

En otra terminal:
```bash
curl -X POST http://localhost:5001/ecotrack-app-23a64/us-central1/classifyWasteManual \
  -H "Content-Type: application/json" \
  -d '{"imageUrl": "gs://ecotrack-app-23a64.appspot.com/reports/test.jpg"}'
```

### Probar en producción
```bash
# Subir imagen de prueba y ver logs
firebase functions:log --only classifyWaste
```

---

## 📱 Verificar en la App

1. **Abre** la app EcoTrack en tu celular
2. **Toma** una foto de un residuo (botella, fruta, etc.)
3. **Espera** 2-3 segundos
4. **Verifica** que aparezca el badge 🤖 con el porcentaje
5. **Revisa** en Environmental Reports para ver los detalles

---

## 📊 Monitoreo

### Ver logs en tiempo real
```bash
firebase functions:log
```

### Logs específicos de clasificación
```bash
firebase functions:log --only classifyWaste
```

### Dashboard de Firebase
```
https://console.firebase.google.com/project/ecotrack-app-23a64/functions
```

### Métricas de Vision API
```
https://console.cloud.google.com/apis/api/vision.googleapis.com/metrics
```

---

## 🎯 Qué Esperar

### Flujo completo:
1. Usuario toma foto → 📸
2. Imagen se sube a Storage → ☁️
3. Cloud Function se activa → ⚡
4. Vision API analiza → 🤖
5. Se clasifica el residuo → 🏷️
6. Firestore se actualiza → 💾
7. Badge aparece en la app → ✨

### Tiempos:
- **Análisis**: 1-2 segundos
- **Actualización**: Inmediata (realtime)
- **Total**: 2-3 segundos

### Ejemplo de logs exitosos:
```
🎯 New image uploaded: reports/userId/abc123.jpg
🔍 Analyzing image with Vision AI
✅ Vision API detected 6 labels
📊 "Plastic bottle" (96.2%) → Reciclable
🏷️ Classified as: Reciclable (92.5% confidence)
✅ Report ECO-12345 updated successfully
⏱️ Total processing time: 1847ms
```

---

## 🐛 Troubleshooting Rápido

### ❌ "Vision API not enabled"
```bash
gcloud services enable vision.googleapis.com --project=ecotrack-app-23a64
```

### ❌ "Permission denied"
```bash
# Verificar que estás autenticado
gcloud auth list
firebase login
```

### ❌ "No labels detected"
- Verifica que la imagen sea clara
- Asegúrate de que sea un residuo visible
- Revisa los logs para ver qué detectó Vision AI

### ❌ "Function not triggering"
- Verifica que la imagen esté en carpeta `reports/`
- Confirma que sea un archivo de imagen (jpg, png)
- Revisa logs: `firebase functions:log`

### ❌ "Clasificación incorrecta"
- Revisa labels en logs
- Ajusta `labelMapping` en `classifyWaste.js`
- Sube nueva versión: `firebase deploy --only functions`

---

## 💰 Costos

### Para demos (GRATIS):
- ✅ 1,000 llamadas/mes a Vision API gratis
- ✅ 2M invocaciones/mes de Cloud Functions gratis
- ✅ Firestore tier gratuito más que suficiente

### Si excedes:
- Vision API: $1.50 por 1,000 llamadas adicionales
- Cloud Functions: $0.40 por millón de invocaciones

**Tu demo estará 100% en tier gratuito** ✨

---

## ✅ Checklist Final

Antes de hacer la demo, verifica:

- [ ] Functions desplegadas correctamente
- [ ] Vision API habilitada
- [ ] Logs muestran actividad
- [ ] App muestra badges de IA
- [ ] Testing con 2-3 tipos de residuos diferentes
- [ ] Screenshots para presentación

---

## 🎉 ¡Listo!

Tu app ahora tiene **clasificación automática con IA** de Google.

### Próximas mejoras (opcionales):
1. Ajustar mapeo de categorías
2. Agregar más keywords
3. Implementar caché
4. Mejorar UI de confianza
5. Agregar feedback del usuario

### Soporte:
- Docs: `GOOGLE_VISION_SETUP.md`
- Functions: `functions/README.md`
- Troubleshooting: `functions/README.md#troubleshooting`

---

**¿Listo para deploy?** 🚀

```bash
./deploy-vision-ai.sh
```
