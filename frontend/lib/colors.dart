// Flutter imports:
import 'package:flutter/material.dart';

/// EcoTrack Color Palette.
///
/// Inspired by natural tones that evoke connection with earth and sky.
/// This class defines the complete color system for the EcoTrack application,
/// following Material Design principles and accessibility guidelines.
class EcoColors {
  /// Private constructor to prevent instantiation.
  ///
  /// This class is designed to be used as a static utility class.
  const EcoColors._();

  // Main palette colors - natural version for ecological app

  /// Light beige color for subtle backgrounds.
  ///
  /// Used for main background areas and subtle surface elements.
  static const Color wool = Color(0xFFF5F5DC);

  /// Natural caramel color for secondary elements.
  ///
  /// Applied to secondary surfaces and complementary UI components.
  static const Color caramel = Color(0xFFD2B48C);

  /// Golden brown color for accents and buttons.
  ///
  /// Primary color for interactive elements and call-to-action buttons.
  static const Color cookies = Color(0xFFCD853F);

  /// Bluish gray color for navigation and headers.
  ///
  /// Used for primary navigation elements and header components.
  static const Color coldSky = Color(0xFF708090);

  /// Slate gray color for main elements.
  ///
  /// Applied to primary text and important UI elements requiring emphasis.
  static const Color frost = Color(0xFF2F4F4F);

  // Support colors based on the palette

  /// Main background color.
  static const Color background = wool;

  /// Surface color for cards and elevated components.
  static const Color surface = Color(0xFFFFFBF5);

  /// Primary brand color.
  static const Color primary = coldSky;

  /// Secondary brand color.
  static const Color secondary = cookies;

  /// Accent color for highlights.
  static const Color accent = frost;

  // Color variations for different states

  /// Light variation of the primary color.
  static const Color primaryLight = caramel;

  /// Dark variation of the primary color.
  static const Color primaryDark = frost;

  /// Color for content displayed on primary color backgrounds.
  static const Color onPrimary = Colors.white;

  /// Color for content displayed on surface backgrounds.
  static const Color onSurface = Color(0xFF2D2D2D);

  /// Color for content displayed on background color.
  static const Color onBackground = Color(0xFF2D2D2D);

  // Semantic colors for different states and feedback

  /// Natural green color for success states.
  ///
  /// Used for confirmation messages and successful operations.
  static const Color success = Color(0xFF7CB342);

  /// Orange color for warning states.
  ///
  /// Applied to cautionary messages and warning indicators.
  static const Color warning = Color(0xFFFF9800);

  /// Soft red color for error states.
  ///
  /// Used for error messages and failed operations.
  static const Color error = Color(0xFFE57373);

  /// Information color using coldSky tone.
  ///
  /// Applied to informational messages and neutral feedback.
  static const Color info = coldSky;

  // Text colors

  /// Primary text color.
  static const Color textPrimary = grey900;

  /// Secondary text color.
  static const Color textSecondary = grey700;

  // Neutral grays derived from the palette

  /// Very light gray for subtle backgrounds.
  static const Color grey100 = Color(0xFFF5F5F5);

  /// Light gray for borders and dividers.
  static const Color grey300 = Color(0xFFE0E0E0);

  /// Medium gray for disabled states.
  static const Color grey500 = Color(0xFF9E9E9E);

  /// Dark gray for secondary text.
  static const Color grey700 = Color(0xFF616161);

  /// Very dark gray for primary text.
  static const Color grey900 = Color(0xFF212121);
}

/// Extension for creating a custom ColorScheme with our palette.
///
/// This extension provides a convenient way to generate a complete
/// Material Design ColorScheme using the EcoColors palette as the foundation.
/// The generated scheme follows accessibility guidelines and provides
/// consistent theming across the application.
extension EcoColorScheme on ColorScheme {
  /// Creates an eco-friendly ColorScheme using the EcoColors palette.
  ///
  /// This method generates a complete color scheme that can be used
  /// with Material Design components, ensuring visual consistency
  /// throughout the application.
  ///
  /// Returns a [ColorScheme] configured with EcoTrack's brand colors.
  static ColorScheme get ecoTheme =>
      ColorScheme.fromSeed(
        seedColor: EcoColors.coldSky,
        primary: EcoColors.primary,
        secondary: EcoColors.secondary,
        surface: EcoColors.surface,
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
