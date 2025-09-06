# EcoTrack Backend

Backend server para recibir y procesar reportes de residuos de la aplicación EcoTrack.

## 🚀 Configuración Rápida para Desarrolladores

### Prerrequisitos
- Node.js (v16 o superior)  
- SQLite3
- npm o yarn

## Instalación

```bash
npm install
```

### 🗄️ Configurar Base de Datos

**Para nuevos desarrolladores:**
```bash
./setup_database.sh
```

Este script automáticamente:
- Crea la base de datos SQLite  
- Inserta datos de ejemplo para desarrollo
- Configura las tablas necesarias

**❌ ¿Por qué no está la BD en Git?**
- Contiene datos que cambian constantemente
- Evita conflictos entre desarrolladores  
- Mantiene el repositorio liviano

**✅ Cada desarrollador tiene su propia BD local**

## Ejecutar

```bash
# Desarrollo (con auto-restart)
npm run dev

# Producción
npm start
```

## Endpoints

### POST /api/reports
Recibe reportes de residuos con foto, ubicación y clasificación.

**Body:**
```json
{
  "photo": "data:image/jpeg;base64,/9j/4AAQSkZJRgABA...",
  "latitude": 4.624335,
  "longitude": -74.063644,
  "accuracy": 8.5,
  "classification": "Botella de plástico PET",
  "timestamp": "2025-09-03T12:30:00Z",
  "device_info": "Android"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Reporte recibido exitosamente",
  "report_code": "ECO-A1B2C3D4",
  "timestamp": "2025-09-03T12:30:15Z",
  "data": {
    "id": "ECO-A1B2C3D4",
    "location": { "latitude": 4.624335, "longitude": -74.063644, "accuracy": 8.5 },
    "classification": "Botella de plástico PET",
    "status": "received"
  }
}
```

### GET /health
Verificar estado del servidor.

### GET /api/reports
Listar todos los reportes (admin).

### GET /api/reports/:reportId
Consultar reporte específico.

## Estructura de Archivos

- `reports/` - Archivos JSON con datos de reportes
- `images/` - Imágenes de reportes guardadas
- `server.js` - Servidor principal## Uso del Servicio Firebase

En el código puedes hacer:

```js
const FirebaseService = require('./firebase');
const firebaseService = new FirebaseService();
await firebaseService.initialize(); // Usa .env
// o: await firebaseService.initialize('/ruta/al/serviceAccount.json');
```

Si no hay credenciales válidas, el backend continuará usando almacenamiento local (`reports/` e `images/`).

## Notas de Seguridad

- No subas el archivo de cuenta de servicio ni el `.env`.
- Revisa que `.gitignore` ya incluye `.env`.
- Usa cuentas con el menor conjunto de permisos posible en producción.

## Estructura de Archivos

- `reports/` - Archivos JSON con datos de reportes
- `images/` - Imágenes de reportes guardadas
- `server.js` - Servidor principal