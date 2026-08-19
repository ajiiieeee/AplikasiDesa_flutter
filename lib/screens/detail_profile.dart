import 'package:flutter/material.dart';
import '../controllers/ProfileController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailProfile extends StatefulWidget {
  const DetailProfile({super.key});

  @override
  State<DetailProfile> createState() => _DetailProfileState();
}

class _DetailProfileState extends State<DetailProfile> {
  static const _primary  = Color(0xFF2E7D32);
  static const _bgGreen  = Color(0xFFE8F5E9);
  static const _fillGreen = Color(0xFFF1F8F1);

  final TextEditingController nameController  = TextEditingController();
  final TextEditingController nikController   = TextEditingController();
  final TextEditingController kkController    = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text  = prefs.getString('nama_lengkap') ?? '-';
      nikController.text   = prefs.getString('nik')          ?? '-';
      kkController.text    = prefs.getString('no_kk')        ?? '-';
      phoneController.text = prefs.getString('no_hp')        ?? '-';
      emailController.text = prefs.getString('email')        ?? '-';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'EDIT PROFIL',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Data Tidak Bisa Diubah ───────────────────────────────
            _sectionCard(
              title: 'Data Kependudukan',
              icon: Icons.badge_outlined,
              children: [
                _buildTextField('NIK',              nikController,  readOnly: true),
                _buildTextField('No. Kartu Keluarga', kkController, readOnly: true),
                _buildTextField('Nama Lengkap',     nameController, readOnly: true),
              ],
            ),

            const SizedBox(height: 16),

            // ── Card Data Bisa Diubah ──────────────────────────────────────
            _sectionCard(
              title: 'Data Kontak',
              icon: Icons.contact_phone_outlined,
              children: [
                _buildTextField('No. Handphone', phoneController,
                    keyboardType: TextInputType.phone),
                _buildTextField('E-Mail', emailController,
                    keyboardType: TextInputType.emailAddress),
              ],
            ),

            const SizedBox(height: 24),

            // ── Tombol Simpan ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        final success = await updateEmailNoHp(
                          context,
                          email: emailController.text.trim(),
                          noHp:  phoneController.text.trim(),
                        );
                        setState(() => isLoading = false);
                        if (success && mounted) Navigator.pop(context, true);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Simpan Perubahan',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section card dengan header ─────────────────────────────────────────────
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
            color: Colors.black.withOpacity(0.06),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.07),
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
          // Konten
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final borderColor = readOnly ? _primary.withOpacity(0.4) : _primary;
    final fillColor   = readOnly ? _fillGreen : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          color: readOnly ? Colors.grey[600] : Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: _primary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          suffixIcon: readOnly
              ? const Icon(Icons.lock_outline, size: 16, color: Colors.grey)
              : null,
          filled: true,
          fillColor: fillColor,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
        ),
      ),
    );
  }
}
