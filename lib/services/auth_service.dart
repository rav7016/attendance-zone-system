import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  static const String _currentUserKey = 'current_user_id';
  static const String _rememberMeKey = 'remember_me';

  User? _currentUser;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  /// Initialize the auth service and check for saved login
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString(_currentUserKey);
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (savedUserId != null && rememberMe) {
      final user = DatabaseService.instance.getUser(savedUserId);
      if (user != null && user.isActive) {
        _currentUser = user;
        // Update last login time
        user.lastLoginAt = DateTime.now();
        await DatabaseService.instance.saveUser(user);
      } else {
        // Clear invalid saved login
        await _clearSavedLogin();
      }
    }

    _isInitialized = true;
  }

  /// Login with username/email and password
  Future<LoginResult> login({
    required String usernameOrEmail,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final user = DatabaseService.instance.getUserByUsernameOrEmail(
        usernameOrEmail,
      );

      if (user == null) {
        return LoginResult(success: false, message: 'User not found');
      }

      if (!user.isActive) {
        return LoginResult(success: false, message: 'Account is deactivated');
      }

      final passwordHash = _hashPassword(password);
      if (user.passwordHash != passwordHash) {
        return LoginResult(success: false, message: 'Invalid password');
      }

      // Update last login time
      user.lastLoginAt = DateTime.now();
      await DatabaseService.instance.saveUser(user);

      // Save login state
      _currentUser = user;
      await _saveLoginState(user.userId, rememberMe);

      return LoginResult(success: true, user: user);
    } catch (e) {
      return LoginResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _currentUser = null;
    await _clearSavedLogin();
  }

  /// Create a new user (admin only)
  Future<CreateUserResult> createUser({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    List<int>? assignedConstituencies,
    String? phoneNumber,
    String? department,
  }) async {
    try {
      // Check if current user is admin
      if (!isLoggedIn || !_currentUser!.isAdmin) {
        return CreateUserResult(
          success: false,
          message: 'Only administrators can create users',
        );
      }

      // Check if username already exists
      if (DatabaseService.instance.getUserByUsernameOrEmail(username) != null) {
        return CreateUserResult(
          success: false,
          message: 'Username already exists',
        );
      }

      // Check if email already exists
      if (DatabaseService.instance.getUserByUsernameOrEmail(email) != null) {
        return CreateUserResult(
          success: false,
          message: 'Email already exists',
        );
      }

      final userId = _generateUserId();
      final passwordHash = _hashPassword(password);

      final user = User(
        userId: userId,
        username: username,
        email: email,
        passwordHash: passwordHash,
        fullName: fullName,
        role: role,
        assignedConstituencies: assignedConstituencies ?? [],
        phoneNumber: phoneNumber,
        department: department,
      );

      await DatabaseService.instance.saveUser(user);

      return CreateUserResult(success: true, user: user);
    } catch (e) {
      return CreateUserResult(
        success: false,
        message: 'Failed to create user: ${e.toString()}',
      );
    }
  }

  /// Update user constituency assignments
  Future<bool> updateUserConstituencies(
    String userId,
    List<int> constituencies,
  ) async {
    try {
      if (!isLoggedIn || !_currentUser!.isAdmin) {
        return false;
      }

      final user = DatabaseService.instance.getUser(userId);
      if (user == null) return false;

      user.assignedConstituencies = constituencies;
      await DatabaseService.instance.saveUser(user);

      // Update current user if it's the same user
      if (_currentUser?.userId == userId) {
        _currentUser = user;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (!isLoggedIn) return false;

      final currentPasswordHash = _hashPassword(currentPassword);
      if (_currentUser!.passwordHash != currentPasswordHash) {
        return false;
      }

      _currentUser!.passwordHash = _hashPassword(newPassword);
      await DatabaseService.instance.saveUser(_currentUser!);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Initialize default admin user if no users exist
  Future<void> initializeDefaultAdmin() async {
    try {
      final users = DatabaseService.instance.getAllUsers();

      if (users.isNotEmpty) {
        return;
      }

      // Create default admin user
      final adminUser = User(
        userId: 'admin-001',
        username: 'admin',
        email: 'admin@system.local',
        passwordHash: _hashPassword('admin123'), // Default password
        fullName: 'System Administrator',
        role: UserRole.admin,
        assignedConstituencies: List.generate(
          21,
          (index) => index + 1,
        ), // All constituencies
      );

      await DatabaseService.instance.saveUser(adminUser);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate unique user ID
  String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'user-$timestamp';
  }

  /// Save login state to SharedPreferences
  Future<void> _saveLoginState(String userId, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, userId);
    await prefs.setBool(_rememberMeKey, rememberMe);
  }

  /// Clear saved login state
  Future<void> _clearSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove(_rememberMeKey);
  }
}

class LoginResult {
  final bool success;
  final String? message;
  final User? user;

  LoginResult({required this.success, this.message, this.user});
}

class CreateUserResult {
  final bool success;
  final String? message;
  final User? user;

  CreateUserResult({required this.success, this.message, this.user});
}
