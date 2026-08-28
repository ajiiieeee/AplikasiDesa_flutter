class PengajuanModel {
  final int idPengajuan;
  final String namaSurat;
  final String namaPemohon;
  final String nik;
  final String status;
  final String keperluan;
  final String tanggalDiajukan;
  final String? keteranganDitolak;
  final List<String> fotos;
  final String? nomorSurat;
  final String? pdfUrl;

  PengajuanModel({
    required this.idPengajuan,
    required this.namaSurat,
    required this.namaPemohon,
    required this.nik,
    required this.status,
    required this.keperluan,
    required this.tanggalDiajukan,
    this.keteranganDitolak,
    required this.fotos,
    this.nomorSurat,
    this.pdfUrl,
  });

  factory PengajuanModel.fromJson(Map<String, dynamic> json) {
    List<String> fotosList = [];
    for (int i = 1; i <= 8; i++) {
      final key = 'foto$i';
      if (json[key] != null && json[key].toString().isNotEmpty && json[key] != 'null') {
        fotosList.add(json[key].toString());
      }
    }

    return PengajuanModel(
      idPengajuan: int.tryParse(json['id_pengajuan'].toString()) ?? 0,
      namaSurat: json['nama_surat']?.toString() ?? json['id_surat']?.toString() ?? 'Pengajuan Surat',
      namaPemohon: json['nama_lengkap']?.toString() ?? json['nama_pemohon']?.toString() ?? json['nik']?.toString() ?? 'Pemohon',
      nik: json['nik']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Diajukan',
      keperluan: json['keperluan']?.toString() ?? json['keterangan']?.toString() ?? '',
      tanggalDiajukan: json['tanggal_diajukan']?.toString() ?? json['created_at']?.toString() ?? '',
      keteranganDitolak: json['keterangan_ditolak']?.toString(),
      fotos: fotosList,
      nomorSurat: json['nomor_surat']?.toString(),
      pdfUrl: json['file_pdf_url']?.toString() ?? json['file_pdf']?.toString(),
    );
  }
}
