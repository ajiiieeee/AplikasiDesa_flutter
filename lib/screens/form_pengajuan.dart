import 'package:digitalv/widgets/bottom_navbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/globals.dart';
import '../controllers/SuratController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Model foto: simpan XFile + preview bytes ──────────────────────────────────
class _FotoItem {
  final XFile xfile;
  Uint8List? bytes;
  _FotoItem(this.xfile);
}

class FormPengajuan extends StatefulWidget {
  final String idSurat;

  const FormPengajuan({super.key, required this.idSurat});
  @override
  State<FormPengajuan> createState() => _FormPengajuan();
}

class _FormPengajuan extends State<FormPengajuan> {
  // ── Controllers data warga ─────────────────────────────────────────────────
  final TextEditingController kecamatanController   = TextEditingController();
  final TextEditingController kelurahanController   = TextEditingController();
  final TextEditingController noKkController        = TextEditingController();
  final TextEditingController nikController         = TextEditingController();
  final TextEditingController namaController        = TextEditingController();
  final TextEditingController tempatLahirController = TextEditingController();
  final TextEditingController tanggalLahirController = TextEditingController();
  final TextEditingController statusKawinController = TextEditingController();
  final TextEditingController jkController          = TextEditingController();
  final TextEditingController alamatController      = TextEditingController();
  final TextEditingController rtController          = TextEditingController();
  final TextEditingController rwController          = TextEditingController();
  final TextEditingController dusunController       = TextEditingController();

  // ── Controller isian pengajuan ─────────────────────────────────────────────
  final TextEditingController keteranganController = TextEditingController();

  bool isLoading = false;

  Map<String, dynamic>? suratData;
  List<dynamic> persyaratan = [];

  // Berkas persyaratan — pakai XFile agar kompatibel web & mobile
  Map<int, _FotoItem?> uploadedFiles = {};

