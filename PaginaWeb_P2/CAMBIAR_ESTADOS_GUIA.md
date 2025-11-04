# 🔄 Guía: Cambiar Estado de Reportes desde la Web

## ✨ Nueva Funcionalidad Agregada

Ahora puedes **cambiar el estado de cualquier reporte** directamente desde la pantalla de **Gestión de Reportes**, sin necesidad de código o APIs externas.

---

## 📍 ¿Dónde Está?

1. Inicia sesión en http://localhost:8000
2. Ve a **Gestión de Reportes**
3. Busca cualquier reporte en la lista
4. En la parte inferior de cada reporte verás:

```
┌─────────────────────────────────────────┐
│ Reporte #ECO-12345678                   │
│ ┌─────────────────────────────────────┐ │
│ │ Tipo: Plástico                      │ │
│ │ Dirección: Calle 45 #23-11          │ │
│ │ Fecha: 03/11/2024 14:30             │ │
│ ├─────────────────────────────────────┤ │
│ │ Cambiar Estado:                     │ │
│ │ [Dropdown ▼]  [Aplicar ✓]          │ │
│ │ ✅ Estado actualizado correctamente │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## 🎯 Cómo Usar

### **Paso 1: Seleccionar Nuevo Estado**

Haz clic en el dropdown "Cambiar Estado" y selecciona:
- ⏳ **Pendiente** - Reporte recibido, esperando asignación
- 👤 **Asignado** - Asignado a una cuadrilla/encargado
- 🔄 **En Proceso** - Se está trabajando en el reporte
- ✅ **Resuelto** - Problema solucionado
- ❌ **Cancelado** - Reporte cancelado o inválido

### **Paso 2: Aplicar Cambio**

1. Al seleccionar un estado diferente, aparece el botón **"Aplicar"**
2. Haz clic en **"Aplicar"**
3. El botón mostrará: `⏳ Actualizando...`

### **Paso 3: Confirmación**

Verás un mensaje de confirmación:
```
✅ Estado actualizado correctamente.
   La app móvil se actualizará en 1-2 segundos.
```

### **Paso 4: Verificar en App Móvil**

1. Abre la app móvil en tu teléfono
2. Navega a la lista de reportes
3. **¡El estado se habrá actualizado automáticamente!** 📱✨

---

## ⚡ Características

### ✅ **Actualizaciones en Tiempo Real**
- Los cambios se sincronizan **instantáneamente** con Firestore
- La app móvil se actualiza en **1-2 segundos** sin refrescar
- **No necesitas recargar la página** - el badge de estado se actualiza solo

### ✅ **Feedback Visual**
- Botón "Aplicar" solo aparece cuando cambias el estado
- Spinner durante la actualización
- Mensajes de éxito/error claros
- El badge de estado se actualiza automáticamente

### ✅ **Validación**
- Solo puedes cambiar estados válidos
- El sistema previene cambios duplicados
- Manejo robusto de errores

---

## 📊 Estados y Su Significado

| Estado | Cuándo Usarlo | Color | App Móvil |
|--------|---------------|-------|-----------|
| **Pendiente** | Reporte nuevo, sin asignar | 🟡 Amarillo | "Recibido" |
| **Asignado** | Asignado a cuadrilla | 🔵 Azul | "Asignado" |
| **En Proceso** | Cuadrilla trabajando | 🟠 Naranja | "En Proceso" |
| **Resuelto** | Problema solucionado | 🟢 Verde | "Completado" |
| **Cancelado** | Cancelado o inválido | 🔴 Rojo | "Cancelado" |

---

## 🔄 Flujo Completo de Trabajo

### **Escenario: Ciudadano reporta basura**

```
1. Usuario crea reporte desde app móvil
   └─> Estado: "Pendiente" (received)

2. Empresa ve reporte en la web
   └─> Cambia estado a: "Asignado" (assigned)
   └─> Asigna a Cuadrilla Norte

3. Cuadrilla recibe notificación en app
   └─> Ve que fue asignado
   └─> Cambia estado a: "En Proceso" (in_progress)

4. Cuadrilla termina trabajo
   └─> Toma foto de validación
   └─> Cambia estado a: "Resuelto" (completed)

5. Ciudadano ve en su app
   └─> Estado: "Completado" ✅
   └─> Puede ver foto de antes/después
```

---

## 🎨 Ejemplo Visual

### **Antes de Cambiar:**
```
┌──────────────────────────────────┐
│ #ECO-ABC123  [Pendiente] [Media] │
│                                   │
│ Tipo: Plástico                    │
│ Dirección: Calle 45 #23-11        │
│                                   │
│ Cambiar Estado: [Pendiente ▼]    │
│                                   │
└──────────────────────────────────┘
```

### **Seleccionando Nuevo Estado:**
```
┌──────────────────────────────────┐
│ #ECO-ABC123  [Pendiente] [Media] │
│                                   │
│ Tipo: Plástico                    │
│ Dirección: Calle 45 #23-11        │
│                                   │
│ Cambiar Estado: [En Proceso ▼]   │
│                 [✓ Aplicar]       │
└──────────────────────────────────┘
```

### **Después del Cambio:**
```
┌──────────────────────────────────┐
│ #ECO-ABC123 [En Proceso] [Media] │  ← Badge actualizado
│                                   │
│ Tipo: Plástico                    │
│ Dirección: Calle 45 #23-11        │
│                                   │
│ Cambiar Estado: [En Proceso ▼]   │
│ ✅ Estado actualizado             │  ← Mensaje de éxito
└──────────────────────────────────┘
```

---

## 🔧 Detalles Técnicos

### **Endpoint API**
```
POST /api/cambiar-estado-reporte/
Content-Type: application/json

