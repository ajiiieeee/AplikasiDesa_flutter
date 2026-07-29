import 'package:digitalv/screens/info_profile.dart';
import 'package:digitalv/screens/notifikasi.dart';
import 'package:flutter/material.dart';
import 'package:digitalv/screens/pengaduan.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/globals.dart';
import '../controllers/ProfileController.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String namaUser = 'User';
  String _fotoProfil = '';
  
  int _totalPengajuan = 0;
  int _diprosesCount = 0;
  int _selesaiCount = 0;
  int _pengaduanCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
    _fetchWargaStats();
  }

  Future<void> _refreshProfile() async {
    await getProfilFromApi(context); 
    await _loadUserData(); 
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final nama = prefs.getString('nama_lengkap') ?? 'User';
    final fotoProfil = prefs.getString('foto_profil') ?? '';

    String fotoProfilUrl = '';
    if (fotoProfil.isNotEmpty) {
      if (fotoProfil.startsWith('http')) {
        fotoProfilUrl = fotoProfil.replaceFirst('/api/storage/', '/storage/');
      } else {
        final cleanPath = fotoProfil.startsWith('/') ? fotoProfil.substring(1) : fotoProfil;
        fotoProfilUrl = '$serverURL/$cleanPath';
      }
    }

    if (!mounted) return;

    setState(() {
      namaUser = nama;
      _fotoProfil = fotoProfilUrl;
    });
  }

  Future<void> _fetchWargaStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return;

    final authHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    int diajukan = 0;
    int selesai = 0;
    int ditolak = 0;
    int pengaduan = 0;

    try {
      final resDiajukan = await http.get(Uri.parse('$baseURL/statusdiajukan'), headers: authHeaders);
      if (resDiajukan.statusCode == 200) {
        final body = json.decode(resDiajukan.body);
        if (body is List) {
          diajukan = body.length;
        } else if (body is Map && body['data'] is List) {
          diajukan = (body['data'] as List).length;
        }
      }
    } catch (_) {}

    try {
      final resSelesai = await http.get(Uri.parse('$baseURL/statusselesai'), headers: authHeaders);
      if (resSelesai.statusCode == 200) {
        final body = json.decode(resSelesai.body);
        if (body is List) {
          selesai = body.length;
        } else if (body is Map && body['data'] is List) {
          selesai = (body['data'] as List).length;
        }
      }
    } catch (_) {}

    try {
      final resDitolak = await http.get(Uri.parse('$baseURL/statusditolak'), headers: authHeaders);
      if (resDitolak.statusCode == 200) {
        final body = json.decode(resDitolak.body);
        if (body is List) {
          ditolak = body.length;
        } else if (body is Map && body['data'] is List) {
          ditolak = (body['data'] as List).length;
        }
      }
    } catch (_) {}

    try {
      final resPengaduan = await http.get(Uri.parse('$baseURL/notifikasi'), headers: authHeaders);
      if (resPengaduan.statusCode == 200) {
        final body = json.decode(resPengaduan.body);
        if (body is List) {
          pengaduan = body.length;
        } else if (body is Map && body['data'] != null) {
          final data = body['data'];
          if (data is List) {
            pengaduan = data.length;
          } else if (data is Map && data['pengaduan'] is List) {
            pengaduan = (data['pengaduan'] as List).length;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _diprosesCount = diajukan;
        _selesaiCount = selesai;
        _totalPengajuan = diajukan + selesai + ditolak;
        _pengaduanCount = pengaduan;
        _isLoadingStats = false;
      });
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    String day = days[now.weekday - 1];
    String month = months[now.month - 1];
    return '$day, ${now.day} $month ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF16A34A);
    const accentGreen = Color(0xFF22C55E);
    const bgGrey = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgGrey,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. HEADER BARU DENGAN LOGO DESA RAMBIPUJI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              decoration: const BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Logo & App Name + Action Icons
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo/logo.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.account_balance,
                            size: 24,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Digital Village',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Sistem Pelayanan Digital Desa Rambipuji',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Notifikasi Icon
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Foto Profil Bulat
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InfoProfile(),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white24,
                            backgroundImage: const AssetImage('assets/images/default.jpg'),
                            foregroundImage: _image != null
                                ? FileImage(_image!)
                                : _fotoProfil.isNotEmpty
                                    ? NetworkImage(_fotoProfil)
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 14),
                  // Welcome Greeting
                  Text(
                    _getFormattedDate(),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Selamat Datang,',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$namaUser 👋',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // B. KARTU STATISTIK RINGKASAN (2 Kartu Utama)
                  Text(
                    'Status Layanan Surat',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Card 1: Surat Diproses
                      Expanded(
                        child: _buildMainStatCard(
                          title: 'Surat Diproses',
                          count: '$_diprosesCount',
                          subtitle: 'Diajukan / Verifikasi',
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFFE65100),
                          bgColor: const Color(0xFFFFF3E0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Card 2: Surat Selesai
                      Expanded(
                        child: _buildMainStatCard(
                          title: 'Surat Selesai',
                          count: '$_selesaiCount',
                          subtitle: 'Siap Diunduh',
                          icon: Icons.check_circle_rounded,
                          color: primaryGreen,
                          bgColor: const Color(0xFFE8F5E9),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // C. MENU PENGADUAN (Card Besar)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: primaryGreen,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PENGADUAN MASYARAKAT',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF263238),
                                    ),
                                  ),
                                  Text(
                                    'Layanan Pengaduan Desa',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Laporkan permasalahan desa seperti infrastruktur, pelayanan, keamanan, dan lainnya secara cepat dan transparan.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF455A64),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Pengaduan(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_comment_rounded, size: 18),
                            label: Text(
                              'Buat Pengaduan',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // D. INFORMASI SINGKAT / RINGKASAN AKTIVITAS
                  Text(
                    'Informasi Singkat Aktivitas',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSummaryCard(
                        title: 'Total Surat',
                        count: '$_totalPengajuan',
                        icon: Icons.description_outlined,
                        color: const Color(0xFF1976D2),
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        title: 'Surat Selesai',
                        count: '$_selesaiCount',
                        icon: Icons.task_alt_rounded,
                        color: accentGreen,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        title: 'Total Pengaduan',
                        count: '$_pengaduanCount',
                        icon: Icons.forum_outlined,
                        color: const Color(0xFF8E24AA),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFECEFF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Text(
                _isLoadingStats ? '...' : count,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF263238),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFCFD8DC).withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              _isLoadingStats ? '...' : count,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF263238),
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
