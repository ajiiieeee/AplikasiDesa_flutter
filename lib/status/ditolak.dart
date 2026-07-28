import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/globals.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pengajuanditolak_model.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';
import 'package:digitalv/widgets/timeline_widget.dart';

class DitolakView extends StatefulWidget {
  const DitolakView({super.key});

  @override
  State<DitolakView> createState() => _DitolakStateView();
}

class _DitolakStateView extends State<DitolakView> {
  late Future<List<StatusDitolakModel>> futureDitolak;

  @override
  void initState() {
    super.initState();
    futureDitolak = fetchDitolak();
  }

  Future<List<StatusDitolakModel>> fetchDitolak() async {
    final prefs = await SharedPreferences.getInstance();
    final nik = prefs.getString('nik') ?? '';

    if (nik.isEmpty) {
      throw Exception('NIK tidak ditemukan di SharedPreferences');
    }

    final response = await http.get(
      Uri.parse('$baseURL/statusditolak?nik=$nik'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => StatusDitolakModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal mengambil data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<List<StatusDitolakModel>>(
        future: fetchDitolak(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
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
                  Icon(Icons.thumb_up_alt_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    "Tidak ada surat yang ditolak",
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

          final ditolak = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: ditolak.length,
            itemBuilder: (context, index) {
              final item = ditolak[index];
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
                    // Header Card Ditolak
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD32F2F),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
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

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tanggal Penolakan:",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                item.updatedAt,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF263238),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Box Alasan Penolakan
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Alasan Penolakan:",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.keteranganDitolak.isEmpty
                                      ? "Persyaratan pengajuan surat belum sesuai standar."
                                      : item.keteranganDitolak,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.red.shade800,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SuratTimelineWidget(
                            status: 'Ditolak',
                            alasanDitolak: item.keteranganDitolak,
                          ),
                          const SizedBox(height: 8),
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
                                      "Apakah Anda yakin ingin menghapus data pengajuan yang ditolak ini?",
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
                                      message: "Data berhasil dihapus",
                                      backgroundColor: Colors.green,
                                      icon: Icons.check_circle,
                                    );
                                    setState(() {
                                      futureDitolak = fetchDitolak();
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
                                "Hapus",
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
