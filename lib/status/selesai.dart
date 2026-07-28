import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/globals.dart';
import '../models/pengajuanselesai_model.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';
import 'package:digitalv/widgets/timeline_widget.dart';

class DisetujuiView extends StatefulWidget {
  const DisetujuiView({super.key});

  @override
  State<DisetujuiView> createState() => _DisetujuiViewState();
}

class _DisetujuiViewState extends State<DisetujuiView> {
  late Future<List<StatusSelesaiModel>> futureSelesai;

  @override
  void initState() {
    super.initState();
    futureSelesai = fetchDisetujui();
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          return false;
        }
      }
    }
    return true;
  }

  Future<List<StatusSelesaiModel>> fetchDisetujui() async {
    final prefs = await SharedPreferences.getInstance();
    final nik = prefs.getString('nik') ?? '';

    if (nik.isEmpty) {
      throw Exception('NIK tidak ditemukan di SharedPreferences');
    }

    final response = await http.get(
      Uri.parse('$baseURL/statusselesai?nik=$nik'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => StatusSelesaiModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal mengambil data');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<List<StatusSelesaiModel>>(
        future: fetchDisetujui(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    "Belum ada surat yang selesai",
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

          final disetujui = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: disetujui.length,
            itemBuilder: (context, index) {
              final item = disetujui[index];
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
                          const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.namaSurat.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Disetujui Pada:',
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.task_alt_rounded, color: primaryGreen, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Selamat! Surat Anda telah selesai diproses dan siap diunduh.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1B5E20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SuratTimelineWidget(status: item.status.isEmpty ? 'Selesai' : item.status),
                          const SizedBox(height: 14),

                          // Tombol Unduh PDF Surat
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final url = item.filePdf;
                                if (!await requestStoragePermission()) {
                                  showCustomSnackbar(
                                    context: context,
                                    message: 'Izin penyimpanan ditolak',
                                    backgroundColor: Colors.red,
                                    icon: Icons.error,
                                  );
                                  return;
                                }

                                try {
                                  final fileName = url.split('/').last;
                                  final directory = Directory('/storage/emulated/0/Download');

                                  if (!await directory.exists()) {
                                    await directory.create(recursive: true);
                                  }

                                  final filePath = '${directory.path}/$fileName';
                                  Dio dio = Dio();
                                  await dio.download(url, filePath);

                                  showCustomSnackbar(
                                    context: context,
                                    message: 'File berhasil diunduh di folder Download',
                                    backgroundColor: Colors.green,
                                    icon: Icons.check_circle,
                                  );
                                } catch (e) {
                                  showCustomSnackbar(
                                    context: context,
                                    message: 'Gagal download file: $e',
                                    backgroundColor: Colors.red,
                                    icon: Icons.error,
                                  );
                                }
                              },
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                              label: Text(
                                "Unduh PDF Surat",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
