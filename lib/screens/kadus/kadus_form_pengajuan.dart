import 'dart:convert';
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../config/globals.dart';
import '../../services/secure_storage_service.dart';
import '../../widgets/snackbarcustom.dart';

// ── Model warga untuk DropdownSearch ─────────────────────────────────────────
class _WargaItem {
  final String nik;
  final String namaLengkap;
  final String? jk;
  final String? rt;
  final String? rw;
  final String? dusun;

  const _WargaItem({
    required this.nik,
    required this.namaLengkap,
    this.jk,
    this.rt,
    this.rw,
    this.dusun,
  });

  factory _WargaItem.fromJson(Map<String, dynamic> json) => _WargaItem(
        nik: json['nik']?.toString() ?? '',
        namaLengkap: json['nama_lengkap']?.toString() ?? '',
        jk: json['jenis_kelamin']?.toString(),
        rt: json['rt']?.toString(),
        rw: json['rw']?.toString(),
        dusun: json['dusun']?.toString(),
      );

  @override
  String toString() => '$namaLengkap (NIK: $nik)';
}

class KadusFormPengajuanScreen extends StatefulWidget {
  const KadusFormPengajuanScreen({super.key});

  @override
  State<KadusFormPengajuanScreen> createState() =>
      _KadusFormPengajuanScreenState();
}

class _KadusFormPengajuanScreenState extends State<KadusFormPengajuanScreen> {
  final _formKey = GlobalKey<FormState>();

  List<_WargaItem> _listWarga = [];
  List<dynamic>    _listSurat = [];

  _WargaItem? _selectedWarga;
  String?     _selectedIdSurat;
  String?     _namaDusun;

  final TextEditingController _keperluanController = TextEditingController();
  final TextEditingController _tanggalController   = TextEditingController();

  final ImagePicker        _picker     = ImagePicker();
  final List<File?>        _imageFiles = [null, null, null];

  bool _isLoading      = false;
  bool _isLoadingWarga = true;

  @override
  void initState() {
    super.initState();
    _tanggalController.text = DateTime.now().toString().split(' ')[0];
    _fetchPenduduk();
    _fetchSurat();
  }

  @override
  void dispose() {
    _keperluanController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  // ── Auth headers ──────────────────────────────────────────────────────────
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await SecureStorageService.instance.getToken() ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Fetch warga dari dusun Kadus ──────────────────────────────────────────
  Future<void> _fetchPenduduk() async {
    try {
      final authHeaders = await _getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseURL/kadus/penduduk'), headers: authHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body  = json.decode(response.body);
        final items = (body['data'] as List? ?? [])
            .map((e) => _WargaItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _listWarga     = items;
            _namaDusun     = body['dusun']?.toString();
            _isLoadingWarga = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingWarga = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingWarga = false);
      debugPrint('Error fetching penduduk: $e');
    }
  }

  // ── Fetch daftar surat ────────────────────────────────────────────────────
  Future<void> _fetchSurat() async {
    try {
      final authHeaders = await _getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseURL/surat'), headers: authHeaders)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        List listData = [];
        if (body is Map && body.containsKey('data')) {
          listData = body['data'] ?? [];
        } else if (body is List) {
          listData = body;
        }
        if (mounted) setState(() => _listSurat = listData);
      }
    } catch (e) {
      debugPrint('Error fetching surat: $e');
    }
  }

