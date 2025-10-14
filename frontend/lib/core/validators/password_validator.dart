/// Password validation utilities for authentication forms.
///
/// This class provides comprehensive password validation functionality
/// following security best practices for user authentication.
class PasswordValidator {
  /// Private constructor to prevent instantiation.
  const PasswordValidator._();

  /// Minimum required password length.
  static const int minLength = 8;

  /// Regular expression for password validation.
  ///
  /// Password must contain:
  /// - At least 8 characters
  /// - At least one uppercase letter [A-Z]
  /// - At least one lowercase letter [a-z]
  /// - At least one digit [0-9]
  static final RegExp _passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
  );

  /// Validates a password against security requirements.
  ///
  /// Returns null if the password is valid, otherwise returns an error message.
  ///
  /// Requirements:
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  ///
  /// Example:
  /// ```dart
  /// String? result = PasswordValidator.validate('MyPassword123');
  /// if (result == null) {
  ///   print('Password is valid');
  /// } else {
  ///   print('Error: $result');
  /// }
  /// ```
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (password.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una letra mayúscula';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'La contraseña debe contener al menos una letra minúscula';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número';
    }

    return null;
  }

  /// Validates a password using the comprehensive regular expression.
  ///
  /// This is an alternative validation method that uses a single regex
  /// instead of multiple checks. Returns true if valid, false otherwise.
  static bool isValid(String? password) {
    if (password == null || password.isEmpty) {
      return false;
    }
    return _passwordRegExp.hasMatch(password);
  }

  /// Gets the password strength as a percentage (0-100).
  ///
  /// This method evaluates password strength based on:
  /// - Length (20 points for >= 8 chars, +5 for each additional char up to 16)
  /// - Character diversity (20 points each for lowercase, uppercase, numbers, symbols)
  /// - Bonus points for length > 12
  static int getStrength(String? password) {
    if (password == null || password.isEmpty) {
      return 0;
    }

    int strength = 0;

    // Length scoring
    if (password.length >= 8) {
      strength += 20;
      if (password.length > 8) {
        strength += (password.length - 8).clamp(0, 8) * 5; // +5 per char up to 16
      }
    }

    // Character type scoring
    if (password.contains(RegExp(r'[a-z]'))) {
      strength += 20; // Lowercase
    }
    if (password.contains(RegExp(r'[A-Z]'))) {
      strength += 20; // Uppercase
    }
    if (password.contains(RegExp(r'[0-9]'))) {
      strength += 20; // Numbers
    }
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength += 20; // Special characters
    }

    return strength.clamp(0, 100);
  }

  /// Gets a human-readable strength description.
  static String getStrengthDescription(int strength) {
    if (strength < 30) return 'Muy débil';
    if (strength < 50) return 'Débil';
    if (strength < 70) return 'Media';
    if (strength < 90) return 'Fuerte';
    return 'Muy fuerte';
  }

  /// Validates password confirmation match.
  ///
  /// Returns null if passwords match, otherwise returns an error message.
  static String? validateConfirmation(String? password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'La confirmación de contraseña es requerida';
    }

    if (password != confirmation) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Gets all validation messages for a password.
  ///
  /// Returns a list of all validation errors, useful for displaying
  /// detailed feedback to users.
  static List<String> getValidationMessages(String? password) {
    final List<String> messages = [];

    if (password == null || password.isEmpty) {
      messages.add('La contraseña es requerida');
      return messages;
    }

    if (password.length < minLength) {
      messages.add('Debe tener al menos $minLength caracteres');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      messages.add('Debe contener al menos una letra mayúscula');
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      messages.add('Debe contener al menos una letra minúscula');
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      messages.add('Debe contener al menos un número');
    }

    return messages;
  }
}