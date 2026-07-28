import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuratTimelineWidget extends StatelessWidget {
  final String status;
  final String? alasanDitolak;

  const SuratTimelineWidget({
    super.key,
    required this.status,
    this.alasanDitolak,
  });

  int _getCompletedStepIndex(String status) {
    switch (status) {
      case 'Diajukan':
        return 1;
      case 'Disetujui Kepala Dusun':
        return 2;
      case 'Disetujui Admin':
        return 3;
      case 'Disetujui Sekretaris Desa':
        return 4;
      case 'Selesai':
        return 5;
      case 'Ditolak':
        return -1;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const secondaryGreen = Color(0xFF4CAF50);
    const greyColor = Color(0xFFBDBDBD);

    final isDitolak = status == 'Ditolak';
    final completedStep = _getCompletedStepIndex(status);

    final List<String> steps = [
      'Diajukan',
      'Disetujui Kepala Dusun',
      'Disetujui Admin',
      'Disetujui Sekretaris Desa',
      'Selesai',
    ];

    if (isDitolak) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Pengajuan Ditolak',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (alasanDitolak != null && alasanDitolak!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Alasan Penolakan: $alasanDitolak',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBE7).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCEDC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, color: primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Timeline Progress Surat',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: List.generate(steps.length, (index) {
              final stepNum = index + 1;
              final isDone = stepNum <= completedStep;
              final isCurrent = stepNum == completedStep;
              final isLast = index == steps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? secondaryGreen : Colors.white,
                          border: Border.all(
                            color: isDone ? primaryGreen : greyColor,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: greyColor,
                                  ),
                                ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 28,
                          color: isDone && (index + 2 <= completedStep)
                              ? secondaryGreen
                              : greyColor.withOpacity(0.5),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[index],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                              color: isDone ? primaryGreen : const Color(0xFF78909C),
                            ),
                          ),
                          if (isCurrent)
                            Text(
                              'Tahap Saat Ini',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: secondaryGreen,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
