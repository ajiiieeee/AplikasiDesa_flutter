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
import '../services/secure_storage_service.dart';

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
  final TextEditingController noKkController        = TextEditingController();
  final TextEditingController nikController         = TextEditingController();
  final TextEditingController namaController        = TextEditingController();
  final TextEditingController tanggalLahirController = TextEditingController();
  final TextEditingController jkController          = TextEditingController();
  final TextEditingController alamatController      = TextEditingController();
  final TextEditingController rtController          = TextEditingController();
  final TextEditingController rwController          = TextEditingController();

  // ── Controller isian pengajuan ─────────────────────────────────────────────
  final TextEditingController keteranganController = TextEditingController();

  bool isLoading = false;

  Map<String, dynamic>? suratData;
  List<dynamic> persyaratan = [];

  // Foto per berkas persyaratan dari admin (Key: indeks berkas 0..N, Value: _FotoItem)
  final Map<int, _FotoItem> berkasPhotos = {};

  // Foto bukti lampiran tambahan (opsional)
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
      final token = await SecureStorageService.instance.getToken();

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

  // ── Load data warga: instant dari local cache lalu enrich dari API ─────────
  Future<void> _loadUserData() async {
    // 1. Load instant dari SharedPreferences & SecureStorage agar form tidak pernah kosong
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedNik = prefs.getString('nik') ?? await SecureStorageService.instance.getNik() ?? '';
      final cachedNama = prefs.getString('nama_lengkap') ?? prefs.getString('nama') ?? '';
      final cachedNoKk = prefs.getString('no_kk') ?? '';
      final cachedAlamat = prefs.getString('alamat') ?? '';
      final cachedRt = prefs.getString('rt') ?? '';
      final cachedRw = prefs.getString('rw') ?? '';
      final cachedTglLahir = prefs.getString('tanggal_lahir') ?? '';
      final cachedJk = prefs.getString('jk') ?? prefs.getString('jenis_kelamin') ?? '';

      if (mounted) {
        setState(() {
          if (nikController.text.isEmpty && cachedNik.isNotEmpty) nikController.text = cachedNik;
          if (namaController.text.isEmpty && cachedNama.isNotEmpty) namaController.text = cachedNama;
          if (noKkController.text.isEmpty && cachedNoKk.isNotEmpty) noKkController.text = cachedNoKk;
          if (alamatController.text.isEmpty && cachedAlamat.isNotEmpty) alamatController.text = cachedAlamat;
          if (rtController.text.isEmpty && cachedRt.isNotEmpty) rtController.text = cachedRt;
          if (rwController.text.isEmpty && cachedRw.isNotEmpty) rwController.text = cachedRw;
          if (tanggalLahirController.text.isEmpty && cachedTglLahir.isNotEmpty) tanggalLahirController.text = cachedTglLahir;
          if (jkController.text.isEmpty && cachedJk.isNotEmpty) jkController.text = cachedJk;
        });
      }
    } catch (e) {
      print('⚠️ Error loading local cache: $e');
    }

    // 2. Fetch data lengkap terbaru dari backend API (/getdata atau fallback /getprofil)
    try {
      final data = await fetchUserData();
      if (data != null && mounted) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          final noKk = (data['no_kk'] ?? '').toString();
          final nik = (data['nik'] ?? '').toString();
          final nama = (data['nama'] ?? data['nama_lengkap'] ?? '').toString();
          final tglLahir = (data['tanggal_lahir'] ?? data['tanggalLahir'] ?? '').toString();
          final jk = (data['jk'] ?? data['jenis_kelamin'] ?? '').toString();
          final alamat = (data['alamat'] ?? '').toString();
          final rt = (data['rt'] ?? '').toString();
          final rw = (data['rw'] ?? '').toString();

          if (noKk.isNotEmpty) noKkController.text = noKk;
          if (nik.isNotEmpty) nikController.text = nik;
          if (nama.isNotEmpty) namaController.text = nama;
          if (tglLahir.isNotEmpty) tanggalLahirController.text = tglLahir;
          if (jk.isNotEmpty) jkController.text = jk;
          if (alamat.isNotEmpty) alamatController.text = alamat;
          if (rt.isNotEmpty) rtController.text = rt;
          if (rw.isNotEmpty) rwController.text = rw;
        });

        // Simpan ke SharedPreferences untuk dipakai seterusnya
        if (noKkController.text.isNotEmpty) await prefs.setString('no_kk', noKkController.text);
        if (nikController.text.isNotEmpty) await prefs.setString('nik', nikController.text);
        if (namaController.text.isNotEmpty) await prefs.setString('nama_lengkap', namaController.text);
        if (alamatController.text.isNotEmpty) await prefs.setString('alamat', alamatController.text);
        if (rtController.text.isNotEmpty) await prefs.setString('rt', rtController.text);
        if (rwController.text.isNotEmpty) await prefs.setString('rw', rwController.text);
        if (tanggalLahirController.text.isNotEmpty) await prefs.setString('tanggal_lahir', tanggalLahirController.text);
        if (jkController.text.isNotEmpty) await prefs.setString('jk', jkController.text);
      }
    } catch (e) {
      print('⚠️ Error fetching user data from API: $e');
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

  // ── Tambah foto bukti lampiran tambahan ──────────────────────────────────
  Future<void> _tambahFotoBukti() async {
    final item = await _pickFoto();
    if (item != null) {
      setState(() => buktiPhotos.add(item));
    }
  }

  void _hapusFotoBukti(int index) {
    setState(() => buktiPhotos.removeAt(index));
  }

  // ── Pick Foto Berkas Persyaratan (Kamera / Galeri) ─────────────────────────
  Future<void> _pickFotoBerkas(int index) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Sumber Foto Dokumen',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005697).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF005697)),
                ),
                title: Text('Ambil dari Kamera',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Foto langsung dokumen menggunakan kamera HP',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005697).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF005697)),
                ),
                title: Text('Pilih dari Galeri',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Pilih foto dokumen yang sudah ada di galeri HP',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) return;

      final item = _FotoItem(picked);
      item.bytes = await picked.readAsBytes();

      if (mounted) {
        setState(() {
          berkasPhotos[index] = item;
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(
          context: context,
          message: 'Gagal mengambil gambar: $e',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  void _hapusFotoBerkas(int index) {
    setState(() {
      berkasPhotos.remove(index);
    });
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

    // ── Validasi Berkas Persyaratan (Semua berkas yang disyaratkan admin WAJIB diisi) ──
    for (int i = 0; i < persyaratan.length; i++) {
      if (!berkasPhotos.containsKey(i) || berkasPhotos[i] == null) {
        final nama = (persyaratan[i]['nama_berkas']?.toString() ?? 'Berkas ${i + 1}').trim().toUpperCase();
        showCustomSnackbar(
          context: context,
          message: 'Foto berkas $nama wajib diunggah!',
          backgroundColor: Colors.red.shade700,
          icon: Icons.warning_amber_rounded,
        );
        return;
      }
    }

    setState(() => isLoading = true);

    final token = await SecureStorageService.instance.getToken() ?? '';

    final uri = Uri.parse('$baseURL/pengajuan');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    });

    request.fields['id_surat']         = suratData?['id_surat']?.toString() ?? widget.idSurat;
    request.fields['nik']              = nikController.text.trim();
    request.fields['keterangan']       = keperluan;
    request.fields['tanggal_diajukan'] = DateTime.now().toIso8601String();

    // ── 1. Upload berkas persyaratan wajib (foto1, foto2, dst sesuai urutan) ──
    int fotoIndex = 1;
    for (int i = 0; i < persyaratan.length; i++) {
      if (fotoIndex <= 8 && berkasPhotos.containsKey(i) && berkasPhotos[i] != null) {
        final item = berkasPhotos[i]!;
        final bytes = item.bytes ?? await item.xfile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'foto$fotoIndex',
          bytes,
          filename: 'berkas_${i + 1}_${item.xfile.name}',
        ));
        fotoIndex++;
      }
    }

    // ── 2. Fallback: upload foto bukti HANYA jika jenis surat tidak memiliki berkas persyaratan khusus ──
    if (persyaratan.isEmpty) {
      for (int i = 0; i < buktiPhotos.length; i++) {
        if (fotoIndex <= 8) {
          final item = buktiPhotos[i];
          final bytes = item.bytes ?? await item.xfile.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'foto$fotoIndex',
            bytes,
            filename: 'lampiran_${i + 1}_${item.xfile.name}',
          ));
          fotoIndex++;
        }
      }
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

        // Kembali ke halaman sebelumnya (BottomNavBar sudah ada di stack)
        Navigator.pop(context);
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
    const primary = Color(0xFF004AAD);
    const primaryLight = Color(0xFF004AAD);
    const bgGreen = Color(0xFFE3F2FD);
    const fillGreen = Color(0xFFF0F6FF);

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
        shadowColor: Colors.black.withValues(alpha: 0.15),
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
                  _field('No. KK', noKkController, primary: primary, fillGreen: fillGreen),
                  _field('NIK', nikController, primary: primary, fillGreen: fillGreen),
                ]),
                _field('Nama Lengkap', namaController, primary: primary, fillGreen: fillGreen, fullWidth: true),
                _buildRow([
                  _field('Tanggal Lahir', tanggalLahirController, primary: primary, fillGreen: fillGreen),
                  _field('Jenis Kelamin', jkController, primary: primary, fillGreen: fillGreen),
                ]),
                _field('Alamat', alamatController, primary: primary, fillGreen: fillGreen, fullWidth: true),
                _buildRow([
                  _field('RT', rtController, primary: primary, fillGreen: fillGreen),
                  _field('RW', rwController, primary: primary, fillGreen: fillGreen),
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
                _fieldEditable(
                  suratData?['keterangan'] != null && suratData!['keterangan'].toString().isNotEmpty
                      ? suratData!['keterangan'].toString()
                      : 'Keterangan / Keperluan Surat',
                  keteranganController,
                  primary: primary,
                  primaryLight: primaryLight,
                  maxLines: 4,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── SECTION: Berkas Persyaratan (Input Foto per Persyaratan Admin) ──
            if (persyaratan.isNotEmpty)
              _sectionCard(
                primary: primary,
                bgGreen: bgGreen,
                title: 'Berkas Persyaratan (Wajib)',
                icon: Icons.checklist_rounded,
                children: [
                  Text(
                    'Admin mewajibkan Anda melampirkan foto dokumen di bawah ini. Semua berkas persyaratan wajib diunggah:',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(persyaratan.length, (index) {
                    final rawNama = persyaratan[index]['nama_berkas']?.toString() ?? 'Berkas ${index + 1}';
                    final nama = rawNama.trim();
                    final item = berkasPhotos[index];
                    final isUploaded = item != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUploaded ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isUploaded ? Colors.green.shade400 : primary.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header berkas: Nomor, Nama Berkas, & Status Badge
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isUploaded ? Colors.green.shade600 : primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isUploaded
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : Text(
                                          '${index + 1}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Foto $nama',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isUploaded ? Colors.green.shade100 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isUploaded ? Colors.green.shade300 : Colors.red.shade200,
                                  ),
                                ),
                                child: Text(
                                  isUploaded ? '✓ Terunggah' : 'Wajib Diisi',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isUploaded ? Colors.green.shade800 : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Area Upload / Preview Foto
                          if (!isUploaded)
                            InkWell(
                              onTap: () => _pickFotoBerkas(index),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.35),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 22,
                                      color: primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Upload Foto $nama',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 65,
                                      height: 65,
                                      child: _imagePreview(
                                        item: item,
                                        fit: BoxFit.cover,
                                        width: 65,
                                        height: 65,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.xfile.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '✓ Berkas $nama siap dikirim',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _pickFotoBerkas(index),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.autorenew_rounded, size: 14, color: primary),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    'Ganti',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            InkWell(
                                              onTap: () => _hapusFotoBerkas(index),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline, size: 14, color: Colors.red.shade700),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    'Hapus',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.red.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),

            // ── SECTION: Foto Bukti Lampiran (HANYA tampil jika jenis surat TIDAK memiliki berkas persyaratan khusus dari admin) ──
            if (persyaratan.isEmpty) ...[
              const SizedBox(height: 16),
              _sectionCard(
                primary: primary,
                bgGreen: bgGreen,
                title: 'Foto Bukti Lampiran (Opsional)',
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
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 32, color: primary.withValues(alpha: 0.5)),
                            const SizedBox(height: 6),
                            Text(
                              'Tap untuk menambahkan foto bukti (Opsional)',
                              style: GoogleFonts.poppins(
                                color: primary.withValues(alpha: 0.6),
                                fontSize: 11,
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
                                border: Border.all(color: primary.withValues(alpha: 0.4)),
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
                                        color: Colors.black.withValues(alpha: 0.3),
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
            ],

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
            color: Colors.black.withValues(alpha: 0.06),
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
              color: primary.withValues(alpha: 0.07),
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
            borderSide: BorderSide(color: primary.withValues(alpha: 0.3), width: 1.2),
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

  // _buildUploadField dihapus — tidak digunakan lagi
}
