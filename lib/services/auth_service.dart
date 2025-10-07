// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/errors/app_exceptions.dart';
import 'hive_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  final _secureStorage = FlutterSecureStorage();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      Logger.debug('AuthService already initialized');
      return;
    }

    // Don't call HiveService().init() here - it's already initialized in main
    _currentUser = await _loadCurrentUser();
    _isInitialized = true;
    Logger.info('AuthService initialized');
  }

  // Register user
  Future<User> register(
    String username,
    String password, {
    String? role = 'user',
    String? email,
    String? fullName,
    String? phone,
  }) async {
    // Validate inputs
    if (username.isEmpty || password.isEmpty) {
      throw ValidationException({
        'username': 'Username and password are required',
      });
    }

    if (username.length < 3) {
      throw ValidationException({
        'username': 'Username must be at least 3 characters long',
      });
    }

    if (password.length < 6) {
      throw ValidationException({
        'password': 'Password must be at least 6 characters long',
      });
    }

    if (await _userExists(username)) {
      throw DuplicateEntryException(
        'User with username $username already exists',
      );
    }

    final hashedPassword = _hashPassword(password);
    final user = User(
      id: _generateUserId(),
      username: username.trim(),
      hashedPassword: hashedPassword,
      role: role ?? 'user',
      email: email?.trim(),
      fullName: fullName?.trim(),
      phone: phone?.trim(),
      createdAt: DateTime.now(),
      isActive: true,
    );

    await HiveService().add<User>(Constants.userBox, user, key: user.id);
    Logger.info('Registered new user: $username with role: $role');
    return user;
  }

  // Login
  Future<User?> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw ValidationException({
        'username': 'Username and password are required',
        'password': 'Password is required',
      });
    }

    try {
      final users = await HiveService().getAll<User>(Constants.userBox);
      final user = users.firstWhere(
        (u) => u.username.toLowerCase() == username.toLowerCase().trim(),
        orElse: () => User(username: ''),
      );

      if (user.username.isEmpty) {
        throw InvalidCredentialsException();
      }

      if (user.hashedPassword == null ||
          user.hashedPassword != _hashPassword(password)) {
        throw InvalidCredentialsException();
      }

      if (!user.isActive) {
        throw AuthenticationException(
          'Account is deactivated. Please contact administrator.',
        );
      }

      _currentUser = user;
      await _saveSession();

      // Update last login time
      // user.lastLoginAt = DateTime.now();
      await HiveService().update<User>(Constants.userBox, user.id!, user);

      Logger.info('User logged in: $username (Role: ${user.role})');
      return user;
    } catch (e) {
      if (e is InvalidCredentialsException || e is AuthenticationException) {
        rethrow;
      }
      Logger.error('Login failed for user: $username', error: e);
      throw DatabaseException('Login failed due to system error');
    }
  }

  // Logout
  Future<void> logout() async {
    final username = _currentUser?.username;
    final role = _currentUser?.role;

    _currentUser = null;
    await _secureStorage.delete(key: 'session_user_id');
    await _secureStorage.delete(key: 'session_token');
    await _secureStorage.delete(key: 'session_expiry');

    Logger.info('User logged out: $username (Role: $role)');
  }

  // Check if authenticated
  bool get isAuthenticated => _currentUser != null;

  // Get current user
  User? get currentUser => _currentUser;

  // 2FA (simple, for demo)
  Future<bool> verify2FA(String code) async {
    if (_currentUser == null) {
      throw AuthenticationException('Not authenticated');
    }

    // Implement 2FA logic, e.g., TOTP
    // For demo, accept any 6-digit code starting with '12'
    final isValid = code.length == 6 && code.startsWith('12');

    if (isValid) {
      Logger.info('2FA verified for user: ${_currentUser!.username}');
    } else {
      Logger.warning(
        '2FA verification failed for user: ${_currentUser!.username}',
      );
    }

    return isValid;
  }

  // Change password
  Future<void> changePassword(String oldPass, String newPass) async {
    if (_currentUser == null) {
      throw AuthenticationException('Not authenticated');
    }

    if (oldPass.isEmpty || newPass.isEmpty) {
      throw ValidationException({
        'oldPassword': 'Old password is required',
        'newPassword': 'New password is required',
      });
    }

    if (_currentUser!.hashedPassword != _hashPassword(oldPass)) {
      throw InvalidCredentialsException();
    }

    if (newPass.length < 6) {
      throw ValidationException({
        'newPassword': 'Password must be at least 6 characters long',
      });
    }

    if (oldPass == newPass) {
      throw ValidationException({
        'newPassword': 'New password must be different from old password',
      });
    }

    _currentUser!.hashedPassword = _hashPassword(newPass);
    _currentUser!.updatedAt = DateTime.now();
    // _currentUser!.passwordChangedAt = DateTime.now();

    await HiveService().update<User>(
      Constants.userBox,
      _currentUser!.id!,
      _currentUser!,
    );

    // Update session after password change
    await _saveSession();

    Logger.info('Password changed for ${_currentUser!.username}');
  }

  // Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? phone,
  }) async {
    if (_currentUser == null) {
      throw AuthenticationException('Not authenticated');
    }

    bool hasChanges = false;

    if (email != null && email.isNotEmpty && email != _currentUser!.email) {
      _currentUser!.email = email.trim();
      hasChanges = true;
    }
    if (fullName != null &&
        fullName.isNotEmpty &&
        fullName != _currentUser!.fullName) {
      _currentUser!.fullName = fullName.trim();
      hasChanges = true;
    }
    if (phone != null && phone.isNotEmpty && phone != _currentUser!.phone) {
      _currentUser!.phone = phone.trim();
      hasChanges = true;
    }

    if (hasChanges) {
      _currentUser!.updatedAt = DateTime.now();

      await HiveService().update<User>(
        Constants.userBox,
        _currentUser!.id!,
        _currentUser!,
      );

      Logger.info('Profile updated for ${_currentUser!.username}');
    }
  }

  // Hash password
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Generate unique user ID
  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Check user exists
  Future<bool> _userExists(String username) async {
    try {
      final users = await HiveService().getAll<User>(Constants.userBox);
      return users.any(
        (u) => u.username.toLowerCase() == username.toLowerCase().trim(),
      );
    } catch (e) {
      Logger.error('Error checking if user exists: $username', error: e);
      return false;
    }
  }

  // Load session
  Future<User?> _loadCurrentUser() async {
    try {
      final userId = await _secureStorage.read(key: 'session_user_id');
      if (userId == null) return null;

      // Check session expiry
      final expiryStr = await _secureStorage.read(key: 'session_expiry');
      if (expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && expiry.isBefore(DateTime.now())) {
          Logger.info('Session expired for user: $userId');
          await logout();
          return null;
        }
      }

      final user = await HiveService().get<User>(Constants.userBox, userId);
      if (user != null && user.isActive) {
        Logger.info('Session loaded for user: ${user.username}');
        return user;
      }

      // Clear invalid session
      await logout();
      return null;
    } catch (e) {
      Logger.error('Failed to load user session', error: e);
      await logout(); // Clear potentially corrupted session
      return null;
    }
  }

  // Save session
  Future<void> _saveSession() async {
    if (_currentUser?.id != null) {
      await _secureStorage.write(
        key: 'session_user_id',
        value: _currentUser!.id,
      );

      // Generate a simple session token
      final token = _generateSessionToken();
      await _secureStorage.write(key: 'session_token', value: token);

      // Set session expiry (24 hours)
      final expiry = DateTime.now().add(Duration(hours: 24));
      await _secureStorage.write(
        key: 'session_expiry',
        value: expiry.toIso8601String(),
      );
    }
  }

  // Generate session token
  String _generateSessionToken() {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256
        .convert(
          utf8.encode(
            '${_currentUser!.id}$time${_currentUser!.hashedPassword}',
          ),
        )
        .toString();
  }

  // Role check
  bool hasRole(String role) {
    return _currentUser?.role == role;
  }

  // Permission check
  bool hasPermission(String permission) {
    final userRole = _currentUser?.role;
    if (userRole == null) return false;

    // Define role permissions
    final rolePermissions = {
      'admin': [
        'read',
        'write',
        'delete',
        'manage_users',
        'manage_system',
        'export_data',
        'import_data',
      ],
      'manager': ['read', 'write', 'export_data', 'import_data'],
      'supervisor': ['read', 'write'],
      'user': ['read'],
      'driver': ['read', 'write_trips', 'read_own_data'],
      'mechanic': ['read', 'write_maintenance', 'read_vehicles'],
    };

    return rolePermissions[userRole]?.contains(permission) ?? false;
  }

  // Check if user has any of the given permissions
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((permission) => hasPermission(permission));
  }

  // Check if user has all of the given permissions
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((permission) => hasPermission(permission));
  }

  // Get all users (admin only)
  Future<List<User>> getAllUsers() async {
    if (!hasPermission('manage_users')) {
      throw InsufficientPermissionException();
    }

    try {
      final users = await HiveService().getAll<User>(Constants.userBox);
      return users;
    } catch (e) {
      Logger.error('Failed to get all users', error: e);
      throw DatabaseException('Failed to retrieve users');
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    if (!hasPermission('manage_users') && userId != _currentUser?.id) {
      throw InsufficientPermissionException();
    }

    try {
      return await HiveService().get<User>(Constants.userBox, userId);
    } catch (e) {
      Logger.error('Failed to get user by ID: $userId', error: e);
      return null;
    }
  }

  // Update user role (admin only)
  Future<void> updateUserRole(String userId, String newRole) async {
    if (!hasPermission('manage_users')) {
      throw InsufficientPermissionException();
    }

    final user = await HiveService().get<User>(Constants.userBox, userId);
    if (user == null) {
      throw DataNotFoundException('User');
    }

    if (user.id == _currentUser?.id) {
      throw AuthenticationException('Cannot change your own role');
    }

    user.role = newRole;
    user.updatedAt = DateTime.now();

    await HiveService().update<User>(Constants.userBox, userId, user);
    Logger.info('User role updated: ${user.username} -> $newRole');
  }

  // Deactivate user (admin only)
  Future<void> deactivateUser(String userId) async {
    if (!hasPermission('manage_users')) {
      throw InsufficientPermissionException();
    }

    final user = await HiveService().get<User>(Constants.userBox, userId);
    if (user == null) {
      throw DataNotFoundException('User');
    }

    if (user.id == _currentUser?.id) {
      throw AuthenticationException('Cannot deactivate your own account');
    }

    user.isActive = false;
    user.updatedAt = DateTime.now();
    // user.deactivatedAt = DateTime.now();

    await HiveService().update<User>(Constants.userBox, userId, user);
    Logger.info('User deactivated: ${user.username}');
  }

  // Activate user (admin only)
  Future<void> activateUser(String userId) async {
    if (!hasPermission('manage_users')) {
      throw InsufficientPermissionException();
    }

    final user = await HiveService().get<User>(Constants.userBox, userId);
    if (user == null) {
      throw DataNotFoundException('User');
    }

    user.isActive = true;
    user.updatedAt = DateTime.now();
    // user.deactivatedAt = null;

    await HiveService().update<User>(Constants.userBox, userId, user);
    Logger.info('User activated: ${user.username}');
  }

  // Reset password (admin only)
  Future<void> resetUserPassword(String userId, String newPassword) async {
    if (!hasPermission('manage_users')) {
      throw InsufficientPermissionException();
    }

    final user = await HiveService().get<User>(Constants.userBox, userId);
    if (user == null) {
      throw DataNotFoundException('User');
    }

    if (newPassword.length < 6) {
      throw ValidationException({
        'newPassword': 'Password must be at least 6 characters long',
      });
    }

    user.hashedPassword = _hashPassword(newPassword);
    user.updatedAt = DateTime.now();
    // user.passwordChangedAt = DateTime.now();
    // user.forcePasswordChange = true;

    await HiveService().update<User>(Constants.userBox, userId, user);
    Logger.info('Password reset for user: ${user.username}');
  }

  // Validate session token
  Future<bool> validateSession() async {
    try {
      final token = await _secureStorage.read(key: 'session_token');
      final userId = await _secureStorage.read(key: 'session_user_id');

      if (token == null || userId == null) {
        return false;
      }

      // Check session expiry
      final expiryStr = await _secureStorage.read(key: 'session_expiry');
      if (expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && expiry.isBefore(DateTime.now())) {
          await logout();
          return false;
        }
      }

      final user = await HiveService().get<User>(Constants.userBox, userId);
      if (user == null || !user.isActive) {
        await logout();
        return false;
      }

      _currentUser = user;
      return true;
    } catch (e) {
      Logger.error('Session validation failed', error: e);
      await logout();
      return false;
    }
  }

  // Extend session
  Future<void> extendSession() async {
    if (_currentUser != null) {
      await _saveSession();
      Logger.debug('Session extended for user: ${_currentUser!.username}');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    if (!hasPermission('manage_users')) {
      throw InsufficientPermissionException();
    }

    try {
      final users = await HiveService().getAll<User>(Constants.userBox);
      final activeUsers = users.where((u) => u.isActive).toList();
      final inactiveUsers = users.where((u) => !u.isActive).toList();

      final adminUsers = users.where((u) => u.role == 'admin').length;
      final managerUsers = users.where((u) => u.role == 'manager').length;
      final driverUsers = users.where((u) => u.role == 'driver').length;
      final mechanicUsers = users.where((u) => u.role == 'mechanic').length;
      final regularUsers = users.where((u) => u.role == 'user').length;

      return {
        'totalUsers': users.length,
        'activeUsers': activeUsers.length,
        'inactiveUsers': inactiveUsers.length,
        'adminUsers': adminUsers,
        'managerUsers': managerUsers,
        'driverUsers': driverUsers,
        'mechanicUsers': mechanicUsers,
        'regularUsers': regularUsers,
        // 'recentlyActive': users.where((u) =>
        //   // u.lastLoginAt != null &&
        //   u.lastLoginAt!.isAfter(DateTime.now().subtract(Duration(days: 7)))
        // ).length,
      };
    } catch (e) {
      Logger.error('Failed to get user statistics', error: e);
      throw DatabaseException('Failed to retrieve user statistics');
    }
  }

  // Search users
  Future<List<User>> searchUsers(String query) async {
    if (!hasPermission('manage_users')) {
      throw InsufficientPermissionException();
    }

    try {
      final users = await HiveService().getAll<User>(Constants.userBox);
      final lowerQuery = query.toLowerCase();

      return users
          .where(
            (user) =>
                user.username.toLowerCase().contains(lowerQuery) ||
                user.fullName?.toLowerCase().contains(lowerQuery) == true ||
                user.email?.toLowerCase().contains(lowerQuery) == true ||
                user.role?.toLowerCase().contains(lowerQuery) == true,
          )
          .toList();
    } catch (e) {
      Logger.error('Failed to search users: $query', error: e);
      throw DatabaseException('Failed to search users');
    }
  }

  // Create demo users for testing
  Future<void> createDemoUsers() async {
    final demoUsers = [
      {
        'username': 'admin',
        'password': 'admin123',
        'role': 'admin',
        'fullName': 'System Administrator',
        'email': 'admin@fleetmaster.com',
        'phone': '+923001234567',
      },
      {
        'username': 'manager',
        'password': 'manager123',
        'role': 'manager',
        'fullName': 'Fleet Manager',
        'email': 'manager@fleetmaster.com',
        'phone': '+923001234568',
      },
      {
        'username': 'supervisor',
        'password': 'supervisor123',
        'role': 'supervisor',
        'fullName': 'Operations Supervisor',
        'email': 'supervisor@fleetmaster.com',
        'phone': '+923001234569',
      },
      {
        'username': 'driver1',
        'password': 'driver123',
        'role': 'driver',
        'fullName': 'John Driver',
        'email': 'driver1@fleetmaster.com',
        'phone': '+923001234570',
      },
      {
        'username': 'mechanic1',
        'password': 'mechanic123',
        'role': 'mechanic',
        'fullName': 'Mike Mechanic',
        'email': 'mechanic1@fleetmaster.com',
        'phone': '+923001234571',
      },
    ];

    int createdCount = 0;
    for (final userData in demoUsers) {
      if (!await _userExists(userData['username']!)) {
        try {
          await register(
            userData['username']!,
            userData['password']!,
            role: userData['role'],
            email: userData['email'],
            fullName: userData['fullName'],
            phone: userData['phone'],
          );
          createdCount++;
        } catch (e) {
          Logger.warning(
            'Failed to create demo user ${userData['username']}: $e',
          );
        }
      }
    }

    if (createdCount > 0) {
      Logger.info('Created $createdCount demo users');
    } else {
      Logger.info('All demo users already exist');
    }
  }

  // Clean up expired sessions (could be called periodically)
  Future<void> cleanupExpiredSessions() async {
    try {
      final expiryStr = await _secureStorage.read(key: 'session_expiry');
      if (expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && expiry.isBefore(DateTime.now())) {
          await logout();
          Logger.info('Cleaned up expired session');
        }
      }
    } catch (e) {
      Logger.error('Failed to cleanup expired sessions', error: e);
    }
  }

  // Dispose service (for testing)
  Future<void> dispose() async {
    await logout();
    _isInitialized = false;
    Logger.info('AuthService disposed');
  }
}
