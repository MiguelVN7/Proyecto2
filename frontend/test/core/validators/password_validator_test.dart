// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:eco_track/core/validators/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    group('validate', () {
      test('should return null for valid password', () {
        // Arrange
        const validPasswords = [
          'Password123',
          'MyStrongPass1',
          'Abc12345',
          'TestPass9',
          'SecureP4ss',
        ];

        // Act & Assert
        for (final password in validPasswords) {
          final result = PasswordValidator.validate(password);
          expect(result, isNull, reason: 'Password "$password" should be valid');
        }
      });

      test('should return error for null password', () {
        // Act
        final result = PasswordValidator.validate(null);

        // Assert
        expect(result, equals('La contraseña es requerida'));
      });

      test('should return error for empty password', () {
        // Act
        final result = PasswordValidator.validate('');

        // Assert
        expect(result, equals('La contraseña es requerida'));
      });

      test('should return error for password too short', () {
        // Arrange
        const shortPasswords = [
          'Abc1',
          'Pass1',
          'Test12',
          'Ab3',
        ];

        // Act & Assert
        for (final password in shortPasswords) {
          final result = PasswordValidator.validate(password);
          expect(
            result,
            equals('La contraseña debe tener al menos 8 caracteres'),
            reason: 'Password "$password" should be too short',
          );
        }
      });

      test('should return error for password without uppercase letter', () {
        // Arrange
        const passwordsWithoutUppercase = [
          'password123',
          'mytest123',
          'lowercase1',
          'nouppercase9',
        ];

        // Act & Assert
        for (final password in passwordsWithoutUppercase) {
          final result = PasswordValidator.validate(password);
          expect(
            result,
            equals('La contraseña debe contener al menos una letra mayúscula'),
            reason: 'Password "$password" should require uppercase',
          );
        }
      });

      test('should return error for password without lowercase letter', () {
        // Arrange
        const passwordsWithoutLowercase = [
          'PASSWORD123',
          'MYTEST123',
          'UPPERCASE1',
          'NOLOWERCASE9',
        ];

        // Act & Assert
        for (final password in passwordsWithoutLowercase) {
          final result = PasswordValidator.validate(password);
          expect(
            result,
            equals('La contraseña debe contener al menos una letra minúscula'),
            reason: 'Password "$password" should require lowercase',
          );
        }
      });

      test('should return error for password without number', () {
        // Arrange
        const passwordsWithoutNumber = [
          'Password',
          'MyTestPass',
          'UpperAndLower',
          'NoNumberHere',
        ];

        // Act & Assert
        for (final password in passwordsWithoutNumber) {
          final result = PasswordValidator.validate(password);
          expect(
            result,
            equals('La contraseña debe contener al menos un número'),
            reason: 'Password "$password" should require number',
          );
        }
      });
    });

    group('isValid', () {
      test('should return true for valid passwords', () {
        // Arrange
        const validPasswords = [
          'Password123',
          'MyStrongPass1',
          'Abc12345',
          'TestPass9',
          'SecureP4ss',
        ];

        // Act & Assert
        for (final password in validPasswords) {
          final result = PasswordValidator.isValid(password);
          expect(result, isTrue, reason: 'Password "$password" should be valid');
        }
      });

      test('should return false for invalid passwords', () {
        // Arrange
        const invalidPasswords = [
          null,
          '',
          'short',
          'password123', // no uppercase
          'PASSWORD123', // no lowercase
          'Password', // no number
          'Pass12', // too short
        ];

        // Act & Assert
        for (final password in invalidPasswords) {
          final result = PasswordValidator.isValid(password);
          expect(result, isFalse, reason: 'Password "$password" should be invalid');
        }
      });
    });

    group('getStrength', () {
      test('should return 0 for null or empty password', () {
        expect(PasswordValidator.getStrength(null), equals(0));
        expect(PasswordValidator.getStrength(''), equals(0));
      });

      test('should return low strength for weak passwords', () {
        const weakPasswords = ['abc', 'ABC', '123', 'password'];

        for (final password in weakPasswords) {
          final strength = PasswordValidator.getStrength(password);
          expect(strength, lessThan(50), reason: 'Password "$password" should be weak');
        }
      });

      test('should return higher strength for strong passwords', () {
        const strongPasswords = [
          'Password123!',
          'MyStr0ng!Pass',
          'Secure123#Pass',
        ];

        for (final password in strongPasswords) {
          final strength = PasswordValidator.getStrength(password);
          expect(strength, greaterThan(70), reason: 'Password "$password" should be strong');
        }
      });

      test('should give points for length', () {
        final strength8 = PasswordValidator.getStrength('Abcd1234');
        final strength12 = PasswordValidator.getStrength('Abcd12345678');
        final strength16 = PasswordValidator.getStrength('Abcd123456789012');

        expect(strength12, greaterThan(strength8));
        expect(strength16, greaterThan(strength12));
      });

      test('should give points for character diversity', () {
        final strengthLower = PasswordValidator.getStrength('abcdefgh');
        final strengthLowerUpper = PasswordValidator.getStrength('Abcdefgh');
        final strengthLowerUpperNum = PasswordValidator.getStrength('Abcdefg1');
        final strengthAll = PasswordValidator.getStrength('Abcdefg1!');

        expect(strengthLowerUpper, greaterThan(strengthLower));
        expect(strengthLowerUpperNum, greaterThan(strengthLowerUpper));
        expect(strengthAll, greaterThan(strengthLowerUpperNum));
      });
    });

    group('getStrengthDescription', () {
      test('should return correct descriptions for strength levels', () {
        expect(PasswordValidator.getStrengthDescription(10), equals('Muy débil'));
        expect(PasswordValidator.getStrengthDescription(40), equals('Débil'));
        expect(PasswordValidator.getStrengthDescription(60), equals('Media'));
        expect(PasswordValidator.getStrengthDescription(80), equals('Fuerte'));
        expect(PasswordValidator.getStrengthDescription(95), equals('Muy fuerte'));
      });
    });

    group('validateConfirmation', () {
      test('should return null when passwords match', () {
        const password = 'Password123';
        const confirmation = 'Password123';

        final result = PasswordValidator.validateConfirmation(password, confirmation);

        expect(result, isNull);
      });

      test('should return error when confirmation is null', () {
        const password = 'Password123';

        final result = PasswordValidator.validateConfirmation(password, null);

        expect(result, equals('La confirmación de contraseña es requerida'));
      });

      test('should return error when confirmation is empty', () {
        const password = 'Password123';

        final result = PasswordValidator.validateConfirmation(password, '');

        expect(result, equals('La confirmación de contraseña es requerida'));
      });

      test('should return error when passwords do not match', () {
        const password = 'Password123';
        const confirmation = 'DifferentPass456';

        final result = PasswordValidator.validateConfirmation(password, confirmation);

        expect(result, equals('Las contraseñas no coinciden'));
      });
    });

    group('getValidationMessages', () {
      test('should return single message for null password', () {
        final messages = PasswordValidator.getValidationMessages(null);

        expect(messages, hasLength(1));
        expect(messages.first, equals('La contraseña es requerida'));
      });

      test('should return single message for empty password', () {
        final messages = PasswordValidator.getValidationMessages('');

        expect(messages, hasLength(1));
        expect(messages.first, equals('La contraseña es requerida'));
      });

      test('should return all validation errors for invalid password', () {
        final messages = PasswordValidator.getValidationMessages('pass');

        expect(messages, hasLength(3));
        expect(messages, contains('Debe tener al menos 8 caracteres'));
        expect(messages, contains('Debe contener al menos una letra mayúscula'));
        expect(messages, contains('Debe contener al menos un número'));
      });

      test('should return empty list for valid password', () {
        final messages = PasswordValidator.getValidationMessages('Password123');

        expect(messages, isEmpty);
      });

      test('should return specific errors for partially valid passwords', () {
        // Missing uppercase
        final messagesNoUpper = PasswordValidator.getValidationMessages('password123');
        expect(messagesNoUpper, contains('Debe contener al menos una letra mayúscula'));
        expect(messagesNoUpper, isNot(contains('Debe tener al menos 8 caracteres')));

        // Missing number
        final messagesNoNumber = PasswordValidator.getValidationMessages('Password');
        expect(messagesNoNumber, contains('Debe contener al menos un número'));
        expect(messagesNoNumber, isNot(contains('Debe tener al menos 8 caracteres')));
      });
    });

    group('constants', () {
      test('should have correct minimum length', () {
        expect(PasswordValidator.minLength, equals(8));
      });
    });
  });
}