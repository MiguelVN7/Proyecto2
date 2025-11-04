# 🧪 Testing Local de Cloud Functions

## ¿Por qué testing local?

Mientras configuras el plan Blaze, puedes probar las Cloud Functions localmente usando Firebase Emulators.

---

## 🚀 Iniciar Emuladores

### 1. Instalar emulators (si no lo has hecho)
```bash
firebase init emulators
```

Selecciona:
- [x] Functions Emulator
- [x] Firestore Emulator
- [x] Storage Emulator

### 2. Iniciar emuladores
```bash
cd "/Users/miguelvillegas/Proyecto 2"
firebase emulators:start
```

Esto iniciará:
- Functions en: http://localhost:5001
- Firestore UI: http://localhost:4000
- Storage: localhost:9199

---

## 🧪 Probar la Clasificación Manual

### Endpoint HTTP (classifyWasteManual)

```bash
# Test con una imagen de ejemplo
curl -X POST http://localhost:5001/ecotrack-app-23a64/us-central1/classifyWasteManual \
  -H "Content-Type: application/json" \
  -d '{
    "imageUrl": "https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400",
    "reportId": "TEST-123"
  }'
```

**Respuesta esperada:**
```json
{
  "success": true,
  "classification": "Reciclable",
  "confidence": 0.92,
  "processingTime": 1500,
  "labels": [
    { "label": "Plastic bottle", "score": 0.96 },
    { "label": "Container", "score": 0.89 }
  ]
}
```

---

## 📱 Conectar App con Emulators

### En Flutter (development)

Agrega esto a tu `main.dart` (temporal para testing):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // 🧪 SOLO PARA TESTING LOCAL
  if (kDebugMode) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }
  
  runApp(MyApp());
}
```

---

## ⚠️ Limitaciones del Emulator

### Lo que SÍ funciona:
- ✅ HTTP endpoint manual
- ✅ Firestore reads/writes
- ✅ Storage uploads
- ✅ Logs y debugging

### Lo que NO funciona:
- ❌ Storage triggers automáticos (onFinalize)
- ❌ Vision API real (necesita proyecto real)

---

## 🎯 Para Testing Completo

**Opción 1**: Activar plan Blaze (recomendado)
- Deployment completo
- Testing end-to-end real
- Vision API funcionando

**Opción 2**: Testing híbrido
- Emulators para development
- Manual classification con endpoint HTTP
- Deploy cuando estés listo

---

## 💡 Recomendación

Para tu demo, **activa el plan Blaze**:
1. Es gratis para demos (tier gratuito)
2. Puedes establecer límites de gasto
3. Funcionalidad completa
4. Mejor para presentaciones

---

## 📞 Si decides continuar con Blaze

Después de activar:
```bash
cd "/Users/miguelvillegas/Proyecto 2"
firebase deploy --only functions
```

Y en 3-5 minutos estará todo funcionando. ✨
