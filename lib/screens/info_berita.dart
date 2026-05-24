import 'package:digitalv/config/globals.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:digitalv/models/detail_berita.dart';
import 'detail_berita.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoBerita extends StatefulWidget {
  @override
  _InfoBeritaState createState() => _InfoBeritaState();
}

class _InfoBeritaState extends State<InfoBerita> {
  List<dynamic> beritaList = [];
  List<dynamic> filteredBeritaList = [];
  TextEditingController searchController = TextEditingController();

  String fixImageUrl(String url) {
    return url
        .replaceAll('http://127.0.0.1:8000', serverURL)
        .replaceAll('http://localhost:8000', serverURL);
  }

  String getImageFromDeskripsi(String html) {
    final regex = RegExp(
      r'''<img[^>]+src=["']([^"']+)["']''',
      caseSensitive: false,
    );

    final match = regex.firstMatch(html);

    if (match != null) {
      return fixImageUrl(match.group(1)!);
    }

    return '';
  }

  @override
  void initState() {
    super.initState();
    fetchBeritaList();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchBeritaList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/berita'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          beritaList = data;
          filteredBeritaList = data; 
        });
      } else {
        print(
          'Request failed\nStatus: ${response.statusCode}\nBody: ${response.body}',
        );
        throw Exception(
          'Gagal memuat data berita. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Exception saat mengambil data berita: $e');
      throw Exception('Terjadi kesalahan saat memuat data berita');
    }
  }

  void _onSearchChanged() {
    String searchText = searchController.text.toLowerCase();

    setState(() {
      if (searchText.isEmpty) {
        filteredBeritaList = beritaList; 
      } else {
        filteredBeritaList =
            beritaList.where((berita) {
              String judul = berita['judul']?.toString().toLowerCase() ?? '';
              return judul.contains(searchText);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Info Berita',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: const Color(0xFF0057A6),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari berita...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 15,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFFFFFFF), 
              ),
              child:
                  filteredBeritaList.isEmpty
                      ? Center(
                        child: Text(
                          'Tidak ada berita ditemukan',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                      : ListView.builder(
                        itemCount: filteredBeritaList.length,
                        itemBuilder: (context, index) {
                          final berita = filteredBeritaList[index];

                          final imageUrl = getImageFromDeskripsi(
                            berita['deskripsi'] ?? '',
                          );

                          print('URL gambar berita: $imageUrl');

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Card(
                              color:
                                  Colors
                                      .white, 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => DetailBerita(
                                            beritaId: berita['idberita'],
                                          ),
                                    ),
                                  );
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                      child:
                                      imageUrl.isNotEmpty
                                              ? Image.network(
                                                imageUrl,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  print(
                                                    'Gagal load gambar: $imageUrl',
                                                  );
                                                  print(error);

                                                  return Container(
                                                    width: 100,
                                                    height: 100,
                                                    color: Colors.grey[300],
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 40,
                                                      color: Colors.grey[600],
                                                    ),
                                                  );
                                                },
                                              )
                                              : Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[300],
                                                child: Icon(
                                                  Icons.image,
                                                  size: 40,
                                                  color: Colors.grey[600],
                                                ),
                                              )
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              berita['judul'] ??
                                                  'Judul tidak tersedia',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  berita['created_at'] ??
                                                      'Tanggal tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
