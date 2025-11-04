# 🎯 Guía Rápida: Probar la IA en 3 Pasos

## Paso 1: Iniciar el Backend ▶️

```bash
cd "/Users/miguelvillegas/Proyecto 2/backend"
node server.js
```

**Deberías ver:**
```
✅ Firestore Service initialized successfully
✅ FCM Service ready
🌱 EcoTrack Backend API ejecutándose en puerto 3000
```

---

## Paso 2: Tomar una Foto en la App 📸

1. Abre **EcoTrack** en tu dispositivo
2. Ve a la pantalla de **"Nuevo Reporte"**
3. Toma una foto de:
   - 🍌 Una banana (→ Orgánico)
   - 🥤 Una botella plástica (→ Reciclable)
   - 🗑️ Un envoltorio (→ No Reciclable)
4. Selecciona cualquier clasificación manual
5. **Envía el reporte**

---

## Paso 3: Ver la Magia de la IA ✨

### En el Backend (Terminal)

Verás estos logs en **tiempo real**:

```
📄 Nuevo reporte recibido: ECO-A1B2C3D4
📍 Ubicación: -12.0464, -77.0428 (±10.5m)
🗂️ Clasificación: Reciclable
💾 Guardado en: /path/to/report.json

🤖 Calling AI classification for image: /path/to/ECO-A1B2C3D4.jpg
📤 Sending image to AI (245.3 KB)
✅ AI Classification successful:
   Category: Reciclable
   Confidence: 87.3%
   Processing time: 2134ms
🎯 AI Classification: Reciclable (87.3% confidence)

✅ Report ECO-A1B2C3D4 inserted into Firestore successfully
```

### En la App 📱

1. **Ve a "Reportes Ambientales"**
2. **Busca tu nuevo reporte** (el más reciente)
3. **Verás el badge de IA**: 🤖 87%

**En la lista:**
```
┌─────────────────────────────────┐
│ ECO-A1B2C3D4                    │
│ Reciclable          🤖 87%      │
│ hace 1 minuto                   │
│ Estado: Recibido                │
└─────────────────────────────────┘
```

4. **Toca para ver el detalle**
5. **Verás la información completa**:

```
┌─────────────────────────────────────┐
│ CLASIFICACIÓN POR IA                │
│                                     │
│ 🤖 Reciclable                       │
│ ✓ Confianza: 87.3%                  │
│ ⏱️ Tiempo: 2.1 segundos             │
│ 📊 Modelo: v1.0                     │
│                                     │
│ Clasificado automáticamente con     │
│ Google Vision AI                    │
└─────────────────────────────────────┘
```

---

## ✅ Checklist de Verificación

Marca cada uno cuando lo veas:

- [ ] Backend muestra logs de "🤖 Calling AI classification"
- [ ] Backend muestra "✅ AI Classification successful"
- [ ] Backend muestra porcentaje de confianza (ej: 87.3%)
- [ ] App muestra el badge 🤖 con porcentaje
- [ ] Al abrir el reporte, aparece la sección "CLASIFICACIÓN POR IA"
- [ ] Muestra: Confianza, Tiempo de procesamiento, Versión del modelo

---

## 🎨 Aspecto Visual Esperado

### Badge en la Lista de Reportes

```
Orgánico              🤖 92%     ← Verde con badge azul
Reciclable            🤖 87%     ← Azul con badge azul
No Reciclable         🤖 78%     ← Naranja con badge azul
```

### Colores del Badge

- **Verde brillante** 🟢: 85-100% confianza (Excelente)
- **Amarillo** 🟡: 70-85% confianza (Buena)
- **Naranja** 🟠: 50-70% confianza (Moderada)
- **Rojo** 🔴: <50% confianza (Baja)

### Indicador de Confianza

En el detalle del reporte verás una barra de progreso:

```
Confianza
█████████████████░░░  87%
```

---

## ⚡ Tiempos Esperados

- **Imagen pequeña** (<500 KB): 1.5-2.5 segundos
- **Imagen mediana** (500 KB - 2 MB): 2.5-4 segundos
- **Imagen grande** (2-5 MB): 4-6 segundos

---

## 🐛 Si algo sale mal

### No aparece el badge 🤖

**Revisa:**
1. ¿El backend muestra logs de IA? 
   - Si NO → Verifica que axios esté instalado
2. ¿Dice "AI Classification successful"?
   - Si NO → La función no respondió
3. ¿El reporte tiene `is_ai_classified: true` en Firestore?
   - Si NO → Los campos no se guardaron

### El badge muestra 0% o porcentaje extraño

**Revisa:**
- ¿La imagen tiene suficiente luz?
- ¿El objeto está enfocado?
- Prueba con otro objeto más reconocible

### Backend se congela o tarda mucho

**Posible causa:**
- Imagen demasiado grande
- Timeout de la función (30 segundos)
- Conexión lenta

**Solución:**
- La app ya redimensiona automáticamente
- Si persiste, verifica tu conexión a internet

---

## 🎉 Caso de Éxito

**Deberías ver algo así:**

### Terminal (Backend)
```
🤖 Calling AI classification for image: /path/to/ECO-12345678.jpg
📤 Sending image to AI (178.2 KB)
✅ AI Classification successful:
   Category: Orgánico
   Confidence: 94.2%
   Processing time: 1876ms
🎯 AI Classification: Orgánico (94.2% confidence)
```

### App
```
Lista de Reportes:
┌─────────────────────────────┐
│ ECO-12345678     🤖 94%     │
│ Orgánico                    │
│ hace 5 segundos             │
└─────────────────────────────┘

Detalle del Reporte:
┌─────────────────────────────┐
│ CLASIFICACIÓN POR IA        │
│ 🤖 Orgánico                 │
│ ✓ Confianza: 94.2%          │
│ ⏱️ Tiempo: 1.9 segundos     │
│ █████████████████████░ 94%  │
└─────────────────────────────┘
```

---

## 📸 Objetos Recomendados para Probar

### Alta Confianza (>85%)
- 🍌 Banana, manzana, naranja
- 🥤 Botella plástica transparente
- 📦 Caja de cartón
- 🗞️ Periódico
- 🥫 Lata de aluminio

### Confianza Media (70-85%)
- 🍕 Restos de comida mixtos
- 🧃 Envase de jugo (tetrapack)
- 🧴 Envase de shampoo
- 📄 Papeles mezclados

### Objetos Difíciles (<70%)
- 🗑️ Bolsas plásticas arrugadas
- 🧹 Objetos muy sucios
- 🌫️ Fotos con poca luz
- 🔍 Objetos muy pequeños

---

¡Listo! Ahora **pruébalo** y cuéntame qué tal funcionó. 🚀
