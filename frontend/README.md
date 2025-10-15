# EcoTrack

## Estrategia de Pruebas Automáticas

La estrategia completa está en `docs/testing-strategy.md`.

Comandos rápidos:

```bash
# Instalar dependencias
flutter pub get

# Pruebas unitarias y de widgets
flutter test

# Cobertura
flutter test --coverage
# (Opcional) generar reporte HTML con genhtml si lo tienes instalado
# genhtml coverage/lcov.info -o coverage/html

# Prueba de integración (smoke)
flutter test integration_test
```

CI: Hemos añadido `.github/workflows/flutter-ci.yml` para correr analyze + test + coverage en cada push/PR.
# Proyecto2 / eco_track

Contiene el proyecto realizado por Juan Esteban Zuluaga, Juan Ignacio Lotero y Miguel Villegas para la materia de Proyecto 2.

## eco_track (Flutter)

Este repositorio también contiene el esqueleto de la aplicación Flutter `eco_track`.

### Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
