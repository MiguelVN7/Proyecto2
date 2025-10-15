# EcoTrack Authentication Implementation

Implementación completa del sistema de autenticación para la aplicación EcoTrack usando Firebase Authentication y Cloud Firestore.

## Resumen de Funcionalidades Implementadas

### ✅ Funcionalidades Completadas

1. **Registro de Usuario**
   - ✅ Formulario de registro con validación completa
   - ✅ Validación de email único
   - ✅ Validación de contraseña (8+ caracteres, mayúscula, minúscula, número)
   - ✅ Confirmación de contraseña
   - ✅ Términos y condiciones
   - ✅ Envío automático de email de verificación

2. **Inicio de Sesión**
   - ✅ Formulario de login con validación
   - ✅ Recuperación de contraseña por email
   - ✅ Manejo de errores de autenticación
   - ✅ Estado "Recordarme" (UI)

3. **Verificación de Email**
   - ✅ Pantalla de verificación dedicada
   - ✅ Reenvío de email con cooldown
   - ✅ Verificación automática en tiempo real
   - ✅ Bloqueo de acceso hasta verificación

4. **Gestión de Estado**
   - ✅ Implementación con BLoC pattern
   - ✅ Estados: unauthenticated, loading, authenticated, awaitingVerification, error
   - ✅ Manejo de errores en español
   - ✅ Persistencia de sesión

5. **Navegación y Rutas**
   - ✅ Router con guards de autenticación
   - ✅ Redirección automática según estado
   - ✅ Pantalla splash durante inicialización
   - ✅ Página 404 personalizada

6. **Perfil de Usuario en Firestore**
   - ✅ Creación automática al registrarse
   - ✅ Modelo de usuario completo
   - ✅ Estados: pending_verification, active, suspended, banned
   - ✅ Roles: citizen, moderator, admin
   - ✅ Sincronización con Firebase Auth

7. **Seguridad**
   - ✅ Reglas de Firestore restrictivas
   - ✅ Validación por UID del usuario
   - ✅ Protección de datos sensibles
   - ✅ Verificación de email obligatoria

8. **Testing**
   - ✅ Tests unitarios para validadores
   - ✅ Tests de widgets para formularios
   - ✅ Cobertura de casos de uso principales

## Arquitectura del Sistema

### Estructura de Carpetas

```
lib/
├── core/
│   ├── validators/
│   │   └── password_validator.dart     # Validación de contraseñas
│   └── routing/
│       └── app_router.dart             # Enrutamiento con guards
├── features/auth/
│   ├── data/
│   │   ├── auth_repository.dart        # Operaciones Firebase Auth
│   │   └── user_repository.dart        # Operaciones Firestore
│   ├── domain/
│   │   └── user_model.dart             # Modelo de usuario
│   ├── presentation/pages/
│   │   ├── login_page.dart             # Pantalla de login
│   │   ├── register_page.dart          # Pantalla de registro
│   │   └── verify_email_page.dart      # Pantalla de verificación
│   └── state/
│       ├── auth_bloc.dart              # Lógica de estado principal
│       ├── auth_event.dart             # Eventos de autenticación
│       └── auth_state.dart             # Estados de autenticación
└── main.dart                           # Punto de entrada con BLoC provider
```

### Dependencias Agregadas

```yaml
dependencies:
  # Authentication y validación
  email_validator: ^3.0.0
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

dev_dependencies:
  # Testing
  mocktail: ^1.0.4
  bloc_test: ^9.1.7
```

## Criterios de Aceptación Cumplidos

### 1. ✅ Email Único en el Sistema
- Firebase Auth garantiza la unicidad automáticamente
- Manejo del error `email-already-in-use` con mensaje en español

### 2. ✅ Validación de Contraseña
Implementado en `password_validator.dart`:
- Mínimo 8 caracteres
- Al menos una mayúscula [A-Z]
- Al menos una minúscula [a-z]
- Al menos un número [0-9]
- Mensajes de error detallados en español
- Validación en tiempo real con feedback visual

