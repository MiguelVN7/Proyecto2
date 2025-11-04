# 🧪 Script para Probar Clasificación IA en la App

## ¿Por qué no veo cambios?

Los badges de IA solo aparecen cuando un reporte tiene los campos:
- `ai_confidence` (debe existir y ser > 0)
- `ai_processing_time_ms`
- `ai_classified_at`
- `ai_model_version`

Como no hemos conectado el backend, **NO HAY reportes con estos campos**.

## 📝 Solución: Crear Reporte de Prueba Manual

### Opción A: Desde Firebase Console (Recomendado)

1. **Ir a Firebase Console**
   - https://console.firebase.google.com
   - Selecciona tu proyecto
   - Ve a Firestore Database

2. **Buscar un reporte existente**
   - Colección: `reports`
   - Selecciona cualquier reporte

3. **Agregar campos de IA**
   Hacer clic en "Add field" y agregar estos campos:

   ```
   Campo: ai_confidence
   Tipo: number
   Valor: 0.95
   
   Campo: ai_processing_time_ms
   Tipo: number
   Valor: 450
   
   Campo: ai_classified_at
   Tipo: timestamp
   Valor: [fecha actual]
   
   Campo: ai_model_version
   Tipo: string
   Valor: 1.0.0
   ```

4. **Guardar y volver a la app**
   - Hot reload en la app (presiona 'r')
   - ¡Deberías ver el badge 🤖 95%!

### Opción B: Crear Reporte Nuevo Completo

Si no tienes reportes, crea uno nuevo con estos datos:

```json
{
  "id": "ECO-TEST12345",
  "foto_url": "https://via.placeholder.com/300",
  "ubicacion": "Prueba con IA",
  "clasificacion": "Orgánico",
  "estado": "Pendiente",
  "prioridad": "Alta",
  "tipo_residuo": "Orgánico",
  "location": {
    "latitude": 6.2476,
    "longitude": -75.5658,
    "accuracy": 10.0
  },
  "created_at": [timestamp actual],
  "updated_at": [timestamp actual],
  "user_id": "[tu user_id]",
  
  // ⭐ CAMPOS DE IA - ESTOS SON LOS IMPORTANTES
  "ai_confidence": 0.95,
  "ai_processing_time_ms": 450,
  "ai_classified_at": [timestamp actual],
  "ai_model_version": "1.0.0"
}
```

## 🎨 Dónde Deberías Ver los Badges

### 1. HomeScreen - Tarjeta de Último Reporte
```
┌─────────────────────────────────────┐
│ 📷  Orgánico           [🤖 95%]    │
│     Prueba con IA                   │
│     [Pendiente]  15/10 08:00        │
└─────────────────────────────────────┘
```

### 2. HomeScreen - Lista de Actividad Reciente
```
Actividad reciente
┌─────────────────────────────────────┐
│ 📷 Orgánico [🤖 95%]               │
│    [Pendiente] 15/10 08:00          │
└─────────────────────────────────────┘
```

## 🧪 Prueba Rápida con Script

Si tienes acceso a Firebase Admin SDK, puedes usar este script de Node.js:

```javascript
// test_ai_report.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createTestReport() {
  const reportData = {
    id: 'ECO-TEST-' + Date.now(),
    foto_url: 'https://via.placeholder.com/300',
    ubicacion: 'Prueba IA - ' + new Date().toLocaleString(),
    clasificacion: 'Orgánico',
    estado: 'Pendiente',
    prioridad: 'Alta',
    tipo_residuo: 'Orgánico',
    location: {
      latitude: 6.2476,
      longitude: -75.5658,
      accuracy: 10.0
    },
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
    user_id: 'test_user',
    
    // Campos IA
    ai_confidence: 0.95,
    ai_processing_time_ms: 450,
    ai_classified_at: admin.firestore.FieldValue.serverTimestamp(),
    ai_model_version: '1.0.0'
  };

  const docRef = await db.collection('reports').add(reportData);
  console.log('✅ Reporte de prueba creado:', docRef.id);
  console.log('🤖 Con clasificación IA: Orgánico (95% confianza)');
}

createTestReport()
  .then(() => process.exit(0))
  .catch(err => {
    console.error('❌ Error:', err);
    process.exit(1);
  });
```

## 🔍 Verificar en la App

Después de crear el reporte de prueba:

1. **Hot Reload** en la app (presiona 'r' en la terminal)
2. **Ve al HomeScreen**
3. **Busca la sección "Resumen"** - Deberías ver el badge
4. **Scroll a "Actividad reciente"** - Deberías ver el badge ahí también

## 💡 Si Aún No Ves Nada

1. **Verifica el user_id**: El reporte debe tener el mismo `user_id` del usuario logueado
2. **Verifica la fecha**: Debe ser reciente para aparecer en "Actividad reciente"
3. **Revisa la consola**: Busca errores en los logs de Flutter
4. **Reinicia la app**: A veces hot reload no es suficiente

## 📱 Ejemplo Visual Esperado

Cuando funcione, verás algo así:

```
╔══════════════════════════════════════╗
║          EcoTrack - Home             ║
╚══════════════════════════════════════╝

┌──────────────────────────────────────┐
│ Resumen                              │
├──────────────────────────────────────┤
│ 📷 [Imagen]                          │
│                                      │
│ Orgánico                    🤖 95%  │ ← AQUÍ!
│ Calle 10 #20-30                      │
│ [Pendiente] 15/10/2025               │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ Actividad reciente                   │
├──────────────────────────────────────┤
│ 📷 Orgánico           🤖 95%        │ ← AQUÍ!
│    [Pendiente] 15/10 08:00           │
└──────────────────────────────────────┘
```

El badge `🤖 95%` será:
- 🟢 Verde si confianza ≥ 85%
- 🟠 Naranja si confianza ≥ 70%
- 🔴 Rojo si confianza < 70%

## ❓ ¿Necesitas Ayuda?

Si después de crear el reporte de prueba aún no ves los badges:
1. Comparte captura de Firestore mostrando el documento
2. Comparte logs de Flutter console
3. Verifica que el código compiló sin errores
