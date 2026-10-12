class StatusSelesaiModel {
  final int idPengajuan;
  final String namaSurat;
  final String updatedAt;
  final String status;
  final String? nomorSurat;
  final String? filePdf; // nullable: URL PDF dari backend
  final String? keperluan;
  final String? keteranganAdmin;

  StatusSelesaiModel({
    required this.idPengajuan,
    required this.namaSurat,
    required this.updatedAt,
    required this.status,
    this.nomorSurat,
    this.filePdf,
    this.keperluan,
    this.keteranganAdmin,
  });

  /// Karena surat yang selesai pasti sudah melewati persetujuan admin,
  /// keterangan yang digunakan adalah keterangan_admin.
  /// Jika kosong/null, tampilkan '-' dan jangan kembali ke keperluan.
  String get keteranganDisplay {
    if (keteranganAdmin != null && keteranganAdmin!.trim().isNotEmpty && keteranganAdmin != 'null') {
      return keteranganAdmin!.trim();
    }
    return '-';
  }

  factory StatusSelesaiModel.fromJson(Map<String, dynamic> json) {
    final rawAdmin = json['keterangan_admin'] ?? json['master_keterangan_admin'];
    final cleanAdmin = (rawAdmin != null && rawAdmin.toString().trim().isNotEmpty && rawAdmin.toString() != 'null')
        ? rawAdmin.toString().trim()
        : null;
    final rawKeperluan = json['keperluan'];
    final cleanKeperluan = (rawKeperluan != null && rawKeperluan.toString().trim().isNotEmpty && rawKeperluan.toString() != 'null')
        ? rawKeperluan.toString().trim()
        : null;

    return StatusSelesaiModel(
      idPengajuan: int.tryParse(json['id_pengajuan']?.toString() ?? '0') ?? 0,
      namaSurat: json['nama_surat']?.toString() ?? 'Tidak diketahui',
      updatedAt: json['updated_at']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'Selesai',
      nomorSurat: json['nomor_surat_keluar']?.toString() ?? json['no_registrasi']?.toString(),
      filePdf: json['file_pdf_url']?.toString() ?? json['file_pdf']?.toString(),
      keperluan: cleanKeperluan,
      keteranganAdmin: cleanAdmin,
    );
  }
}
