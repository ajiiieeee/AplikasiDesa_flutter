import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/home.dart';
import '../screens/surat.dart';
import '../screens/status.dart';
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
          const KadusSuratMasukScreen(),
          const KadusFormPengajuanScreen(),
        ];
      case 'sekretaris_desa':
        return [
          const SekdesHomeScreen(),
          const SekdesPersetujuanScreen(),
          const SekdesMonitoringPengaduanScreen(),
        ];
      case 'kepala_desa':
        return [
          const KadesHomeScreen(),
          const KadesPersetujuanScreen(),
          const KadesMonitoringPengaduanScreen(),
        ];
      default: // warga
        return [
          const HomeScreen(),
          const SuratScreen(),
          StatusTabScreen(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWarga = widget.role == 'warga';
    bool isKadus = widget.role == 'kepala_dusun';
    bool isSekdes = widget.role == 'sekretaris_desa';
    bool isKades = widget.role == 'kepala_desa';

    int safeIndex = _currentIndex;
    if ((isWarga || isKadus || isSekdes || isKades) && safeIndex > 2) {
      safeIndex = 0;
    }

    List<Map<String, dynamic>> navItems;
    if (isWarga) {
      navItems = [
        {'icon': Icons.home_rounded, 'label': 'Beranda'},
        {'icon': Icons.assignment_outlined, 'label': 'Jenis Surat'},
        {'icon': Icons.analytics_outlined, 'label': 'Tracking'},
      ];
    } else if (isKadus) {
      navItems = [
        {'icon': Icons.home_rounded, 'label': 'Beranda'},
        {'icon': Icons.inbox_rounded, 'label': 'Pengajuan Masuk'},
        {'icon': Icons.edit_note_rounded, 'label': 'Ajukan Surat'},
      ];
    } else if (isSekdes) {
      navItems = [
        {'icon': Icons.home_rounded, 'label': 'Beranda'},
        {'icon': Icons.inbox_rounded, 'label': 'Pengajuan Masuk'},
        {'icon': Icons.campaign_rounded, 'label': 'Pengaduan'},
      ];
    } else {
      // kepala_desa
      navItems = [
        {'icon': Icons.home_rounded, 'label': 'Beranda'},
        {'icon': Icons.inbox_rounded, 'label': 'Pengajuan Masuk'},
        {'icon': Icons.campaign_rounded, 'label': 'Pengaduan'},
      ];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _screens[safeIndex],
      bottomNavigationBar: (isWarga || isKadus || isSekdes || isKades)
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: navItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return _buildCustomNavItem(
                        idx,
                        item['icon'] as IconData,
                        item['label'] as String,
                      );
                    }).toList(),
                  ),
                ),
              ),
            )
          : CurvedNavigationBar(
              backgroundColor: Colors.transparent,
              color: const Color(0xFF0057A6),
              buttonBackgroundColor: const Color(0xFF0057A6),
              height: 60,
              items: const [
                Icon(Icons.dashboard, size: 25, color: Colors.white),
                Icon(Icons.approval, size: 25, color: Colors.white),
                Icon(Icons.forum, size: 25, color: Colors.white),
                Icon(Icons.person, size: 25, color: Colors.white),
              ],
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

  Widget _buildCustomNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    const Color activeColor = Color(0xFF16A34A);
    const Color inactiveColor = Color(0xFF9E9E9E);

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: activeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}