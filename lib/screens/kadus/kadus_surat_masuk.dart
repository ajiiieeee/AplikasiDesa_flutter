import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../config/globals.dart';
import '../../models/pengajuan_model.dart';
import '../../widgets/snackbarcustom.dart';
import '../../widgets/timeline_widget.dart';

class KadusSuratMasukScreen extends StatefulWidget {
  const KadusSuratMasukScreen({super.key});

  @override
  State<KadusSuratMasukScreen> createState() => _KadusSuratMasukScreenState();
}

class _KadusSuratMasukScreenState extends State<KadusSuratMasukScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<PengajuanModel>> _futureSuratMasuk;
  late Future<List<PengajuanModel>> _futureSuratMonitoring;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _futureSuratMasuk = _fetchSuratMasuk();
      _futureSuratMonitoring = _fetchSuratMonitoring();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // TAB 1: Surat Masuk dengan status "Diajukan"
  Future<List<PengajuanModel>> _fetchSuratMasuk() async {
    final response = await http.get(
      Uri.parse('$baseURL/kadus/suratmasuk'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] ?? [];
      final list = data.map((item) => PengajuanModel.fromJson(item)).toList();
      return list.where((item) => item.status == 'Diajukan' || item.status.isEmpty).toList();
    } else {
      throw Exception('Gagal memuat data surat masuk');
    }
  }

  // TAB 2: Surat yang sudah diteruskan oleh Kadus (Disetujui Kadus, Admin, Sekdes, Selesai)
  Future<List<PengajuanModel>> _fetchSuratMonitoring() async {
    final response = await http.get(
      Uri.parse('$baseURL/kadus/suratmasuk'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] ?? [];
      final list = data.map((item) => PengajuanModel.fromJson(item)).toList();
      return list.where((item) => item.status != 'Diajukan').toList();
    } else {
      throw Exception('Gagal memuat data monitoring');
    }
  }

  Future<void> _approve(int idPengajuan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Persetujuan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Apakah Anda yakin ingin menyetujui pengajuan ini? Surat akan diteruskan ke Admin Desa.', style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: Text('Setujui', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse('$baseURL/kadus/suratmasuk/$idPengajuan/setuju'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Pengajuan berhasil disetujui dan diteruskan ke Admin Desa.',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
        _refreshData();
      } else {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Gagal menyetujui pengajuan',
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
        title: Text('Tolak Pengajuan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
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
                hintText: 'Tuliskan alasan penolakan...',
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
      final response = await http.post(
        Uri.parse('$baseURL/kadus/suratmasuk/$idPengajuan/tolak'),
        headers: headers,
        body: json.encode({'keterangan_ditolak': reasonController.text.trim()}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Pengajuan telah ditolak',
          backgroundColor: Colors.red,
          icon: Icons.cancel,
        );
        _refreshData();
      } else {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Gagal menolak pengajuan',
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
          initialChildSize: 0.75,
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
                    'Detail Pengajuan Surat',
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
                  _detailRow('Status Saat Ini', item.status),
                  _detailRow('Keperluan', item.keperluan),
                  const SizedBox(height: 16),
                  if (item.fotos.isNotEmpty) ...[
                    Text(
                      'Lampiran Berkas Persyaratan:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
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
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120,
                                  height: 120,
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
                        backgroundColor: const Color(0xFF2E7D32),
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
      padding: const EdgeInsets.only(bottom: 10),
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
    const primaryGreen = Color(0xFF2E7D32);
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
            'VERIFIKASI PENGAJUAN (KADUS)',
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
            Tab(text: "Surat Masuk"),
            Tab(text: "Pengajuan Selesai"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Surat Masuk (Perlu Verifikasi)
          _buildSuratListTab(_futureSuratMasuk, isVerifikasiTab: true),
          // TAB 2: Pengajuan Selesai Kadus (Monitoring Progress)
          _buildSuratListTab(_futureSuratMonitoring, isVerifikasiTab: false),
        ],
      ),
    );
  }

  Widget _buildSuratListTab(Future<List<PengajuanModel>> futureData, {required bool isVerifikasiTab}) {
    const primaryGreen = Color(0xFF2E7D32);

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
                    isVerifikasiTab ? Icons.inbox_rounded : Icons.task_alt_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isVerifikasiTab ? "Tidak Ada Surat Masuk Perlu Verifikasi" : "Belum Ada Pengajuan Yang Diteruskan",
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
                          const Icon(Icons.description_rounded, color: Colors.white, size: 20),
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
                          _rowInfo('Status:', item.status.isEmpty ? 'Diajukan' : item.status),

                          const SizedBox(height: 10),

                          if (!isVerifikasiTab) ...[
                            SuratTimelineWidget(status: item.status),
                            const SizedBox(height: 10),
                          ],

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Tombol Lihat Detail
                              TextButton.icon(
                                onPressed: () => _showDetailModal(item),
                                icon: const Icon(Icons.visibility_outlined, size: 16, color: primaryGreen),
                                label: Text(
                                  'Detail',
                                  style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              if (isVerifikasiTab) ...[
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
