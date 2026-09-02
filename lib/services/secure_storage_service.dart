import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Singleton service untuk menyimpan data sensitif secara aman.
/// Gunakan [SecureStorageService.instance] di seluruh aplikasi.
class SecureStorageService {
  SecureStorageService._internal();
  static final SecureStorageService instance = SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const String _keyToken     = 'token';
  static const String _keyNik       = 'nik';
  static const String _keyRoleName  = 'role_name';
  static const String _keyLevel     = 'level';

  // ── Token ─────────────────────────────────────────────────────────────────
  Future<void> saveToken(String token) async =>
      _storage.write(key: _keyToken, value: token);

  Future<String?> getToken() async =>
      _storage.read(key: _keyToken);

  // ── NIK ───────────────────────────────────────────────────────────────────
  Future<void> saveNik(String nik) async =>
      _storage.write(key: _keyNik, value: nik);

  Future<String?> getNik() async =>
      _storage.read(key: _keyNik);

  // ── Role ──────────────────────────────────────────────────────────────────
  Future<void> saveRole(String roleName, int level) async {
    await _storage.write(key: _keyRoleName, value: roleName);
    await _storage.write(key: _keyLevel, value: level.toString());
  }

  Future<String> getRole() async =>
      await _storage.read(key: _keyRoleName) ?? 'warga';

  Future<int> getLevel() async {
    final val = await _storage.read(key: _keyLevel);
    return int.tryParse(val ?? '') ?? 5;
  }

  // ── Cek status login ──────────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Hapus semua data sensitif (logout) ───────────────────────────────────
  Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyNik);
    await _storage.delete(key: _keyRoleName);
    await _storage.delete(key: _keyLevel);
  }
}