### 3. ✅ Verificación por Email
- Envío automático tras registro
- Pantalla dedicada de verificación
- Reenvío con cooldown de 60 segundos
- Verificación automática cada 3 segundos
- Bloqueo total de la app hasta verificación

## Flujos de Usuario Implementados

### Flujo de Registro
1. Usuario completa formulario de registro
2. Validación de todos los campos
3. Aceptación de términos y condiciones
4. Creación de cuenta en Firebase Auth
5. Creación de perfil en Firestore
6. Envío automático de email de verificación
7. Redirección a pantalla de verificación

### Flujo de Login
1. Usuario ingresa email y contraseña
2. Validación de campos
3. Autenticación con Firebase Auth
4. Verificación del estado de email
5. Redirección según estado:
   - Email verificado → Home
   - Email no verificado → Pantalla de verificación

### Flujo de Verificación
1. Pantalla muestra email del usuario
2. Verificación automática cada 3 segundos
3. Opción de reenvío con cooldown
4. Botón de verificación manual
5. Redirección automática al verificar

### Flujo de Recuperación
1. Usuario hace clic en "¿Olvidaste tu contraseña?"
2. Ingresa email en el campo de login
3. Sistema envía email de recuperación
4. Confirmación visual del envío

## Manejo de Errores

### Errores de Firebase Auth Traducidos

```dart
// Ejemplos de mensajes en español
'weak-password' → 'La contraseña es muy débil. Debe tener al menos 6 caracteres.'
'email-already-in-use' → 'Este email ya está registrado. Intenta iniciar sesión.'
'user-not-found' → 'No existe una cuenta con este email.'
'wrong-password' → 'Contraseña incorrecta.'
'network-request-failed' → 'Error de conexión. Verifica tu internet.'
```

### Estados de Error Manejados
- Errores de red
- Credenciales inválidas
- Email ya registrado
- Contraseñas débiles
- Límites de velocidad
- Errores de Firestore

## Reglas de Seguridad Firestore

### Colección `users`
```javascript
match /users/{uid} {
  // Solo el propietario puede leer/escribir su perfil
  allow read, update: if isOwner(uid);

  // Creación solo durante registro con validaciones
  allow create: if isSignedIn() &&
                  request.auth.uid == uid &&
                  validateUserCreation();
}
```

### Funciones de Seguridad
- `isSignedIn()`: Verifica autenticación
- `isOwner(uid)`: Verifica propiedad
- `isEmailVerified()`: Verifica email verificado
- `isValidUser()`: Usuario activo y verificado

## Testing Implementado

### Tests Unitarios (`test/core/validators/password_validator_test.dart`)
- ✅ Validación de contraseñas válidas e inválidas
- ✅ Casos edge (null, vacío, muy corto)
- ✅ Validación de caracteres requeridos
- ✅ Confirmación de contraseña
- ✅ Fortaleza de contraseña
- ✅ Mensajes de validación

### Tests de Widget (`test/features/auth/presentation/pages/register_page_test.dart`)
- ✅ Renderizado de formulario completo
- ✅ Validación de campos requeridos
- ✅ Validación de email inválido
- ✅ Validación de contraseña débil
- ✅ Confirmación de contraseña no coincidente
- ✅ Toggle de visibilidad de contraseña
- ✅ Validación de términos y condiciones

### Ejecutar Tests
```bash
# Tests unitarios
flutter test test/core/validators/password_validator_test.dart

# Tests de widgets
flutter test test/features/auth/presentation/pages/register_page_test.dart

# Todos los tests
flutter test

# Tests con cobertura
flutter test --coverage
```

## Configuración de Firebase

### 1. Instalación y Configuración
```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar proyecto
flutterfire configure

# Obtener dependencias
flutter pub get
```

### 2. Reglas de Firestore
```bash
# Aplicar reglas de seguridad
firebase deploy --only firestore:rules
```

