import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  SecureStorage() : _storage = const FlutterSecureStorage();

  Future<void> saveTokens(String? access, String? refresh) async {
    await Future.wait([
      if (access != null) _storage.write(key: _accessKey, value: access),
      if (refresh != null) _storage.write(key: _refreshKey, value: refresh),
    ]);
  }

  Future<({String? access, String? refresh})> readTokens() async {
    final results = await Future.wait([
      _storage.read(key: _accessKey),
      _storage.read(key: _refreshKey),
    ]);
    return (access: results[0], refresh: results[1]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }
}
