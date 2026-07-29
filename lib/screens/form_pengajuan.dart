import 'package:digitalv/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/globals.dart';
import '../controllers/SuratController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FormPengajuan extends StatefulWidget {
  final String idSurat;

  const FormPengajuan({super.key, required this.idSurat});
  @override
  State<FormPengajuan> createState() => _FormPengajuan();
}

class _FormPengajuan extends State<FormPengajuan> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nikController = TextEditingController();
  final TextEditingController tempatLahirController = TextEditingController();
  final TextEditingController tanggalLahirController = TextEditingController();
  final TextEditingController golDarahController = TextEditingController();
  final TextEditingController jkController = TextEditingController();
  final TextEditingController kewarganegaraanController = TextEditingController();
  final TextEditingController agamaController = TextEditingController();
  // final TextEditingController statusNikahController = TextEditingController(text: 'Belum Kawin');
  final TextEditingController statusKeluargaController = TextEditingController();
  final TextEditingController pekerjaanController = TextEditingController();
  final TextEditingController pendidikanController = TextEditingController();
  final TextEditingController keteranganController = TextEditingController();
  bool isLoading = false;

  Map<String, dynamic>? suratData;
  List<dynamic> persyaratan = [];

  Map<int, File?> uploadedFiles = {};

  @override
  void initState() {
    super.initState();
    _loadUserData(); // ← ini penting!
    fetchSurat();
  }

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
              if (berkas != null && berkas.toString().isNotEmpty && berkas.toString() != '-') {
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

  Future<void> _loadUserData() async {
    final data = await fetchUserData();
    if (data != null) {
      setState(() {
        namaController.text = data['nama'] ?? '';
        nikController.text = data['nik'] ?? '';
        tempatLahirController.text = data['tempatLahir'] ?? '';
        tanggalLahirController.text = data['tanggalLahir'] ?? '';
        golDarahController.text = data['golDarah'] ?? '';
        jkController.text = data['jk'] ?? '';
        kewarganegaraanController.text = data['kewarganegaraan'] ?? '';
        agamaController.text = data['agama'] ?? '';
        statusKeluargaController.text = data['statusKeluarga'] ?? '';
        pekerjaanController.text = data['pekerjaan'] ?? '';
        pendidikanController.text = data['pendidikan'] ?? '';
      });
    }
  }
  Future<void> _submitForm() async {
    final keperluan = keteranganController.text.trim();

    if (keperluan.isEmpty) {
      showCustomSnackbar(
        context: context,
        message: 'Form keterangan harus diisi.',
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

    request.fields['id_surat'] = suratData?['id_surat']?.toString() ?? '';
    request.fields['nik'] = nikController.text.trim();
    request.fields['keterangan'] = keperluan;
    request.fields['tanggal_diajukan'] = DateTime.now().toIso8601String();

    print('URL dikirim: $uri');
    print('ID Surat dikirim: ${request.fields['id_surat']}');
    print('NIK dikirim: ${request.fields['nik']}');
    print('Keterangan dikirim: ${request.fields['keterangan']}');
    print('Tanggal dikirim: ${request.fields['tanggal_diajukan']}');

    for (int i = 0; i < uploadedFiles.length; i++) {
      File? file = uploadedFiles[i];

      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('foto${i + 1}', file.path),
        );
      }
    }

    try {
      final response = await request.send();
      final res = await http.Response.fromStream(response);

      print('URL dikirim: $uri');
      print('STATUS CODE: ${res.statusCode}');
      print('RESPONSE BODY: ${res.body}');

      if (res.statusCode == 200) {
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
        message: 'Terjadi kesalahan saat mengirim: $e',
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
      appBar: AppBar(
        title: Text(
          suratData?['nama_surat'] ?? 'Loading...',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0057A6),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.25),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            buildInputField('Nama lengkap', namaController, readOnly: true),
            buildInputField('NIK', nikController, readOnly: true),
            buildInputField(
              'Tempat Lahir',
              tempatLahirController,
              readOnly: true,
            ),
            buildInputField(
              'Tanggal Lahir',
              tanggalLahirController,
              readOnly: true,
            ),
            buildInputField(
              'Golongan Darah',
              golDarahController,
              readOnly: true,
            ),
            buildInputField('Jenis Kelamin', jkController, readOnly: true),
            buildInputField(
              'Kewarganegaraan',
              kewarganegaraanController,
              readOnly: true,
            ),
            buildInputField('Agama', agamaController, readOnly: true),
            // buildInputField('Status Perkawinan', statusNikahController, readOnly: true),
            buildInputField(
              'Status Keluarga',
              statusKeluargaController,
              readOnly: true,
            ),
            buildInputField('Pekerjaan', pekerjaanController, readOnly: true),
            buildInputField('Pendidikan', pendidikanController, readOnly: true),
            if (suratData != null)
              if (suratData != null)
                buildInputField(
                  suratData?['keterangan'] ?? '',
                  keteranganController,
                ),
            const SizedBox(height: 16),
            Column(
              children: List.generate(persyaratan.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: buildUploadField(
                    persyaratan[index]['nama_berkas'],
                    uploadedFiles[index],
                    (file) {
                      setState(() {
                        uploadedFiles[index] = file;
                      });
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0057A6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child:
                    isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2.5,
                          ),
                        )
                        : Text(
                          'Kirim',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final Color borderColor =
        readOnly
            ? const Color.fromARGB(255, 13, 103, 221)
            : const Color(0xFF0057A6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: Colors.black, fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: borderColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget buildUploadField(
    String label,
    File? imageFile,
    Function(File) onImagePicked,
  ) {
    return InkWell(
      onTap: () async {
        final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (pickedFile != null) {
          onImagePicked(File(pickedFile.path));
        }
      },
      child: Container(
        width: double.infinity,
        height: 146,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF0057A6), width: 1.5),
        ),
        child: Center(
          child:
              imageFile == null
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/upload.png',
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0057A6),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                  : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      imageFile,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
        ),
      ),
    );
  }
}
