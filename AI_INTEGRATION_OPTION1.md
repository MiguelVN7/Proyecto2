# 🤖 Integración de IA - Opción 1: Función HTTP

## ✅ Lo que se implementó

### 1. **Cloud Function Desplegada**
- ✅ `classifyWasteManual`: Función HTTP desplegada en Firebase
- 🔗 URL: `https://us-central1-ecotrack-app-23a64.cloudfunctions.net/classifyWasteManual`
- 📍 Región: `us-central1`
- 🚀 Estado: **ACTIVA**

### 2. **Servicio de IA en el Backend**
- ✅ Creado: `backend/ai_classification_service.js`
- 🎯 Función: Envía imágenes a la Cloud Function
- 📦 Dependencia: `axios` (instalada)

### 3. **Integración en server.js**
- ✅ Importado servicio de IA
- 🔄 Clasificación automática al recibir reportes
- 💾 Campos de IA guardados en Firestore:
  - `is_ai_classified`: true/false
  - `ai_confidence`: 0.0 - 1.0
  - `ai_processing_time_ms`: milisegundos
  - `ai_model_version`: "1.0"
  - `ai_classified_at`: timestamp
  - `ai_suggested_classification`: categoría sugerida por IA

### 4. **Actualización de Firestore Service**
- ✅ Modificado: `backend/firestore_service.js`
- 💾 Guarda todos los campos de IA en Firestore
- 🔄 Compatible con reportes sin IA (backward compatible)

## 🚀 Cómo funciona ahora

```
1. Usuario toma foto en la app
   ↓
2. App envía foto al backend (POST /api/reports)
   ↓
3. Backend guarda imagen localmente
   ↓
4. Backend convierte imagen a base64
   ↓
5. Backend llama a la Cloud Function con la imagen
   ↓
6. Cloud Function usa Google Vision AI para analizar
   ↓
7. Vision AI devuelve labels (etiquetas)
   ↓
8. Cloud Function clasifica: Orgánico, Reciclable, o No Reciclable
   ↓
9. Backend recibe clasificación + confianza
   ↓
10. Backend guarda en Firestore con campos de IA
    ↓
11. App muestra badge 🤖 con porcentaje
```

## 🧪 Cómo probar

### Opción A: Desde la App (Recomendado)

1. **Reinicia el backend** (si no está corriendo):
   ```bash
   cd "/Users/miguelvillegas/Proyecto 2/backend"
   node server.js
   ```

2. **Abre tu app EcoTrack**

3. **Toma una foto de prueba**:
   - 🍌 Banana o fruta → Esperado: **Orgánico**
   - 🥤 Botella plástica → Esperado: **Reciclable**
   - 🗑️ Envoltorio → Esperado: **No Reciclable**

4. **Observa los logs del backend**:
   Deberías ver algo como:
   ```
   📄 Nuevo reporte recibido: ECO-ABCD1234
   🤖 Calling AI classification for image: /path/to/image.jpg
   📤 Sending image to AI (123.5 KB)
   ✅ AI Classification successful:
      Category: Orgánico
      Confidence: 92.5%
      Processing time: 2340ms
   🎯 AI Classification: Orgánico (92.5% confidence)
   ```

5. **Verifica en la app**:
   - Ve a "Reportes Ambientales"
   - Busca tu nuevo reporte
   - Deberías ver el badge: **🤖 92%**
   - Al abrir el detalle, verás:
     - Confianza: 92.5%
     - Tiempo: 2.3s
     - Modelo: v1.0

### Opción B: Con Script de Prueba

1. **Asegúrate de que hay al menos una imagen en `backend/images/`**

2. **Ejecuta el script de prueba**:
   ```bash
   cd "/Users/miguelvillegas/Proyecto 2/backend"
   ./test_ai_classification.sh
   ```

3. **El script hará**:
   - ✅ Verificar que el backend está corriendo
   - 📸 Buscar la imagen más reciente
   - 🔄 Convertirla a base64
   - 📤 Enviarla al backend como nuevo reporte
   - 📊 Mostrar la respuesta
   - 🤖 La IA clasificará automáticamente

## 🐛 Solución de Problemas

### La IA no clasifica (is_ai_classified: false)

**Posibles causas:**

1. **Función HTTP no responde**
   ```bash
   # Probar la función directamente
   curl https://us-central1-ecotrack-app-23a64.cloudfunctions.net/classifyWasteManual
   ```
   Debería responder con código 200

2. **Imagen muy grande**
   - Límite: ~10 MB
   - Solución: La app ya redimensiona, pero verifica

3. **Timeout**
   - La función tiene 30 segundos de timeout
   - Imágenes muy grandes pueden tardar más

4. **Error en Vision API**
   - Revisa los logs: `firebase functions:log`

### Ver logs de la Cloud Function

```bash
cd "/Users/miguelvillegas/Proyecto 2"
firebase functions:log --only classifyWasteManual
```

### Backend no se conecta a la función

**Verifica la URL en el código:**
```javascript
// backend/ai_classification_service.js línea 7
const AI_FUNCTION_URL = 'https://us-central1-ecotrack-app-23a64.cloudfunctions.net/classifyWasteManual';
```

## 📊 Campos de IA en Firestore

Cuando abras Firestore Console, verás estos campos en cada reporte clasificado por IA:

```javascript
{
  "id": "ECO-ABCD1234",
  "clasificacion": "Orgánico",              // Original del usuario
  "is_ai_classified": true,                 // ✅ IA procesó esta imagen
  "ai_confidence": 0.925,                   // 92.5% de confianza
  "ai_processing_time_ms": 2340,            // 2.34 segundos
  "ai_model_version": "1.0",                // Versión del modelo
  "ai_classified_at": Timestamp,            // Cuándo se clasificó
  "ai_suggested_classification": "Orgánico" // Sugerencia de la IA
}
```

## 🎯 Próximos Pasos

Una vez que confirmes que funciona:

1. ✅ **Probar con diferentes tipos de residuos**
2. ✅ **Verificar los badges en la app**
3. 📝 **Commit de los cambios**
4. 🔄 **[Opcional] Migrar a Firebase Storage** para clasificación automática

## 💡 Notas Importantes

- ⏱️ **Tiempo de procesamiento**: 2-5 segundos (depende del tamaño de imagen)
- 💰 **Costo**: $0 dentro del free tier (1,000 clasificaciones/mes)
- 🔄 **Backward compatible**: Reportes antiguos siguen funcionando
- 🚫 **No bloquea**: Si la IA falla, el reporte se guarda igual
- 📈 **Escalable**: Cuando migres a Firebase Storage, será automático

## 🆘 ¿Necesitas ayuda?

Si algo no funciona:
1. Revisa los logs del backend
2. Verifica que la Cloud Function esté activa: `firebase functions:list`
3. Prueba la función directamente con curl
4. Revisa Firestore Console para ver si los campos se guardaron

---

**Estado actual**: ✅ **TODO LISTO PARA PROBAR**

Simplemente abre tu app, toma una foto, y la IA la clasificará automáticamente en 2-3 segundos. 🚀
