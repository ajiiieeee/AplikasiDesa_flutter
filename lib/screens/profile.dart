import 'dart:io';
import 'package:flutter/material.dart';
import '../screens/detail_profile.dart';
import '../screens/info_profile.dart';
import '../config/globals.dart';
import '../auth/LoginRegis.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/ProfileController.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;

  String _nama = '';
  String _nik = '';
  String _noHp = '';
  String _fotoProfil = '';

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    final nik = prefs.getString('nik') ?? 'Belum diatur';
    final nama = prefs.getString('nama_lengkap') ?? 'Belum diatur';
    final noHP = prefs.getString('no_hp') ?? 'Belum diatur';
    String fotoProfil = prefs.getString('foto_profil') ?? '';

    // Jika kosong/null → pakai default
    if (fotoProfil.isEmpty || fotoProfil == 'null') {
      fotoProfil = '';
    } else {
      // Kalau masih ada /api/storage, ubah jadi /storage
      fotoProfil = fotoProfil.replaceFirst('/api/storage/', '/storage/');

      // Kalau path belum lengkap, tambahkan serverURL
      if (!fotoProfil.startsWith('http')) {
        final cleanPath =
            fotoProfil.startsWith('/') ? fotoProfil.substring(1) : fotoProfil;

        fotoProfil = '$serverURL/$cleanPath';
      }

      // Kalau ada slash dobel setelah domain, rapikan
      fotoProfil = fotoProfil.replaceFirst('$serverURL//', '$serverURL/');
    }

    print('===== Data Profil dari SharedPreferences =====');
    print('NIK: $nik');
    print('Nama: $nama');
    print('No HP: $noHP');
    print('Foto Profil: $fotoProfil');
    print('=============================================');

    if (!mounted) return;

    setState(() {
      _nik = nik;
      _nama = nama;
      _noHp = noHP;
      _fotoProfil = fotoProfil;
    });
  }
  Future<void> _refreshProfile() async {
    await getProfilFromApi(context); // ← panggil fungsi dari file lain
    await _loadProfileData();
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Konfirmasi Logout",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            content: Text(
              "Apakah Anda yakin ingin keluar dari aplikasi?",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Batal",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  "Keluar",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              
            ],
          ),
    );

    if (confirm == true) {
      await logout(context); // ← Panggil fungsi logout di sini
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'PROFILE',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0057A6),
          ),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.25),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    buildProfileCard(),
                    const SizedBox(height: 15),
                   InkWell(
                      onTap: () => _showLogoutDialog(context),
                      splashColor: Colors.white24,
                      highlightColor: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      child: Material(
                        color: const Color.fromARGB(255, 224, 13, 13),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.logout_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 15),
                              Text(
                                'Keluar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildProfileCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey.shade200,

                  // Default dari assets
                  backgroundImage: const AssetImage(
                    'assets/images/default.jpg',
                  ),

                  // Kalau ada foto baru / foto server, tampilkan di atas default
                  foregroundImage:
                      _image != null
                          ? FileImage(_image!)
                          : _fotoProfil.isNotEmpty
                          ? NetworkImage(_fotoProfil)
                          : null,

                  // Kalau network image error, default asset tetap tampil
                  onForegroundImageError:
                      _fotoProfil.isNotEmpty
                          ? (exception, stackTrace) {
                            debugPrint('Gagal load foto profil: $exception');
                          }
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _nama,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.badge, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            _nik,
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            _noHp,
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InfoProfile()),
                );
              },
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Container(
                height: 55,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.edit,
                          color: Color(0xFF0057A6),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Info Profil',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0057A6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF0057A6),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
