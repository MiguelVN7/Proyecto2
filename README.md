# 🌱 EcoTrack - Proyecto Completo

Sistema completo de seguimiento ecológico con aplicación móvil y backend API.

## 📁 Estructura del Proyecto

```
Proyecto2/
├── 📱 frontend/           # Aplicación Flutter
├── 🖥️  backend/            # API Backend (Node.js/SQLite)
├── 🎨 assets/             # Recursos y mockups
├── 📚 docs/               # Documentación
└── 🛠️  scripts/            # Scripts de desarrollo
```

## 🚀 Inicio Rápido

### Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run -d [device_id]
```

### Backend (Node.js)
```bash
cd backend
npm install
npm start
```

## 🛠️ Desarrollo

### Script de Despliegue Limpio
```bash
cd frontend
./dev_deploy.sh [device_id]
```

### Comandos Útiles
```bash
# Limpiar todo
flutter clean && cd android && ./gradlew clean

# Verificar servidor
curl http://localhost:3000/health

# Ver reportes en base de datos
curl http://localhost:3000/api/reports | jq
```

## 📋 Tecnologías

- **Frontend**: Flutter, Dart
- **Backend**: Node.js, Express, SQLite
- **Móvil**: Android (cámara personalizada)
- **Base de datos**: SQLite
- **API**: RESTful

## 🎯 Funcionalidades

- ✅ Captura de fotos con cámara personalizada
- ✅ Clasificación automática de residuos
- ✅ Geolocalización automática
- ✅ API REST para reportes
- ✅ Base de datos SQLite persistente
- ✅ Sistema de versiones automático

## 🔄 Estado del Proyecto

**Última actualización**: Septiembre 2025  
**Versión actual**: v1.0.0+2  
**Estado**: ✅ Funcionando correctamente

---

**Desarrollado por**: Miguel Villegas  
**Repositorio**: MiguelVN7/Proyecto2
