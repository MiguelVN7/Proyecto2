# 🔥 Integración Firestore - EcoTrack Django

Esta guía explica cómo usar la página web Django con Firestore como base de datos.

## 📋 Descripción

La página web Django ahora se conecta directamente a **Firestore** para mostrar los reportes de residuos en tiempo real. Esto significa que los reportes creados desde la app móvil aparecen automáticamente en la web empresarial.

## 🏗️ Arquitectura

```
┌─────────────┐
│  App Móvil  │────┐
│   Flutter   │    │
└─────────────┘    │
                   ├──────▶ ┌──────────────┐
┌─────────────┐    │        │   Firestore  │
│ Backend API │────┘        │   Database   │
│   Node.js   │             └──────────────┘
└─────────────┘                     ▲
                                    │
┌─────────────┐                     │
│ Django Web  │─────────────────────┘
│  (Empresas) │
└─────────────┘
```

## 🚀 Instalación

### 1. Instalar Dependencias

```bash
cd PaginaWeb_P2

# Activar entorno virtual
source venv/bin/activate  # En macOS/Linux
# o
venv\Scripts\activate  # En Windows

# Instalar paquetes
pip install -r requirements.txt
```

### 2. Verificar Credenciales Firebase

Asegúrate de que el archivo `firebase-service-account.json` esté en la raíz del proyecto Django:

```bash
ls -la firebase-service-account.json
```

Si no está, cópialo desde el backend:

```bash
cp ../backend/firebase-service-account.json .
```

⚠️ **IMPORTANTE**: Este archivo **NUNCA** debe subirse a Git. Ya está incluido en `.gitignore`.

### 3. Ejecutar Migraciones (Solo para usuarios/cuadrillas)

```bash
python manage.py migrate
```

**Nota**: Los reportes ya no se almacenan en SQLite, vienen directamente de Firestore. Solo necesitamos las tablas de Django para usuarios y cuadrillas.

### 4. Crear Superusuario

```bash
python manage.py createsuperuser
```

### 5. Iniciar Servidor

```bash
python manage.py runserver
```

La aplicación estará disponible en: http://localhost:8000

## 📊 Funcionalidades

### ✅ Lo que funciona con Firestore:

- **Dashboard**: Muestra estadísticas en tiempo real de todos los reportes
- **Gestión de Reportes**:
  - Ver todos los reportes de Firestore
  - Filtrar por estado, tipo, prioridad
  - Visualización en mapa con Leaflet
  - Asignar reportes a cuadrillas
- **Sincronización en tiempo real**: Los cambios se reflejan automáticamente
- **Cache inteligente**: Reduce llamadas a Firestore (5 minutos de cache)

### 🔄 Lo que sigue usando SQLite:

- **Usuarios y Encargados**: Gestión local de usuarios Django
- **Cuadrillas**: Equipos de recolección
- **Autenticación**: Sistema de login Django

## 🗂️ Estructura de Archivos

```
PaginaWeb_P2/
├── firebase-service-account.json  ⚠️ No subir a Git
├── requirements.txt               ✅ Actualizado con firebase-admin
├── .gitignore                     ✅ Protege credenciales
├── reports/
│   ├── firestore_service.py      🔥 Servicio Firestore
│   ├── views.py                  ✅ Actualizado para Firestore
│   ├── models.py                 ➡️ Solo usuarios/cuadrillas
│   └── templates/
│       └── reports/
│           └── gestion_reportes.html  ✅ Compatible con Firestore
└── ecotrack_admin/
    └── settings.py                ✅ Configuración Firebase
```

## 🔧 Configuración

### Cache

El sistema usa cache local para reducir lecturas de Firestore:

```python
# En settings.py
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'TIMEOUT': 300,  # 5 minutos
    }
}
```

Para limpiar el cache manualmente:

```python
from django.core.cache import cache
cache.delete('firestore_reports_all')
```

### Mapeo de Datos

El servicio `firestore_service.py` convierte automáticamente los datos de Firestore al formato esperado por Django:

| Firestore Field | Django Field | Conversión |
|----------------|--------------|------------|
| `estado` | `estado` | `received` → `pendiente` |
| `clasificacion` | `tipo_residuo` | `Plástico` → `plastico` |
| `prioridad` | `prioridad` | Directo (minúsculas) |
| `location.latitude` | `latitud` | Float |
| `location.longitude` | `longitud` | Float |
| `ubicacion` | `direccion` | String |
| `foto_url` | `foto_url` | URL |

## 📝 Uso

### Ver Reportes

1. Inicia sesión en http://localhost:8000/login/
2. Ve a **Gestión de Reportes**
3. Verás todos los reportes de Firestore con:
   - Badge verde "Firestore" en el título
   - Indicador "Datos en tiempo real desde Firestore"

### Asignar Reportes a Cuadrilla

