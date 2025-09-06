# 👥 Instrucciones para Compañeros de Equipo

## 🚀 Configuración Inicial del Proyecto EcoTrack

¡Bienvenido al equipo! Sigue estos pasos para configurar el proyecto en tu máquina local.

### 📋 Prerrequisitos

Asegúrate de tener instalado:
- **Node.js** (v16+): [Descargar aquí](https://nodejs.org/)
- **Flutter** (v3.0+): [Guía de instalación](https://docs.flutter.dev/get-started/install)
- **Git**: [Descargar aquí](https://git-scm.com/)
- **SQLite3**: 
  - macOS: `brew install sqlite`
  - Ubuntu: `sudo apt-get install sqlite3`

### 1️⃣ Clonar el Repositorio

```bash
git clone https://github.com/MiguelVN7/Proyecto2.git
cd Proyecto2
```

### 2️⃣ Configurar Backend

```bash
# Ir al directorio del backend
cd backend

# Instalar dependencias
npm install

# Configurar base de datos automáticamente
./setup_database.sh

# Iniciar servidor (en una terminal separada)
npm start
```

✅ **El servidor debería estar corriendo en:** http://localhost:3000

### 3️⃣ Configurar Frontend

```bash
# Ir al directorio del frontend (nueva terminal)
cd frontend

# Instalar dependencias de Flutter
flutter pub get

# Conectar dispositivo Android o iniciar emulador
flutter devices

# Ejecutar la app
flutter run
```

### 4️⃣ Verificar Configuración

**Backend funcionando:**
- Ve a: http://localhost:3000/health
- Deberías ver: `{"status":"OK","message":"EcoTrack Backend API funcionando correctamente"}`

**Frontend funcionando:**
- La app debería abrir en tu dispositivo/emulador
- Deberías ver la pantalla principal de EcoTrack

### 🗄️ Sobre la Base de Datos

**¿Por qué no está la BD en el repositorio?**
- Las bases de datos contienen datos dinámicos que cambian constantemente
- Cada desarrollador necesita su propia BD local para evitar conflictos
- Mantiene el repositorio limpio y liviano

**¿Cómo funciona?**
- El script `setup_database.sh` crea automáticamente la BD con datos de ejemplo
- Puedes reiniciar la BD en cualquier momento ejecutando el script nuevamente
- Los datos son solo para desarrollo, no afectan producción

### 🛠️ Scripts Útiles

```bash
# Backend
cd backend
npm start              # Iniciar servidor
npm run dev            # Desarrollo con auto-reload
./setup_database.sh    # Reiniciar BD con datos frescos

# Frontend  
cd frontend
flutter run            # Ejecutar app
flutter clean          # Limpiar caché de build
flutter pub get        # Actualizar dependencias
```

### 🆘 Problemas Comunes

**Error: "Puerto 3000 ya en uso"**
```bash
lsof -i :3000
kill -9 [PID_DEL_PROCESO]
```

**Error: "Base de datos no encontrada"**
```bash
cd backend
./setup_database.sh
```

**Error: "Flutter command not found"**
- Reinstala Flutter siguiendo la [guía oficial](https://docs.flutter.dev/get-started/install)
- Asegúrate de que esté en tu PATH

**Error: "npm: command not found"**
- Instala Node.js desde [nodejs.org](https://nodejs.org/)

### 📱 Desarrollo

**Para probar la app:**
1. Asegúrate de que el backend esté corriendo (puerto 3000)
2. Ejecuta la app Flutter en un dispositivo Android
3. Prueba tomar fotos y registrar reportes
4. Los datos se guardarán en tu BD local

### 🤝 Colaboración

- **Ramas**: Crea una rama para cada feature (`git checkout -b feature/nombre-feature`)
- **Commits**: Usa mensajes descriptivos en inglés
- **Pull Requests**: Siempre haz PR para revisar código
- **Comunicación**: Avisa si encuentras problemas o necesitas ayuda

### 📞 Contacto

Si tienes problemas o preguntas, contacta al equipo:
- Miguel Villegas (Líder del proyecto)
- [Agrega otros contactos del equipo]

---

¡Listo para programar! 🚀 ¡Bienvenido al equipo EcoTrack! 🌱
