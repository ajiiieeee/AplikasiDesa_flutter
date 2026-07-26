class SuratService {
  static String? cekPertanyaan(
    String pesan,
    List<Map<String, dynamic>> dataSurat,
  ) {
    final pesanLower = pesan.toLowerCase().trim();

    if (pesanLower.contains("jenis surat") ||
        pesanLower.contains("daftar surat") ||
        pesanLower.contains("surat apa saja") ||
        pesanLower.contains("apa saja surat") ||
        pesanLower.contains("macam macam surat") ||
        pesanLower.contains("layanan surat")) {
      return getDaftarSurat(dataSurat);
    }

    if (pesanLower.contains("cara mengajukan") ||
        pesanLower.contains("cara pengajuan") ||
        pesanLower.contains("ajukan surat") ||
        pesanLower.contains("pengajuan surat") ||
        pesanLower.contains("buat surat")) {
      return """
Cara mengajukan surat secara online:
1. Login ke aplikasi Digital Village
2. Masuk ke menu Pengajuan Surat
3. Pilih jenis surat yang ingin diajukan
4. Isi formulir pengajuan dengan benar
5. Upload berkas persyaratan yang diminta
6. Klik tombol Kirim Pengajuan
7. Tunggu proses verifikasi dari RT, RW, atau Admin Desa
8. Cek status pengajuan melalui menu Riwayat Pengajuan
""";
    }

    for (var item in dataSurat) {
      final namaSurat = item["nama_surat"].toString().toLowerCase();

      if (pesanLower.contains(namaSurat) ||
          _cocokAlias(pesanLower, namaSurat)) {
        return getDetailSurat(item);
      }
    }

    return null;
  }

  static bool _cocokAlias(String pesan, String namaSurat) {
    if (namaSurat.contains("kartu keluarga")) {
      return pesan.contains("kk");
    }

    if (namaSurat.contains("ktp")) {
      return pesan.contains("kartu tanda penduduk");
    }

    if (namaSurat.contains("akte kelahiran") ||
        namaSurat.contains("akta kelahiran")) {
      return pesan.contains("kelahiran") ||
          pesan.contains("akte") ||
          pesan.contains("akta");
    }

    if (namaSurat.contains("sktm")) {
      return pesan.contains("tidak mampu") || pesan.contains("surat miskin");
    }

    if (namaSurat.contains("akta perkawinan")) {
      return pesan.contains("perkawinan") ||
          pesan.contains("pernikahan") ||
          pesan.contains("nikah");
    }

    if (namaSurat.contains("akta kematian")) {
      return pesan.contains("kematian") || pesan.contains("meninggal");
    }

    if (namaSurat.contains("pindah penduduk")) {
      return pesan.contains("pindah") ||
          pesan.contains("surat pindah") ||
          pesan.contains("pindah alamat");
    }

    if (namaSurat.contains("pernyataan miskin")) {
      return pesan.contains("miskin") || pesan.contains("keterangan miskin");
    }

    return false;
  }

  static String getDaftarSurat(List<Map<String, dynamic>> dataSurat) {
    if (dataSurat.isEmpty) {
      return "Data surat belum tersedia.";
    }

    String jawaban =
        "Jenis surat yang tersedia di aplikasi Digital Village:\n\n";

    for (int i = 0; i < dataSurat.length; i++) {
      jawaban += "${i + 1}. ${dataSurat[i]["nama_surat"]}\n";
    }

    jawaban +=
        "\nUntuk mengajukan surat, masuk ke menu Pengajuan Surat lalu pilih jenis surat yang dibutuhkan.";

    return jawaban;
  }

  static String getDetailSurat(Map<String, dynamic> item) {
    final String namaSurat = item["nama_surat"] ?? "-";
    final List<String> syarat = List<String>.from(item["syarat"] ?? []);

    String jawaban = "Syarat $namaSurat:\n";

    if (syarat.isEmpty) {
      jawaban += "Persyaratan belum tersedia di database.\n";
    } else {
      for (int i = 0; i < syarat.length; i++) {
        jawaban += "${i + 1}. ${syarat[i]}\n";
      }
    }

    jawaban += """

Cara pengajuan:
1. Login ke aplikasi Digital Village
2. Masuk ke menu Pengajuan Surat
3. Pilih $namaSurat
4. Isi formulir pengajuan
5. Upload berkas persyaratan
6. Klik tombol Kirim Pengajuan
7. Tunggu proses verifikasi dari RT, RW, atau Admin Desa
""";

    return jawaban;
  }
}
