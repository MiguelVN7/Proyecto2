# Firebase Setup Guide for EcoTrack Authentication

Este documento proporciona instrucciones completas para configurar Firebase Authentication y Cloud Firestore en el proyecto EcoTrack.

## Requisitos Previos

- Flutter SDK 3.x instalado
- Dart SDK
- Cuenta de Firebase/Google Cloud
- Android Studio o Xcode (para configuración de plataformas)

## 1. Configuración del Proyecto Firebase

### 1.1 Crear Proyecto Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Agregar proyecto"
3. Nombra tu proyecto (ej: "ecotrack-app")
4. Habilita Google Analytics (opcional pero recomendado)
5. Selecciona tu cuenta de Analytics
6. Haz clic en "Crear proyecto"

### 1.2 Habilitar Authentication

1. En Firebase Console, ve a "Authentication"
2. Haz clic en "Comenzar"
3. Ve a la pestaña "Sign-in method"
4. Habilita "Correo electrónico/contraseña"
5. **IMPORTANTE**: Asegúrate de marcar "Habilitar enlace de correo electrónico (inicio de sesión sin contraseña)"

### 1.3 Configurar Cloud Firestore

1. En Firebase Console, ve a "Firestore Database"
2. Haz clic en "Crear base de datos"
3. Selecciona "Comenzar en modo de prueba" (temporalmente)
4. Elige una ubicación cercana (ej: us-central1)
5. Haz clic en "Listo"

## 2. Configuración de FlutterFire CLI

### 2.1 Instalar FlutterFire CLI

```bash
# Instalar FlutterFire CLI globalmente
dart pub global activate flutterfire_cli

# Verificar instalación
flutterfire --version
```

### 2.2 Configurar Firebase para Flutter

```bash
# Navegar al directorio del proyecto
cd frontend

# Configurar Firebase (esto creará firebase_options.dart automáticamente)
flutterfire configure

# Seguir las instrucciones:
# 1. Seleccionar tu proyecto Firebase
# 2. Seleccionar las plataformas (Android, iOS, Web, macOS, Windows)
# 3. Confirmar la configuración
```

## 3. Configuración de Plataformas

### 3.1 Android

El archivo `android/app/google-services.json` se descarga automáticamente con `flutterfire configure`.

**Verificar configuración en `android/app/build.gradle`:**

```gradle
// En la parte superior del archivo
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services" // Agregar esta línea
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    implementation 'com.google.firebase:firebase-analytics' // Opcional
}
```

**Verificar configuración en `android/build.gradle`:**

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15' // Agregar esta línea
    }
}
```

### 3.2 iOS

El archivo `ios/Runner/GoogleService-Info.plist` se descarga automáticamente con `flutterfire configure`.

**Verificaciones adicionales:**
1. Abrir `ios/Runner.xcworkspace` en Xcode
2. Verificar que `GoogleService-Info.plist` esté agregado al target Runner
3. Verificar Bundle ID coincida con el configurado en Firebase

### 3.3 Web

La configuración web se maneja automáticamente en `firebase_options.dart`.

## 4. Configuración de Dependencias

Las dependencias ya están configuradas en `pubspec.yaml`. Ejecutar:

```bash
flutter pub get
```

## 5. Configuración de Authentication Templates

### 5.1 Configurar Plantillas de Email

1. En Firebase Console, ve a "Authentication" > "Templates"
2. Personaliza las plantillas de:
   - Verificación de correo electrónico
   - Restablecimiento de contraseña
   - Cambio de dirección de correo electrónico

**Ejemplo de plantilla de verificación:**

```html
<h1>Verifica tu correo electrónico</h1>
<p>Hola,</p>
<p>Gracias por registrarte en EcoTrack. Para completar tu registro, haz clic en el siguiente enlace:</p>
<a href="%LINK%">Verificar Email</a>
<p>Si no te registraste en EcoTrack, puedes ignorar este mensaje.</p>
<p>¡Gracias!</p>
<p>El equipo de EcoTrack</p>
```

### 5.2 Configurar Dominio Autorizado

1. Ve a "Authentication" > "Settings"
2. En la pestaña "Authorized domains"
3. Agrega tus dominios (ej: localhost, tu-dominio.com)

## 6. Configurar Firestore Security Rules

### 6.1 Aplicar Reglas de Seguridad

```bash
# Instalar Firebase CLI si no lo tienes
npm install -g firebase-tools

