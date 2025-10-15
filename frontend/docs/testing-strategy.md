# Estrategia de Pruebas Automáticas

La meta es que cada funcionalidad entregada tenga al menos una prueba automática. Usaremos una pirámide de pruebas: unitarias (base), widgets/escenarios, integración y algunas goldens para regresión visual.

## Tabla de cobertura

| Funcionalidad | Tipo de Prueba | Justificación |
|---|---|---|
| Autenticación (email/clave) | Unitarias (AuthRepository, manejo de errores) + Widgets (LoginPage) + Integración (happy path con emulador) | Validar reglas de negocio y UX; el happy path se asegura con emulador. |
| Recuperar contraseña (email) | Unitarias (sendPasswordResetEmail) + Widgets (diálogo “Olvidé mi contraseña”) | Verificar que se invoque correctamente y la UI informe el resultado. |
| Crear reporte | Unitarias (modelo/serialización) + Integración (crear y ver en lista) | Evitar regresiones de datos y asegurar el flujo end-to-end básico. |
| HU-21 Validación de duplicados (50 m) | Unitarias (distancia Haversine y bounding box) + Widget/Golden del diálogo | Exactitud matemática y UI consistente del aviso/decisión. |
| Ver solo mis reportes | Unitarias (consultas filtradas por userId) + Integración (usuario A vs B) | Garantizar privacidad a nivel de cliente y flujo. |
| Logros/insignias | Unitarias (premiado con contadores, idempotencia) | Evitar dobles premios y asegurar transición de pendiente → completado. |
| Subida de imágenes (thumbnail/penalización) | Unitarias (cálculo de puntaje final con penalización) | Mantener lógica estable independiente de almacenamiento. |
| Notificaciones locales/FCM (callback de navegación) | Widgets (callback/route) | Asegurar que los taps navegan a la pestaña esperada (sin depender de FCM real). |
| Regresión visual de pantallas clave | Golden tests | Prevenir cambios sutiles de UI. |
| Rendimiento básico (arranque/pantalla lista) | Integración (timeline summary opcional) | Detectar grandes regresiones de performance. |

## Herramientas
- flutter_test (unit/widget)
- fake_cloud_firestore (mocks in-memory)
- integration_test (smokes/flujo)
- GitHub Actions para CI (analyze + test + cobertura)

## Comandos
- Unit/Widget: `flutter test`
- Cobertura: `flutter test --coverage` (ver en coverage/html con genhtml)
- Integración (local con dispositivo/emulador): `flutter test integration_test`

## Emuladores Firebase (opcional)
Para pruebas de integración con Auth/Firestore/Storage, usar la Local Emulator Suite. App Check se mantiene desactivado en desarrollo para evitar fricción.
