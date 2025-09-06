import 'package:flutter/material.dart';

/// EcoTrack Color Palette
/// Inspirada en tonos naturales que evocan la conexión con la tierra y el cielo
class EcoColors {
  // Colores principales de la paleta - versión natural para app ecológica
  static const Color wool = Color(0xFFF5F5DC); // Beige claro - fondos sutiles
  static const Color caramel = Color(
    0xFFD2B48C,
  ); // Caramelo natural - elementos secundarios
  static const Color cookies = Color(
    0xFFCD853F,
  ); // Marrón dorado - acentos y botones
  static const Color coldSky = Color(
    0xFF708090,
  ); // Gris azulado - navegación y headers
  static const Color frost = Color(
    0xFF2F4F4F,
  ); // Gris pizarra - elementos principales

  // Colores de apoyo basados en la paleta
  static const Color background = wool; // Fondo principal
  static const Color surface = Color(0xFFFFFBF5); // Superficies y tarjetas
  static const Color primary = coldSky; // Color primario de la app
  static const Color secondary = cookies; // Color secundario
  static const Color accent = frost; // Color de acento

  // Variaciones para diferentes estados
  static const Color primaryLight = caramel;
  static const Color primaryDark = frost;
  static const Color onPrimary = Colors.white;
  static const Color onSurface = Color(0xFF2D2D2D);
  static const Color onBackground = Color(0xFF2D2D2D);

  // Colores semánticos
  static const Color success = Color(0xFF7CB342); // Verde natural para éxito
  static const Color warning = Color(0xFFFF9800); // Naranja para advertencias
  static const Color error = Color(0xFFE57373); // Rojo suave para errores
  static const Color info = coldSky; // Usando coldSky para información

  // Grises neutros derivados de la paleta
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey900 = Color(0xFF212121);
}

/// Extensión para crear un ColorScheme personalizado con nuestra paleta
extension EcoColorScheme on ColorScheme {
  static ColorScheme get ecoTheme =>
      ColorScheme.fromSeed(
        seedColor: EcoColors.coldSky,
        primary: EcoColors.primary,
        secondary: EcoColors.secondary,
        surface: EcoColors.surface,
        background: EcoColors.background,
        brightness: Brightness.light,
      ).copyWith(
        primary: EcoColors.primary,
        onPrimary: EcoColors.onPrimary,
        secondary: EcoColors.secondary,
        onSecondary: Colors.white,
        tertiary: EcoColors.accent,
        onTertiary: Colors.white,
        surface: EcoColors.surface,
        onSurface: EcoColors.onSurface,
        error: EcoColors.error,
        onError: Colors.white,
      );
}
