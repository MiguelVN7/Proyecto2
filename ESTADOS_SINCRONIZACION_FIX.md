# 🔧 Fix: Sincronización de Estados entre App y Página Web

**Fecha**: 10 de noviembre de 2025  
**Problema**: Los filtros en Environmental Reports no funcionan correctamente cuando se actualiza el estado desde la página web

---

## 📊 Problema Identificado

### Inconsistencia de Estados

**Página Web (Django)** guarda en Firestore:
- `'received'` → Recibido
- `'assigned'` → Asignado  
- `'in_progress'` → En Proceso
- `'completed'` → Resuelto
- `'cancelled'` → Cancelado

**App Móvil (Flutter)** guardaba:
- `'Pendiente'` / `'Recibido'` / `'Asignado'` / `'En Proceso'` / `'Resuelto'` / `'Cancelado'`

**Problema**: 
- ❌ App filtraba por `'received'` pero guardaba `'Recibido'`
- ❌ Cuando la web actualizaba a `'in_progress'`, la app no lo reconocía
- ❌ Los filtros no mostraban reportes actualizados desde la web

---

## ✅ Solución Implementada

### 1. **Modelo de Estados Unificado**

En `frontend/lib/models/reporte.dart`:

```dart
enum ReportStatus {
  pending('Pendiente', 'pending'),
  received('Recibido', 'received'),
  assigned('Asignado', 'assigned'),
  inProgress('En Proceso', 'in_progress'),
  completed('Resuelto', 'completed'),
  cancelled('Cancelado', 'cancelled');

  const ReportStatus(this.displayName, this.firestoreValue);
  final String displayName;  // Para mostrar en UI
  final String firestoreValue;  // Para guardar en Firestore
}
```

### 2. **Guardar con Valores Normalizados**

**ANTES** ❌:
```dart
Map<String, dynamic> toFirestore() {
  return {
    'estado': estado,  // Guardaba "Pendiente", "Recibido", etc.
    // ...
  };
}
```

**AHORA** ✅:
```dart
Map<String, dynamic> toFirestore() {
  final statusEnum = ReportStatus.fromString(estado);
  return {
    'estado': statusEnum.firestoreValue,  // Guarda "pending", "received", etc.
    // ...
  };
}
```

### 3. **Leer con Conversión Correcta**

**ANTES** ❌:
```dart
factory Reporte.fromFirestore(DocumentSnapshot doc) {
  return Reporte(
    estado: data['estado'] ?? 'Pendiente',  // Leía directamente
    // ...
  );
}
```

**AHORA** ✅:
```dart
factory Reporte.fromFirestore(DocumentSnapshot doc) {
  final firestoreEstado = data['estado'] ?? 'pending';
  final statusEnum = ReportStatus.fromString(firestoreEstado);
  
  return Reporte(
    estado: statusEnum.displayName,  // Convierte a displayName para UI
    // ...
  );
}
```

### 4. **Filtros Actualizados**

En `firestore_service.dart`:

**ANTES** ❌:
```dart
.where('estado', isEqualTo: status.displayName)  // Buscaba "Pendiente"
```

**AHORA** ✅:
```dart
.where('estado', isEqualTo: status.firestoreValue)  // Busca "pending"
```

---

## 🔄 Flujo de Datos Corregido

### Cuando la App Crea un Reporte:
```
Usuario selecciona estado → "Pendiente" (displayName)
       ↓
toFirestore() convierte → "pending" (firestoreValue)
       ↓
Firestore guarda → { estado: "pending" }
```

### Cuando la Web Actualiza un Reporte:
```
Admin cambia a "En Proceso" → Django envía "in_progress"
       ↓
Firestore actualiza → { estado: "in_progress" }
       ↓
App lee en tiempo real → fromFirestore() convierte a "En Proceso"
       ↓
UI muestra correctamente → "En Proceso"
```

### Cuando el Usuario Filtra:
```
Usuario selecciona filtro "En Proceso"
       ↓
firestore_reports_screen.dart → ReportStatus.inProgress
       ↓
getReportsByStatus() usa → status.firestoreValue ("in_progress")
       ↓
Firestore busca → .where('estado', '==', 'in_progress')
       ↓
✅ Encuentra todos los reportes en ese estado
```

---

## 🎯 Archivos Modificados

1. **`frontend/lib/models/reporte.dart`**
   - ✅ `toFirestore()`: Usa `firestoreValue`
   - ✅ `fromFirestore()`: Convierte de Firestore a `displayName`
   - ✅ `fromFirestoreData()`: Convierte de Firestore a `displayName`

2. **`frontend/lib/services/firestore_service.dart`**
   - ✅ `updateReportStatus()`: Usa `firestoreValue`
   - ✅ `getReportsByStatus()`: Filtra por `firestoreValue`
   - ✅ `getStatistics()`: Consulta por `firestoreValue`

---

## 🧪 Cómo Probar

### Paso 1: Limpiar y Recompilar la App
```bash
cd "/Users/miguelvillegas/Proyecto 2/frontend"
flutter clean
flutter pub get
flutter run
```

### Paso 2: Crear un Reporte desde la App
1. Abre la app
2. Crea un nuevo reporte
3. Verifica en Firebase Console que `estado: "pending"`

### Paso 3: Actualizar desde la Página Web
1. Ve a la página web Django
2. Cambia el estado del reporte a "En Proceso"
3. Verifica en Firebase Console que `estado: "in_progress"`

### Paso 4: Verificar Filtros en la App
1. En la app, ve a Environmental Reports
2. Selecciona el filtro "En Proceso"
3. ✅ El reporte debe aparecer correctamente

### Paso 5: Prueba Todos los Estados
Cambia entre:
- ✅ Pendiente → `pending`
- ✅ Recibido → `received`
- ✅ Asignado → `assigned`
- ✅ En Proceso → `in_progress`
- ✅ Resuelto → `completed`
- ✅ Cancelado → `cancelled`

---

## 📋 Mapeo Completo de Estados

| Estado UI (displayName) | Firestore (firestoreValue) | Django Web |
|------------------------|---------------------------|------------|
| Pendiente              | `pending`                 | pendiente  |
| Recibido               | `received`                | pendiente  |
| Asignado               | `assigned`                | asignado   |
| En Proceso             | `in_progress`             | en_proceso |
| Resuelto               | `completed`               | resuelto   |
| Cancelado              | `cancelled`               | cancelado  |

---

## ✅ Beneficios

1. **Sincronización perfecta** entre app y web
2. **Filtros funcionan correctamente** sin importar quién actualizó el estado
3. **Consistencia de datos** en Firestore
4. **Compatibilidad hacia atrás** con el mapeo de Django
5. **Código más mantenible** con enum type-safe

---

## 🔍 Verificación en Firebase Console

Para verificar que todo funciona:

1. Ve a Firebase Console → Firestore
2. Abre cualquier documento en `reports`
3. Verifica que `estado` tenga valores como:
   - ✅ `"pending"`, `"received"`, `"in_progress"`, etc.
   - ❌ NO `"Pendiente"`, `"Recibido"`, etc.

---

## 🚀 Estado: COMPLETADO

Los cambios están implementados y listos para probar. Los filtros ahora funcionarán correctamente independientemente de si el estado se actualiza desde la app móvil o la página web.
