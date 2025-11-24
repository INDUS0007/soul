import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static const String _accessTokenKey = 'access';
  static const String _refreshTokenKey = 'refresh';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    webOptions: WebOptions(),
  );
  final SharedPreferences? _prefs;

  TokenManager({SharedPreferences? prefs}) : _prefs = prefs;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String role,
    required int userId,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
    await prefs.setInt(_userIdKey, userId);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<String?> getUserRole() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<int?> getUserId() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<bool> refreshToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;

    // This will be implemented in api_client
    return false;
  }

  Future<void> clearTokens() async {
    await _secureStorage.deleteAll();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
  }
}

