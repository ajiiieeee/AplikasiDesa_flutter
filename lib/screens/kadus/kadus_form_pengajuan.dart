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
        setState(() {
          _listKK = body['data'] ?? [];
          _isLoadingKK = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingKK = false);
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
        setState(() {
          _listAnggota = body['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching anggota: $e');
    }
  }

  Future<void> _fetchSurat() async {
    try {
      final response = await http.get(Uri.parse('$baseURL/surat'));
      if (response.statusCode == 200) {
        setState(() {
          _listSurat = json.decode(response.body);
        });
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
        message: 'Pilih Warga dan Jenis Surat terlebih dahulu',
        backgroundColor: Colors.orange,
        icon: Icons.warning,
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

      setState(() => _isLoading = false);

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          message: 'Pengajuan atas nama warga berhasil dibuat!',
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
      setState(() => _isLoading = false);
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'AJUKAN SURAT (KADUS)',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0057A6),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0057A6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF0057A6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pengajuan ini dibuat atas nama warga dan akan langsung berstatus "Disetujui Kepala Dusun".',
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF0057A6)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 1. Pilih Kartu Keluarga
              Text('1. Pilih Kartu Keluarga (KK)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              _isLoadingKK
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      value: _selectedNoKK,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

              const SizedBox(height: 16),

              // 2. Pilih Anggota Keluarga (Warga Pemohon)
              Text('2. Pilih Warga Pemohon', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedNik,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

              const SizedBox(height: 16),

              // 3. Jenis Surat
              Text('3. Jenis Surat', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedIdSurat,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                hint: Text('Pilih Jenis Surat', style: GoogleFonts.poppins(fontSize: 13)),
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

              const SizedBox(height: 16),

              // 4. Keperluan / Keterangan
              Text('4. Keperluan Pengajuan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _keperluanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tuliskan keperluan pengajuan surat ini...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Keperluan wajib diisi' : null,
              ),

              const SizedBox(height: 16),

              // 5. Upload Foto Persyaratan
              Text('5. Upload Persyaratan (Opsional max 3 foto)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  return GestureDetector(
                    onTap: () => _pickImage(index),
                    child: Container(
                      width: 100,
                      height: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade100,
                      ),
                      child: _imageFiles[index] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_imageFiles[index]!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo, color: Colors.grey),
                                const SizedBox(height: 4),
                                Text('Foto ${index + 1}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPengajuan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0057A6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Kirim Pengajuan (Disetujui Kadus)',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
}
