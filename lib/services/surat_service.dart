class SuratService {

  static Map<String, String> syaratSurat = {

    "ktp": """
Syarat membuat KTP:
1. Fotokopi Kartu Keluarga
2. Surat pengantar RT/RW
3. Mengisi formulir permohonan
""",

    "kk": """
Syarat membuat Kartu Keluarga:
1. Buku nikah
2. KTP suami dan istri
3. Surat pengantar RT/RW
""",

    "akta kelahiran": """
Syarat Akta Kelahiran:
1. Kartu Keluarga
2. Surat Keterangan Lahir
3. KTP Orang Tua
""",

    "sktm": """
Syarat SKTM:
1. Fotokopi KTP
2. Fotokopi KK
3. Surat pengantar RT/RW
"""
  };

  static String? cekPertanyaan(String pesan) {

    pesan = pesan.toLowerCase();

    for (var key in syaratSurat.keys) {

      if (pesan.contains(key)) {

        return syaratSurat[key];

      }

    }

    return null;
  }
}