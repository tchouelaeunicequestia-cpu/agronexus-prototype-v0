import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String role,
    String? userId,
    String? name,
    String? email,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _userRoleKey, value: role);
    if (userId != null) await _storage.write(key: _userIdKey, value: userId);
    if (name != null) await _storage.write(key: _userNameKey, value: name);
    if (email != null) await _storage.write(key: _userEmailKey, value: email);
  }

  Future<String?> getAccessToken() async =>
      await _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() async =>
      await _storage.read(key: _refreshTokenKey);
  Future<String?> getUserRole() async => await _storage.read(key: _userRoleKey);
  Future<String?> getUserId() async => await _storage.read(key: _userIdKey);
  Future<String?> getUserName() async => await _storage.read(key: _userNameKey);
  Future<String?> getUserEmail() async =>
      await _storage.read(key: _userEmailKey);

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
