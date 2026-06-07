import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final DatabaseService _dbService = DatabaseService();

  String _hashPassword(String password) {
    return sha256.convert(password.codeUnits).toString();
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final db = await _dbService.database;
      final userId = const Uuid().v4();
      final hashedPassword = _hashPassword(password);

      await db.insert('users', {
        'id': userId,
        'username': username,
        'email': email,
        'password': hashedPassword,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
        'is_logged_in': 0,
      });

      return true;
    } catch (e) {
      print('Sign up error: $e');
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final db = await _dbService.database;
      final hashedPassword = _hashPassword(password);

      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, hashedPassword],
      );

      if (result.isNotEmpty) {
        final userId = result.first['id'];
        await db.update(
          'users',
          {'is_logged_in': 1},
          where: 'id = ?',
          whereArgs: [userId],
        );
        return true;
      }

      return false;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }

  Future<bool> logOut({required String userId}) async {
    try {
      final db = await _dbService.database;
      await db.update(
        'users',
        {'is_logged_in': 0},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'is_logged_in = ?',
        whereArgs: [1],
      );

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<bool> isUserLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  Future<bool> emailExists(String email) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> usernameExists(String username) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