  // Foto bukti lampiran (multi-foto)
  List<_FotoItem> buktiPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchSurat();
  }

  // ── Fetch daftar surat ────────────────────────────────────────────────────
  Future<void> fetchSurat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseURL/surat'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List listData = [];

        if (responseData is Map && responseData.containsKey('data')) {
          listData = responseData['data'] ?? [];
        } else if (responseData is List) {
          listData = responseData;
        }

        final surat = listData.firstWhere(
          (item) => item['id_surat'].toString() == widget.idSurat.toString(),
          orElse: () => null,
        );

        if (surat != null) {
          List<dynamic> tempPersyaratan = [];

          if (surat['syarat'] != null && surat['syarat'] is List) {
            for (var berkas in surat['syarat']) {
              if (berkas != null &&
                  berkas.toString().isNotEmpty &&
                  berkas.toString() != '-') {
                tempPersyaratan.add({'nama_berkas': berkas.toString()});
              }
            }
          } else {
            for (int i = 1; i <= 9; i++) {
              final berkas = surat['berkas$i'];
              if (berkas != null && berkas != '' && berkas != '-') {
                tempPersyaratan.add({'nama_berkas': berkas.toString()});
              }
            }
          }

          if (mounted) {
            setState(() {
              suratData = Map<String, dynamic>.from(surat);
              persyaratan = tempPersyaratan;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetchSurat: $e');
    }
  }

  // ── Load data warga dari API /getdata ─────────────────────────────────────
  Future<void> _loadUserData() async {
    final data = await fetchUserData();
    if (data != null) {
      setState(() {
        kecamatanController.text    = data['kecamatan']    ?? '';
        kelurahanController.text    = data['kelurahan']    ?? '';
        noKkController.text         = data['no_kk']        ?? data['nomor_kk'] ?? '';
        nikController.text          = data['nik']          ?? data['nomor_ktp'] ?? '';
        namaController.text         = data['nama']         ?? data['nama_lengkap'] ?? '';
        tempatLahirController.text  = data['tempat_lahir'] ?? data['tempatLahir'] ?? '';
        tanggalLahirController.text = data['tanggal_lahir'] ?? data['tanggalLahir'] ?? '';
        statusKawinController.text  = data['sts_kawin']   ?? data['status_kawin'] ?? data['statusKawin'] ?? '';
        jkController.text           = data['kelamin']      ?? data['jk'] ?? '';
        alamatController.text       = data['alamat']       ?? '';
        rtController.text           = data['rt']           ?? '';
        rwController.text           = data['rw']           ?? '';
        dusunController.text        = data['dusun']        ?? '';
      });
    }
  }

  // ── Pick foto dan simpan bytes ────────────────────────────────────────────
  Future<_FotoItem?> _pickFoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final item = _FotoItem(picked);
    item.bytes = await picked.readAsBytes();
    return item;
  }

  // ── Tambah foto bukti ─────────────────────────────────────────────────────
  Future<void> _tambahFotoBukti() async {
    final item = await _pickFoto();
    if (item != null) {
      setState(() => buktiPhotos.add(item));
    }
  }

  void _hapusFotoBukti(int index) {
    setState(() => buktiPhotos.removeAt(index));
  }

  // ── Submit form ───────────────────────────────────────────────────────────
  Future<void> _submitForm() async {
    final keperluan = keteranganController.text.trim();

    if (keperluan.isEmpty) {
      showCustomSnackbar(
        context: context,
        message: 'Keterangan / keperluan surat harus diisi.',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse('$baseURL/pengajuan');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    });

    request.fields['id_surat']         = suratData?['id_surat']?.toString() ?? '';
    request.fields['nik']              = nikController.text.trim();
    request.fields['keterangan']       = keperluan;
    request.fields['tanggal_diajukan'] = DateTime.now().toIso8601String();

    // Berkas persyaratan
    for (int i = 0; i < uploadedFiles.length; i++) {
      final item = uploadedFiles[i];
      if (item != null) {
        final bytes = item.bytes ?? await item.xfile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'foto${i + 1}',
          bytes,
          filename: item.xfile.name,
        ));
      }
    }

    // Foto bukti tambahan
    for (int i = 0; i < buktiPhotos.length; i++) {
      final item = buktiPhotos[i];
      final bytes = item.bytes ?? await item.xfile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'bukti${i + 1}',
        bytes,
        filename: item.xfile.name,
      ));
    }

    try {
      final response = await request.send();
      final res = await http.Response.fromStream(response);

      if (res.statusCode == 200 || res.statusCode == 201) {
        showCustomSnackbar(
          context: context,
          message: 'Pengajuan berhasil dikirim!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNavBar()),
        );
      } else if (res.statusCode == 409) {
        final responseData = jsonDecode(res.body);
        showCustomSnackbar(
          context: context,
          message: responseData['message'] ?? 'Pengajuan masih diproses.',
          backgroundColor: Colors.orange,
          icon: Icons.warning_amber_rounded,
        );
      } else if (res.statusCode == 422) {
        final responseData = jsonDecode(res.body);
        String errorMessage = 'Validasi gagal';
        if (responseData['errors'] != null) {
          errorMessage = responseData['errors'].values
              .map((errList) => (errList as List).join(', '))
              .join('\n');
        } else if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        }
        showCustomSnackbar(
          context: context,
          message: errorMessage,
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      } else {
        showCustomSnackbar(
          context: context,
          message: 'Gagal mengirim pengajuan. Status: ${res.statusCode}',
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

  // ── Preview gambar (kompatibel web & mobile) ──────────────────────────────
  Widget _imagePreview({
    required _FotoItem item,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (item.bytes != null) {
      return Image.memory(
        item.bytes!,
        fit: fit,
        width: width,
        height: height,
      );
    }
    // Fallback mobile
    if (!kIsWeb) {
      return Image.file(
        File(item.xfile.path),
        fit: fit,
        width: width,
        height: height,
      );
    }
    return const Center(child: Icon(Icons.image, size: 40, color: Colors.grey));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2E7D32);
    const primaryLight = Color(0xFF16A34A);
    const bgGreen = Color(0xFFE8F5E9);
    const fillGreen = Color(0xFFF1F8F1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          suratData?['nama_surat'] ?? 'Loading...',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.15),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SECTION: Data Warga ────────────────────────────────────────
            _sectionCard(
              primary: primary,
              bgGreen: bgGreen,
              title: 'Data Warga',
              icon: Icons.person_outline,
              children: [
                _buildRow([
                  _field('Kecamatan', kecamatanController, primary: primary, fillGreen: fillGreen),
                  _field('Kelurahan', kelurahanController, primary: primary, fillGreen: fillGreen),
                ]),
                _buildRow([
                  _field('No. KK', noKkController, primary: primary, fillGreen: fillGreen),
                  _field('NIK', nikController, primary: primary, fillGreen: fillGreen),
                ]),
                _field('Nama Lengkap', namaController, primary: primary, fillGreen: fillGreen, fullWidth: true),
                _buildRow([
                  _field('Tempat Lahir', tempatLahirController, primary: primary, fillGreen: fillGreen),
                  _field('Tanggal Lahir', tanggalLahirController, primary: primary, fillGreen: fillGreen),
                ]),
                _buildRow([
                  _field('Status Kawin', statusKawinController, primary: primary, fillGreen: fillGreen),
                  _field('Jenis Kelamin', jkController, primary: primary, fillGreen: fillGreen),
                ]),
                _field('Alamat', alamatController, primary: primary, fillGreen: fillGreen, fullWidth: true),
                _buildRow([
                  _field('RT', rtController, primary: primary, fillGreen: fillGreen),
                  _field('RW', rwController, primary: primary, fillGreen: fillGreen),
                  _field('Dusun', dusunController, primary: primary, fillGreen: fillGreen),
                ]),
              ],
            ),

            const SizedBox(height: 16),

            // ── SECTION: Keterangan Pengajuan ──────────────────────────────
            _sectionCard(
              primary: primary,
              bgGreen: bgGreen,
              title: 'Keterangan Pengajuan',
              icon: Icons.description_outlined,
              children: [
                if (suratData != null)
                  _fieldEditable(
                    suratData?['keterangan'] ?? 'Keterangan / Keperluan',
                    keteranganController,
                    primary: primary,
                    primaryLight: primaryLight,
                    maxLines: 4,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ── SECTION: Berkas Persyaratan ───────────────────────────────
            if (persyaratan.isNotEmpty)
              _sectionCard(
                primary: primary,
                bgGreen: bgGreen,
                title: 'Berkas Persyaratan',
                icon: Icons.attach_file_rounded,
                children: List.generate(persyaratan.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildUploadField(
                      label: persyaratan[index]['nama_berkas'],
                      item: uploadedFiles[index],
                      primary: primary,
                      onPicked: (item) => setState(() => uploadedFiles[index] = item),
                    ),
                  );
                }),
              ),

            if (persyaratan.isNotEmpty) const SizedBox(height: 16),

            // ── SECTION: Foto Bukti Lampiran ──────────────────────────────
            _sectionCard(
              primary: primary,
              bgGreen: bgGreen,
              title: 'Foto Bukti Lampiran',
              icon: Icons.photo_library_outlined,
              trailing: TextButton.icon(
                onPressed: _tambahFotoBukti,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(
                  'Tambah Foto',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  backgroundColor: bgGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              children: [
                if (buktiPhotos.isEmpty)
                  // Placeholder kosong
                  InkWell(
                    onTap: _tambahFotoBukti,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primary.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 36, color: primary.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text(
                            'Tap untuk menambahkan foto bukti',
                            style: GoogleFonts.poppins(
                              color: primary.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Grid foto
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: buktiPhotos.length + 1,
                    itemBuilder: (context, index) {
                      // Tombol tambah di akhir grid
                      if (index == buktiPhotos.length) {
                        return InkWell(
                          onTap: _tambahFotoBukti,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgGreen,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: primary.withOpacity(0.4)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 28, color: primary),
                                const SizedBox(height: 4),
                                Text(
                                  'Tambah',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Thumbnail foto
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: double.infinity,
                              height: double.infinity,
                              child: _imagePreview(
                                item: buktiPhotos[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _hapusFotoBukti(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // ── TOMBOL KIRIM ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Kirim Pengajuan',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _sectionCard({
    required Color primary,
    required Color bgGreen,
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
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

  Widget _buildRow(List<Widget> fields) {
    return Row(
      children: fields
          .map((f) => Expanded(
                child: Padding(padding: const EdgeInsets.only(right: 8), child: f),
              ))
          .toList(),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required Color primary,
    required Color fillGreen,
    bool fullWidth = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: GoogleFonts.poppins(color: Colors.black87, fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: primary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          filled: true,
          fillColor: fillGreen,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primary.withOpacity(0.3), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _fieldEditable(
    String label,
    TextEditingController controller, {
    required Color primary,
    required Color primaryLight,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          labelStyle: GoogleFonts.poppins(
            color: primary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryLight, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadField({
    required String label,
    required _FotoItem? item,
    required Color primary,
    required Function(_FotoItem) onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await _pickFoto();
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primary, width: 1.5),
        ),
        child: Center(
          child: item == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/upload.png', width: 44, height: 44),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _imagePreview(
                    item: item,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
        ),
      ),
    );
  }
}
