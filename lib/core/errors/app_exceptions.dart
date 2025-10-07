// lib/core/errors/app_exceptions.dart

// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic underlyingError;

  const AppException(this.message, {this.code, this.underlyingError});

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

// Authentication exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(String message, {String? code, dynamic error})
    : super(message, code: code, underlyingError: error);
}

class InvalidCredentialsException extends AuthenticationException {
  const InvalidCredentialsException()
    : super('Invalid username or password', code: 'INVALID_CREDENTIALS');
}

class SessionExpiredException extends AuthenticationException {
  const SessionExpiredException()
    : super('Your session has expired', code: 'SESSION_EXPIRED');
}

// Network exceptions
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic error})
    : super(message, code: code, underlyingError: error);
}

class NoInternetException extends NetworkException {
  const NoInternetException()
    : super('No internet connection', code: 'NO_INTERNET');
}

class TimeoutException extends NetworkException {
  const TimeoutException() : super('Request timed out', code: 'TIMEOUT');
}

// Database exceptions
class DatabaseException extends AppException {
  const DatabaseException(String message, {String? code, dynamic error})
    : super(message, code: code, underlyingError: error);
}

class DataNotFoundException extends DatabaseException {
  const DataNotFoundException(String entity)
    : super('$entity not found', code: 'DATA_NOT_FOUND');
}

class DuplicateEntryException extends DatabaseException {
  const DuplicateEntryException(String field)
    : super('$field already exists', code: 'DUPLICATE_ENTRY');
}

// File operations exceptions
class FileException extends AppException {
  const FileException(String message, {String? code, dynamic error})
    : super(message, code: code, underlyingError: error);
}

class FileNotFoundException extends FileException {
  const FileNotFoundException(String path)
    : super('File not found: $path', code: 'FILE_NOT_FOUND');
}

class PermissionDeniedException extends FileException {
  const PermissionDeniedException()
    : super('Storage permission denied', code: 'PERMISSION_DENIED');
}

// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String> errors;

  const ValidationException(this.errors, {String? code})
    : super('Validation failed', code: code);

  @override
  String toString() {
    return 'ValidationException: $message - ${errors.entries.map((e) => '${e.key}: ${e.value}').join(', ')}';
  }
}

// Import/Export exceptions
class ImportException extends AppException {
  const ImportException(String message, {String? code, dynamic error})
    : super(message, code: code, underlyingError: error);
}

class ExportException extends AppException {
  const ExportException(String message, {String? code, dynamic error})
    : super(message, code: code, underlyingError: error);
}

// Business logic exceptions
class BusinessLogicException extends AppException {
  const BusinessLogicException(String message, {String? code, dynamic error})
    : super(message, code: code, underlyingError: error);
}

class InsufficientPermissionException extends BusinessLogicException {
  const InsufficientPermissionException()
    : super('Insufficient permissions', code: 'INSUFFICIENT_PERMISSION');
}

// Helper methods for exception handling
class ExceptionHandler {
  static String getUserFriendlyMessage(AppException exception) {
    if (exception is InvalidCredentialsException) {
      return 'The username or password you entered is incorrect.';
    } else if (exception is NoInternetException) {
      return 'Please check your internet connection and try again.';
    } else if (exception is TimeoutException) {
      return 'The request took too long. Please try again.';
    } else if (exception is DataNotFoundException) {
      return 'The requested data was not found.';
    } else if (exception is DuplicateEntryException) {
      return 'This record already exists in the system.';
    } else if (exception is PermissionDeniedException) {
      return 'Storage permission is required to perform this action.';
    } else if (exception is SessionExpiredException) {
      return 'Your session has expired. Please log in again.';
    } else if (exception is ValidationException) {
      return 'Please check the entered information and try again.';
    } else {
      return exception.message;
    }
  }

  static bool shouldRetry(AppException exception) {
    return exception is NoInternetException || exception is TimeoutException;
  }
}
