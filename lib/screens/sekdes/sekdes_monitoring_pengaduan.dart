import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/globals.dart';
import '../../models/pengaduan_model.dart';

class SekdesMonitoringPengaduanScreen extends StatefulWidget {
  const SekdesMonitoringPengaduanScreen({super.key});

  @override
  State<SekdesMonitoringPengaduanScreen> createState() => _SekdesMonitoringPengaduanScreenState();
}

class _SekdesMonitoringPengaduanScreenState extends State<SekdesMonitoringPengaduanScreen> {
  late Future<List<PengaduanModel>> _futurePengaduan;

  @override
  void initState() {
    super.initState();
    _futurePengaduan = _fetchPengaduan();
  }

  Future<List<PengaduanModel>> _fetchPengaduan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseURL/sekdes/pengaduan'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] ?? [];
      return data.map((item) => PengaduanModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat data pengaduan masyarakat');
    }
  }

  void _showDetailPengaduan(PengaduanModel item) {
    const primaryGreen = Color(0xFF16A34A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Detail Pengaduan Warga',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _detailRow('Nama Warga', '${item.namaPemohon} (${item.nik})'),
                  _detailRow('Kategori', item.kategori),
                  _detailRow('Tanggal', item.createdAt.isNotEmpty ? item.createdAt : 'Baru Saja'),
                  _detailRow('Status Response', item.isResponded ? 'Sudah Ditanggapi Admin' : 'Belum Ditanggapi'),

                  const SizedBox(height: 12),
                  Text(
                    'Isi Laporan Pengaduan:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF263238)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFECEFF1)),
                    ),
                    child: Text(
                      item.ulasan,
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF37474F), height: 1.4),
                    ),
                  ),

                  if (item.fotoUrl != null && item.fotoUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Foto Bukti Pengaduan:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF263238)),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        item.fotoUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    'Tanggapan / Feedback Admin Desa:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF263238)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: item.isResponded ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: item.isResponded ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80)),
                    ),
                    child: Text(
                      (item.feedbackAdmin != null && item.feedbackAdmin!.isNotEmpty)
                          ? item.feedbackAdmin!
                          : 'Belum ada tanggapan resmi dari Admin Desa.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: item.isResponded ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Tutup',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF263238),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF16A34A);
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
            'MONITORING PENGADUAN (SEKDES)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: () async {
          setState(() {
            _futurePengaduan = _fetchPengaduan();
          });
        },
        child: FutureBuilder<List<PengaduanModel>>(
          future: _futurePengaduan,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryGreen));
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Gagal memuat data: ${snapshot.error}",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      "Belum Ada Pengaduan Masyarakat",
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final items = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final bool isResponded = item.isResponded;

                return GestureDetector(
                  onTap: () => _showDetailPengaduan(item),
                  child: Container(
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.kategori,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isResponded ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isResponded ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80)),
                                ),
                                child: Text(
                                  isResponded ? 'Sudah Ditanggapi' : 'Belum Ditanggapi',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isResponded ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Text(
                            item.namaPemohon,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF263238),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            item.ulasan,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF546E7A), height: 1.4),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.createdAt.isNotEmpty ? item.createdAt : 'Tanggal Baru',
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Lihat Detail',
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: primaryGreen),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
