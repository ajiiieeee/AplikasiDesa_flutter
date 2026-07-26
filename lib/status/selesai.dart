import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/globals.dart';
import '../models/pengajuanselesai_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';
import 'package:digitalv/widgets/timeline_widget.dart';

class DisetujuiView extends StatefulWidget {
  const DisetujuiView({super.key});

  @override
  State<DisetujuiView> createState() => _DisetujuiViewState();
}

class _DisetujuiViewState extends State<DisetujuiView> {
  late Future<List<StatusSelesaiModel>> futureSelesai;

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<StatusSelesaiModel>>(
        future: fetchDisetujui(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
           return const Center(
              child: Text(
                "Tidak ada data",
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
              ),
            );
          }

          final disetujui = snapshot.data!;
          return ListView.builder(
            itemCount: disetujui.length,
            itemBuilder: (context, index) {
              final item = disetujui[index];
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
                    // Header Card
                    Container(
                      width: double.infinity,
                      height: 50,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF28A745),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        item.namaSurat.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Body Content
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disetujui Pada: ${item.updatedAt}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 128, 128, 128),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Terima Kasih! Surat Anda Telah Disetujui,\nUnduh Surat Pada Tombol Di Bawah Ini.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SuratTimelineWidget(status: item.status.isEmpty ? 'Selesai' : item.status),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () async {
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
                                    final directory = Directory(
                                      '/storage/emulated/0/Download',
                                    );

                                    if (!await directory.exists()) {
                                      await directory.create(recursive: true);
                                    }

                                    final filePath =
                                        '${directory.path}/$fileName';
                                    Dio dio = Dio();
                                    await dio.download(url, filePath);

                                    showCustomSnackbar(
                                      context: context,
                                      message:
                                          'File berhasil diunduh di folder Download',
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
                                borderRadius: BorderRadius.circular(12),
                                 child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.download_outlined,
                                      color: Color(0xFF0057A6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Unduh Surat",
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFF0057A6),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                 ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
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
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
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
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
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
                                        futureSelesai = fetchDisetujui();
                                      });
                                      // Trigger refresh if in StatefulWidget
                                      if (context is StatefulElement) {
                                        (context as Element).markNeedsBuild();
                                      }
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
                                borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
