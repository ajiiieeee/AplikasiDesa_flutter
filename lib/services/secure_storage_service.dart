import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      final val = await _storage.read(key: _keyToken);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyToken);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    return null;
  }

  // ── NIK ───────────────────────────────────────────────────────────────────
  Future<void> saveNik(String nik) async {
    await _storage.write(key: _keyNik, value: nik);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNik, nik);
    } catch (_) {}
  }

  Future<String?> getNik() async {
    try {
      final val = await _storage.read(key: _keyNik);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyNik);
    } catch (_) {
      return null;
    }
  }

  // ── Role ──────────────────────────────────────────────────────────────────
  Future<void> saveRole(String roleName, int level) async {
    await _storage.write(key: _keyRoleName, value: roleName);
    await _storage.write(key: _keyLevel, value: level.toString());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', roleName);
      await prefs.setString(_keyRoleName, roleName);
      await prefs.setInt(_keyLevel, level);
    } catch (_) {}
  }

  Future<String> getRole() async {
    try {
      final val = await _storage.read(key: _keyRoleName);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('role') ?? prefs.getString(_keyRoleName) ?? 'warga';
    } catch (_) {
      return 'warga';
    }
  }

  Future<int> getLevel() async {
    try {
      final val = await _storage.read(key: _keyLevel);
      if (val != null && val.isNotEmpty) {
        return int.tryParse(val) ?? 5;
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyLevel) ?? 5;
    } catch (_) {
      return 5;
    }
  }

  // ── Cek status login ──────────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Hapus semua data sensitif (logout) ───────────────────────────────────
  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyNik);
      await _storage.delete(key: _keyRoleName);
      await _storage.delete(key: _keyLevel);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('nik');
      await prefs.remove('role');
      await prefs.remove('role_name');
      await prefs.remove('level');
      await prefs.remove('nama');
      await prefs.remove('nama_lengkap');
    } catch (_) {}
  }
}
