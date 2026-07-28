import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/globals.dart';
import '../../models/pengajuan_model.dart';
import '../info_profile.dart';
import '../notifikasi.dart';

class SekdesHomeScreen extends StatefulWidget {
  const SekdesHomeScreen({super.key});

  @override
  State<SekdesHomeScreen> createState() => _SekdesHomeScreenState();
}

class _SekdesHomeScreenState extends State<SekdesHomeScreen> {
  String _namaUser = 'Sekretaris Desa';
  String _fotoProfil = '';
  int _menungguPersetujuan = 0;
  int _diproses = 0;
  int _selesai = 0;
  int _ditolak = 0;
  bool _isLoading = true;

  List<PengajuanModel> _suratTerbaru = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchDashboardData();
    _fetchSuratTerbaru();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final nama = prefs.getString('nama_lengkap') ?? prefs.getString('nama') ?? 'Sekretaris Desa';
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
      final response = await http.get(
        Uri.parse('$baseURL/sekdes/dashboard'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == 'success') {
          final data = body['data'];
          if (mounted) {
            setState(() {
              _menungguPersetujuan = (data['menunggu_persetujuan'] as num?)?.toInt() ?? 0;
              _diproses = (data['diproses'] as num?)?.toInt() ?? 0;
              _selesai = (data['selesai'] as num?)?.toInt() ?? 0;
              _ditolak = (data['ditolak'] as num?)?.toInt() ?? 0;
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

  Future<void> _fetchSuratTerbaru() async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/sekdes/suratmasuk'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'] ?? [];
        final list = data.map((item) => PengajuanModel.fromJson(item)).toList();
        if (mounted) {
          setState(() {
            _suratTerbaru = list.take(5).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetch surat terbaru: $e');
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

  void _showDetailModal(PengajuanModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Detail Pengajuan Terbaru',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 16),
              _detailRow('Jenis Surat', item.namaSurat),
              _detailRow('Nama Pemohon', item.namaPemohon),
              _detailRow('NIK', item.nik),
              _detailRow('Tanggal Pengajuan', item.tanggalDiajukan),
              _detailRow('Status', item.status),
              _detailRow('Keperluan', item.keperluan),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF263238),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF16A34A);
    const bgGrey = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgGrey,
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: () async {
          await _fetchDashboardData();
          await _fetchSuratTerbaru();
        },
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
                      'Sekretaris Desa',
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
                      'Statistik Verifikasi Sekdes',
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
                                      title: 'Menunggu Persetujuan',
                                      count: '$_menungguPersetujuan',
                                      subtitle: 'Status = Disetujui Admin',
                                      icon: Icons.hourglass_top_rounded,
                                      color: const Color(0xFFE65100),
                                      bgColor: const Color(0xFFFFF3E0),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Surat Diproses',
                                      count: '$_diproses',
                                      subtitle: 'Disetujui Sekdes',
                                      icon: Icons.assignment_turned_in_rounded,
                                      color: primaryGreen,
                                      bgColor: const Color(0xFFE8F5E9),
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
                                      subtitle: 'TTE Kades Selesai',
                                      icon: Icons.check_circle_rounded,
                                      color: const Color(0xFF1565C0),
                                      bgColor: const Color(0xFFE3F2FD),
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

                    // C. SECTION "SURAT TERBARU" (5 SURAT TERBARU)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Surat Terbaru',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF263238),
                          ),
                        ),
                        Text(
                          '5 Pengajuan Terakhir',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _suratTerbaru.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFECEFF1)),
                            ),
                            child: Center(
                              child: Text(
                                'Belum ada pengajuan surat terbaru',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                              ),
                            ),
                          )
                        : Column(
                            children: _suratTerbaru.map((item) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(color: const Color(0xFFECEFF1)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  onTap: () => _showDetailModal(item),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.description_rounded, color: primaryGreen, size: 22),
                                  ),
                                  title: Text(
                                    item.namaPemohon,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF263238),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.namaSurat,
                                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF546E7A)),
                                      ),
                                      Text(
                                        item.tanggalDiajukan,
                                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.status.isEmpty ? 'Baru' : item.status,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: primaryGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
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
              fontSize: 12,
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
}
