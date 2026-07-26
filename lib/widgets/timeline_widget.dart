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
    final isDitolak = status == 'Ditolak';
    final completedStep = _getCompletedStepIndex(status);

    final steps = [
      'Diajukan',
      'Kadus',
      'Admin',
      'Sekdes',
      'Kades / Selesai',
    ];

    if (isDitolak) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cancel, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pengajuan Ditolak',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (alasanDitolak != null && alasanDitolak!.isNotEmpty) ...[
              const SizedBox(height: 6),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline Progress Surat',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(steps.length, (index) {
              final stepNum = index + 1;
              final isDone = stepNum <= completedStep;
              final isCurrent = stepNum == completedStep;

              Color circleColor = isDone ? const Color(0xFF28A745) : Colors.grey.shade300;
              if (isCurrent && status != 'Selesai') {
                circleColor = const Color(0xFF0057A6);
              }

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (index > 0)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: isDone ? const Color(0xFF28A745) : Colors.grey.shade300,
                            ),
                          ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: circleColor,
                          ),
                          child: Icon(
                            isDone ? Icons.check : Icons.circle,
                            size: 12,
                            color: isDone ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                        if (index < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: (stepNum < completedStep) ? const Color(0xFF28A745) : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isDone ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
