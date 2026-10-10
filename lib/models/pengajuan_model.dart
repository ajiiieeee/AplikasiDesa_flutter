import '../config/globals.dart';

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

  static String? _normalizeUrl(dynamic raw) {
    if (raw == null) return null;
    String s = raw.toString().trim();
    if (s.isEmpty || s == 'null' || s == '-' || s == 'default.jpg') return null;

    // Bersihkan duplikasi /storage/storage/ jika ada
    while (s.contains('/storage/storage/')) {
      s = s.replaceAll('/storage/storage/', '/storage/');
    }

    // Jika bukan URL absolut http/https, tambahkan serverURL
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      final clean = s.startsWith('/') ? s.substring(1) : s;
      return '$serverURL/$clean';
    }
    return s;
  }

  factory PengajuanModel.fromJson(Map<String, dynamic> json) {
    List<String> fotosList = [];

    // 1. Periksa array 'fotos' jika dikembalikan dari backend
    if (json['fotos'] is List) {
      for (var f in json['fotos']) {
        final url = _normalizeUrl(f);
        if (url != null && !fotosList.contains(url)) {
          fotosList.add(url);
        }
      }
    }

    // 2. Periksa key 'foto1' s/d 'foto8'
    for (int i = 1; i <= 8; i++) {
      final key = 'foto$i';
      final url = _normalizeUrl(json[key]);
      if (url != null && !fotosList.contains(url)) {
        fotosList.add(url);
      }
    }

    // 3. Periksa fallback key 'bukti1' s/d 'bukti8'
    for (int i = 1; i <= 8; i++) {
      final key = 'bukti$i';
      final url = _normalizeUrl(json[key]);
      if (url != null && !fotosList.contains(url)) {
        fotosList.add(url);
      }
    }

    return PengajuanModel(
      idPengajuan: int.tryParse(json['id_pengajuan'].toString()) ?? 0,
      namaSurat: json['nama_surat']?.toString() ??
          json['id_surat']?.toString() ??
          'Pengajuan Surat',
      namaPemohon: json['nama_lengkap']?.toString() ??
          json['nama_pemohon']?.toString() ??
          json['nik']?.toString() ??
          'Pemohon',
      nik: json['nik']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Diajukan',
      keperluan: json['keperluan']?.toString() ??
          json['keterangan']?.toString() ??
          '',
      tanggalDiajukan: json['tanggal_diajukan']?.toString() ??
          json['created_at']?.toString() ??
          '',
      keteranganDitolak: json['keterangan_ditolak']?.toString(),
      fotos: fotosList,
      nomorSurat: json['nomor_surat']?.toString(),
      pdfUrl: _normalizeUrl(json['file_pdf_url'] ?? json['file_pdf']),
    );
  }
}
