import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/globals.dart';
import '../models/pengajuandiajukan_model.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';
import 'package:digitalv/widgets/timeline_widget.dart';

class PengajuanView extends StatefulWidget {
  const PengajuanView({super.key});

  @override
  State<PengajuanView> createState() => _PengajuanViewState();
}

class _PengajuanViewState extends State<PengajuanView> {
  late Future<List<StatusDiajukanModel>> futurePengajuan;

  @override
  void initState() {
    super.initState();
    futurePengajuan = fetchPengajuan();
  }

  Future<List<StatusDiajukanModel>> fetchPengajuan() async {
    final prefs = await SharedPreferences.getInstance();
    final nik = prefs.getString('nik') ?? '';

    if (nik.isEmpty) {
      throw Exception('NIK tidak ditemukan di SharedPreferences');
    }

    final response = await http.get(
      Uri.parse('$baseURL/statusdiajukan?nik=$nik'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => StatusDiajukanModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal mengambil data');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<List<StatusDiajukanModel>>(
        future: fetchPengajuan(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Terjadi kesalahan: ${snapshot.error}",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    "Tidak ada surat yang sedang diproses",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final pengajuans = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: pengajuans.length,
            itemBuilder: (context, index) {
              final item = pengajuans[index];
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
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Diajukan Pada:",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                item.tanggalDiajukan,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF263238),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFE082)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Surat Anda sedang dalam proses verifikasi pihak terkait.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF5D4037),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SuratTimelineWidget(status: item.status),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      "Konfirmasi Hapus",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    content: Text(
                                      "Apakah Anda yakin ingin batalkan / hapus pengajuan surat ini?",
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(
                                          "Batal",
                                          style: GoogleFonts.poppins(color: Colors.grey[700]),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: Text(
                                          "Hapus",
                                          style: GoogleFonts.poppins(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  final response = await http.delete(
                                    Uri.parse('$baseURL/suratdelete/${item.idPengajuan}'),
                                    headers: headers,
                                  );

                                  if (response.statusCode == 200) {
                                    showCustomSnackbar(
                                      context: context,
                                      message: "Pengajuan berhasil dihapus",
                                      backgroundColor: Colors.green,
                                      icon: Icons.check_circle,
                                    );
                                    setState(() {
                                      futurePengajuan = fetchPengajuan();
                                    });
                                  } else {
                                    showCustomSnackbar(
                                      context: context,
                                      message: "Gagal menghapus surat",
                                      backgroundColor: Colors.red,
                                      icon: Icons.error,
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              label: Text(
                                "Hapus Pengajuan",
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
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
}