{
  "reporte_id": "ECO-12345678",
  "estado": "en_proceso"
}
```

### **Mapeo de Estados**

La página web usa nombres en español, pero Firestore usa nombres en inglés:

| Web (Django) | Firestore | App Móvil |
|--------------|-----------|-----------|
| `pendiente` | `received` | Recibido |
| `asignado` | `assigned` | Asignado |
| `en_proceso` | `in_progress` | En Proceso |
| `resuelto` | `completed` | Completado |
| `cancelado` | `cancelled` | Cancelado |

**Esto se maneja automáticamente** - no necesitas preocuparte por la conversión.

---

## 🐛 Troubleshooting

### **El botón "Aplicar" no aparece**
- Asegúrate de seleccionar un estado **diferente** al actual
- El botón solo aparece cuando hay cambios

### **Error: "No se pudo actualizar el reporte"**
- Verifica la conexión a Firestore
- Revisa la consola del navegador (F12)
- Verifica que `firebase-service-account.json` esté configurado

### **La app móvil no se actualiza**
- Verifica que la app esté usando Streams de Firestore
- Espera 2-3 segundos (puede haber un pequeño delay)
- Verifica la conexión a internet de la app

### **El estado cambia pero el badge no se actualiza**
- Recarga la página (F5)
- Limpia el cache del navegador
- Verifica que estés usando la versión más reciente del código

---

## 📱 Verificar en App Móvil

### **Opción 1: En la Lista de Reportes**
1. Abre la app móvil
2. Ve a "Mis Reportes" o "Todos los Reportes"
3. Busca el reporte que modificaste
4. El estado debe mostrarse actualizado

### **Opción 2: En Detalle del Reporte**
1. Abre el reporte específico
2. Verás el nuevo estado en la parte superior
3. Si está "En Proceso" o "Completado", verás información adicional

---

## 💡 Consejos

### **✅ Buenas Prácticas**

1. **Asigna antes de poner en proceso**
   - Primero cambia a "Asignado"
   - Luego a "En Proceso" cuando la cuadrilla empiece

2. **Usa estados apropiados**
   - No saltes de "Pendiente" a "Resuelto"
   - Sigue el flujo lógico del trabajo

3. **Verifica en la app móvil**
   - Confirma que los cambios se reflejen
   - Asegura que los usuarios vean las actualizaciones

### **⚠️ Evitar**

1. ❌ Cambiar a "Resuelto" sin foto de validación
2. ❌ Usar "Cancelado" para reportes válidos
3. ❌ Cambiar estados de reportes ya completados sin razón

---

## 🎉 Ventajas de Esta Funcionalidad

1. **✅ Interfaz Visual Simple**
   - No necesitas conocimientos técnicos
   - Todo desde la misma pantalla
   - Feedback inmediato

2. **✅ Sincronización Automática**
   - Los usuarios ven cambios al instante
   - No hay retrasos en la información
   - Transparencia total

3. **✅ Control Centralizado**
   - Las empresas pueden gestionar todos los reportes
   - Visibilidad completa del flujo de trabajo
   - Mejor seguimiento de tareas

4. **✅ Experiencia de Usuario Mejorada**
   - Ciudadanos informados en tiempo real
   - Confianza en el sistema
   - Mayor satisfacción

---

## 📊 Estadísticas de Uso

Después de cambiar estados, puedes ver estadísticas en tiempo real:

```python
# En el shell de Django
from reports.firestore_service import firestore_service

stats = firestore_service.get_stats()
print(stats['by_status'])
# {
#   'pendiente': 15,
#   'asignado': 8,
#   'en_proceso': 5,
#   'resuelto': 22,
#   'cancelado': 2
# }
```

---

## 🚀 Próximas Mejoras

Ideas para futuras versiones:

- [ ] Cambio masivo de estados (múltiples reportes a la vez)
- [ ] Historial de cambios de estado
- [ ] Notificaciones push al usuario cuando cambia el estado
- [ ] Comentarios al cambiar estado (ej: "Retrasado por lluvia")
- [ ] Asignación automática basada en zona

---

## ✅ Checklist de Uso

Antes de cambiar un estado, verifica:

- [ ] El reporte está seleccionado correctamente
- [ ] El nuevo estado es apropiado para la situación
- [ ] Si es "Resuelto", hay foto de validación (opcional por ahora)
- [ ] Tienes conexión a internet
- [ ] La app móvil del usuario tiene conexión

---

**¡Listo!** Ya puedes gestionar el estado de todos los reportes desde la interfaz web de forma simple e intuitiva.

🎯 **Resultado:** Ciudadanos informados + Empresas eficientes + Sistema transparente = ✅

---

**Última actualización**: Noviembre 2024
**Versión**: 2.0.0
