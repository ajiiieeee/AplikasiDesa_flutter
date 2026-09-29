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
  final String? updatedAt;

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
    this.updatedAt,
  });

  factory PengaduanModel.fromJson(Map<String, dynamic> json) {
    return PengaduanModel(
      id:            int.tryParse(json['id'].toString()) ?? 0,
      nik:           json['nik']?.toString() ?? '',
      namaPemohon:   json['nama_pemohon']?.toString() ?? 'Warga',
      kategori:      json['kategori']?.toString() ?? 'Lainnya',
      ulasan:        json['ulasan']?.toString() ?? '',
      fotoUrl:       json['foto1_url']?.toString(),
      feedbackAdmin: json['feedback_admin']?.toString(),
      isResponded:   json['is_responded'] == true || (json['feedback_admin'] != null && json['feedback_admin'].toString().isNotEmpty),
      createdAt:     json['created_at']?.toString() ?? '',
      updatedAt:     json['updated_at']?.toString(),
    );
  }

  /// Kembalikan salinan dengan field yang diperbarui
  PengaduanModel copyWith({
    String? kategori,
    String? ulasan,
    String? fotoUrl,
  }) {
    return PengaduanModel(
      id:            id,
      nik:           nik,
      namaPemohon:   namaPemohon,
      kategori:      kategori ?? this.kategori,
      ulasan:        ulasan ?? this.ulasan,
      fotoUrl:       fotoUrl ?? this.fotoUrl,
      feedbackAdmin: feedbackAdmin,
      isResponded:   isResponded,
      createdAt:     createdAt,
      updatedAt:     updatedAt,
    );
  }
}
