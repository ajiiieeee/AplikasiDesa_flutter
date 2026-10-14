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
  static const String _keyToken    = 'token';
  static const String _keyNik      = 'nik';
  static const String _keyRoleName = 'role_name';
  static const String _keyLevel    = 'level';

  // Backup keys di SharedPreferences biasa (fallback jika SecureStorage gagal)
  // Beberapa perangkat Android menghapus EncryptedSharedPreferences
  // saat app di-swipe dari Recent Apps atau restart — backup ini mencegahnya.
  static const String _bkToken = 'bk_token';
  static const String _bkRole  = 'bk_role';
  static const String _bkLevel = 'bk_level';

  // ── Token ─────────────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    // Layer 1: SecureStorage (terenkripsi)
    try { await _storage.write(key: _keyToken, value: token); } catch (_) {}
    // Layer 2 & 3: SharedPreferences (dua key berbeda sebagai fallback)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_bkToken, token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    // Layer 1: SecureStorage
    try {
      final val = await _storage.read(key: _keyToken);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    // Layer 2: SharedPreferences key 'token'
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyToken);
      if (val != null && val.isNotEmpty) return val;
      // Layer 3: backup key
      final bk = prefs.getString(_bkToken);
      if (bk != null && bk.isNotEmpty) return bk;
    } catch (_) {}
    return null;
  }

  // ── NIK ───────────────────────────────────────────────────────────────────

  Future<void> saveNik(String nik) async {
    try { await _storage.write(key: _keyNik, value: nik); } catch (_) {}
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
    // Layer 1: SecureStorage
    try {
      await _storage.write(key: _keyRoleName, value: roleName);
      await _storage.write(key: _keyLevel, value: level.toString());
    } catch (_) {}
    // Layer 2 & 3: SharedPreferences + backup key
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', roleName);
      await prefs.setString(_keyRoleName, roleName);
      await prefs.setInt(_keyLevel, level);
      await prefs.setString(_bkRole, roleName);
      await prefs.setInt(_bkLevel, level);
    } catch (_) {}
  }

  Future<String> getRole() async {
    // Layer 1: SecureStorage
    try {
      final val = await _storage.read(key: _keyRoleName);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    // Layer 2 & 3: SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final v1 = prefs.getString('role');
      if (v1 != null && v1.isNotEmpty) return v1;
      final v2 = prefs.getString(_keyRoleName);
      if (v2 != null && v2.isNotEmpty) return v2;
      final bk = prefs.getString(_bkRole);
      if (bk != null && bk.isNotEmpty) return bk;
    } catch (_) {}
    return 'warga';
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
      final v1 = prefs.getInt(_keyLevel);
      if (v1 != null) return v1;
      final bk = prefs.getInt(_bkLevel);
      if (bk != null) return bk;
    } catch (_) {}
    return 5;
  }

  // ── Cek status login ──────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Hapus semua data sensitif (logout) ───────────────────────────────────

  Future<void> clearSession() async {
    // Hapus dari SecureStorage
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyNik);
      await _storage.delete(key: _keyRoleName);
      await _storage.delete(key: _keyLevel);
    } catch (_) {}
    // Hapus dari SharedPreferences termasuk semua backup key
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('nik');
      await prefs.remove('role');
      await prefs.remove('role_name');
      await prefs.remove('level');
      await prefs.remove('nama');
      await prefs.remove('nama_lengkap');
      await prefs.remove(_bkToken);
      await prefs.remove(_bkRole);
      await prefs.remove(_bkLevel);
    } catch (_) {}
  }
}
