class StatusSelesaiModel {
  final int idPengajuan;
  final String namaSurat;
  final String updatedAt;
  final String status;
  final String filePdf;

  StatusSelesaiModel({
    required this.idPengajuan,
    required this.namaSurat,
    required this.updatedAt,
    required this.status,
    required this.filePdf,
  });

  factory StatusSelesaiModel.fromJson(Map<String, dynamic> json) {
    return StatusSelesaiModel(
      idPengajuan: int.tryParse(json['id_pengajuan'].toString()) ?? 0,
      namaSurat: json['nama_surat'],
      updatedAt: json['updated_at'],
      status: json['status'],
      filePdf: json['file_pdf'],
    );
  }

  // Map<String, dynamic> toJson() {
  //   return {
  //     'nama_surat': namaSurat,
  //     'updated_at': updatedAt,
  //     'status': status,
  //     'file_pdf': filePdf,
  //   };
  // }
}
