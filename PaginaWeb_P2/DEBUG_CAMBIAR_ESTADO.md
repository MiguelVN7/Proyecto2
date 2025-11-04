# 🐛 Debug: Cambiar Estado de Reportes

## Problema Reportado
El botón "Aplicar" no cambia el estado del reporte.

## ✅ Correcciones Aplicadas

1. **Mejorado el selector de badges** (línea 759-776)
   - Ahora usa `querySelectorAll` para obtener todos los badges
   - Selecciona el primero (que es el de estado)

2. **Agregado preventDefault y stopPropagation** (líneas 717-718)
   - Previene comportamiento por defecto
   - Evita que el click se propague al contenedor padre

3. **Agregados console.log para debugging** (líneas 729, 736, 750, 795)
   - Ver qué reporte se está modificando
   - Ver la URL del endpoint
   - Ver la respuesta del servidor
   - Ver errores si ocurren

## 🔍 Cómo Debuggear

### Paso 1: Abrir Consola del Navegador
1. Presiona **F12** en tu navegador
2. Ve a la pestaña **Console**
3. Limpia la consola (ícono de 🚫 o Ctrl+L)

### Paso 2: Intentar Cambiar Estado
1. Ve a la página de **Gestión de Reportes**
2. Selecciona un nuevo estado en el dropdown
3. Haz clic en **Aplicar**

### Paso 3: Revisar Logs
Deberías ver algo como:

```
Cambiando estado de reporte: ECO-8A92CC73 a: en_proceso
Enviando petición a: /api/cambiar-estado-reporte/
Respuesta del servidor: {success: true, message: "...", ...}
```

## 🎯 Posibles Problemas y Soluciones

### Problema 1: No aparece ningún log
**Causa:** El evento click no se está disparando

**Solución:**
1. Verifica que el botón tenga la clase `btn-cambiar-estado`
2. Abre la consola y ejecuta:
```javascript
document.querySelectorAll('.btn-cambiar-estado').forEach(btn => {
  console.log('Botón encontrado:', btn.dataset.reporteId);
});
```

### Problema 2: Error de CSRF Token
**Logs:**
```
Error: 403 Forbidden
```

**Solución:**
1. Verifica que la función `getCookie` esté definida
2. Abre consola y ejecuta:
```javascript
function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}
console.log('CSRF Token:', getCookie('csrftoken'));
```

### Problema 3: Reporte no encontrado
**Logs:**
```
Respuesta del servidor: {success: false, error: "Report with ID ECO-XXX not found"}
```

**Solución:**
1. Verifica que el reporte exista en Firestore
2. Ejecuta en consola de Python:
```python
from reports.firestore_service import firestore_service
report = firestore_service.get_report_by_id('ECO-8A92CC73')
print(report)
```

### Problema 4: Error de conexión a Firestore
**Logs:**
```
Error al cambiar estado: Error updating report status
```

**Solución:**
1. Verifica que `firebase-service-account.json` esté en su lugar
2. Verifica los logs del servidor Django:
```bash
# En la terminal donde corre el servidor, verás:
❌ Error updating report status: [details]
```

3. Prueba la conexión:
```bash
cd PaginaWeb_P2
python test_sincronizacion.py
```

## 🧪 Prueba Manual desde Consola

Si el botón no funciona, puedes probar directamente desde la consola del navegador:

```javascript
// 1. Obtener función getCookie
function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}

// 2. Hacer petición manual
fetch('/api/cambiar-estado-reporte/', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRFToken': getCookie('csrftoken')
  },
  body: JSON.stringify({
    reporte_id: 'ECO-8A92CC73',  // Cambia por ID real
    estado: 'en_proceso'
  })
})
.then(r => r.json())
.then(data => console.log('Respuesta:', data))
.catch(err => console.error('Error:', err));
```

## 🔧 Verificar Estado en Firestore

Desde Python (Django shell):

```python
from reports.firestore_service import firestore_service

# Ver reporte actual
report = firestore_service.get_report_by_id('ECO-8A92CC73')
print('Estado actual:', report['estado'])

# Cambiar estado manualmente
success = firestore_service.update_report_status('ECO-8A92CC73', 'in_progress')
print('Actualizado:', success)

# Verificar cambio
report = firestore_service.get_report_by_id('ECO-8A92CC73')
print('Nuevo estado:', report['estado'])
```

## 📊 Checklist de Diagnóstico

Ejecuta estos pasos en orden:

- [ ] Abrir consola del navegador (F12)
- [ ] Verificar que no hay errores de JavaScript previos
- [ ] Verificar que el botón "Aplicar" existe en el DOM
- [ ] Intentar cambiar estado y ver logs
- [ ] Si no hay logs: verificar que el evento click se dispara
- [ ] Si hay error 403: verificar CSRF token
- [ ] Si hay error 500: revisar logs del servidor Django
- [ ] Si dice "success: false": leer el mensaje de error
- [ ] Probar petición manual desde consola
- [ ] Verificar conexión a Firestore con script de prueba

## 🎯 Solución Rápida

Si nada funciona, intenta esto:

1. **Recargar la página** (Ctrl+F5 para limpiar caché)
2. **Reiniciar el servidor Django**
```bash
# Ctrl+C para detener
python manage.py runserver
```
3. **Limpiar cache de Django**
```python
# En Django shell
from django.core.cache import cache
cache.clear()
```

## 📝 Reportar el Problema

Si el problema persiste, copia y pega esto:

```
### Información del Error

**Navegador:** [Chrome/Firefox/Safari]
**Versión Django:** 5.2.7

**Logs de la Consola:**
[Pegar logs aquí]

**Respuesta del servidor:**
[Pegar respuesta aquí]

**Código de estado HTTP:**
[Pegar código aquí, ej: 200, 403, 500]
```

---

**Última actualización:** Noviembre 2024
