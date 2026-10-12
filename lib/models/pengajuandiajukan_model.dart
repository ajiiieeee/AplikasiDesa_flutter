class StatusDiajukanModel {
  final int idPengajuan;
  final String namaSurat;
  final String tanggalDiajukan;
  final String status;
  final String? keperluan;
  final String? keteranganAdmin;
  final String? noRegistrasi;

  StatusDiajukanModel({
    required this.idPengajuan,
    required this.namaSurat,
    required this.tanggalDiajukan,
    required this.status,
    this.keperluan,
    this.keteranganAdmin,
    this.noRegistrasi,
  });

  static String? _cleanString(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty || str == '-' || str == 'null') return null;
    return str;
  }

  factory StatusDiajukanModel.fromJson(Map<String, dynamic> json) {
    return StatusDiajukanModel(
      idPengajuan: int.tryParse(json['id_pengajuan'].toString()) ?? 0,
      namaSurat: json['nama_surat']?.toString() ?? '',
      tanggalDiajukan: json['tanggal_diajukan']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      keperluan: _cleanString(json['keperluan'] ?? json['keterangan']),
      keteranganAdmin: _cleanString(json['keterangan_admin']),
      noRegistrasi: _cleanString(json['no_registrasi']),
    );
  }

  bool get isApprovedByAdmin {
    final s = status.trim().toLowerCase();
    return s == 'disetujui admin' ||
        s == 'disetujui sekretaris desa' ||
        s == 'disetujui sekdes' ||
        s == 'selesai';
  }

  String get keteranganDisplay {
    if (isApprovedByAdmin) {
      if (keteranganAdmin != null && keteranganAdmin!.isNotEmpty && keteranganAdmin != 'null') {
        return keteranganAdmin!;
      }
      return '-';
    }
    return keperluan ?? '-';
  }
}
