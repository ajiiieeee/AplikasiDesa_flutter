import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../config/globals.dart';
import '../../models/pengajuan_model.dart';
import '../../widgets/snackbarcustom.dart';

class KadesPersetujuanScreen extends StatefulWidget {
  const KadesPersetujuanScreen({super.key});

  @override
  State<KadesPersetujuanScreen> createState() => _KadesPersetujuanScreenState();
}

class _KadesPersetujuanScreenState extends State<KadesPersetujuanScreen> {
  late Future<List<PengajuanModel>> _futurePersetujuan;

  @override
  void initState() {
    super.initState();
    _futurePersetujuan = _fetchPersetujuan();
  }

  Future<List<PengajuanModel>> _fetchPersetujuan() async {
    final response = await http.get(
      Uri.parse('$baseURL/kades/suratmasuk'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] ?? [];
      return data.map((item) => PengajuanModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat surat persetujuan Kades');
    }
  }

  Future<void> _approve(int idPengajuan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pengesahan & Tanda Tangan Digital', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin mengesahkan surat ini dengan Tanda Tangan Digital Kepala Desa?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sahkan Surat', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse('$baseURL/kades/suratmasuk/$idPengajuan/setuju'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Surat berhasil disahkan dengan TTD Digital!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
        setState(() {
          _futurePersetujuan = _fetchPersetujuan();
        });
      } else {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Gagal mengesahkan surat',
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
        title: Text('Tolak Pengajuan Surat', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masukkan alasan penolakan:', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Alasan penolakan oleh Kades...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
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
            child: Text('Tolak', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse('$baseURL/kades/suratmasuk/$idPengajuan/tolak'),
        headers: headers,
        body: json.encode({'keterangan_ditolak': reasonController.text.trim()}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Pengajuan surat telah ditolak oleh Kades',
          backgroundColor: Colors.red,
          icon: Icons.cancel,
        );
        setState(() {
          _futurePersetujuan = _fetchPersetujuan();
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'PENGESAHAN SURAT (KADES)',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0057A6),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _futurePersetujuan = _fetchPersetujuan();
          });
        },
        child: FutureBuilder<List<PengajuanModel>>(
          future: _futurePersetujuan,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Gagal memuat data: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.draw_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      "Tidak Ada Surat Menunggu Pengesahan",
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final items = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0057A6),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Text(
                          item.namaSurat.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _rowInfo('Pemohon:', item.namaPemohon),
                            _rowInfo('NIK:', item.nik),
                            _rowInfo('Keperluan:', item.keperluan),
                            _rowInfo('Tanggal:', item.tanggalDiajukan),
                            _rowInfo('Status:', 'Disetujui Sekretaris Desa'),
                            const SizedBox(height: 10),
                            if (item.fotos.isNotEmpty) ...[
                              Text('Berkas Lampiran:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 60,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: item.fotos.length,
                                  itemBuilder: (context, fIndex) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          item.fotos[fIndex],
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.broken_image, size: 20),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _reject(item.idPengajuan),
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                                  label: Text('Tolak', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: () => _approve(item.idPengajuan),
                                  icon: const Icon(Icons.draw, color: Colors.white, size: 18),
                                  label: Text('Sahkan Surat (TTD)', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF28A745),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
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
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
