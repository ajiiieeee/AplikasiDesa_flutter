import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:digitalv/screens/riwayat_pengaduan.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import '../config/globals.dart';
import '../widgets/snackbarcustom.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/secure_storage_service.dart';

class Pengaduan extends StatefulWidget {
  const Pengaduan({super.key});

  @override
  State<Pengaduan> createState() => _PengaduanState();
}

class _PengaduanState extends State<Pengaduan> {
  static const _primary   = Color(0xFF004AAD);
  static const _accent    = Color(0xFF004AAD);
  static const _bgGreen   = Color(0xFFE3F2FD);
  static const _fillGreen = Color(0xFFF0F6FF);
  static const _bgPage    = Color(0xFFF5F7FA);

  final TextEditingController ulasanController = TextEditingController();
  bool isLoading = false;

  // Gambar — simpan XFile + bytes agar aman di web
  XFile?      _pickedFile;
  Uint8List?  _imageBytes;
  File?       _imageFile;

  String? _selectedKategori;
  final List<String> _kategoriList = [
    'Infrastruktur',
    'Pelayanan',
    'Keamanan',
    'Lingkungan',
    'Lainnya',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      // Validasi ukuran file maksimal 5MB
      const maxSizeBytes = 5 * 1024 * 1024; // 5 MB
      if (bytes.lengthInBytes > maxSizeBytes) {
        final sizeMB = (bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1);
        if (mounted) {
          showCustomSnackbar(
            context: context,
            message: 'Foto terlalu besar ($sizeMB MB). Maksimal 5 MB.',
            backgroundColor: Colors.orange,
            icon: Icons.warning_amber_rounded,
          );
        }
        return;
      }

      setState(() {
        _pickedFile  = pickedFile;
        _imageBytes  = bytes;
        _imageFile   = kIsWeb ? null : File(pickedFile.path);
      });
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(
          context: context,
          message: 'Gagal mengambil foto: $e',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  'Pilih Sumber Foto Bukti',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _fillGreen,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _primary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.camera_alt_rounded, color: _primary, size: 30),
                              const SizedBox(height: 8),
                              Text(
                                'Kamera',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _fillGreen,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _primary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.photo_library_rounded, color: _primary, size: 30),
                              const SizedBox(height: 8),
                              Text(
                                'Galeri',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_selectedKategori == null) {
      showCustomSnackbar(
        context: context,
        message: 'Kategori pengaduan belum dipilih',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    if (ulasanController.text.trim().isEmpty) {
      showCustomSnackbar(
        context: context,
        message: 'Uraian pengaduan tidak boleh kosong',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    // Validasi foto bukti wajib minimal 1 foto
    if (_imageBytes == null || _pickedFile == null) {
      showCustomSnackbar(
        context: context,
        message: 'Foto bukti pengaduan wajib dilampirkan minimal 1 foto.',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => isLoading = true);

    final token = await SecureStorageService.instance.getToken();
    if (token == null || token.isEmpty) {
      showCustomSnackbar(
        context: context,
        message: 'Sesi habis. Silakan login ulang.',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
      setState(() => isLoading = false);
      return;
    }

    final uri     = Uri.parse('$baseURL/pengaduan');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept']        = 'application/json'
      ..headers['Authorization'] = 'Bearer $token';

    request.fields['ulasan']   = ulasanController.text.trim();
    request.fields['kategori'] = _selectedKategori ?? '';

    // Lampiran foto — pakai bytes agar kompatibel web & mobile
    if (_pickedFile != null && _imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto1',
          _imageBytes!,
          filename: _pickedFile!.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    try {
      final response = await request.send();
      final res      = await http.Response.fromStream(response);

      if (res.statusCode == 201) {
        showCustomSnackbar(
          context: context,
          message: 'Pengaduan berhasil dikirim!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RiwayatPengaduanScreen()),
        );
      } else {
        showCustomSnackbar(
          context: context,
          message: 'Gagal kirim pengaduan: ${res.statusCode}',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      showCustomSnackbar(
        context: context,
        message: 'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'FORM PENGADUAN',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RiwayatPengaduanScreen()),
              );
            },
            icon: const Icon(Icons.list_alt_rounded, color: _primary, size: 18),
            label: Text(
              'Riwayat',
              style: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Banner ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bgGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: _primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sampaikan pengaduan Anda terkait fasilitas, kebersihan, keamanan, atau masalah desa lainnya.',
                      style: GoogleFonts.poppins(
                        color: _primary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Form Card ─────────────────────────────────────────────────
            _sectionCard(
              title: 'Isi Pengaduan',
              icon: Icons.edit_document,
              children: [
                // Kategori
                _buildKategoriField(),
                const SizedBox(height: 12),
                // Ulasan
                _buildUlasanField(),
              ],
            ),

            const SizedBox(height: 16),

            // ── Upload Foto ───────────────────────────────────────────────
            _sectionCard(
              title: 'Foto Bukti Pengaduan (Wajib *)',
              icon: Icons.photo_library_outlined,
              children: [
                _buildUploadField(),
              ],
            ),

            const SizedBox(height: 24),

            // ── Tombol Kirim ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _submitForm,
                icon: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  isLoading ? 'Mengirim...' : 'Kirim Pengaduan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Section card ──────────────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: _primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dropdown kategori ─────────────────────────────────────────────────────
  Widget _buildKategoriField() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Kategori Pengaduan',
        labelStyle: GoogleFonts.poppins(
          color: _primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        filled: true,
        fillColor: _fillGreen,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: _primary.withValues(alpha: 0.4), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedKategori,
          isExpanded: true,
          hint: Text('Pilih kategori',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[500])),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _primary),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          items: _kategoriList.map((k) {
            IconData icon;
            switch (k) {
              case 'Infrastruktur':
                icon = Icons.construction_rounded;
                break;
              case 'Pelayanan':
                icon = Icons.support_agent_rounded;
                break;
              case 'Keamanan':
                icon = Icons.security_rounded;
                break;
              case 'Lingkungan':
                icon = Icons.eco_rounded;
                break;
              default:
                icon = Icons.help_outline_rounded;
            }
            return DropdownMenuItem(
              value: k,
              child: Row(
                children: [
                  Icon(icon, color: _primary, size: 18),
                  const SizedBox(width: 10),
                  Text(k,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedKategori = v),
        ),
      ),
    );
  }

  // ── Textarea ulasan ───────────────────────────────────────────────────────
  Widget _buildUlasanField() {
    return TextFormField(
      controller: ulasanController,
      maxLines: 5,
      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'Uraian Pengaduan',
        alignLabelWithHint: true,
        labelStyle: GoogleFonts.poppins(
          color: _primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
      ),
    );
  }

  // ── Upload foto ───────────────────────────────────────────────────────────
  Widget _buildUploadField() {
    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _imageBytes != null ? _primary : _primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: _imageBytes != null
            // Preview foto
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _imageBytes!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _pickedFile = null;
                        _imageBytes = null;
                        _imageFile  = null;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(5),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            // Placeholder kosong
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: _bgGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_outlined,
                        size: 30, color: _primary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pilih Foto (Kamera / Galeri)',
                    style: GoogleFonts.poppins(
                      color: _primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Wajib melampirkan minimal 1 foto bukti (Maks. 5 MB)',
                    style: GoogleFonts.poppins(
                        color: Colors.red.shade400, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
      ),
    );
  }
}