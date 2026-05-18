import 'dart:convert';

import 'package:digitalv/config/globals.dart';
import 'package:digitalv/screens/form_pengajuan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class SuratScreen extends StatefulWidget {
  const SuratScreen({super.key});

  @override
  State<SuratScreen> createState() => _SuratScreenState();
}

class _SuratScreenState extends State<SuratScreen> {
  final TextStyle titleStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  final List<Color> buttonColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  final TextStyle descStyle = const TextStyle(
    fontSize: 12,
    color: Colors.grey,
    fontWeight: FontWeight.w400,
  );

  final TextStyle btnTextStyle = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );

  final double spacingBetweenTitleAndDesc = 6;

  List<dynamic> suratList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSurat();
  }

  Future<void> fetchSurat() async {
    try {
      final response = await http.get(Uri.parse('$baseURL/surat'));

      if (response.statusCode == 200) {
        setState(() {
          suratList = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'LAYANAN SURAT',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0057A6),
          ),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.25),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3 / 2.5,

                  children: List.generate(suratList.length, (index) {
                    final surat = suratList[index];

                    return buildCard(
                      title: surat['nama_surat'] ?? '',
                      desc: surat['slug'] ?? '',
                      btnText: 'Ajukan',
                      btnColor: buttonColors[index % buttonColors.length]
                          .withOpacity(0.15),
                      btnTextColor: buttonColors[index % buttonColors.length],
                      btnIcon: Icons.edit,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => FormPengajuan(idSurat: surat['id_surat'])
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
    );
  }

  Widget buildCard({
    required String title,
    required String desc,
    required String btnText,
    required Color btnColor,
    required Color btnTextColor,
    required IconData btnIcon,
    VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: titleStyle)),
              Icon(Icons.chevron_right, color: btnTextColor),
            ],
          ),

          SizedBox(height: spacingBetweenTitleAndDesc),

          Text(desc, style: descStyle),

          const Spacer(),

          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(btnIcon, size: 16, color: btnTextColor),
              label: Text(btnText, style: btnTextStyle),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: btnColor,
                foregroundColor: btnTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: btnTextColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
