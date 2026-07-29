import 'package:digitalv/screens/detail_notifikasi.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/globals.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:digitalv/widgets/snackbarcustom.dart';
import 'package:digitalv/widgets/bottom_navbar.dart';


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages()); // set locale id
    fetchLatestNotifikasi();
  }

  Future<void> fetchLatestNotifikasi() async {
    final prefs = await SharedPreferences.getInstance();
    final nik = prefs.getString('nik') ?? '';
    final token = prefs.getString('token') ?? '';

    if (nik.isEmpty) {
      print('NIK tidak ditemukan di SharedPreferences');
      setState(() => isLoading = false);
      return; // <-- penting agar keluar dari fungsi
    }

    final authHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(
        Uri.parse('$baseURL/notifikasi?nik=$nik'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pengajuanList = data['pengajuan'] as List<dynamic>?;
        final pengaduanList = data['pengaduan'] as List<dynamic>?;

        final List<Map<String, dynamic>> fetched = [];

        if (pengajuanList != null) {
          for (var item in pengajuanList) {
            final rawTime = item['created_at'];
            final localTime = DateTime.parse(rawTime).toLocal();
            final now = DateTime.now();
            final diffSeconds = now.difference(localTime).inSeconds;

            fetched.add({
              'title': 'Notifikasi Pengajuan',
              'message': item['pesan'],
              'time': rawTime,
            });
          }
        }

        if (pengaduanList != null) {
          for (var item in pengaduanList) {
            final rawTime = item['created_at'];
            final localTime = DateTime.parse(rawTime).toLocal();
            final now = DateTime.now();
            final diffSeconds = now.difference(localTime).inSeconds;

            print('ID Ref Pengaduan: ${item['id_ref']}');

            fetched.add({
              'title': 'Notifikasi Pengaduan',
              'message': item['pesan'],
              'time': rawTime,
              'id_ref': item['id_ref'], 
            });


          }
        }

        // Sort berdasarkan waktu terbaru
        fetched.sort((a, b) => b['time'].compareTo(a['time']));

        setState(() {
          notifications = fetched;
          isLoading = false;
        });
      } else {
        print('Gagal mengambil notifikasi (${response.statusCode})');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Text(
              'NOTIFIKASI',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0057A6),
          foregroundColor: Colors.white,
          leading: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
              ? Center(
                child: Text(
                  'Tidak ada notifikasi',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: notifications.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final isPengajuan = notif['title'] == 'Notifikasi Pengajuan';

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: Card(
                      color: Colors.white,
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                       onTap: () {
                          if (notif['title'] == 'Notifikasi Pengaduan' &&
                              notif['id_ref'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => DetailPengaduanScreen(
                                      idPengaduan:
                                          (notif['id_ref'] is int)
                                              ? notif['id_ref']
                                              : int.parse(
                                                notif['id_ref'].toString(),
                                              ),
                                    ),
                              ),
                            );
                          } else if (notif['title'] == 'Notifikasi Pengajuan') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const BottomNavBar(initialIndex: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ID notifikasi tidak ditemukan'),
                              ),
                            );
                          }
                        },

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              isPengajuan
                                  ? const Color(0xFF2196F3)
                                  : const Color(0xFFFF9800),
                          child: Icon(
                            isPengajuan
                                ? Icons.mark_email_read
                                : Icons.campaign,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          notif['title'] ?? '',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['message'] ?? '',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 13,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notif['time'] != null
                                      ? timeago.format(
                                        DateTime.parse(notif['time']).toLocal(),
                                        locale: 'id',
                                      )
                                      : '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }


}
