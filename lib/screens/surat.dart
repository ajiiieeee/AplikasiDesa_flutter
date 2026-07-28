import 'dart:convert';
import 'package:digitalv/config/globals.dart';
import 'package:digitalv/screens/form_pengajuan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class SuratScreen extends StatefulWidget {
  const SuratScreen({super.key});

  @override
  State<SuratScreen> createState() => _SuratScreenState();
}

class _SuratScreenState extends State<SuratScreen> {
  List<dynamic> suratList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSurat();
  }

  Future<void> fetchSurat() async {
    try {
      final response = await http.get(Uri.parse('$baseURL/surat'));

      if (response.statusCode == 200) {
        setState(() {
          suratList = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
            'JENIS LAYANAN SURAT',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            )
          : suratList.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada layanan surat tersedia',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: suratList.length,
                  itemBuilder: (context, index) {
                    final surat = suratList[index];
                    return _buildSuratCard(surat, primaryGreen);
                  },
                ),
    );
  }

  Widget _buildSuratCard(Map<String, dynamic> surat, Color primaryGreen) {
    final String namaSurat = surat['nama_surat'] ?? 'Nama Surat';
    final String deskripsi = surat['persyaratan'] ?? surat['slug'] ?? 'Persyaratan pengajuan surat desa.';
    final int idSurat = surat['id_surat'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFECEFF1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FormPengajuan(idSurat: idSurat.toString()),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaSurat,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deskripsi,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF546E7A),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Ajukan Surat',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: primaryGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
