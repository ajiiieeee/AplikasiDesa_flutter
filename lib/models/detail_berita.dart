import '../config/globals.dart';

class Berita {
  final String idberita;
  final String judul;
  final String createdAt;
  final String deskripsi;
  final String? gambar;
  final String nik;
  final String? nama;

  Berita({
    required this.idberita,
    required this.judul,
    required this.createdAt,
    required this.deskripsi,
    this.gambar,
    required this.nik,
    this.nama,
  });

  factory Berita.fromJson(Map<String, dynamic> json) {
    return Berita(
      idberita: json['idberita'] ?? '',
      judul: json['judul'] ?? '',
      createdAt: json['created_at'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      gambar: json['gambar'],
      nik: json['nik'] ?? '',
      nama: json['nama'],
    );
  }

  String _fixUrl(String url) {
    return url
        .replaceAll('http://127.0.0.1:8000', serverURL)
        .replaceAll('http://localhost:8000', serverURL);
  }

  String get gambarDariDeskripsi {
    final regex = RegExp(
      r'''<img[^>]+src=["']([^"']+)["']''',
      caseSensitive: false,
    );

    final match = regex.firstMatch(deskripsi);

    if (match != null) {
      return _fixUrl(match.group(1)!);
    }

    return '';
  }

  String get gambarUtama {
    if (gambarDariDeskripsi.isNotEmpty) {
      return gambarDariDeskripsi;
    }

    if (gambar != null && gambar!.isNotEmpty) {
      return _fixUrl(gambar!);
    }

    return '';
  }
}
