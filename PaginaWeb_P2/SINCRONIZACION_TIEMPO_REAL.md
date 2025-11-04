# 🔄 Sincronización en Tiempo Real - Firestore

## ✅ **RESPUESTA CORTA: SÍ, funciona en tiempo real**

Cuando cambias el estado de un reporte en la **página web Django**, el cambio **SÍ se refleja automáticamente** en la **app móvil** gracias a los **Streams de Firestore**.

---

## 📡 ¿Cómo Funciona?

### **1. App Móvil - Escucha Cambios en Tiempo Real**

La app móvil Flutter usa **Streams de Firestore** que escuchan cambios automáticamente:

```dart
// En frontend/lib/services/firestore_service.dart (línea 508)
Stream<List<Reporte>> getReportsStream({int limit = 50, String? userId}) {
  return _firestore
    .collection('reports')
    .orderBy('created_at', descending: true)
    .limit(limit)
    .snapshots()  // 👈 Esto hace la magia!
    .map((snapshot) {
      // Cada vez que cambia algo en Firestore, este código se ejecuta
      return snapshot.docs.map((doc) => Reporte.fromFirestore(doc)).toList();
    });
}
```

**¿Qué hace `.snapshots()`?**
- Establece una conexión persistente con Firestore
- Cada vez que un documento cambia, Firestore **envía automáticamente** el nuevo dato
- La app móvil se actualiza sin necesidad de refresh manual

---

### **2. Página Web Django - Escribe Cambios a Firestore**

Cuando cambias el estado desde Django, se actualiza directamente en Firestore:

```python
# En views.py - Nueva vista que agregamos
def cambiar_estado_reporte_view(request):
    # 1. Recibe el nuevo estado
    nuevo_estado = data.get('estado')  # ej: 'en_proceso'

    # 2. Actualiza en Firestore
    firestore_service.update_report_status(reporte_id, nuevo_estado)

    # 3. Firestore notifica automáticamente a todos los clientes conectados
    # (incluyendo la app móvil) ✅
```

---

## 🔄 Flujo Completo de Sincronización

```
┌─────────────────┐
│  Página Web     │
│  Django         │
└────────┬────────┘
         │
         │ 1. Usuario cambia estado
         │    de "pendiente" a "en_proceso"
         ▼
┌─────────────────┐
│  firestore_     │
│  service.py     │
└────────┬────────┘
         │
         │ 2. Llama a Firestore API
         │    update_report_status()
         ▼
┌─────────────────┐
│   FIRESTORE     │ ◄─────┐ 3. Stream activo
│   (Cloud)       │       │    escuchando cambios
└─────────────────┘       │
         │                │
         │ 4. Firestore   │
         │    envía       │
         │    evento      │
         ▼                │
┌─────────────────┐       │
│  App Móvil      │───────┘
│  Flutter        │
└─────────────────┘
         │
         │ 5. UI se actualiza
         │    automáticamente
         ▼
    👤 Usuario ve
       nuevo estado
```

---

## 🧪 **Cómo Probarlo**

### **Opción 1: Cambiar Estado desde Django Web**

1. **Abre la página web Django**:
   ```bash
   cd PaginaWeb_P2
   python manage.py runserver
   ```
   Ve a: http://localhost:8000

2. **Abre la app móvil** en tu teléfono/emulador

3. **Cambia el estado de un reporte** desde la web usando la nueva API:

   ```javascript
   // Desde la consola del navegador o un botón
   fetch('/api/cambiar-estado-reporte/', {
     method: 'POST',
     headers: {
       'Content-Type': 'application/json',
     },
     body: JSON.stringify({
       reporte_id: 'ECO-12345678',
       estado: 'en_proceso'
     })
   })
   .then(r => r.json())
   .then(data => console.log(data));
   ```

4. **¡Observa la app móvil!** El estado debe cambiar **automáticamente en 1-2 segundos** sin necesidad de:
   - ❌ Refrescar la pantalla
   - ❌ Cerrar y abrir la app
   - ❌ Hacer pull-to-refresh

### **Opción 2: Cambiar Estado desde App Móvil**

1. Abre la app móvil
2. Cambia el estado de un reporte (ej: marcar como completado)
3. **¡Observa la página web!** Actualiza la página y verás el cambio reflejado
   - Nota: La web usa cache de 5 minutos, así que puede tardar hasta 5 min en reflejarse
   - Para ver cambios inmediatos, limpia el cache o espera a que expire

---

## ⚡ **Tiempos de Sincronización**

| Origen del Cambio | Destino | Tiempo | Notas |
|------------------|---------|--------|-------|
| Web → App Móvil | **1-2 segundos** | ✅ Tiempo real | Gracias a `.snapshots()` |
| App Móvil → Web | **5 minutos** | ⚠️ Con cache | Cache configurado en `settings.py` |
| App Móvil → Web | **Inmediato** | ✅ Sin cache | Si limpias cache o esperas expiración |

---

## 🔧 **Configuración Actual**

