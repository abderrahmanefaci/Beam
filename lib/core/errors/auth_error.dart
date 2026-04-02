/// Authentication error types
enum AuthErrorType {
  invalidEmail,
  invalidPassword,
  invalidCredentials,
  userNotFound,
  userAlreadyExists,
  emailNotVerified,
  weakPassword,
  sessionExpired,
  networkError,
  unknown,
}

/// Authentication error class
class AuthError implements Exception {
  final AuthErrorType type;
  final String message;
  final String? originalMessage;

  const AuthError({
    required this.type,
    required this.message,
    this.originalMessage,
  });

  @override
  String toString() => 'AuthError(${type.name}): $message';

  /// Create AuthError from Supabase error message
  factory AuthError.fromMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return const AuthError(
        type: AuthErrorType.invalidCredentials,
        message: 'Invalid email or password',
      );
    } else if (message.contains('Email not confirmed')) {
      return const AuthError(
        type: AuthErrorType.emailNotVerified,
        message: 'Please verify your email address',
      );
    } else if (message.contains('User not found')) {
      return const AuthError(
        type: AuthErrorType.userNotFound,
        message: 'No account found with this email',
      );
    } else if (message.contains('User already registered')) {
      return const AuthError(
        type: AuthErrorType.userAlreadyExists,
        message: 'This email is already registered',
      );
    } else if (message.contains('Weak password')) {
      return const AuthError(
        type: AuthErrorType.weakPassword,
        message: 'Password must be at least 6 characters',
      );
    } else if (message.contains('Invalid email')) {
      return const AuthError(
        type: AuthErrorType.invalidEmail,
        message: 'Please enter a valid email address',
      );
    } else if (message.contains('Session expired') ||
        message.contains('Not logged in')) {
      return const AuthError(
        type: AuthErrorType.sessionExpired,
        message: 'Session expired. Please sign in again.',
      );
    } else if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('offline')) {
      return const AuthError(
        type: AuthErrorType.networkError,
        message: 'No connection. Check your internet and try again.',
      );
    } else {
      return AuthError(
        type: AuthErrorType.unknown,
        message: 'An unexpected error occurred',
        originalMessage: message,
      );
    }
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (type) {
      case AuthErrorType.invalidEmail:
        return 'Please enter a valid email address';
      case AuthErrorType.invalidPassword:
        return 'Password is incorrect';
      case AuthErrorType.invalidCredentials:
        return 'Invalid email or password';
      case AuthErrorType.userNotFound:
        return 'No account found with this email';
      case AuthErrorType.userAlreadyExists:
        return 'This email is already registered';
      case AuthErrorType.emailNotVerified:
        return 'Please verify your email address';
      case AuthErrorType.weakPassword:
        return 'Password must be at least 6 characters';
      case AuthErrorType.sessionExpired:
        return 'Session expired. Please sign in again.';
      case AuthErrorType.networkError:
        return 'No connection. Check your internet and try again.';
      case AuthErrorType.unknown:
        return originalMessage ?? 'An unexpected error occurred';
    }
  }

  /// Check if error is retryable
  bool get isRetryable {
    switch (type) {
      case AuthErrorType.networkError:
        return true;
      case AuthErrorType.sessionExpired:
        return true;
      default:
        return false;
    }
  }
}

/// Extension to convert Supabase AuthException to AuthError
extension AuthExceptionExtension on Object {
  AuthError toAuthError() {
    if (this is AuthError) {
      return this as AuthError;
    }
    final message = toString();
    return AuthError.fromMessage(message);
  }
}