  // ── Pick gambar ───────────────────────────────────────────────────────────
  Future<void> _pickImage(int index) async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _imageFiles[index] = File(picked.path));
    }
  }

  // ── Submit pengajuan ──────────────────────────────────────────────────────
  Future<void> _submitPengajuan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWarga == null || _selectedIdSurat == null) {
      showCustomSnackbar(
        context: context,
        message: 'Pilih Warga Pemohon dan Jenis Surat terlebih dahulu',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authHeaders    = await _getAuthHeaders();
      final multipartHeaders = Map<String, String>.from(authHeaders)
        ..remove('Content-Type');

      final request =
          http.MultipartRequest('POST', Uri.parse('$baseURL/kadus/pengajuan'));
      request.headers.addAll(multipartHeaders);
      request.fields['nik']               = _selectedWarga!.nik;
      request.fields['id_surat']          = _selectedIdSurat!;
      request.fields['keterangan']        = _keperluanController.text.trim();
      request.fields['tanggal_diajukan']  = _tanggalController.text.trim();

      for (int i = 0; i < 3; i++) {
        if (_imageFiles[i] != null) {
          request.files.add(await http.MultipartFile.fromPath(
              'foto${i + 1}', _imageFiles[i]!.path));
        }
      }

      final streamedRes = await request.send();
      final res         = await http.Response.fromStream(streamedRes);

      if (mounted) setState(() => _isLoading = false);

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (!mounted) return;
        final body = json.decode(res.body);
        final noReg = body['no_registrasi']?.toString();
        showCustomSnackbar(
          context: context,
          message: noReg != null && noReg.isNotEmpty
              ? 'Pengajuan berhasil dibuat! No. Reg: $noReg'
              : 'Pengajuan atas nama warga berhasil dibuat dan otomatis disetujui Kadus!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
        _keperluanController.clear();
        setState(() {
          _selectedWarga   = null;
          _selectedIdSurat = null;
          _imageFiles[0]   = null;
          _imageFiles[1]   = null;
          _imageFiles[2]   = null;
        });
      } else {
        final body = json.decode(res.body);
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: body['message'] ?? 'Gagal membuat pengajuan',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (!mounted) return;
      showCustomSnackbar(
        context: context,
        message: 'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const bgGrey       = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'AJUKAN SURAT (KADUS)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Banner Info ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: primaryGreen, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengajuan ini dibuat atas nama warga dan akan langsung berstatus "Disetujui Kepala Dusun".',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF1B5E20),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_namaDusun != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Menampilkan warga Dusun: $_namaDusun',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF388E3C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── STEP 1: PILIH WARGA ──────────────────────────────────────
              _buildStepHeader(step: '1', title: 'Pilih Warga Pemohon'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFECEFF1)),
                ),
                child: _isLoadingWarga
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(color: primaryGreen),
                        ),
                      )
                    : DropdownSearch<_WargaItem>(
                        items: (filter, _) async {
                          if (filter.isEmpty) return _listWarga;
                          final f = filter.toLowerCase();
                          return _listWarga
                              .where((w) =>
                                  w.namaLengkap.toLowerCase().contains(f) ||
                                  w.nik.contains(f))
                              .toList();
                        },
                        selectedItem: _selectedWarga,
                        compareFn: (a, b) => a.nik == b.nik,
                        itemAsString: (w) => '${w.namaLengkap} (${w.nik})',
                        onChanged: (val) =>
                            setState(() => _selectedWarga = val),
                        suffixProps: DropdownSuffixProps(
                          dropdownButtonProps: DropdownButtonProps(
                            iconOpened: const Icon(Icons.arrow_drop_up,
                                color: Color(0xFF2E7D32)),
                            iconClosed: const Icon(Icons.arrow_drop_down,
                                color: Color(0xFF2E7D32)),
                          ),
                        ),
                        decoratorProps: DropDownDecoratorProps(
                          decoration: InputDecoration(
                            labelText: 'Pilih Warga Pemohon',
                            labelStyle: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.grey[600]),
                            filled: true,
                            fillColor: bgGrey,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        popupProps: PopupProps.dialog(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Cari nama atau NIK...',
                              hintStyle: GoogleFonts.poppins(fontSize: 13),
                              prefixIcon: const Icon(Icons.search,
                                  color: Color(0xFF2E7D32), size: 20),
                              filled: true,
                              fillColor: bgGrey,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          itemBuilder:
                              (ctx, item, isDisabled, isSelected) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isSelected
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFE8F5E9),
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.namaLengkap,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF263238),
                                        ),
                                      ),
                                      Text(
                                        'NIK: ${item.nik}${item.rt != null ? ' · RT ${item.rt}/RW ${item.rw}' : ''}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: Color(0xFF2E7D32), size: 18),
                              ],
                            ),
                          ),
                          dialogProps: DialogProps(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          title: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Text(
                              'Pilih Warga Pemohon',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          emptyBuilder: (ctx, filter) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                filter.isEmpty
                                    ? 'Tidak ada warga di dusun ini'
                                    : 'Warga "$filter" tidak ditemukan',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.grey[500]),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // ── STEP 2: PILIH JENIS SURAT ──────────────────────────────
              _buildStepHeader(step: '2', title: 'Pilih Jenis Surat'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFECEFF1)),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedIdSurat,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: bgGrey,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  hint: Text('Pilih Jenis Surat Layanan',
                      style: GoogleFonts.poppins(fontSize: 13)),
                  items: _listSurat.map((surat) {
                    return DropdownMenuItem<String>(
                      value: surat['id_surat'].toString(),
                      child: Text(
                        surat['nama_surat'].toString(),
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedIdSurat = val),
                ),
              ),

              const SizedBox(height: 20),

              // ── STEP 3: ISI KEPERLUAN ────────────────────────────────────
              _buildStepHeader(step: '3', title: 'Isi Keperluan'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFECEFF1)),
                ),
                child: TextFormField(
                  controller: _keperluanController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        'Tuliskan keperluan pengajuan surat ini secara detail...',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[400]),
                    filled: true,
                    fillColor: bgGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Keperluan wajib diisi'
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              // ── STEP 4: UPLOAD LAMPIRAN ──────────────────────────────────
              _buildStepHeader(step: '4', title: 'Upload Lampiran Persyaratan'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFECEFF1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Berkas (KTP, Persyaratan - Max 3 foto):',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(3, (index) {
                        return GestureDetector(
                          onTap: () => _pickImage(index),
                          child: Container(
                            width:
                                (MediaQuery.of(context).size.width - 80) / 3,
                            height: 95,
                            decoration: BoxDecoration(
                              color: bgGrey,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFCFD8DC)),
                            ),
                            child: _imageFiles[index] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(_imageFiles[index]!,
                                        fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_a_photo_outlined,
                                          color: primaryGreen, size: 24),
                                      const SizedBox(height: 4),
                                      Text('Foto ${index + 1}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey[600])),
                                    ],
                                  ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── STEP 5: SUBMIT ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitPengajuan,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.send_rounded, size: 18),
                  label: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Submit Pengajuan (Otomatis Disetujui)',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader({required String step, required String title}) {
    const primaryGreen = Color(0xFF2E7D32);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
              color: primaryGreen, shape: BoxShape.circle),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF263238)),
        ),
      ],
    );
  }
}
