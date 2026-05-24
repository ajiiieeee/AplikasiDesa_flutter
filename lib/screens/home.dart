import 'package:digitalv/screens/info_profile.dart';
import 'package:digitalv/screens/notifikasi.dart';
import 'package:flutter/material.dart';
import 'package:digitalv/screens/pengaduan.dart';
import 'package:digitalv/screens/form_pengajuan.dart';
import 'package:digitalv/screens/info_berita.dart';
import 'package:digitalv/screens/detail_berita.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digitalv/models/detail_berita.dart';
import 'package:digitalv/screens/chatbot_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/globals.dart';
import '../controllers/ProfileController.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool _isNavigating = false;
  String namaUser = 'User'; // Default
  String _fotoProfil = '';

 @override
  void initState() {
    super.initState();
    _refreshProfile();
    fetchLayanan();
  }

  Future<void> fetchLayanan() async {
    try {
      final response = await http.get(Uri.parse('$baseURL/surat'));

      if (response.statusCode == 200) {
        setState(() {
          layanan = jsonDecode(response.body);
          isLoadingLayanan = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // List layanan (menu utama)
  List<dynamic> layanan = [];
  bool isLoadingLayanan = true;


  // Fungsi untuk ambil daftar berita dari API
  Future<List<Berita>> fetchBeritaList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/berita'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Berita.fromJson(json)).toList();
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

  // Untuk membuat warna lebih soft
  Color tintColor(Color baseColor) {
    return Color.lerp(baseColor, Colors.white, 0.7)!;
  }

  Future<void> _refreshProfile() async {
    await getProfilFromApi(
      context,
    ); 
    await _loadUserData(); 
  }

  // Mengambil data nama dan foto dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final nama = prefs.getString('nama_lengkap') ?? 'User';
    final fotoProfil = prefs.getString('foto_profil') ?? '';

    String fotoProfilUrl = '';

    if (fotoProfil.isNotEmpty) {
      if (fotoProfil.startsWith('http')) {
        fotoProfilUrl = fotoProfil.replaceFirst('/api/storage/', '/storage/');
      } else {
        final cleanPath =
            fotoProfil.startsWith('/') ? fotoProfil.substring(1) : fotoProfil;

        fotoProfilUrl = '$serverURL/$cleanPath';
      }
    }

    await prefs.setString('foto_profil', fotoProfilUrl);

    if (!mounted) return;

    setState(() {
      namaUser = nama;
      _fotoProfil = fotoProfilUrl;
    });

    print('===== Data Profil dari SharedPreferences =====');
    print('Nama: $namaUser');
    print('Foto Profil: $_fotoProfil');
  }

  // Menyimpan data nama pengguna (misalnya setelah login)
  void _saveUserData(String nama) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('nama', nama);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.white,
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 45),
                decoration: const BoxDecoration(
                  color: Color(0xFF0057A6),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang,',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$namaUser 👋',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Notification Icon
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen() ,
                            ),
                          );
                        },
                          child: Stack(
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Profile Photo
                    Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InfoProfile(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              _image != null
                                  ? FileImage(_image!)
                                  : NetworkImage(
                                        _fotoProfil.isNotEmpty
                                            ? _fotoProfil
                                            : '$serverURL/storage/foto_profil/default.jpg',
                                      )
                                      as ImageProvider,
                        ),
                              ),
                            ),
                          ],
                        ),
                      ),

              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                
                padding: const EdgeInsets.all(20),
                
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaduan!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lakukan pengaduan jika anda memiliki keluhan, saran, atau masukan. Silakan sampaikan melalui laman ini untuk kami tindak lanjuti.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Pengaduan(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Klik Disini"),
              ),
            ),
          ],
        ),
      ),
    ),

    const SizedBox(width: 10),

    GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatbotScreen(),
          ),
        );
      },
      child: Column(
        children: [
          Image.asset(
            'assets/images/devi.png',
            width: 85,
          ),
          const SizedBox(height: 4),
          Text(
            "Tanya Devi",
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  ],
),
                    const SizedBox(height: 15),
                     Text(
                      'Kategori Layanan',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding:
                          EdgeInsets
                              .zero, // Menghilangkan padding default dari GridView
                      itemCount: layanan.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                     itemBuilder: (context, index) {
                        final item = layanan[index];

                        final List<Color> colors = [
                          const Color(0xFF1976D2),
                          const Color(0xFF388E3C),
                          const Color(0xFFFF9307),
                          const Color(0xFF6A1B9A),
                          const Color(0xFFA70011),
                        ];

                        final Color baseColor = colors[index % colors.length];

                        final backgroundColor = tintColor(baseColor);

                        return GestureDetector(
                          onTap: () async {
                            if (_isNavigating) return;

                            _isNavigating = true;

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                       FormPengajuan(
                                      idSurat: item['id_surat'],
                                    )
                              ),
                            );

                            _isNavigating = false;
                          },

                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.description,
                                  color: baseColor,
                                  size: 28,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                item['nama_surat'],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                   
                  Padding(
                    padding: const EdgeInsets.only(left: 0, right: 0, top: 15), // Hapus padding top
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          'Berita Terkini',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InfoBerita(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, 
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            children: const [
                              Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 5),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 15,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                   const SizedBox(height: 20),
                    SizedBox(
                        height: 170,
                        child: FutureBuilder<List<Berita>>(
                          future: fetchBeritaList(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return const Center(child: Text('Gagal memuat berita'));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(child: Text('Tidak ada berita'));
                            }

                            final beritaList = snapshot.data!;

                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: beritaList.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final item = beritaList[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailBerita(beritaId: item.idberita),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      children: [
                                        item.gambarUtama.isNotEmpty
                                          ? Image.network(
                                            item.gambarUtama,
                                            height: 170,
                                            width: 250,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                height: 170,
                                                width: 250,
                                                color: Colors.grey,
                                                child: const Center(
                                                  child: Text(
                                                    'Gambar gagal dimuat',
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                          : Container(
                                            height: 170,
                                            width: 250,
                                            color: Colors.grey,
                                            child: const Center(
                                              child: Text('No Image'),
                                            ),
                                          ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          height: 60,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black87,
                                                  Color.fromARGB(221, 64, 64, 64),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 10,
                                          left: 10,
                                          right: 10,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.judul,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.createdAt,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

