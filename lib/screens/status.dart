import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/my_tab_controller.dart';
import '../status/diajukan.dart';
import '../status/selesai.dart';
import '../status/ditolak.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusTabScreen extends StatelessWidget {
  StatusTabScreen({super.key});

  final MyTabController controller = Get.put(MyTabController());

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
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
            "TRACKING SURAT",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              letterSpacing: 0.5,
            ),
          ),
        ),
        bottom: TabBar(
          controller: controller.tabController,
          indicatorColor: primaryGreen,
          indicatorWeight: 3,
          labelColor: primaryGreen,
          unselectedLabelColor: const Color(0xFF78909C),
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: "Sedang Diproses"),
            Tab(text: "Selesai"),
            Tab(text: "Ditolak"),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: const [
          PengajuanView(),
          DisetujuiView(),
          DitolakView(),
        ],
      ),
    );
  }
}
