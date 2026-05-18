import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

import '../config/globals.dart';
import '../models/detail_berita.dart';

class DetailBerita extends StatefulWidget {
  final String beritaId;

  const DetailBerita({required this.beritaId, Key? key}) : super(key: key);

  @override
  _DetailBeritaState createState() => _DetailBeritaState();
}

class _DetailBeritaState extends State<DetailBerita> {
  Berita? berita;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
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
        setState(() {
          berita = Berita.fromJson(data);
          isLoading = false;
        });
       
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load detail berita');
      }
    } catch (e) {
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
        appBar: AppBar(
          title: Text('Detail Berita', style: GoogleFonts.poppins()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (berita == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Detail Berita', style: GoogleFonts.poppins()),
        ),
        body: Center(
          child: Text(
            'Data berita tidak ditemukan',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
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
            if (berita!.gambar != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(berita!.gambar!, fit: BoxFit.cover),
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
              berita!.createdAt,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const Divider(height: 32,),

            ...berita!.deskripsi
                .split('. ')
                .map(
                  (kalimat) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: SelectableText(
                      '${kalimat.trim()}.',
                      style: GoogleFonts.poppins(fontSize: 16, height: 1.6),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
