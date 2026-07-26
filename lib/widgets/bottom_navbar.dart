import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../screens/home.dart';
import '../screens/surat.dart';
import '../screens/status.dart';
import '../screens/profile.dart';
import '../screens/pengaduan.dart';
// Kepala Dusun
import '../screens/kadus/kadus_home.dart';
import '../screens/kadus/kadus_surat_masuk.dart';
import '../screens/kadus/kadus_form_pengajuan.dart';
// Sekretaris Desa
import '../screens/sekdes/sekdes_home.dart';
import '../screens/sekdes/sekdes_persetujuan.dart';
import '../screens/sekdes/sekdes_monitoring_pengaduan.dart';
// Kepala Desa
import '../screens/kades/kades_home.dart';
import '../screens/kades/kades_persetujuan.dart';
import '../screens/kades/kades_monitoring_pengaduan.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;
  final String role;

  const BottomNavBar({
    super.key,
    this.initialIndex = 0,
    this.role = 'warga',
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> get _screens {
    switch (widget.role) {
      case 'kepala_dusun':
        return [
          const KadusHomeScreen(),
          const KadusFormPengajuanScreen(),
          const KadusSuratMasukScreen(),
          const ProfileScreen(),
        ];
      case 'sekretaris_desa':
        return [
          const SekdesHomeScreen(),
          const SekdesPersetujuanScreen(),
          const SekdesMonitoringPengaduanScreen(),
          const ProfileScreen(),
        ];
      case 'kepala_desa':
        return [
          const KadesHomeScreen(),
          const KadesPersetujuanScreen(),
          const KadesMonitoringPengaduanScreen(),
          const ProfileScreen(),
        ];
      default: // warga (5 items: Dashboard, Jenis Surat, Tracking, Pengaduan, Profil)
        return [
          const HomeScreen(),
          const SuratScreen(),
          StatusTabScreen(),
          const Pengaduan(),
          const ProfileScreen(),
        ];
    }
  }

  List<Widget> get _items {
    switch (widget.role) {
      case 'kepala_dusun':
        return const [
          Icon(Icons.dashboard, size: 25, color: Colors.white),
          Icon(Icons.edit_document, size: 25, color: Colors.white),
          Icon(Icons.inbox, size: 25, color: Colors.white),
          Icon(Icons.person, size: 25, color: Colors.white),
        ];
      case 'sekretaris_desa':
      case 'kepala_desa':
        return const [
          Icon(Icons.dashboard, size: 25, color: Colors.white),
          Icon(Icons.approval, size: 25, color: Colors.white),
          Icon(Icons.forum, size: 25, color: Colors.white),
          Icon(Icons.person, size: 25, color: Colors.white),
        ];
      default: // warga
        return const [
          Icon(Icons.home, size: 24, color: Colors.white),
          Icon(Icons.mail, size: 24, color: Colors.white),
          Icon(Icons.history, size: 24, color: Colors.white),
          Icon(Icons.campaign, size: 24, color: Colors.white),
          Icon(Icons.person, size: 24, color: Colors.white),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: const Color(0xFF0057A6),
        buttonBackgroundColor: const Color(0xFF0057A6),
        height: 60,
        items: _items,
        index: _currentIndex,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}