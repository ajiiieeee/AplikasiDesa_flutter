class StatusSelesaiModel {
  final int idPengajuan;
  final String namaSurat;
  final String updatedAt;
  final String status;
  final String? filePdf; // nullable: URL PDF dari backend

  StatusSelesaiModel({
    required this.idPengajuan,
    required this.namaSurat,
    required this.updatedAt,
    required this.status,
    this.filePdf,
  });

  factory StatusSelesaiModel.fromJson(Map<String, dynamic> json) {
    return StatusSelesaiModel(
      idPengajuan: int.tryParse(json['id_pengajuan']?.toString() ?? '0') ?? 0,
      namaSurat: json['nama_surat']?.toString() ?? 'Tidak diketahui',
      updatedAt: json['updated_at']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'Selesai',
      filePdf: json['file_pdf_url']?.toString(), // key yang benar dari backend
    );
  }
}
