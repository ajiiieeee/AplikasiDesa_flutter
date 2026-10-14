import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/globals.dart';

class DetailPengaduanScreen extends StatefulWidget {
  final int idPengaduan;

  const DetailPengaduanScreen({super.key, required this.idPengaduan});

  @override
  State<DetailPengaduanScreen> createState() => _DetailPengaduanScreenState();
}

class _DetailPengaduanScreenState extends State<DetailPengaduanScreen> {
  // ── Tema ────────────────────────────────────────────────
  static const _primaryGreen  = Color(0xFF2E7D32);
  static const _primaryGreenL = Color(0xFF43A047);
  static const _bgColor       = Color(0xFFF5F7FA);

  // ── State ────────────────────────────────────────────────
  bool isLoading = true;
  Map<String, dynamic>? pengaduan;
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    fetchDetailPengaduan();
  }

  // ── Data Fetching ─────────────────────────────────────────
  Future<void> fetchDetailPengaduan() async {
    setState(() {
      isLoading = true;
      errorMsg  = '';
    });

    final url = Uri.parse('$baseURL/notifikasi/${widget.idPengaduan}');

    try {
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          pengaduan = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMsg  = 'Gagal mengambil data (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMsg  = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  String getFotoUrl(String fotoPath) {
    if (fotoPath.startsWith('http')) return fotoPath;
    final serverRoot = baseURL.replaceAll(RegExp(r'/api.*$'), '');
    return '$serverRoot/storage/$fotoPath';
  }

  // ── Avatars ───────────────────────────────────────────────
  Widget _buildUserAvatar() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        shape: BoxShape.circle,
      ),
      child: const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
        child: Icon(Icons.person_rounded, color: _primaryGreen, size: 22),
      ),
    );
  }

  Widget _buildAdminAvatar() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        shape: BoxShape.circle,
      ),
      child: const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
        child: Icon(Icons.support_agent_rounded, color: _primaryGreen, size: 23),
      ),
    );
  }

  // ── Chat Bubbles ──────────────────────────────────────────
  Widget _buildUserBubble() {
    final String ulasan = pengaduan?['ulasan'] ?? 'Tidak ada pesan';
    final String? foto  = pengaduan?['foto1']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 5),
                  child: Text(
                    'Anda',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryGreen, _primaryGreenL],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withValues(alpha: 0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ulasan,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          height: 1.45,
                          color: Colors.white,
                        ),
                      ),
                      if (foto != null && foto.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            getFotoUrl(foto),
                            width: MediaQuery.of(context).size.width * 0.65,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: MediaQuery.of(context).size.width * 0.65,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.white,
                                  size: 42,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAdminBubble() {
    final String feedback = pengaduan?['feedback'] ?? 'Belum ada tanggapan';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAdminAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 5),
                  child: Text(
                    'Admin Desa',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: const Color(0xFFE8F5E9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.reply_rounded,
                        color: _primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feedback,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            height: 1.45,
                            color: Colors.black87,
                          ),
                        ),
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
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: _primaryGreen, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Detail percakapan pengaduan masyarakat dengan Admin Desa.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF2E7D32),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: _primaryGreen,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 42, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: fetchDetailPengaduan,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 26, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryGreen, _primaryGreenL],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Pengaduan',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Percakapan dengan Admin Desa',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: isLoading
          ? _buildLoading()
          : errorMsg.isNotEmpty
              ? _buildError(errorMsg)
              : pengaduan == null
                  ? _buildError('Data tidak ditemukan')
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInfoBanner(),
                          _buildUserBubble(),
                          _buildAdminBubble(),
                        ],
                      ),
                    ),
    );
  }
}
