import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';

import '../config/globals.dart';
import '../models/detail_berita.dart';

class DetailBerita extends StatefulWidget {
  final String beritaId;

  const DetailBerita({required this.beritaId, Key? key}) : super(key: key);

  @override
  State<DetailBerita> createState() => _DetailBeritaState();
}

class _DetailBeritaState extends State<DetailBerita> {
  Berita? berita;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  String fixLocalhostUrl(String text) {
    return text
        .replaceAll('http://127.0.0.1:8000', serverURL)
        .replaceAll('http://localhost:8000', serverURL);
  }

  String removeImageTagsFromHtml(String html) {
    return html
        // hapus paragraf yang isinya hanya gambar
        .replaceAll(
          RegExp(
            r'<p[^>]*>\s*<img[^>]*>\s*(<br\s*/?>)?\s*</p>',
            caseSensitive: false,
          ),
          '',
        )
        // hapus tag img yang masih tersisa
        .replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '')
        // hapus br kosong
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '');
  }

  String formatTanggal(String tanggal) {
    if (tanggal.isEmpty) return '-';

    try {
      final date = DateTime.parse(tanggal);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      return '$day-$month-$year';
    } catch (e) {
      return tanggal;
    }
  }

  Future<void> fetchDetail() async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/berita/${widget.beritaId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        print('Decoded JSON: $data');

        if (!mounted) return;

        setState(() {
          berita = Berita.fromJson(data);
          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        print('Gagal load detail berita: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      print('Error fetch detail berita: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Detail Berita', style: GoogleFonts.poppins()),
          backgroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (berita == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Detail Berita', style: GoogleFonts.poppins()),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            'Data berita tidak ditemukan',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      );
    }

    final String deskripsiTanpaGambar = removeImageTagsFromHtml(
      fixLocalhostUrl(berita!.deskripsi),
    );

    final String? gambarUtama =
        berita!.gambar != null && berita!.gambar!.isNotEmpty
            ? fixLocalhostUrl(berita!.gambar!)
            : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          berita!.judul.length > 30
              ? '${berita!.judul.substring(0, 30)}...'
              : berita!.judul,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (gambarUtama != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  gambarUtama,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 220,
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: Text(
                        'Gambar gagal dimuat',
                        style: GoogleFonts.poppins(color: Colors.grey[700]),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            Text(
              berita!.judul,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Penulis : ${berita!.nama?.isNotEmpty == true ? berita!.nama : 'Tidak diketahui'}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),

            const SizedBox(height: 8),

            Text(
              formatTanggal(berita!.createdAt),
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),

            const Divider(height: 32),

            Html(
              data: deskripsiTanpaGambar,
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(16),
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  lineHeight: const LineHeight(1.6),
                  textAlign: TextAlign.justify,
                ),
                "p": Style(margin: Margins.only(bottom: 12)),
              },
            ),
          ],
        ),
      ),
    );
  }
}
