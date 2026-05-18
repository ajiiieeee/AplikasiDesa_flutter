class StatusDiajukanModel {
  final int idPengajuan;
  final String namaSurat;
  final String tanggalDiajukan;
  final String status;

  StatusDiajukanModel({
    required this.idPengajuan,
    required this.namaSurat,
    required this.tanggalDiajukan,
    required this.status,
  });

  factory StatusDiajukanModel.fromJson(Map<String, dynamic> json) {
    return StatusDiajukanModel(
      idPengajuan: int.tryParse(json['id_pengajuan'].toString()) ?? 0,
      namaSurat: json['nama_surat']?.toString() ?? '',
      tanggalDiajukan: json['tanggal_diajukan']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}
