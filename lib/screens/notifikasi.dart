import 'package:digitalv/screens/detail_notifikasi.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/globals.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:digitalv/widgets/bottom_navbar.dart';
import '../services/secure_storage_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  // ── Tema ────────────────────────────────────────────────
  static const _primaryGreen   = Color(0xFF2E7D32);
  static const _primaryGreenL  = Color(0xFF43A047);
  static const _bgGrey         = Color(0xFFF5F7FA);
  static const _cardBg         = Colors.white;

  // ── State ────────────────────────────────────────────────
  bool isLoading = true;
  List<Map<String, dynamic>> notifications = [];
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    fetchLatestNotifikasi();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Data Fetching ─────────────────────────────────────────
  Future<void> fetchLatestNotifikasi() async {
    setState(() => isLoading = true);

    final nik   = await SecureStorageService.instance.getNik()   ?? '';
    final token = await SecureStorageService.instance.getToken() ?? '';

    if (nik.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept'      : 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(
        Uri.parse('$baseURL/notifikasi?nik=$nik'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data          = json.decode(response.body);
        final pengajuanList = data['pengajuan'] as List<dynamic>? ?? [];
        final pengaduanList = data['pengaduan'] as List<dynamic>? ?? [];

        final List<Map<String, dynamic>> fetched = [];

        for (var item in pengajuanList) {
          fetched.add({
            'title'  : 'Notifikasi Pengajuan',
            'message': item['pesan'],
            'time'   : item['created_at'],
          });
        }

        for (var item in pengaduanList) {
          fetched.add({
            'title'  : 'Notifikasi Pengaduan',
            'message': item['pesan'],
            'time'   : item['created_at'],
            'id_ref' : item['id_ref'],
          });
        }

        fetched.sort((a, b) => b['time'].compareTo(a['time']));

        setState(() {
          notifications = fetched;
          isLoading     = false;
        });
        _fadeCtrl.forward(from: 0);
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  void _onTapNotif(Map<String, dynamic> notif) {
    if (notif['title'] == 'Notifikasi Pengaduan' && notif['id_ref'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailPengaduanScreen(
            idPengaduan: (notif['id_ref'] is int)
                ? notif['id_ref']
                : int.parse(notif['id_ref'].toString()),
          ),
        ),
      );
    } else if (notif['title'] == 'Notifikasi Pengajuan') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavBar(initialIndex: 2)),
      );
    }
  }

  // ── Widgets ───────────────────────────────────────────────
  Widget _buildNotifCard(Map<String, dynamic> notif, int index) {
    final isPengajuan = notif['title'] == 'Notifikasi Pengajuan';

    // Ikon & warna aksen per kategori — tetap dalam palet hijau
    final iconData  = isPengajuan ? Icons.mark_email_read_rounded : Icons.campaign_rounded;
    final accentColor = isPengajuan
        ? _primaryGreen
        : const Color(0xFF388E3C); // hijau sedikit lebih gelap untuk pengaduan

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.08 * (index + 1)),
          end: Offset.zero,
        ).animate(_fadeAnim),
        child: GestureDetector(
          onTap: () => _onTapNotif(notif),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8F5E9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aksen vertikal kiri
                Container(
                  width: 5,
                  height: double.infinity,
                  constraints: const BoxConstraints(minHeight: 80),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),
                // Icon bulat
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 10, 16),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: accentColor, size: 24),
                  ),
                ),
                // Konten teks
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge kategori
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            notif['title'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Pesan
                        Text(
                          notif['message'] ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF37474F),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Waktu
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 13, color: Colors.grey[500]),
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
                                color: Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            // Tombol lihat detail
                            Row(
                              children: [
                                Text(
                                  'Lihat',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    size: 16, color: accentColor),
                              ],
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
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 44,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Belum Ada Notifikasi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifikasi terbaru akan muncul di sini',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchLatestNotifikasi,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Muat Ulang',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
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

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryGreen, _primaryGreenL],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              const Icon(Icons.notifications_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'NOTIFIKASI',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 22),
              onPressed: fetchLatestNotifikasi,
              tooltip: 'Muat ulang',
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: isLoading
          ? _buildLoading()
          : notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: _primaryGreen,
                  onRefresh: fetchLatestNotifikasi,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) =>
                        _buildNotifCard(notifications[index], index),
                  ),
                ),
    );
  }
}