# Iniciar sesión
firebase login

# Inicializar Firebase en el proyecto (ejecutar en la raíz del proyecto)
firebase init firestore

# Aplicar las reglas de seguridad
firebase deploy --only firestore:rules
```

Las reglas están definidas en `firestore.rules` en la raíz del proyecto.

### 6.2 Configurar Índices de Firestore

Los índices se configuran automáticamente cuando se necesitan. Firebase mostrará enlaces en la consola para crearlos según sea necesario.

## 7. Variables de Entorno y Configuración

### 7.1 Archivo firebase_options.dart

El archivo `lib/firebase_options.dart` se genera automáticamente y contiene todas las configuraciones necesarias.

**NO** commitear este archivo si contiene información sensible de producción.

### 7.2 Configuración de Desarrollo vs Producción

Para manejar múltiples entornos, puedes crear proyectos Firebase separados:

```bash
# Configurar desarrollo
flutterfire configure --project=ecotrack-dev

# Configurar producción
flutterfire configure --project=ecotrack-prod
```

## 8. Testing y Verificación

### 8.1 Verificar Conexión

Ejecutar la aplicación:

```bash
flutter run
```

Verificar en logs que Firebase se inicializa correctamente:
```
✅ Firebase initialized successfully
✅ FCM initialized successfully
```

### 8.2 Probar Authentication

1. Ejecutar la aplicación
2. Ir a la pantalla de registro
3. Crear una cuenta de prueba
4. Verificar que el email de verificación llega
5. Completar el flujo de verificación

### 8.3 Probar Firestore

1. Registrar un usuario
2. Verificar en Firebase Console que el documento del usuario se crea en la colección `users`
3. Probar crear un reporte
4. Verificar que aparece en la colección `reports`

## 9. Comandos de Desarrollo

```bash
# Obtener dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Ejecutar tests
flutter test

# Limpiar build
flutter clean

# Actualizar dependencias de Firebase
flutterfire configure

# Aplicar reglas de Firestore
firebase deploy --only firestore:rules
```

## 10. Solución de Problemas Comunes

### 10.1 Error de configuración de plataforma

**Problema**: "No Firebase App '[DEFAULT]' has been created"

**Solución**:
1. Verificar que `Firebase.initializeApp()` se llama en `main()`
2. Verificar que `firebase_options.dart` existe y es correcto
3. Re-ejecutar `flutterfire configure`

### 10.2 Error de permisos en Firestore

**Problema**: "FirebaseError: Missing or insufficient permissions"

**Solución**:
1. Verificar que las reglas de seguridad están aplicadas
2. Verificar que el usuario está autenticado y verificado
3. Verificar que los campos requeridos están presentes

### 10.3 Email de verificación no llega

**Problema**: El email de verificación no se envía

**Solución**:
1. Verificar configuración SMTP en Firebase Console
2. Verificar dominio autorizado
3. Revisar carpeta de spam
4. Verificar plantillas de email

### 10.4 Builds Android fallan

**Problema**: Error de compilación en Android

**Solución**:
1. Verificar versión de `google-services` plugin
2. Limpiar build: `flutter clean && flutter pub get`
3. Verificar que `google-services.json` está en `android/app/`

## 11. Recursos Adicionales

- [Documentación Firebase Flutter](https://firebase.flutter.dev/)
- [FlutterFire CLI](https://github.com/invertase/flutterfire_cli)
- [Firebase Console](https://console.firebase.google.com/)
- [Reglas de Seguridad Firestore](https://firebase.google.com/docs/firestore/security/get-started)

## 12. Próximos Pasos

Una vez completada la configuración:

1. ✅ Configurar email templates personalizados
2. ✅ Configurar dominios de producción
3. ✅ Implementar logging y monitoring
4. ✅ Configurar Cloud Functions (opcional)
5. ✅ Configurar push notifications (ya implementado)
6. ✅ Implementar analytics (opcional)

---

**Nota**: Esta guía asume que tienes conocimientos básicos de Flutter y Firebase. Si encuentras problemas, consulta la documentación oficial o crea un issue en el repositorio del proyecto.