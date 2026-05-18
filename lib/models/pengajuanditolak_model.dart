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
      idPengajuan: int.tryParse(json['id_pengajuan'].toString()) ?? 0,
      namaSurat: json['nama_surat'],
      status: json['status'],
      keteranganDitolak: json['keterangan_ditolak'],
      updatedAt: json['updated_at'],
    );
  }

  // Map<String, dynamic> toJson() {
  //   return {
  //     'id_pengajuan': idPengajuan,
  //     'nama_surat': namaSurat,
  //     'status': status,
  //     'keterangan_ditolak': keteranganDitolak,
  //     'updated_at': updatedAt,
  //   };
  // }
}
