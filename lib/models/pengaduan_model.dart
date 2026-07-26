class PengaduanModel {
  final int id;
  final String nik;
  final String namaPemohon;
  final String kategori;
  final String ulasan;
  final String? fotoUrl;
  final String? feedbackAdmin;
  final bool isResponded;
  final String createdAt;

  PengaduanModel({
    required this.id,
    required this.nik,
    required this.namaPemohon,
    required this.kategori,
    required this.ulasan,
    this.fotoUrl,
    this.feedbackAdmin,
    required this.isResponded,
    required this.createdAt,
  });

  factory PengaduanModel.fromJson(Map<String, dynamic> json) {
    return PengaduanModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nik: json['nik']?.toString() ?? '',
      namaPemohon: json['nama_pemohon']?.toString() ?? 'Warga',
      kategori: json['kategori']?.toString() ?? 'Pengaduan',
      ulasan: json['ulasan']?.toString() ?? '',
      fotoUrl: json['foto1_url']?.toString(),
      feedbackAdmin: json['feedback_admin']?.toString(),
      isResponded: json['is_responded'] == true,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
