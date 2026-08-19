import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/detail_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/ProfileController.dart';
import '../widgets/snackbarcustom.dart';
import '../config/globals.dart';
import 'package:image_cropper/image_cropper.dart';

class InfoProfile extends StatefulWidget {
  const InfoProfile({super.key});

  @override
  State<InfoProfile> createState() => _InfoProfileState();
}

class _InfoProfileState extends State<InfoProfile> {
  static const _primary   = Color(0xFF2E7D32);
  static const _bgGreen   = Color(0xFFE8F5E9);
  static const _bgPage    = Color(0xFFF5F7FA);

  File? _image;
  Uint8List? _imageBytes;

  String _nik       = '';
  String _noKK      = '';
  String _nama      = '';
  String _noHP      = '';
  String _email     = '';
  String _fotoProfil = '';

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    await getProfilFromApi(context);
    await _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    final nik   = prefs.getString('nik')          ?? '-';
    final noKK  = prefs.getString('no_kk')        ?? '-';
    final nama  = prefs.getString('nama_lengkap') ?? '-';
    final noHP  = prefs.getString('no_hp')        ?? '-';
    final email = prefs.getString('email')        ?? '-';

    String fotoProfil = prefs.getString('foto_profil') ?? '';
    if (fotoProfil.isEmpty || fotoProfil == 'null') {
      fotoProfil = '';
    } else {
      fotoProfil = fotoProfil.replaceFirst('/api/storage/', '/storage/');
      if (!fotoProfil.startsWith('http')) {
        final cleanPath = fotoProfil.startsWith('/') ? fotoProfil.substring(1) : fotoProfil;
        fotoProfil = '$serverURL/$cleanPath';
      }
      fotoProfil = fotoProfil.replaceFirst('$serverURL//', '$serverURL/');
      fotoProfil = fotoProfil.replaceAll('.png', '.jpg');
    }

    if (!mounted) return;
    setState(() {
      _nik       = nik;
      _noKK      = noKK;
      _nama      = nama;
      _noHP      = noHP;
      _email     = email;
      _fotoProfil = fotoProfil;
    });
  }

  Future<void> _pickImageAndUpload() async {
    final picker    = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Foto',
          toolbarColor: _primary,
          toolbarWidgetColor: Colors.white,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(title: 'Crop Foto'),
      ],
    );

    if (croppedFile == null) {
      showCustomSnackbar(
        context: context,
        message: 'Pemotongan gambar dibatalkan',
        backgroundColor: Colors.orange,
        icon: Icons.warning,
      );
      return;
    }

    final imageFile  = File(croppedFile.path);
    final imageBytes = await imageFile.readAsBytes();

    setState(() {
      _image      = imageFile;
      _imageBytes = imageBytes;
    });

    await uploadFotoProfil(context, imageFile);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Logout',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'PROFIL',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // Tombol edit profil
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF2E7D32)),
            tooltip: 'Edit Profil',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DetailProfile()),
              );
              if (result == true) await _refreshProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HEADER HIJAU ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 36),
              decoration: const BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white24,
                          backgroundImage: const AssetImage('assets/images/default.jpg'),
                          foregroundImage: _imageBytes != null
                              ? MemoryImage(_imageBytes!)
                              : _image != null && !kIsWeb
                                  ? FileImage(_image!) as ImageProvider
                                  : _fotoProfil.isNotEmpty
                                      ? NetworkImage(_fotoProfil)
                                      : null,
                          onForegroundImageError: _fotoProfil.isNotEmpty
                              ? (e, s) => debugPrint('Gagal load foto: $e')
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: _pickImageAndUpload,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _primary, width: 2),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.camera_alt,
                                color: _primary, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _nama,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIK: $_nik',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── CARD INFO ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.07),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined,
                              color: _primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Informasi Akun',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Isi card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _infoRow(Icons.badge_outlined,      'NIK',            _nik),
                          _divider(),
                          _infoRow(Icons.family_restroom,     'No. KK',         _noKK),
                          _divider(),
                          _infoRow(Icons.person_outline,      'Nama Lengkap',   _nama),
                          _divider(),
                          _infoRow(Icons.phone_outlined,      'No. Handphone',  _noHP),
                          _divider(),
                          _infoRow(Icons.email_outlined,      'E-Mail',         _email),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── TOMBOL EDIT ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DetailProfile()),
                    );
                    if (result == true) await _refreshProfile();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    'Edit Profil',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── TOMBOL LOGOUT ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _bgGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        color: Colors.grey[500], fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100);
}
