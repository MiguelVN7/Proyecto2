# 🌱 EcoTrack - Proyecto Completo

Sistema completo de seguimiento ecológico con aplicación móvil y backend API.

##  Estructura del Proyecto (Monorepo)

```
Proyecto2/
├── 📱 frontend/           # Aplicación Flutter (eco_track)
├── 🖥️  backend/            # API Backend (Node.js/SQLite)
├── 🎨 assets/             # Recursos y mockups de diseño
├── 📚 docs/               # Documentación del proyecto
├── 🛠️  scripts/            # Scripts de desarrollo automatizados
└── 📝 logs/               # Logs de desarrollo
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

##  Funcionalidades

- ✅ Captura de fotos con cámara personalizada
- ✅ Clasificación automática de residuos (10 tipos diferentes)
- ✅ Geolocalización automática
- ✅ API REST para reportes
- ✅ Base de datos SQLite persistente
- ✅ Sistema de versiones automático
- ✅ Monorepo con frontend y backend integrados

##  Estado del Proyecto

**Última actualización**: Octubre 2025  
**Versión actual**: v1.0.0+2  
**Estado**:  Funcionando correctamente

##  Equipo de Desarrollo

**Desarrollado por**: 
- Juan Esteban Zuluaga
- Juan Ignacio Lotero  
- Miguel Villegas

**Materia**: Proyecto 2  
**Repositorio**: MiguelVN7/Proyecto2

##  Recursos Flutter

Información sobre Flutter:
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)