1. En la vista de gestión de reportes
2. Selecciona uno o más reportes (checkbox)
3. Haz clic en "Asignar a Cuadrilla"
4. Selecciona la cuadrilla
5. Los reportes se actualizan en Firestore automáticamente

### Crear Cuadrillas

1. Ve a **Cuadrillas**
2. Clic en "Nueva Cuadrilla"
3. Asigna miembros (usuarios Django)
4. Las cuadrillas se guardan en SQLite local

## 🐛 Troubleshooting

### Error: "firebase_admin not found"

```bash
pip install firebase-admin google-cloud-firestore
```

### Error: "Could not find the specified credentials"

Verifica que `firebase-service-account.json` esté en la raíz del proyecto Django:

```bash
ls -la firebase-service-account.json
```

### Error: "Permission denied" en Firestore

Revisa las reglas de Firestore en Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /reports/{reportId} {
      allow read, write: if true;  // Temporal para desarrollo
    }
  }
}
```

### No se muestran reportes

1. Verifica que hay reportes en Firestore
2. Revisa la consola del servidor Django para errores
3. Limpia el cache:
   ```python
   from django.core.cache import cache
   cache.clear()
   ```

## 🧪 Probar Sincronización en Tiempo Real

### Script de Prueba Automático

Hemos incluido un script de prueba para verificar que todo funciona:

```bash
cd PaginaWeb_P2
python test_sincronizacion.py
```

Este script:
1. ✅ Verifica conexión a Firestore
2. ✅ Obtiene reportes
3. ✅ **Cambia el estado de un reporte** (¡observa la app móvil!)
4. ✅ Asigna un reporte a un usuario

**Durante la prueba:**
- 📱 Abre la app móvil en tu teléfono
- 👀 Observa cómo el estado cambia automáticamente
- ⏱️ Debe actualizarse en 1-2 segundos

### Cambiar Estado Manualmente

También puedes cambiar estados desde código:

```python
from reports.firestore_service import firestore_service

# Cambiar estado de un reporte
firestore_service.update_report_status('ECO-12345678', 'in_progress')

# Asignar a usuario
firestore_service.assign_report_to_user(
    'ECO-12345678',
    'user_123',
    'Juan Pérez'
)
```

### Cambiar Estado desde la Web (API)

Usa el nuevo endpoint:

```javascript
// Desde consola del navegador o JavaScript
fetch('/api/cambiar-estado-reporte/', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    reporte_id: 'ECO-12345678',
    estado: 'en_proceso'  // pendiente, asignado, en_proceso, resuelto, cancelado
  })
})
.then(r => r.json())
.then(data => console.log(data));
```

**Resultado esperado:**
- ✅ La app móvil se actualiza en 1-2 segundos
- ✅ El usuario ve el nuevo estado sin refrescar

## 📊 Monitoreo

### Ver logs de Firestore

El servicio imprime logs detallados:

```
🔥 Firebase Admin SDK initialized successfully
✅ Firestore Service ready
📋 Fetching all reports from Firestore (limit: 500)
✅ Retrieved 37 reports from Firestore
```

### Estadísticas

Puedes obtener estadísticas directamente:

```python
from reports.firestore_service import firestore_service

stats = firestore_service.get_stats()
print(stats)
# {
#   'total_reports': 37,
#   'by_status': {'pendiente': 20, 'asignado': 10, 'resuelto': 7},
#   'by_classification': {...},
#   'by_priority': {...}
# }
```

## 🔐 Seguridad

### Credenciales

- ✅ `firebase-service-account.json` está en `.gitignore`
- ✅ No expongas las credenciales en el código
- ✅ Usa variables de entorno en producción

### Producción

Para producción, usa variables de entorno:

```python
# settings.py
import os

FIREBASE_CREDENTIALS = os.environ.get(
    'FIREBASE_CREDENTIALS',
    os.path.join(BASE_DIR, 'firebase-service-account.json')
)
```

## 🚀 Próximos Pasos

- [ ] Implementar actualizaciones en tiempo real con WebSockets
- [ ] Agregar paginación para grandes volúmenes de reportes
- [ ] Implementar filtros geográficos (por zona)
- [ ] Exportar reportes a Excel/PDF
- [ ] Dashboard con gráficos (Chart.js)
- [ ] Notificaciones push para nuevos reportes

## 📞 Soporte

Para preguntas o problemas:

1. Revisa esta guía
2. Verifica los logs del servidor Django
3. Consulta la documentación de Firebase: https://firebase.google.com/docs/firestore

## 🎉 ¡Listo!

Tu aplicación Django ahora está completamente integrada con Firestore. Los reportes de la app móvil aparecen automáticamente en la web empresarial.

**Características principales:**
- ✅ Datos en tiempo real
- ✅ Sincronización automática
- ✅ Cache inteligente
- ✅ Escalabilidad cloud
- ✅ Una sola fuente de verdad

---

**Última actualización**: Noviembre 2024
**Versión**: 1.0.0
