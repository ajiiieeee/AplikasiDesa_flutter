class StatusDitolakModel {
  final int idPengajuan;
  final String namaSurat;
  final String status;
  final String keteranganDitolak;
  final String updatedAt;

  StatusDitolakModel({
    required this.idPengajuan,
    required this.namaSurat,
    required this.status,
    required this.keteranganDitolak,
    required this.updatedAt,
  });

  factory StatusDitolakModel.fromJson(Map<String, dynamic> json) {
    return StatusDitolakModel(
      idPengajuan: int.tryParse(json['id_pengajuan']?.toString() ?? '0') ?? 0,
      namaSurat: json['nama_surat']?.toString() ?? 'Tidak diketahui',
      status: json['status']?.toString() ?? 'Ditolak',
      keteranganDitolak: json['keterangan_ditolak']?.toString() ?? 'Tidak ada keterangan',
      updatedAt: json['updated_at']?.toString() ?? '-',
    );
  }
}
