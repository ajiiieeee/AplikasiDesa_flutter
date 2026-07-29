import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../config/globals.dart';
import '../../widgets/snackbarcustom.dart';

class KadusFormPengajuanScreen extends StatefulWidget {
  const KadusFormPengajuanScreen({super.key});

  @override
  State<KadusFormPengajuanScreen> createState() => _KadusFormPengajuanScreenState();
}

class _KadusFormPengajuanScreenState extends State<KadusFormPengajuanScreen> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _listKK = [];
  List<dynamic> _listAnggota = [];
  List<dynamic> _listSurat = [];

  String? _selectedNoKK;
  String? _selectedNik;
  // ignore: unused_field
  String? _selectedNamaWarga;
  String? _selectedIdSurat;

  final TextEditingController _keperluanController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<File?> _imageFiles = [null, null, null];
  bool _isLoading = false;
  bool _isLoadingKK = true;

  @override
  void initState() {
    super.initState();
    _tanggalController.text = DateTime.now().toString().split(' ')[0];
    _fetchKK();
    _fetchSurat();
  }

  Future<void> _fetchKK() async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/kadus/kartukeluarga'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (mounted) {
          setState(() {
            _listKK = body['data'] ?? [];
            _isLoadingKK = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingKK = false);
    }
  }

  Future<void> _fetchAnggota(String noKK) async {
    setState(() {
      _listAnggota = [];
      _selectedNik = null;
      _selectedNamaWarga = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseURL/kadus/kartukeluarga/$noKK/anggota'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (mounted) {
          setState(() {
            _listAnggota = body['data'] ?? [];
          });
        }
      }
    } catch (e) {
      print('Error fetching anggota: $e');
    }
  }

  Future<void> _fetchSurat() async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/surat'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        List listData = [];
        if (body is Map && body.containsKey('data')) {
          listData = body['data'] ?? [];
        } else if (body is List) {
          listData = body;
        }
        if (mounted) {
          setState(() {
            _listSurat = listData;
          });
        }
      }
    } catch (e) {
      print('Error fetching surat: $e');
    }
  }

  Future<void> _pickImage(int index) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFiles[index] = File(picked.path);
      });
    }
  }

  Future<void> _submitPengajuan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedNik == null || _selectedIdSurat == null) {
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
      var request = http.MultipartRequest('POST', Uri.parse('$baseURL/kadus/pengajuan'));
      request.headers.addAll(headers);

      request.fields['nik'] = _selectedNik!;
      request.fields['id_surat'] = _selectedIdSurat!;
      request.fields['keterangan'] = _keperluanController.text.trim();
      request.fields['tanggal_diajukan'] = _tanggalController.text.trim();

      for (int i = 0; i < 3; i++) {
        if (_imageFiles[i] != null) {
          request.files.add(await http.MultipartFile.fromPath('foto${i + 1}', _imageFiles[i]!.path));
        }
      }

      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);

      if (mounted) setState(() => _isLoading = false);

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Pengajuan atas nama warga berhasil dibuat dan otomatis disetujui Kadus!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        // Reset form
        _keperluanController.clear();
        setState(() {
          _selectedNoKK = null;
          _selectedNik = null;
          _selectedNamaWarga = null;
          _selectedIdSurat = null;
          _imageFiles[0] = null;
          _imageFiles[1] = null;
          _imageFiles[2] = null;
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

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const bgGrey = Color(0xFFF5F7FA);

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
              // Banner Informasi
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: primaryGreen, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pengajuan ini dibuat atas nama warga dan akan langsung berstatus "Disetujui Kepala Dusun".',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF1B5E20),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // STEP 1: PILIH PENDUDUK / KK
              _buildStepHeader(step: '1', title: 'Pilih Penduduk Pemohon'),
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
                    Text('Pilih Kartu Keluarga (KK):', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    const SizedBox(height: 6),
                    _isLoadingKK
                        ? const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: primaryGreen)))
                        : DropdownButtonFormField<String>(
                            value: _selectedNoKK,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: bgGrey,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            hint: Text('Pilih No. KK', style: GoogleFonts.poppins(fontSize: 13)),
                            items: _listKK.map((kk) {
                              return DropdownMenuItem<String>(
                                value: kk['no_kk'].toString(),
                                child: Text(
                                  '${kk['no_kk']} - ${kk['kepala_keluarga']}',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedNoKK = val;
                                });
                                _fetchAnggota(val);
                              }
                            },
                          ),
                    const SizedBox(height: 14),
                    Text('Pilih Warga Pemohon:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedNik,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: bgGrey,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      hint: Text(_selectedNoKK == null ? 'Pilih KK terlebih dahulu' : 'Pilih Anggota Keluarga', style: GoogleFonts.poppins(fontSize: 13)),
                      items: _listAnggota.map((ang) {
                        return DropdownMenuItem<String>(
                          value: ang['nik'].toString(),
                          child: Text(
                            '${ang['nama_lengkap']} (${ang['nik']})',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final selectedObj = _listAnggota.firstWhere((a) => a['nik'].toString() == val);
                          setState(() {
                            _selectedNik = val;
                            _selectedNamaWarga = selectedObj['nama_lengkap'];
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // STEP 2: PILIH JENIS SURAT
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  hint: Text('Pilih Jenis Surat Layanan', style: GoogleFonts.poppins(fontSize: 13)),
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

              // STEP 3: ISI KEPERLUAN
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
                    hintText: 'Tuliskan keperluan pengajuan surat ini secara detail...',
                    filled: true,
                    fillColor: bgGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Keperluan wajib diisi' : null,
                ),
              ),

              const SizedBox(height: 20),

              // STEP 4: UPLOAD LAMPIRAN
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
                    Text('Upload Berkas (KTP, KK, Persyaratan - Max 3 foto):', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(3, (index) {
                        return GestureDetector(
                          onTap: () => _pickImage(index),
                          child: Container(
                            width: (MediaQuery.of(context).size.width - 80) / 3,
                            height: 95,
                            decoration: BoxDecoration(
                              color: bgGrey,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFCFD8DC)),
                            ),
                            child: _imageFiles[index] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(_imageFiles[index]!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_a_photo_outlined, color: primaryGreen, size: 24),
                                      const SizedBox(height: 4),
                                      Text('Foto ${index + 1}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
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

              // STEP 5: SUBMIT
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitPengajuan,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Submit Pengajuan (Otomatis Disetujui)',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            color: primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF263238),
          ),
        ),
      ],
    );
  }
}