### **En la App Móvil** (Tiempo Real ✅)

La app usa **Streams** para escuchar cambios:

```dart
// Se ejecuta automáticamente cuando Firestore cambia
getReportsStream().listen((reportes) {
  // UI se actualiza automáticamente
  setState(() {
    _reportes = reportes;
  });
});
```

### **En la Página Web** (Con Cache ⚠️)

Django usa cache para reducir llamadas a Firestore:

```python
# settings.py
CACHES = {
    'default': {
        'TIMEOUT': 300,  # 5 minutos
    }
}
```

**Para desactivar el cache temporalmente** (durante desarrollo):

```python
# En views.py, comenta estas líneas:
# reportes_firestore = cache.get(cache_key)
# if reportes_firestore is None:

# Y siempre obtén de Firestore directamente:
reportes_firestore = firestore_service.get_all_reports(limit=500)
```

---

## 🎯 **Estados Soportados**

La API mapea automáticamente entre formatos Django y Firestore:

| Django (Web) | Firestore (DB) | App Móvil |
|--------------|----------------|-----------|
| `pendiente` | `received` | "Recibido" |
| `asignado` | `assigned` | "Asignado" |
| `en_proceso` | `in_progress` | "En Proceso" |
| `resuelto` | `completed` | "Completado" |
| `cancelado` | `cancelled` | "Cancelado" |

---

## 📊 **Ejemplo Práctico**

### **Escenario: Empresa asigna cuadrilla a un reporte**

1. **T=0s**: Encargado en la web selecciona reporte ECO-ABC123
2. **T=0s**: Hace clic en "Asignar a Cuadrilla Norte"
3. **T=0.5s**: Django actualiza Firestore
4. **T=1s**: Firestore envía notificación push a todos los clientes
5. **T=1.5s**: App móvil del ciudadano recibe actualización
6. **T=1.5s**: UI de la app se actualiza mostrando "Asignado"

**Total: ~1.5 segundos** ⚡

---

## 🛠️ **API Endpoint para Cambiar Estado**

### **URL**: `POST /api/cambiar-estado-reporte/`

### **Request Body**:
```json
{
  "reporte_id": "ECO-12345678",
  "estado": "en_proceso"
}
```

### **Response Success**:
```json
{
  "success": true,
  "message": "Estado del reporte ECO-12345678 actualizado a en_proceso",
  "reporte_id": "ECO-12345678",
  "nuevo_estado": "en_proceso"
}
```

### **Response Error**:
```json
{
  "success": false,
  "error": "No se pudo actualizar el reporte en Firestore"
}
```

---

## 🔍 **Verificar Sincronización en Vivo**

### **Opción 1: Firebase Console**

1. Ve a https://console.firebase.google.com
2. Selecciona tu proyecto
3. Ve a **Firestore Database**
4. Navega a la colección `reports`
5. Cambia el estado de un documento manualmente
6. **¡Observa ambas apps actualizarse!** 🎉

### **Opción 2: Logs de la App Móvil**

La app imprime logs cuando recibe actualizaciones:

```
📡 Reports stream update: 37 reports
✅ Report ECO-ABC123 updated
```

### **Opción 3: Logs de Django**

Django imprime cuando actualiza Firestore:

```
🔄 Updating report ECO-ABC123 status to: in_progress
✅ Report ECO-ABC123 status updated to in_progress
```

---

## 💡 **Mejoras Futuras**

Para sincronización **100% en tiempo real** en la web también:

### **1. WebSockets con Django Channels**

```python
# Instalar Django Channels
pip install channels channels-redis

# Configurar consumer que escucha Firestore
class ReportConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # Suscribirse a cambios de Firestore
        firestore_service.watch_reports(self.send_update)
```

### **2. Server-Sent Events (SSE)**

```python
# Vista que mantiene conexión abierta
def reports_stream(request):
    def event_stream():
        while True:
            reports = firestore_service.get_all_reports()
            yield f"data: {json.dumps(reports)}\n\n"
            time.sleep(1)

    return StreamingHttpResponse(event_stream(), content_type='text/event-stream')
```

### **3. Polling JavaScript**

```javascript
// En el template
setInterval(() => {
  fetch('/gestion-reportes/')
    .then(r => r.text())
    .then(html => {
      document.querySelector('#reportesList').innerHTML = html;
    });
}, 5000);  // Cada 5 segundos
```

---

## ✅ **Conclusión**

**SÍ, la sincronización en tiempo real funciona:**

- ✅ **App Móvil → Firestore**: Inmediato
- ✅ **Firestore → App Móvil**: 1-2 segundos (tiempo real)
- ✅ **Web Django → Firestore**: Inmediato
- ⚠️ **Firestore → Web Django**: 5 minutos (con cache) o inmediato (sin cache)

La app móvil **siempre** verá los cambios de la web en **tiempo real** gracias a los Firestore Streams.

---

**Última actualización**: Noviembre 2024
**Versión**: 1.0.0
