import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/globals.dart';
import '../models/pengajuanselesai_model.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';
import 'package:digitalv/widgets/timeline_widget.dart';
import '../services/secure_storage_service.dart';

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
      // Android 13+ (API 33+) tidak butuh permission storage untuk download ke app dir
      // Cukup cek READ_EXTERNAL_STORAGE untuk versi lama
      if (await Permission.storage.isGranted) return true;
      final status = await Permission.storage.request();
      if (!status.isGranted && !status.isPermanentlyDenied) return false;
    }
    return true;
  }

  Future<List<StatusSelesaiModel>> fetchDisetujui() async {
    final nik = await SecureStorageService.instance.getNik() ?? '';
    final token = await SecureStorageService.instance.getToken() ?? '';

    final authHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('$baseURL/statusselesai?nik=$nik'),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body is List ? body : (body['data'] ?? []);
      return data.map((item) => StatusSelesaiModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal mengambil data (${response.statusCode})');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF004AAD);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<List<StatusSelesaiModel>>(
        future: futureSelesai,
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
                      color: Colors.black.withValues(alpha: 0.04),
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
                          if (item.nomorSurat != null && item.nomorSurat!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Nomor Surat:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  item.nomorSurat!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF003580),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (item.keteranganDisplay.isNotEmpty && item.keteranganDisplay != '-') ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Keterangan:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.keteranganDisplay,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF263238),
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBBDEFB)),
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
                                      color: const Color(0xFF003580),
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
                              onPressed: item.filePdf == null || item.filePdf!.isEmpty
                                  ? null // tombol dinonaktifkan jika PDF belum ada
                                  : () async {
                                      String downloadUrl = item.filePdf!;
                                      if (!downloadUrl.startsWith('http://') && !downloadUrl.startsWith('https://')) {
                                        downloadUrl = '$serverURL/${downloadUrl.startsWith('/') ? downloadUrl.substring(1) : downloadUrl}';
                                      }

                                      final uri = Uri.parse(downloadUrl);

                                      if (context.mounted) {
                                        showCustomSnackbar(
                                          context: context,
                                          message: 'Membuka dan mengunduh PDF...',
                                          backgroundColor: Colors.blue,
                                          icon: Icons.downloading_rounded,
                                        );
                                      }

                                      // Metode 1: Buka melalui external application (Browser / Download Manager)
                                      // Ini metode standar Android modern (tidak memicu blokir "Izin penyimpanan ditolak" dan file otomatis masuk ke Download)
                                      bool launched = false;
                                      try {
                                        if (await canLaunchUrl(uri)) {
                                          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      } catch (_) {}

                                      if (launched) {
                                        if (context.mounted) {
                                          showCustomSnackbar(
                                            context: context,
                                            message: 'Surat dibuka di browser/pengunduh perangkat.',
                                            backgroundColor: Colors.green,
                                            icon: Icons.check_circle,
                                          );
                                        }
                                        return;
                                      }

                                      // Metode 2: Download langsung via Dio jika aplikasi external gagal
                                      try {
                                        final fileName = downloadUrl.split('/').last
                                            .replaceAll(RegExp(r'[^\w\-_\.]'), '_');

                                        Directory? directory;
                                        if (Platform.isAndroid) {
                                          try {
                                            directory = Directory('/storage/emulated/0/Download');
                                            if (!await directory.exists()) {
                                              directory = await getExternalStorageDirectory();
                                            }
                                          } catch (_) {
                                            directory = await getExternalStorageDirectory();
                                          }
                                        } else {
                                          directory = await getApplicationDocumentsDirectory();
                                        }

                                        directory ??= await getTemporaryDirectory();
                                        final filePath = '${directory.path}/$fileName';

                                        Dio dio = Dio();
                                        await dio.download(
                                          downloadUrl,
                                          filePath,
                                          options: Options(receiveTimeout: const Duration(seconds: 60)),
                                        );

                                        if (context.mounted) {
                                          showCustomSnackbar(
                                            context: context,
                                            message: 'PDF berhasil diunduh ke: $filePath',
                                            backgroundColor: Colors.green,
                                            icon: Icons.check_circle,
                                          );
                                        }
                                      } catch (e) {
                                        // Metode 3: Fallback ke launchUrl mode default
                                        try {
                                          await launchUrl(uri, mode: LaunchMode.platformDefault);
                                        } catch (_) {
                                          if (context.mounted) {
                                            showCustomSnackbar(
                                              context: context,
                                              message: 'Gagal mengunduh PDF: periksa koneksi internet.',
                                              backgroundColor: Colors.red,
                                              icon: Icons.error,
                                            );
                                          }
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                              label: Text(
                                item.filePdf == null || item.filePdf!.isEmpty
                                    ? "PDF Belum Tersedia"
                                    : "Unduh PDF Surat",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: item.filePdf == null || item.filePdf!.isEmpty
                                    ? Colors.grey
                                    : primaryGreen,
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
