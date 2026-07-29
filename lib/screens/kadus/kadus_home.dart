import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/globals.dart';
import '../info_profile.dart';
import '../notifikasi.dart';

class KadusHomeScreen extends StatefulWidget {
  const KadusHomeScreen({super.key});

  @override
  State<KadusHomeScreen> createState() => _KadusHomeScreenState();
}

class _KadusHomeScreenState extends State<KadusHomeScreen> {
  String _namaUser = 'Kepala Dusun';
  String _fotoProfil = '';
  int _suratMasuk = 0;
  int _diproses = 0;
  int _selesai = 0;
  int _ditolak = 0;
  int _masukHariIni = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchDashboardData();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final nama = prefs.getString('nama_lengkap') ?? prefs.getString('nama') ?? 'Kepala Dusun';
    final foto = prefs.getString('foto_profil') ?? '';

    String fotoUrl = '';
    if (foto.isNotEmpty) {
      if (foto.startsWith('http')) {
        fotoUrl = foto.replaceFirst('/api/storage/', '/storage/');
      } else {
        final cleanPath = foto.startsWith('/') ? foto.substring(1) : foto;
        fotoUrl = '$serverURL/$cleanPath';
      }
    }

    if (mounted) {
      setState(() {
        _namaUser = nama;
        _fotoProfil = fotoUrl;
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$baseURL/kadus/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == 'success') {
          final data = body['data'];
          if (mounted) {
            setState(() {
              _suratMasuk = (data['surat_masuk'] as num?)?.toInt() ?? 0;
              _diproses = (data['diproses'] as num?)?.toInt() ?? 0;
              _selesai = (data['selesai'] as num?)?.toInt() ?? 0;
              _ditolak = (data['ditolak'] as num?)?.toInt() ?? 0;
              _masukHariIni = (data['masuk_hari_ini'] as num?)?.toInt() ?? _suratMasuk;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
    const bgGrey = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgGrey,
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                                'Desa Rambipuji',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Notification Icon
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationScreen()),
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
                              MaterialPageRoute(builder: (context) => InfoProfile()),
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
                              foregroundImage: _fotoProfil.isNotEmpty ? NetworkImage(_fotoProfil) : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),
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
                      'Kepala Dusun',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$_namaUser 👋',
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

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // B. STATISTIK UTAMA (4 KARTU)
                    Text(
                      'Statistik Pengajuan Surat',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(color: primaryGreen),
                            ),
                          )
                        : Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Surat Masuk',
                                      count: '$_suratMasuk',
                                      subtitle: 'Perlu Verifikasi',
                                      icon: Icons.inbox_rounded,
                                      color: const Color(0xFF1565C0),
                                      bgColor: const Color(0xFFE3F2FD),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Surat Diproses',
                                      count: '$_diproses',
                                      subtitle: 'Diteruskan ke Admin',
                                      icon: Icons.hourglass_top_rounded,
                                      color: const Color(0xFFE65100),
                                      bgColor: const Color(0xFFFFF3E0),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Surat Selesai',
                                      count: '$_selesai',
                                      subtitle: 'Selesai Diproses',
                                      icon: Icons.check_circle_rounded,
                                      color: primaryGreen,
                                      bgColor: const Color(0xFFE8F5E9),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Surat Ditolak',
                                      count: '$_ditolak',
                                      subtitle: 'Ditolak Verifikasi',
                                      icon: Icons.cancel_rounded,
                                      color: const Color(0xFFC62828),
                                      bgColor: const Color(0xFFFFEBEE),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                    const SizedBox(height: 24),

                    // C. RINGKASAN AKTIVITAS KADUS
                    Text(
                      'Ringkasan Aktivitas Kadus',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                        children: [
                          _buildSummaryRow(
                            label: 'Total Surat Masuk Hari Ini',
                            value: '$_masukHariIni',
                            icon: Icons.today_rounded,
                            iconColor: const Color(0xFF1976D2),
                          ),
                          const Divider(height: 20, color: Color(0xFFECEFF1)),
                          _buildSummaryRow(
                            label: 'Total Surat Disetujui Kadus',
                            value: '${_diproses + _selesai}',
                            icon: Icons.thumb_up_alt_rounded,
                            iconColor: primaryGreen,
                          ),
                          const Divider(height: 20, color: Color(0xFFECEFF1)),
                          _buildSummaryRow(
                            label: 'Total Surat Ditolak',
                            value: '$_ditolak',
                            icon: Icons.thumb_down_alt_rounded,
                            iconColor: const Color(0xFFC62828),
                          ),
                          const Divider(height: 20, color: Color(0xFFECEFF1)),
                          _buildSummaryRow(
                            label: 'Total Surat Selesai Diterbitkan',
                            value: '$_selesai',
                            icon: Icons.task_alt_rounded,
                            iconColor: const Color(0xFF2E7D32),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
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
                count,
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
              fontWeight: FontWeight.bold,
              fontSize: 13,
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

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF37474F),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF263238),
          ),
        ),
      ],
    );
  }
}
