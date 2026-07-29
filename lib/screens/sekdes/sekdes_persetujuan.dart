import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/globals.dart';
import '../../models/pengajuan_model.dart';
import '../../widgets/snackbarcustom.dart';
import '../../widgets/timeline_widget.dart';

class SekdesPersetujuanScreen extends StatefulWidget {
  const SekdesPersetujuanScreen({super.key});

  @override
  State<SekdesPersetujuanScreen> createState() => _SekdesPersetujuanScreenState();
}

class _SekdesPersetujuanScreenState extends State<SekdesPersetujuanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<PengajuanModel>> _futureMenunggu;
  late Future<List<PengajuanModel>> _futureDiproses;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _futureMenunggu = _fetchSuratMenunggu();
      _futureDiproses = _fetchSuratDiproses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // TAB 1: Surat Menunggu Persetujuan Sekdes (Status: Disetujui Admin)
  Future<List<PengajuanModel>> _fetchSuratMenunggu() async {
    final authHeaders = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseURL/sekdes/suratmasuk'),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] ?? [];
      final list = data.map((item) => PengajuanModel.fromJson(item)).toList();
      return list.where((item) => item.status == 'Disetujui Admin' || item.status.isEmpty).toList();
    } else {
      throw Exception('Gagal memuat data surat persetujuan Sekdes');
    }
  }

  // TAB 2: Surat Diproses (Status: Disetujui Sekretaris Desa)
  Future<List<PengajuanModel>> _fetchSuratDiproses() async {
    final authHeaders = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseURL/sekdes/suratmasuk'),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] ?? [];
      final list = data.map((item) => PengajuanModel.fromJson(item)).toList();
      return list.where((item) => item.status == 'Disetujui Sekretaris Desa' || item.status == 'Selesai').toList();
    } else {
      throw Exception('Gagal memuat data surat diproses');
    }
  }

  Future<void> _approve(int idPengajuan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Persetujuan Sekdes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Apakah Anda yakin ingin menyetujui surat ini? Status akan berubah menjadi "Disetujui Sekretaris Desa" dan diteruskan ke Kepala Desa untuk TTE.', style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            child: Text('Setujui', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authHeaders = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseURL/sekdes/suratmasuk/$idPengajuan/setuju'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Surat berhasil disetujui & diteruskan ke Kepala Desa',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
        _refreshData();
      } else {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Gagal menyetujui surat',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackbar(
        context: context,
        message: 'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

  Future<void> _reject(int idPengajuan) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tolak Pengajuan Surat', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masukkan alasan penolakan (Wajib diisi):', style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Alasan penolakan oleh Sekretaris Desa...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                showCustomSnackbar(
                  context: context,
                  message: 'Alasan penolakan wajib diisi',
                  backgroundColor: Colors.orange,
                  icon: Icons.warning,
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            child: Text('Tolak', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authHeaders = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseURL/sekdes/suratmasuk/$idPengajuan/tolak'),
        headers: authHeaders,
        body: json.encode({'keterangan_ditolak': reasonController.text.trim()}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Pengajuan telah ditolak oleh Sekdes',
          backgroundColor: Colors.red,
          icon: Icons.cancel,
        );
        _refreshData();
      } else {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Gagal menolak surat',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackbar(
        context: context,
        message: 'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

  void _showDetailModal(PengajuanModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
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
                    'Detail Verifikasi Sekdes',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailRow('A. Data Pemohon', '${item.namaPemohon} (NIK: ${item.nik})'),
                  _detailRow('B. Data Surat', item.namaSurat),
                  _detailRow('Tanggal Pengajuan', item.tanggalDiajukan),
                  _detailRow('Keperluan', item.keperluan),
                  _detailRow('C. Verifikasi Admin', 'Telah disetujui & diverifikasi oleh Admin Desa'),
                  const SizedBox(height: 14),
                  Text(
                    'E. Timeline Proses Surat:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF263238)),
                  ),
                  const SizedBox(height: 8),
                  SuratTimelineWidget(status: item.status.isEmpty ? 'Disetujui Admin' : item.status),
                  const SizedBox(height: 14),
                  if (item.fotos.isNotEmpty) ...[
                    Text(
                      'D. Lampiran Persyaratan:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF263238)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.fotos.length,
                        itemBuilder: (context, fIndex) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.fotos[fIndex],
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 110,
                                  height: 110,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
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
    const bgGrey = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'PERSETUJUAN SURAT (SEKDES)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              letterSpacing: 0.5,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryGreen,
          indicatorWeight: 3,
          labelColor: primaryGreen,
          unselectedLabelColor: const Color(0xFF78909C),
          labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: "Menunggu Persetujuan"),
            Tab(text: "Surat Diproses"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Menunggu Persetujuan
          _buildSuratListTab(_futureMenunggu, isApprovalTab: true),
          // TAB 2: Surat Diproses (Read Only)
          _buildSuratListTab(_futureDiproses, isApprovalTab: false),
        ],
      ),
    );
  }

  Widget _buildSuratListTab(Future<List<PengajuanModel>> futureData, {required bool isApprovalTab}) {
    const primaryGreen = Color(0xFF16A34A);

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: () async => _refreshData(),
      child: FutureBuilder<List<PengajuanModel>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Gagal memuat data: ${snapshot.error}",
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isApprovalTab ? Icons.hourglass_empty_rounded : Icons.task_alt_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isApprovalTab ? "Tidak Ada Surat Menunggu Persetujuan Sekdes" : "Belum Ada Surat Diproses",
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: primaryGreen,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.namaSurat.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _rowInfo('Pemohon:', item.namaPemohon),
                          _rowInfo('NIK:', item.nik),
                          _rowInfo('Keperluan:', item.keperluan),
                          _rowInfo('Tanggal:', item.tanggalDiajukan),
                          _rowInfo('Status:', isApprovalTab ? 'Disetujui Admin' : 'Disetujui Sekretaris Desa (Menunggu TTE Kades)'),

                          const SizedBox(height: 10),

                          if (!isApprovalTab) ...[
                            SuratTimelineWidget(status: item.status),
                            const SizedBox(height: 10),
                          ],

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showDetailModal(item),
                                icon: const Icon(Icons.visibility_outlined, size: 16, color: primaryGreen),
                                label: Text(
                                  'Detail',
                                  style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              if (isApprovalTab) ...[
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _reject(item.idPengajuan),
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                                  label: Text('Tolak', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _approve(item.idPengajuan),
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                                  label: Text('Setujui', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF263238)),
            ),
          ),
        ],
      ),
    );
  }
}