## Estructura del Modelo de Usuario

```dart
class UserModel {
  final String uid;           // ID único de Firebase Auth
  final String email;         // Email del usuario
  final UserRole role;        // citizen, moderator, admin
  final UserStatus status;    // pending_verification, active, suspended, banned
  final DateTime createdAt;   // Fecha de creación
  final DateTime? updatedAt;  // Fecha de última actualización
  final String? displayName;  // Nombre de usuario (opcional)
  final String? photoUrl;     // URL de foto de perfil (opcional)
  final String? phoneNumber;  // Número de teléfono (opcional)
  final bool emailVerified;   // Estado de verificación de email
}
```

## Estados de Autenticación

### Estados del AuthBloc
1. **AuthUnauthenticated**: Usuario no autenticado
2. **AuthLoading**: Operación en progreso
3. **AuthEmailVerificationSent**: Email de verificación enviado
4. **AuthAwaitingVerification**: Esperando verificación de email
5. **AuthAuthenticated**: Usuario autenticado y verificado
6. **AuthError**: Error en operación
7. **AuthPasswordResetSent**: Email de recuperación enviado

### Transiciones de Estado
```
Registro → Loading → EmailVerificationSent → AwaitingVerification → Authenticated
Login → Loading → AwaitingVerification/Authenticated (según verificación)
Logout → Loading → Unauthenticated
Error → (cualquier estado con mensaje)
```

## Configuración de Pantallas

### RegisterPage
- Campos: Nombre (opcional), Email, Contraseña, Confirmar Contraseña
- Validación en tiempo real
- Indicador de fortaleza de contraseña
- Checkbox de términos y condiciones
- Navegación a LoginPage

### LoginPage
- Campos: Email, Contraseña
- Checkbox "Recordarme"
- Link "¿Olvidaste tu contraseña?"
- Navegación a RegisterPage

### VerifyEmailPage
- Muestra email del usuario
- Verificación automática cada 3 segundos
- Botón de reenvío con cooldown
- Botón "Verificar ahora"
- Consejos útiles
- Opción de cerrar sesión

## Próximos Pasos Opcionales

### Funcionalidades Adicionales (No Implementadas)
- [ ] Autenticación con redes sociales (Google, Facebook)
- [ ] Autenticación biométrica
- [ ] Two-Factor Authentication (2FA)
- [ ] Change password en la app
- [ ] Perfil de usuario editable
- [ ] Eliminación de cuenta
- [ ] Cloud Functions para limpieza de cuentas no verificadas

### Mejoras de UX (Consideraciones)
- [ ] Animaciones entre pantallas
- [ ] Feedback haptic
- [ ] Dark mode support
- [ ] Internacionalización (i18n)
- [ ] Accessibility improvements

## Comandos de Desarrollo

```bash
# Desarrollo
flutter run

# Tests
flutter test

# Análisis de código
flutter analyze

# Formatear código
dart format .

# Limpiar build
flutter clean

# Actualizar dependencias
flutter pub upgrade

# Aplicar reglas Firestore
firebase deploy --only firestore:rules
```

## Solución de Problemas

### Error de inicialización Firebase
```dart
// Verificar en main.dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Error de permisos Firestore
- Verificar que las reglas están aplicadas
- Verificar que el usuario está autenticado
- Verificar estructura de documentos

### Email de verificación no llega
- Verificar carpeta de spam
- Verificar configuración de dominio en Firebase Console
- Verificar plantillas de email

---

## ✅ Criterio de "Done"

- [x] No permite registro con email duplicado (manejando email-already-in-use)
- [x] Rechaza contraseñas que no cumplan el patrón
- [x] Envía correo de verificación y bloquea el uso hasta verificar
- [x] Persiste el perfil en Firestore vinculado al uid
- [x] Reglas de seguridad protegen los perfiles por uid
- [x] Tests incluidos y ejecutables

**El sistema de autenticación está completamente implementado y listo para uso en producción.**