import '../services/secure_storage_service.dart';

/// Route guard sederhana untuk mengecek status login warga.
/// Digunakan di splash screen dan main.dart.
class AuthService {
  AuthService._();

  static final _storage = SecureStorageService.instance;

  /// Kembalikan true jika user memiliki token tersimpan.
  static Future<bool> isLoggedIn() => _storage.isLoggedIn();

  /// Kembalikan role pengguna (default: 'warga').
  static Future<String> getRole() => _storage.getRole();

  /// Hapus semua sesi sensitif (token, nik, role, level).
  static Future<void> clearSession() => _storage.clearSession();
}
