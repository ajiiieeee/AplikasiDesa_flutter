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
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<StatusDiajukanModel>>(
        future: fetchPengajuan(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Tidak ada data",
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
              ),
            );
          }

          final pengajuans = snapshot.data!;
          return ListView.builder(
            itemCount: pengajuans.length,
            itemBuilder: (context, index) {
              final item = pengajuans[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.all(11),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 50,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0057A6),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        item.namaSurat.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Diajukan Pada: ${item.tanggalDiajukan}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 128, 128, 128),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Surat Anda Sedang Ditinjau. \nMohon Tunggu Keputusan Dari Pihak Terkait.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Status : ${item.status}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 128, 128, 128),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SuratTimelineWidget(status: item.status),
                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text(
                                        "Konfirmasi",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      content: Text(
                                        "Apakah Anda yakin ingin menghapus surat ini?",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
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
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: Text(
                                            "Hapus",
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
                                final response = await http.delete(
                                  Uri.parse(
                                    '$baseURL/suratdelete/${item.idPengajuan}',
                                  ),
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
                                    futurePengajuan =
                                        fetchPengajuan(); // reload setelah hapus
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFF91717),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Hapus",
                                    style: GoogleFonts.poppins(
                                      color: Color(0xFFF91717),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              const SizedBox(height: 8);
            },
          );
        },
      ),
    );
  }
}
